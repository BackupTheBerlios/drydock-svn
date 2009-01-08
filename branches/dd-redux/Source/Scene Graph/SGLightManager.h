//
//  SGLightManager.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "SGSceneGraphBase.h"

@class SGLight;


@interface SGLightManager: NSObject <NSFastEnumeration>
{
@private
	NSOpenGLContext		*_context;
	NSMutableSet		*_lights;
	NSUInteger			_activeCount, _maxCount;
}

- (id) initWithContext:(NSOpenGLContext *)context;
- (id) initWithCurrentContext;

@property (readonly) NSOpenGLContext *context;
@property (readonly) NSUInteger maxLights;	// If there are more than maxLights enabled lights, an undefined subset will be used.

- (NSEnumerator *) lightEnumerator;
- (void) addLight:(SGLight *)light;
- (void) removeLight:(SGLight *)light;

- (void) setUpLights;

@end


@interface SGLightManager (Conveniences)

- (void) removeAllLights;

- (void) enableAllLights;
- (void) disableAllLights;

@end
