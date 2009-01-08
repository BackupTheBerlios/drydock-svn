//
//  SGSceneGraph.mm
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "SGSceneGraph.h"
#import "SGSceneNode.h"


NSString * const kSceneGraphStateKey = @"SGSceneGraph";


@implementation SGSceneGraph

@synthesize context = _context;
@synthesize rootNode = _root;


- (id) initWithContext:(NSOpenGLContext *)context
{
	if (context == nil)
	{
		context = [NSOpenGLContext currentContext];
		if (context == nil)
		{
			[self release];
			return nil;
		}
	}
	
	self = [super init];
	if (self != nil)
	{
		_context = [context retain];
	}
	
	return self;
}


- (id) initWithCurrentContext
{
	return [self initWithContext:nil];
}


- (id) init
{
	return [self initWithCurrentContext];
}


- (void) dealloc
{
	[_context release];
	[_root release];
	[_lightManager release];
	
	[super dealloc];
}


- (SGLightManager *) lightManager
{
	if (_lightManager == nil)
	{
		_lightManager = [[SGLightManager alloc] initWithContext:self.context];
	}
	return _lightManager;
}

- (void) render
{
	NSOpenGLContext *saved = [NSOpenGLContext currentContext];
	if (saved != _context)  [_context makeCurrentContext];
	
	NSAutoreleasePool *releasePool = nil;
	@try
	{
		releasePool = [[NSAutoreleasePool alloc] init];
		
		if (_lightManager != nil)
		{
			glMatrixMode(GL_MODELVIEW);
			glPushMatrix();
			glLoadIdentity();
			[_lightManager setUpLights];
			glPopMatrix();
		}
		[_root renderWithState:$dict(kSceneGraphStateKey, self)];
	}
	@catch (id exception)
	{
		// Hoist exception out of our autorelease pool
		[exception retain];
		[releasePool release];
		releasePool = nil;
		[exception autorelease];
		@throw (exception);
	}
	@finally
	{
		[releasePool drain];
		if (saved != _context)  [saved makeCurrentContext];
	}
}

@end
