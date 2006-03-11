/*
	DDSceneView.h
	Dry Dock for Oolite
	$Id$
	
	Core OpenGL view class for Dry Dock. The various OpenGL views used in Dry Dock are
	specialisations of this.
	
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

#import <Cocoa/Cocoa.h>
#import "phystypes.h"

@class DDLightController;
@class SceneNode;

enum
{
	kDragAction_none = 0UL,
	kDragAction_currentTool,
	kDragAction_rotateObject,
	kDragAction_rotateLight,
	kDragAction_moveCamera,
	
	// first ID for subclasses to use for their own drag actions
	kDragAction_customBase
};


@interface DDSceneView: NSOpenGLView
{
	DDLightController			*_lightController;
	NSSize						_oldSize;
	
	unsigned					_dragAction;
	Vector						_dragPoint;
	
	Matrix						_transform;
	GLfloat						_z;
	GLfloat						_oldZ;
	
	SceneNode					*_oldSceneRoot;
}

- (DDLightController *)lightController;
- (void)setLightController:(DDLightController *)inLightController;

- (void)noteSceneRootChanged;

- (float)cameraDistance;
- (void)setCameraDistance:(float)inZ;
- (void)setObjectSize:(float)inRadius;
- (Matrix)transformationMatrix;
- (void)setTransformationMatrix:(Matrix)inMatrix;

// Subclass stuff
- (SceneNode *)sceneRoot;
- (BOOL)drawLightVector;
- (unsigned)dragActionForEvent:(NSEvent *)inEvent;
- (unsigned)filterModifiers:(unsigned)inModifiers forDragActionForEvent:(NSEvent *)inEvent;
- (void)handleCustomDragEvent:(NSEvent *)inEvent;	// Called for drags where action is not none, rotateObject, rotateLight or moveCamera

@end


extern NSString *kNotificationDDSceneViewSceneChanged;
extern NSString *kNotificationDDSceneViewCameraOrLightChanged;
