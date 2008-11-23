/*
	DDSceneView.mm
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

#import "DDSceneView.h"
#import "DDLightController.h"
#import "Logging.h"
#import "GLUtilities.h"
#import "SceneNode.h"

NSString *kNotificationDDSceneViewSceneChanged = @"de.berlios.drydock kNotificationDDSceneViewSceneChanged";
NSString *kNotificationDDSceneViewCameraOrLightChanged = @"de.berlios.drydock kNotificationDDSceneViewCameraOrLightChanged";


#define USE_MULTISAMPLE 1


static const GLuint kAttributes[] =
{
	NSOpenGLPFAWindow,
	NSOpenGLPFANoRecovery,
	NSOpenGLPFAAccelerated,
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFAColorSize, 24,
	NSOpenGLPFAAlphaSize, 8,
	NSOpenGLPFADepthSize, 24,
	#if USE_MULTISAMPLE
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples,4,
	#endif
	0
};


static const GLuint kFallbackAttributes[] =
{
	NSOpenGLPFAWindow,
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFAColorSize, 24,
	NSOpenGLPFAAlphaSize, 8,
	NSOpenGLPFADepthSize, 24,
	0
};


@interface DDSceneView(Private)

- (void)beginDragForEvent:(NSEvent *)inEvent;
- (void)endDrag;
- (void)handleDragEvent:(NSEvent *)inEvent;

- (void)handleCameraDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY;

- (Vector)virtualTrackballLocationForPoint:(NSPoint)inPoint;

@end


@implementation DDSceneView


- (id) initWithFrame:(NSRect)frame
{
	TraceEnter();
	
	NSOpenGLPixelFormat		*fmt;
	
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kAttributes];
	if (nil == fmt) fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kFallbackAttributes];
	
	if (!fmt)
	{
		LogMessage(@"No OpenGL pixel format");
		[self release];
		return nil;
	}
	
	_transform.RotateY(-30.0f * M_PI / 180.0f);
	_transform.RotateX(20.0f * M_PI / 180.0f);
	_transform.Orthogonalize();
	
	self = [super initWithFrame:frame pixelFormat:[fmt autorelease]];
	
	return self;
	
	TraceExit();
}


- (void)dealloc
{
	[_lightController autorelease];
	
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:nil object:self];
	[super dealloc];
}


- (DDLightController *)lightController
{
	if (nil == _lightController)
	{
		_lightController = [[DDLightController alloc] init];
	}
	return _lightController;
}


- (void)setLightController:(DDLightController *)inLightController
{
	if (inLightController != _lightController)
	{
		[_lightController autorelease];
		_lightController = [inLightController retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDSceneViewSceneChanged object:self];
	}
}


- (void)setCameraDistance:(float)inZ
{
	TraceMessage(@"Setting Z to %g", inZ);
	TraceIndent();
	
	if (-0.5f < inZ) inZ = -0.5f;
	if (_z != inZ)
	{
		_z = inZ;
		[self setNeedsDisplay:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDSceneViewCameraOrLightChanged object:self];
	}
	
	TraceOutdent();
}


- (float)cameraDistance
{
	return _z;
}


- (Matrix)transformationMatrix
{
	return _transform;
}


- (void)setTransformationMatrix:(Matrix)inMatrix
{
	_transform = inMatrix;
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDSceneViewCameraOrLightChanged object:self];
}


- (void)setObjectSize:(float)inRadius
{
	TraceMessage(@"Changing object radius to %g.", inRadius);
	TraceIndent();
	
	if (inRadius < 1) inRadius = 1;
	[self setCameraDistance:inRadius * -2.5];
	[[self lightController] setLightDistance:inRadius * 4];
	
	TraceOutdent();
}


- (void)prepareOpenGL
{
	TraceEnter();
	
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClearDepth(1.0);
	
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_DEPTH_TEST);
	
	glShadeModel(GL_SMOOTH);
	glEnable(GL_LIGHTING);
	
//	glEnable(GL_CULL_FACE);
	glFrontFace(GL_CCW);
	glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, NO);
	
	#if USE_MULTISAMPLE
		glEnable(GL_MULTISAMPLE_ARB);
	#endif
	
	glEnable(GL_TEXTURE_2D);
	
	glPointSize(3);
	glLineWidth(1);
	
	glEnable(GL_POLYGON_OFFSET_FILL);
	glPolygonOffset(1, 1);
	
	LogGLErrors();
	
	TraceExit();
}


- (void)rebuildDisplayList
{
	[[self sceneRoot] becomeDirtyDownwards];
}


- (void)drawRect:(NSRect)inRect
{
	TraceEnter();
	
	SceneNode				*sceneRoot;
	
	if (inRect.size.width != _oldSize.width || inRect.size.height != _oldSize.height || _z != _oldZ)
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glViewport(0, 0, (GLsizei)inRect.size.width, (GLsizei)inRect.size.height);
		float near = 0.2f;
		if (near < -3000.0f - _z) near = -3000.0f - _z;
		gluPerspective(45.0f, inRect.size.width / inRect.size.height, near, 3000.0f - _z);
		_oldSize.width = inRect.size.width;
		_oldSize.height = inRect.size.height;
		_oldZ = _z;
		glMatrixMode(GL_MODELVIEW);
	}
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	
	@try
	{
		glTranslatef(0, 0, _z);
		
		[[self lightController] updateLightState];
		if ([self drawLightVector]) [[self lightController] drawLightPos];
		
		_transform.glMult();
		
		sceneRoot = [self sceneRoot];
		if (sceneRoot != _oldSceneRoot)
		{
			// Craptacular hack: cause display list to be rebuilt after a fraction of a second. Dunno why, but this improves rendering performance.
			[self performSelector:@selector(rebuildDisplayList) withObject:nil afterDelay:0.2];
			_oldSceneRoot = sceneRoot;
		}
		[sceneRoot render];
	}
	@catch (id ex)
	{
		LogMessage(@"Exception \"%@\" rendering.", ex);
	}
	
	//glFlush();
	[[self openGLContext] flushBuffer];
	LogGLErrors();
	
	TraceExit();
}


- (void)noteSceneRootChanged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDSceneViewSceneChanged object:self];
}


- (SceneNode *)sceneRoot
{
	return nil;
}


- (BOOL)drawLightVector
{
	return kDragAction_rotateLight == _dragAction;
}


- (BOOL)isOpaque
{
	return YES;
}


- (void)beginDragForEvent:(NSEvent *)inEvent
{
	_dragAction = [self dragActionForEvent:inEvent];
}


- (void)endDrag
{
	_dragAction = kDragAction_none;
	[self setNeedsDisplay:YES];
}


- (unsigned)filterModifiers:(unsigned)inModifiers forDragActionForEvent:(NSEvent *)inEvent
{
	return inModifiers;
}


- (unsigned)dragActionForEvent:(NSEvent *)inEvent
{
	unsigned				button;
	unsigned				modifiers;
	NSPoint					where;
	unsigned				result = kDragAction_none;
	
	where = [inEvent locationInWindow];
	where = [self convertPoint:where fromView:nil];
	
	_dragPoint = [self virtualTrackballLocationForPoint:where];
	
	button = [inEvent buttonNumber];
	modifiers = [inEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	modifiers = [self filterModifiers:modifiers forDragActionForEvent:inEvent];
	
	if (1 == button)
	{
		// Right-drag works like holding down option.
		modifiers |= NSAlternateKeyMask;
		button = 0;
	}
	
	if (0 == button)
	{
		if (0 == modifiers)
		{
			// Left-click
			result = kDragAction_currentTool;
		}
		else if (NSAlternateKeyMask == modifiers)
		{
			// Option-left: rotate object
			result = kDragAction_rotateObject;
		}
		else if ((NSAlternateKeyMask | NSShiftKeyMask) == modifiers)
		{
			// Option-shift-left: rotate light
			result = kDragAction_rotateLight;
		}
		else if (NSCommandKeyMask == modifiers || (NSAlternateKeyMask | NSCommandKeyMask) == modifiers)
		{
			// Command-left: move camera
			result = kDragAction_moveCamera;
		}
	}
	else if (2 == button)
	{
		if (0 == modifiers)
		{
			// Button-3 click: move camera
			result = kDragAction_moveCamera;
		}
	}
	else if (3 == button)
	{
		if (0 == modifiers)
		{
			// Button-4 click: rotate light
			result = kDragAction_rotateLight;
		}
	}
	
	return result;
}


- (void)handleDragEvent:(NSEvent *)inEvent
{
	NSPoint					where;
	Vector					newDragPoint, delta, axis;
	float					dx, dy;
	
	dx = [inEvent deltaX];
	dy = [inEvent deltaY];
	
	switch (_dragAction)
	{
		case kDragAction_rotateObject:
			where = [inEvent locationInWindow];
			where = [self convertPoint:where fromView:nil];
			newDragPoint = [self virtualTrackballLocationForPoint:where];
			delta = newDragPoint - _dragPoint;
			if (0.001f < delta)
			{
				// Rotate about the axis that is perpendicular to the great circle connecting the mouse points.
				axis = _dragPoint % newDragPoint;
				_transform.RotateAroundAxis(axis, delta.Magnitude());
				[self setNeedsDisplay:YES];
				_dragPoint = newDragPoint;
			}
			break;
		
		case kDragAction_rotateLight:
			[[self lightController] handleDragDeltaX:dx deltaY:dy];
			[self setNeedsDisplay:YES];
			break;
		
		case kDragAction_moveCamera:
			[self handleCameraDragDeltaX:dx deltaY:dy];
			[self setNeedsDisplay:YES];
			break;
		
		default:
			[self handleCustomDragEvent:inEvent];
			return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDSceneViewCameraOrLightChanged object:self];
}


- (void)handleCustomDragEvent:(NSEvent *)inEvent
{
	
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if (NSControlKeyMask == [theEvent modifierFlags]) [super mouseDown:theEvent];	// Pass through for contextual menu handling
	else [self beginDragForEvent:theEvent];
}


- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self beginDragForEvent:theEvent];
}


- (void)otherMouseDown:(NSEvent *)theEvent
{
	[self beginDragForEvent:theEvent];
}


- (void)mouseUp:(NSEvent *)theEvent
{
	[self endDrag];
}


- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self endDrag];
}


- (void)otherMouseUp:(NSEvent *)theEvent
{
	[self endDrag];
}


- (void)mouseDragged:(NSEvent *)theEvent
{
	[self handleDragEvent:theEvent];
}


- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self handleDragEvent:theEvent];
}


- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[self handleDragEvent:theEvent];
}


- (void)scrollWheel:(NSEvent *)theEvent
{
	float				delta;
	
	delta = [theEvent deltaZ];
	if (0.0f == delta) delta = [theEvent deltaY];	// True in approximately 100% of cases
	
	[self setCameraDistance:_z * (1.0 + (delta * 0.1f))];
}


- (void)handleCameraDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY
{
	[self setCameraDistance:_z * (1.0 - (inDeltaY * 0.01f))];
}


- (Vector)virtualTrackballLocationForPoint:(NSPoint)inPoint
{
	Vector					result;
	float					d;
	NSRect					frame;
	
	frame = [self frame];
	
	result.x = (2.0f * inPoint.x - frame.size.width) / frame.size.width;
	result.y = (2.0f * inPoint.y - frame.size.height) / frame.size.height;
	result.z = 0;
	
	d = result.SquareMagnitude();
	if (1.0f < d) d = 1.0f;
	result.z = sqrtf(1.0001 - d);
	result.Normalize();
	
	return result;
}


- (BOOL)shouldBeTreatedAsInkEvent:(NSEvent *)theEvent
{
	// Don’t use write-anywhere (i.e., be an “instant mouser”)
	return NO;
}

@end
