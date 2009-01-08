//
//  Universe.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDMockSingleton.h"

typedef enum
{
	SHADERS_NOT_SUPPORTED,
	SHADERS_OFF,
	SHADERS_SIMPLE,
	SHADERS_FULL
} OOShaderSetting;


@interface DDMockUniverse: DDMockSingleton
{
@private
	NSUInteger				_debugFlags;
}

+ (id) sharedUniverse;

- (void) handleOoliteException:(NSException *)exception;

@property NSUInteger debugFlags;
@property (readonly) BOOL reducedDetail;
@property (readonly) BOOL useShaders;
@property (readonly) OOShaderSetting shaderEffectsLevel;

@end


@compatibility_alias Universe DDMockUniverse;


#define UNIVERSE ((DDMockUniverse *)[DDMockUniverse sharedUniverse])

#define gDebugFlags [UNIVERSE debugFlags]


enum
{
	DEBUG_DRAW_NORMALS			= 0x0001,
	DEBUG_OCTREE_DRAW			= 0x0002,
	DEBUG_OCTREE_TEXT			= 0x0004,
	DEBUG_OCTREE				= 0x0008
};
