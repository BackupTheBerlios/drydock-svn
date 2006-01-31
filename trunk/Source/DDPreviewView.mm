/*
	DDPreviewView.mm
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

#import "MathsUtils.h"
#import "DDPreviewView.h"

#import "DDDocumentWindowController.h"
#import "DDLightController.h"

#import "SceneNode.h"
#import "Logging.h"
#import "GLUtilities.h"

#define USE_MULTISAMPLE		1

enum
{
	kDragAction_none,
	kDragAction_currentTool,
	kDragAction_rotateObject,
	kDragAction_rotateLight,
	kDragAction_moveCamera
};


static void LogGLErrors(void);
static NSString *DescribeGLError(GLenum inError);


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
	NSOpenGLPFAAccelerated,
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFAColorSize, 24,
	NSOpenGLPFAAlphaSize, 8,
	NSOpenGLPFADepthSize, 24,
	0
};


@interface DDPreviewView(Private)

- (void)updateDisplayParameters;

- (void)setZ:(float)inZ;

- (void)beginDragForEvent:(NSEvent *)inEvent;
- (void)endDrag;
- (void)handleDragEvent:(NSEvent *)inEvent;

- (void)handleScrollDelta:(float)inDelta;
- (void)handleCameraDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY;

- (Vector)virtualTrackballLocationForPoint:(NSPoint)inPoint;

@end


@implementation DDPreviewView


- (id) initWithFrame:(NSRect)frame
{
	TraceMessage(@"Initing GL view.");
	TraceIndent();
	
	NSOpenGLPixelFormat		*fmt;
	
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kAttributes];
	if (nil == fmt) fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kFallbackAttributes];
	
	if (!fmt)
	{
		LogMessage(@"No OpenGL pixel format");
		[self release];
		return nil;
	}
	
	self = [super initWithFrame:frame pixelFormat:[fmt autorelease]];
	
	if (nil != self)
	{
		lightController = [[DDLightController alloc] initWithView:self];
	}
	
	TraceOutdent();
	
	_transform.RotateY(-30.0f * M_PI / 180.0f);
	_transform.RotateX(20.0f * M_PI / 180.0f);
	_transform.Orthogonalize();
	
	return self;
}


- (void)dealloc
{
	TraceMessage(@"Deallocating GL view.");
	TraceIndent();
	
	[DDLightController release];
	
	[super dealloc];
	TraceOutdent();
}


- (void)setController:(DDDocumentWindowController *)inController
{
	controller = inController;	// Don’t retain
}


- (void)prepareOpenGL
{
	TraceMessage(@"Preparing OpenGL context.");
	TraceIndent();
	
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
	
	glEnable (GL_POLYGON_OFFSET_FILL);
	glPolygonOffset(1, 1);
	
	LogGLErrors();
	
	[self updateDisplayParameters];
	
	// Craptacular hack: cause display list to be rebuilt after half a second. Dunno why, but this improves rendering performance.
	[self performSelector:@selector(rebuildDisplayList) withObject:nil afterDelay:0.5];
	
	TraceOutdent();
}


- (void)rebuildDisplayList
{
	[[controller sceneRoot] becomeDirtyDownwards];
}


- (void)drawRect:(NSRect)inRect
{
	TraceMessage(@"Drawing.");
	TraceIndent();
	
	if (inRect.size.width != _oldSize.width || inRect.size.height != _oldSize.height)
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glViewport(0, 0, (GLsizei)inRect.size.width, (GLsizei)inRect.size.height);
		gluPerspective(45.0f, inRect.size.width / inRect.size.height, 0.1f, 5000.0f);
		_oldSize.width = inRect.size.width;
		_oldSize.height = inRect.size.height;
		glMatrixMode(GL_MODELVIEW);
	}
	
//	glClearColor(0.2, 0.2, 0.2, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glLoadIdentity();
//	_inverseCamera.glMult();
	
/*	float specColor[] = {0.8, 0.4, 0.4, 1};
	float specExponent = 64;
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specColor);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, specExponent);*/
	
	@try
	{
		glTranslatef(0, 0, _z);
		[lightController updateLightState];
		if (kDragAction_rotateLight == _dragAction)
		{
			[lightController drawLightPos];
		}
		_transform.glMult();
		[[controller sceneRoot] render];
	}
	@catch (id ex)
	{
		NSLog(@"Exception \"%@\" rendering.", ex);
	}
	
	LogGLErrors();
	
	[[self openGLContext] flushBuffer];
	
	TraceOutdent();
}


- (void)scrollWheel:(NSEvent *)theEvent
{
	float				delta;
	
	delta = [theEvent deltaZ];
	if (0.0f == delta) delta = [theEvent deltaY];	// True in approximately 100% of cases
	
	[self handleScrollDelta:delta];
}


- (void)beginDragForEvent:(NSEvent *)inEvent
{
	unsigned				button;
	unsigned				modifiers;
	NSPoint					where;
	
	where = [inEvent locationInWindow];
	where = [self convertPoint:where fromView:nil];
	
	_dragPoint = [self virtualTrackballLocationForPoint:where];
	
	button = [inEvent buttonNumber];
	modifiers = [inEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	
	// Rotate tool works like holding down option.
	if (0 == button && kRotateTool == [controller tool]) modifiers |= NSAlternateKeyMask;
	
	if (1 == button)
	{
		// Right-drag also works like holding down option.
		modifiers |= NSAlternateKeyMask;
		button = 0;
	}
	
	if (0 == button)
	{
		if (0 == modifiers)
		{
			// Left-click
			_dragAction = kDragAction_currentTool;
			// Ought to handle non-drag stuff, like selecting under the mouse
		}
		else if (NSAlternateKeyMask == modifiers)
		{
			// Option-left: rotate object
			_dragAction = kDragAction_rotateObject;
		}
		else if ((NSAlternateKeyMask | NSShiftKeyMask) == modifiers)
		{
			// Option-shift-left: rotate light
			_dragAction = kDragAction_rotateLight;
		}
		else if (NSCommandKeyMask == modifiers || (NSAlternateKeyMask | NSCommandKeyMask) == modifiers)
		{
			// Command-left: move camera
			_dragAction = kDragAction_moveCamera;
		}
	}
	else if (2 == button)
	{
		if (0 == modifiers)
		{
			// Button-3 click: move camera
			_dragAction = kDragAction_moveCamera;
		}
	}
	else if (3 == button)
	{
		if (0 == modifiers)
		{
			// Button-4 click: rotate light
			_dragAction = kDragAction_rotateLight;
		}
	}
	
	[self setNeedsDisplay:YES];
}


- (void)endDrag
{
	_dragAction = kDragAction_none;
	[self setNeedsDisplay:YES];
}


- (void)handleDragEvent:(NSEvent *)inEvent
{
	NSPoint					where;
	float					angle;
	Vector					newDragPoint, delta, axis;
	float					dx, dy;
	
	dx = [inEvent deltaX];
	dy = [inEvent deltaY];
	
	switch (_dragAction)
	{
		case kDragAction_none:
		case kDragAction_currentTool:
			break;
		
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
			[lightController handleDragDeltaX:dx deltaY:dy];
			break;
		
		case kDragAction_moveCamera:
			[self handleCameraDragDeltaX:dx deltaY:dy];
			break;
	}
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


- (void)handleScrollDelta:(float)inDelta
{
	[self setZ:_z * (1.0 + (inDelta * 0.1f))];
}


- (void)handleCameraDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY
{
	[self setZ:_z * (1.0 - (inDeltaY * 0.01f))];
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


- (void)setZ:(float)inZ
{
	TraceMessage(@"Setting Z to %g", inZ);
	TraceIndent();
	
	if (-5.f < inZ) inZ = -5.f;
	if (_z != inZ)
	{
		_z = inZ;
		[self updateDisplayParameters];
	}
	
	TraceOutdent();
}


- (void)updateDisplayParameters
{
	TraceMessage(@"Display parameters changed.");
	TraceIndent();
	
	[self setNeedsDisplay:YES];
	
	TraceOutdent();
}


- (void)setObjectSize:(float)inRadius
{
	TraceMessage(@"Changing object radius to %g.", inRadius);
	TraceIndent();
	
	if (inRadius < 1) inRadius = 1;
	[self setZ:inRadius * -2.8];
	[lightController setLightDistance:inRadius * 4];
	
	TraceOutdent();
}


- (BOOL)isOpaque
{
	return YES;
}


#if ENABLE_TRACE && 0
- (id)retain
{
	TraceMessage(@"Called. Ref count going to %u.", [self retainCount] + 1);
	TraceIndent();
	
	self = [super retain];
	
	TraceOutdent();
	
	return self;
}


- (id)autorelease
{
	TraceMessage(@"Called. Ref count = %u.", [self retainCount]);
	TraceIndent();
	
	self = [super autorelease];
	
	TraceOutdent();
	
	return self;
}


- (void)release
{
	TraceMessage(@"Called. Ref count going to %u.", [self retainCount] - 1);
	TraceIndent();
	
	[super release];
	
	TraceOutdent();
}
#endif	/* ENABLE_TRACE */


@end


static void LogGLErrors(void)
{
	GLenum					error;
	
	for (;;)
	{
		error = glGetError();
		if (GL_NO_ERROR == error) break;
		
		NSLog(@"Got OpenGL error %@", DescribeGLError(error));
	}
}


static NSString *DescribeGLError(GLenum inError)
{
	switch (inError)
	{
		case GL_NO_ERROR:			return @"GL_NO_ERROR";
		case GL_INVALID_ENUM:		return @"GL_INVALID_ENUM";
		case GL_INVALID_VALUE:		return @"GL_INVALID_VALUE";
		case GL_INVALID_OPERATION:	return @"GL_INVALID_OPERATION";
		case GL_STACK_OVERFLOW:		return @"GL_STACK_OVERFLOW";
		case GL_STACK_UNDERFLOW:	return @"GL_STACK_UNDERFLOW";
		case GL_OUT_OF_MEMORY:		return @"GL_OUT_OF_MEMORY";
		case GL_TABLE_TOO_LARGE:	return @"GL_TABLE_TOO_LARGE";
		
		default:
			return [NSString stringWithFormat:@"Unknown error 0x%.4X", inError];
	}
}
