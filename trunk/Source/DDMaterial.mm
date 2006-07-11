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
#import "DDUtilities.h"


@interface DDMaterial(Private)

- (id)initWithTexture:(DDTextureBuffer *)inTexture;

@end


@implementation DDMaterial

+ (id)materialWithName:(NSString *)inName
{
	TraceEnter();
	
	return [[[self alloc] initWithName:inName] autorelease];
	
	TraceExit();
}


- (id)initWithName:(NSString *)inName
{
	TraceEnterMsg(@"Called with name=\"%@\" {", inName);
	
	self = [super init];
	if (nil != self)
	{
		_name = [inName copy];
	}
	
	return self;
	TraceExit();
}


#ifndef FACELESS

- (void)setDiffuseMap:(NSString *)inFileName relativeTo:(NSURL *)inBaseFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnterMsg(@"Called for %@ relative to %@.", inFileName, inBaseFile);
	
	DDTextureBuffer			*texture;
	NSURL					*url;
	NSString				*ooliteResources;
	NSString				*path;
	
	// Look for texture in same folder as base file
	TraceMessage(@"Looking in same folder");
	url = [NSURL URLWithString:inFileName relativeToURL:inBaseFile];
	texture = [DDTextureBuffer textureWithFile:url issues:ioIssues];
	
	if (nil == texture)
	{
		// Try in base/Textures/file
		TraceMessage(@"Looking in Textures/");
		url = [NSURL URLWithString:[@"Textures" stringByAppendingPathComponent:inFileName] relativeToURL:inBaseFile];
		texture = [DDTextureBuffer textureWithFile:url issues:ioIssues];
	}
	
	if (nil == texture)
	{
		// Try in base/../Textures/file
		url = [NSURL URLWithString:[[@".." stringByAppendingPathComponent:@"Textures"] stringByAppendingPathComponent:inFileName] relativeToURL:inBaseFile];
		url = [url standardizedURL];
		TraceMessage(@"Looking in ../Textures/ (%@)", url);
		texture = [DDTextureBuffer textureWithFile:url issues:ioIssues];
	}
	
	if (nil == texture)
	{
		// Find Oolite bundle if we haven’t already
		ooliteResources = LocationOfOoliteResources();
		
		if (nil != ooliteResources)
		{
			// Try in $OOLITE/Contents/Resources/Textures/file
			TraceMessage(@"Looking in [oolite]/Contents/Resources/Textures/");
			path = [ooliteResources stringByAppendingPathComponent:@"Textures"];
			path = [path stringByAppendingPathComponent:inFileName];
			if (nil != path) texture = [DDTextureBuffer textureWithFile:[NSURL fileURLWithPath:path] issues:ioIssues];
			
			if (nil == texture)
			{
				// Try in $OOLITE/Contents/Resources/file (because development builds don’t have a Textures subfolder)
				TraceMessage(@"Looking in [oolite]/Contents/Resources/");
				path = [ooliteResources stringByAppendingPathComponent:inFileName];
				if (nil != path) texture = [DDTextureBuffer textureWithFile:[NSURL fileURLWithPath:path] issues:ioIssues];
			}
		}
	}
	
	if (nil == texture)
	{
		TraceMessage(@"Not found, using placeholder.");
		[ioIssues addNoteIssueWithKey:@"textureNotFound" localizedFormat:@"No texture named \"%@\" could be found, using fallback texture.", inFileName];
		texture = [DDTextureBuffer placeholderTextureWithIssues:ioIssues];
		if (nil == texture)
		{
			TraceMessage(@"Couldn't load placeholder, using nil material.");
			[self release];
			self = nil;
		}
	}
	
	if (nil != texture)
	{
		[_diffuseMapName release];
		_diffuseMapName = [inFileName copy];
		
		#ifndef FACELESS
			[_diffuseTexture release];
			_diffuseTexture = [texture retain];
			_diffuseGLName = 0;
		#endif
	}
	
	TraceExit();
}

#else

- (void)setDiffuseMap:(NSString *)inFileName relativeTo:(NSURL *)inBaseFile issues:(DDProblemReportManager *)ioIssues
{
	[_diffuseMapName release];
	_diffuseMapName = [inFileName copy];
}

#endif


- (void)dealloc
{
	TraceEnter();
	
	[_name release];
	[_diffuseMapName autorelease];
	#ifndef FACELESS
		[_diffuseTexture autorelease];
	#endif
	
	[super dealloc];
	
	TraceExit();
}


- (id)copyWithZone:(NSZone *)inZone
{
	TraceEnter();
	
	DDMaterial *result = [[DDMaterial allocWithZone:inZone] initWithName:_name];
	result->_diffuseMapName = [_diffuseMapName copyWithZone:inZone];
	
	#ifndef FACELESS
		result->_diffuseTexture = [_diffuseTexture retain];
	#endif
	
	return result;
	TraceExit();
}


- (void)setName:(NSString *)inName
{
	[_name autorelease];
	_name = [inName retain];
}


- (NSString *)name
{
	return _name;
}


- (NSString *)diffuseMapName
{
	return _diffuseMapName;
}


#ifndef FACELESS

- (void)makeActive
{
	if (nil == _diffuseTexture)
	{
		_diffuseTexture = [DDTextureBuffer placeholderTextureWithIssues:nil];
	}
	
	if (0 == _diffuseGLName)
	{
		// Set up GL texture
		glGenTextures(1, &_diffuseGLName);
		glBindTexture(GL_TEXTURE_2D, _diffuseGLName);
		[_diffuseTexture setUpCurrentTexture];
	}
	else
	{
		glBindTexture(GL_TEXTURE_2D, _diffuseGLName);
	}
}

#endif


- (id)initWithPropertyListRepresentation:(id)inPList issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	BOOL						OK = YES;
	NSDictionary				*dict;
	id							object;
	
	if (![inPList isKindOfClass:[NSDictionary class]])
	{
		OK = NO;
		LogMessage(@"Input %@ is not a dictionary.", inPList);
		[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
	}
	
	if (OK)
	{
		dict = inPList;
		
		object = [dict objectForKey:@"name"];
		if ([object isKindOfClass:[NSString class]]) _name = [object copy];
		object = [dict objectForKey:@"diffuse map"];
		if ([object isKindOfClass:[NSString class]]) _diffuseMapName = [object copy];
		
		if (nil == _name) _name = [_diffuseMapName copy];
		else if (nil == _diffuseMapName) _diffuseMapName = [_name copy];
	}
	
	
	if (!OK)
	{
		[self release];
		self = nil;
	}
	return self;
	TraceExit();
}


- (void)gatherIssuesWithGeneratingPropertyListRepresentation:(DDProblemReportManager *)ioManager
{
	// Nothing to do.
}


- (id)propertyListRepresentationWithIssues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	NSMutableDictionary	*result;
	
	result = [[NSMutableDictionary alloc] initWithCapacity:2];
	if (nil == result)
	{
		[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		return nil;
	}
	
	if (nil != _diffuseMapName) [result setObject:_diffuseMapName forKey:@"diffuse map"];
	if (nil != _name && ![_diffuseMapName isEqual:_name]) [result setObject:_name forKey:@"name"];
	
	return result;
	
	TraceExit();
}


- (NSString *)description
{
	#ifndef FACELESS
		return [NSString stringWithFormat:@"<%@ %p>{\"%@\", diffuse map=%@}", [self className], self, _name, _diffuseTexture];
	#else
		return [NSString stringWithFormat:@"<%@ %p>{\"%@\", diffuse map=%@}", [self className], self, _name, _diffuseMapName];
	#endif
}

@end
