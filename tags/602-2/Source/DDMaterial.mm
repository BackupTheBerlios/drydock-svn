/*
	DDMaterial.mm
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

#define ENABLE_TRACE 0

#import "DDMaterial.h"
#import "DDTextureBuffer.h"
#import "Logging.h"
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"


@interface DDMaterial(Private)

- (id)initWithTexture:(DDTextureBuffer *)inTexture;

@end


@implementation DDMaterial

+ (id)materialWithName:(NSString *)inName relativeTo:(NSURL *)inBaseFile issues:(DDProblemReportManager *)ioIssues
{
	TraceMessage(@"Called.");
	TraceIndent();
	
	id result = [[[self alloc] initWithName:inName relativeTo:inBaseFile issues:ioIssues] autorelease];
	
	TraceOutdent();
	
	return result;
}


+ (id)materialWithFile:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceMessage(@"Called.");
	TraceIndent();
	
	id result = [[[self alloc] initWithFile:inFile issues:ioIssues] autorelease];
	
	TraceOutdent();
	
	return result;
}


- (id)initWithName:(NSString *)inName relativeTo:(NSURL *)inBaseFile issues:(DDProblemReportManager *)ioIssues
{
	DDTextureBuffer			*texture;
	NSURL					*url;
	static NSBundle			*oolite = nil;
	NSURL					*ooliteURL;
	OSStatus				err;
	NSString				*path;
	
	TraceMessage(@"Called for %@ relative to %@.", inName, inBaseFile);
	TraceIndent();
	
	_texFileName = [inName retain];
	
	// Look for texture in same folder as base file
	TraceMessage(@"Looking in same folder");
	url = [NSURL URLWithString:inName relativeToURL:inBaseFile];
	texture = [DDTextureBuffer textureWithFile:url];
	
	if (nil == texture)
	{
		// Try in base/Textures/file
		TraceMessage(@"Looking in Textures/");
		url = [NSURL URLWithString:[@"Textures" stringByAppendingPathComponent:inName] relativeToURL:inBaseFile];
		texture = [DDTextureBuffer textureWithFile:url];
	}
	
	if (nil == texture)
	{
		// Try in base/../Textures/file
		url = [NSURL URLWithString:[[@".." stringByAppendingPathComponent:@"Textures"] stringByAppendingPathComponent:inName] relativeToURL:inBaseFile];
		url = [url standardizedURL];
		TraceMessage(@"Looking in ../Textures/ (%@)", url);
		texture = [DDTextureBuffer textureWithFile:url];
	}
	
	if (nil == texture)
	{
		// Find Oolite bundle if we haven’t already
		if (nil == oolite)
		{
			err = LSFindApplicationForInfo('Ool8', (CFStringRef)@"org.aegidian.oolite", NULL, NULL, (CFURLRef *)&ooliteURL);
			if (noErr == err && [ooliteURL isFileURL])
			{
			//	LogMessage(@"Oolite found at %@", [ooliteURL path]);
				oolite = [[NSBundle alloc] initWithPath:[ooliteURL path]];
			}
			[ooliteURL release];
		}
		
		if (nil != oolite)
		{
			// Try in [oolite]/Contents/Resources/Textures/file
			TraceMessage(@"Looking in [oolite]/Contents/Resources/Textures/");
			path = [oolite pathForResource:inName ofType:nil inDirectory:@"Textures"];
			if (nil != path) texture = [DDTextureBuffer textureWithFile:[NSURL fileURLWithPath:path]];
			
			if (nil == texture)
			{
				// Try in $OOLITE/Contents/Resources/file (because development builds don’t have a Textures subfolder)
				TraceMessage(@"Looking in [oolite]/Contents/Textures/");
				path = [oolite pathForResource:inName ofType:nil];
				if (nil != path) texture = [DDTextureBuffer textureWithFile:[NSURL fileURLWithPath:path]];
			}
		}
	}
	
	if (nil == texture)
	{
		[ioIssues addNoteIssueWithKey:@"textureNotFound" localizedFormat:@"No texture named \"%@\" could be found, using fallback texture.", inName];
		TraceMessage(@"Not found, using placeholder.");
		texture = [DDTextureBuffer placeholderTexture];
		if (nil == texture)
		{
			[self release];
			self = nil;
		}
	}
	
	if (nil != texture)
	{
		[self setDisplayName:inName];
		self = [self initWithTexture:texture];
	}
	
	if (nil == self)
	{
		[ioIssues addStopIssueWithKey:@"fallbackTextureNotLoaded" localizedFormat:@"The fallback texture could not be loaded. This probably indicates a memory problem."];
	}
	
	TraceOutdent();
	
	return self;
}


+ (id)placeholderMaterialForFileName:(NSString *)inName
{
	DDMaterial *result = [[[self alloc] initWithTexture:[DDTextureBuffer placeholderTexture]] autorelease];
	[result setDisplayName:@"Placeholder"];
	result->_texFileName = [inName retain];
	return result;
}


- (id)initWithFile:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	DDTextureBuffer			*texture;
	
	TraceMessage(@"Called.");
	TraceIndent();
	
	texture = [DDTextureBuffer textureWithFile:inFile];
	if (nil == texture) texture = [DDTextureBuffer placeholderTexture];
	
	if (nil != texture)
	{
		self = [self initWithTexture:texture];
	}
	else
	{
		[self release];
		self = nil;
		[ioIssues addStopIssueWithKey:@"noTextureDataLoaded" localizedFormat:@"No texture data could be loaded from %@.", [inFile displayString]];
	}
	
	TraceOutdent();
	
	return self;
}


// Designated initialiser
- (id)initWithTexture:(DDTextureBuffer *)inTexture;
{
	TraceMessage(@"Called.");
	TraceIndent();
	
	self = [super init];
	if (nil != self)
	{
		_texture = [inTexture retain];
	}
	
	TraceOutdent();
	
	return self;
}


- (void)dealloc
{
	TraceMessage(@"Called.");
	TraceIndent();
	
	[_texture release];
	[_displayName autorelease];
	[_texFileName autorelease];
	
	[super dealloc];
	
	TraceOutdent();
}


- (id)copyWithZone:(NSZone *)inZone
{
	TraceMessage(@"Called.");
	TraceIndent();
	
	DDMaterial *result = [[DDMaterial allocWithZone:inZone] initWithTexture:_texture];
	[result setDisplayName:_displayName];
	
	TraceOutdent();
	
	return result;
}


- (void)setDisplayName:(NSString *)inName
{
	[_displayName autorelease];
	_displayName = [inName retain];
}


- (NSString *)displayName
{
	return _displayName;
}


- (NSURL *)diffuseMapURL
{
	return [_texture file];
}


- (NSString *)diffuseMapName
{
	return _texFileName;
}


- (NSString *)keyName
{
	NSString *result;
	
	result = [self diffuseMapName];
	if (nil == result) result = [self displayName];
	
	return result;
}


- (void)makeActive
{
	GLint				wrapMode;
	GLint				magFilter;
	GLint				level;
	unsigned			w, h;
	
	if (0 == _texName)
	{
		// Set up GL texture
		glGenTextures(1, &_texName);
		glBindTexture(GL_TEXTURE_2D, _texName);
		[_texture setUpCurrentTexture];
	}
	else
	{
		glBindTexture(GL_TEXTURE_2D, _texName);
	}
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{\"%@\", texName=%u, texture=%@}", [self className], self, _displayName, _texName, _texture];
}

@end
