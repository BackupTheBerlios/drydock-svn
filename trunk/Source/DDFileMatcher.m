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


@implementation DDFileMatcher

+ (id)matcherWithUTI:(NSString *)utiString
{
	return [[[DDUTIFileMatcher alloc] initWithUTI:utiString] autorelease];
}


+ (id)matcherWithExtension:(NSString *)extensionString
{
	return [[[DDUTIFileMatcher alloc] initWithExtension:extensionString] autorelease];
}


+ (id)matcherWithCreator:(FileType)creator
{
	return [[[DDUTIFileMatcher alloc] initWithCreator:creator] autorelease];
}


- (BOOL)matchesFileAtPath:(NSString *)inPath
{
	return NO;	// stub implementation
}

@end


@implementation DDUTIFileMatcher: DDFileMatcher

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
	CFTypeRef				fileUTI = NULL;
	
	url = [NSURL fileURLWithPath:inPath];
	if (nil != url)
	{
		if (CFURLGetFSRef((CFURLRef)url, &fsRef))
		{
			LSCopyItemAttribute(&fsRef, kLSRolesAll, (CFStringRef)@"LSItemContentType", &fileUTI);
			[(NSString *)fileUTI autorelease];
		}
	}
	
	return (NULL != fileUTI && UTTypeConformsTo(fileUTI, _uti));
}


- (id)description
{
	return [NSString stringWithFormat:@"<%@ %p>{uti=%@ (%@)}", [self className], self, _uti, [(NSString *)UTTypeCopyDescription(_uti) autorelease]];
}

@end
