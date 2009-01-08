//
//  Universe.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "Universe.h"
#import "OOOpenGLExtensionManager.h"


@implementation DDMockUniverse

@synthesize debugFlags = _debugFlags;


+ (id) sharedUniverse
{
	return [self sharedInstance];
}


- (void) handleOoliteException:(NSException *)exception
{
	// FIXME
	NSLog(@"Got an internal Oolite exception: %@, %@. What am I supposed to do with it?", exception.name, exception.reason);
}


- (BOOL) reducedDetail
{
	return NO;
}


- (BOOL) useShaders
{
	return [[OOOpenGLExtensionManager sharedManager] shadersSupported];
}


- (OOShaderSetting) shaderEffectsLevel
{
	return self.useShaders ? SHADERS_FULL : SHADERS_NOT_SUPPORTED;
}

@end
