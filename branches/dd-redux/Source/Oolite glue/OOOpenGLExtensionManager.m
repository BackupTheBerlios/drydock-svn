//
//  OOOpenGLExtensionManager.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOOpenGLExtensionManager.h"


static unsigned IntegerFromString(const GLubyte **ioString);


@implementation OOOpenGLExtensionManager

+ (id) sharedManager
{
	return [self sharedInstance];
}


- (BOOL) shadersSupported
{
	return [self.mockSingletonContext.owner shadersSupported];
}


- (NSSet *) extensions
{
	// Extensions are cached for current context.
	NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
	if (currentContext == nil)  return nil;
	
	if (_glContext != currentContext)
	{
		_glContext = nil;
		_extensions = nil;
	}
	
	if (_extensions == nil)
	{
		_glContext = currentContext;
		NSString *extensionString = [NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)];
		NSArray *components = [extensionString componentsSeparatedByString:@" "];
		_extensions = [NSSet setWithArray:components];
	}
	
	return _extensions;
}


- (BOOL) haveExtension:(NSString *)extension
{
	return [self.extensions containsObject:extension];
}


- (unsigned)majorVersionNumber
{
	unsigned result;
	[self getVersionMajor:&result minor:NULL release:NULL];
	return result;
}


- (unsigned)minorVersionNumber
{
	unsigned result;
	[self getVersionMajor:NULL minor:&result release:NULL];
	return result;
}


- (unsigned)releaseVersionNumber
{
	unsigned result;
	[self getVersionMajor:NULL minor:NULL release:&result];
	return result;
}


- (void)getVersionMajor:(unsigned *)outMajor minor:(unsigned *)outMinor release:(unsigned *)outRelease
{
	const GLubyte		*versionString = NULL, *curr = NULL;
	unsigned			vMajor = 0, vMinor = 0, vRelease = 0;
	
	versionString = glGetString(GL_VERSION);
	if (versionString != NULL)
	{
		/*	String is supposed to be "major.minorFOO" or
		 "major.minor.releaseFOO" where FOO is an empty string or
		 a string beginning with space.
		 */
		curr = versionString;
		vMajor = IntegerFromString(&curr);
		if (*curr == '.')
		{
			curr++;
			vMinor = IntegerFromString(&curr);
		}
		if (*curr == '.')
		{
			curr++;
			vRelease = IntegerFromString(&curr);
		}
	}
	
	if (outMajor != NULL)  *outMajor = vMajor;
	if (outMinor != NULL)  *outMinor = vMinor;
	if (outRelease != NULL)  *outRelease = vRelease;
}

@end


static unsigned IntegerFromString(const GLubyte **ioString)
{
	if (ioString == NULL)  return 0;
	
	unsigned		result = 0;
	const GLubyte	*curr = *ioString;
	
	while ('0' <= *curr && *curr <= '9')
	{
		result = result * 10 + *curr++ - '0';
	}
	
	*ioString = curr;
	return result;
}
