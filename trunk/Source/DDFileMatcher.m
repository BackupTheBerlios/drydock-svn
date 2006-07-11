/*
	DDFileMatcher.m
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2006 Jens Ayton

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the “Software”), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all copies or
	substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#define DLOPEN_NO_WARN

#import "DDFileMatcher.h"
#import "DDUtilities.h"
#import <dlfcn.h>


#if 0
	// Testing covenience
	#ifdef TigerOrLater
		#undef TigerOrLater
	#endif
	#define TigerOrLater() 0
#endif


OSStatus (*LSCopyItemAttribute_ptr)(
  const FSRef *  inItem,
  LSRolesMask    inRoles,
  CFStringRef    inAttributeName,
  CFTypeRef *    outValue) = NULL;


// Note: this is a class cluster. There is one implementation for Tiger and later, and one for Panther.


@interface DDFileMatcher (Private)

- (id)initWithUTI:(NSString *)utiString;
- (id)initWithExtension:(NSString *)extensionString;
- (id)initWithCreator:(FileType)creator;

@end


@interface DDUTIFileMatcher: DDFileMatcher
{
	CFStringRef				_uti;
}
@end


@interface DDPantherFileMatcher: DDFileMatcher
{
	NSString				*_extension;
	FileType				_creator;
}
@end


@implementation DDFileMatcher

+ (id)matcherWithUTI:(NSString *)utiString
{
	if (TigerOrLater())
	{
		return [[[DDUTIFileMatcher alloc] initWithUTI:utiString] autorelease];
	}
	else
	{
		return [[[DDPantherFileMatcher alloc] initWithUTI:utiString] autorelease];
	}
}


+ (id)matcherWithExtension:(NSString *)extensionString
{
	if (TigerOrLater())
	{
		return [[[DDUTIFileMatcher alloc] initWithExtension:extensionString] autorelease];
	}
	else
	{
		return [[[DDPantherFileMatcher alloc] initWithExtension:extensionString] autorelease];
	}
}


+ (id)matcherWithCreator:(FileType)creator
{
	if (TigerOrLater())
	{
		return [[[DDUTIFileMatcher alloc] initWithCreator:creator] autorelease];
	}
	else
	{
		return [[[DDPantherFileMatcher alloc] initWithCreator:creator] autorelease];
	}
}


- (BOOL)matchesFileAtPath:(NSString *)inPath
{
	return NO;	// stub implementation
}

@end


@implementation DDUTIFileMatcher: DDFileMatcher

- (id)init
{
	CFBundleRef				launchServicesBundle;
	
	self = [super init];
	if (nil != self)
	{
		if (NULL == LSCopyItemAttribute_ptr)
		{
			launchServicesBundle = CFBundleGetBundleWithIdentifier((CFStringRef)@"com.apple.LaunchServices");
			if (NULL != launchServicesBundle)
			{
				LSCopyItemAttribute_ptr = CFBundleGetFunctionPointerForName(launchServicesBundle, (CFStringRef)@"LSCopyItemAttribute");
			}
		}
		if (NULL == LSCopyItemAttribute_ptr)
		{
			[self release];
			self = nil;
		}
	}
	return self;
}


- (id)initWithUTI:(NSString *)utiString
{
	self = [self init];
	if (nil != self)
	{
		_uti = (CFStringRef)[utiString copy];
	}
	
	return self;
}


- (id)initWithExtension:(NSString *)extensionString
{
	self = [self init];
	if (nil != self)
	{
		_uti = UTTypeCreatePreferredIdentifierForTag(CFSTR("public.filename-extension"), (CFStringRef)extensionString, NULL);
		if (NULL == _uti)
		{
			self = nil;
			[self release];
		}
	}
	
	return self;
}


- (id)initWithCreator:(FileType)creator
{
	self = [self init];
	if (nil != self)
	{
		NSString			*creatorString;
		
		creatorString = [[NSString alloc] initWithBytes:&creator length:4 encoding:NSMacOSRomanStringEncoding];
		
		_uti = UTTypeCreatePreferredIdentifierForTag(CFSTR("com.apple.ostype"), (CFStringRef)creatorString, NULL);
		if (NULL == _uti)
		{
			self = nil;
			[self release];
		}
		
		[creatorString release];
	}
	
	return self;
}

- (BOOL)matchesFileAtPath:(NSString *)inPath
{
	FSRef					fsRef;
	NSURL					*url;
	NSString				*fileUTI;
	
	url = [NSURL fileURLWithPath:inPath];
	if (nil != url)
	{
		if (CFURLGetFSRef((CFURLRef)url, &fsRef))
		{
			LSCopyItemAttribute_ptr(&fsRef, kLSRolesAll, (CFStringRef)@"LSItemContentType", (CFTypeRef *)&fileUTI);
			[fileUTI autorelease];
		}
	}
	
	return (nil != fileUTI && UTTypeConformsTo((CFStringRef)fileUTI, _uti));
}


- (id)description
{
	return [NSString stringWithFormat:@"<%@ %p>{uti=%@ (%@)}", [self className], self, _uti, [(NSString *)UTTypeCopyDescription(_uti) autorelease]];
}

@end


@implementation DDPantherFileMatcher: DDFileMatcher

- (id)initWithUTI:(NSString *)utiString
{
	NSBundle				*bundle;
	NSArray					*utis;
	NSDictionary			*utiSpec, *matchedUTI = nil;
	NSEnumerator			*utiEnum;
	NSString				*creatorString;
	NSData					*creatorData;
	
	self = [super init];
	if (nil != self)
	{
		@try
		{
			// Search for matching UTI spec
			bundle = [NSBundle mainBundle];
			// …in exported declarations
			utis = [bundle objectForInfoDictionaryKey:@"UTExportedTypeDeclarations"];
			for (utiEnum = [utis objectEnumerator]; (utiSpec = [utiEnum nextObject]); )
			{
				if ([[utiSpec objectForKey:@"UTTypeIdentifier"] isEqual:utiString])
				{
					matchedUTI = utiSpec;
				}
			}
			if (nil == matchedUTI)
			{
				// …or imported declarations
				utis = [bundle objectForInfoDictionaryKey:@"UTImportedTypeDeclarations"];
				for (utiEnum = [utis objectEnumerator]; (utiSpec = [utiEnum nextObject]); )
				{
					if ([[utiSpec objectForKey:@"UTTypeIdentifier"] isEqual:utiString])
					{
						matchedUTI = utiSpec;
					}
				}
			}
		}
		@catch (id whatever) {}
		
		if (nil != matchedUTI)
		{
			utiSpec = [matchedUTI objectForKey:@"UTTypeTagSpecification"];
			_extension = [[[utiSpec objectForKey:@"public.filename-extension"] objectAtIndex:0] retain];
			creatorString = [[utiSpec objectForKey:@"com.apple.ostype"] objectAtIndex:0];
			if (nil != creatorString)
			{
				creatorData = [creatorString dataUsingEncoding:NSMacOSRomanStringEncoding];
				if (4 == [creatorData length])
				{
					_creator = *(uint32_t *)[creatorData bytes];
				}
			}
		}
		
		if (nil == _extension && 0 == _creator)
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (id)initWithExtension:(NSString *)extensionString
{
	self = [super init];
	if (nil != self)
	{
		_extension = [extensionString copy];
		// TODO: walk CFBundleDocumentTypes to look for matching creator
	}
	
	return self;
}


- (id)initWithCreator:(FileType)creator
{
	self = [super init];
	if (nil != self)
	{
		_creator = creator;
		// TODO: walk CFBundleDocumentTypes to look for matching extension
	}
	
	return self;
}


- (BOOL)matchesFileAtPath:(NSString *)inPath
{
	FileType				fileCreator;
	NSString				*fileExtension;
	NSFileManager			*fileManager;
	
	fileManager = [NSFileManager defaultManager];
	
	if (_creator)
	{
		fileCreator = [[fileManager fileAttributesAtPath:inPath traverseLink:YES] fileHFSCreatorCode];
		if (fileCreator == _creator) return YES;
	}
	if (_extension)
	{
		fileExtension = [inPath pathExtension];
		if ([fileExtension isEqual:_extension]) return YES;
	}
	
	return NO;
}


- (id)description
{
	return [NSString stringWithFormat:@"<%@ %p>{creator='%@', extension=%@}", [self className], self, _creator ? [[[NSString alloc] initWithBytes:&_creator length:4 encoding:NSMacOSRomanStringEncoding] autorelease] : @"\?\?\?\?", _extension];
}

@end
