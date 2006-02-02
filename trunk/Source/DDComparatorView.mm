/*
	DDComparatorView.mm
	Dry Dock for Oolite
	
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

#import "DDComparatorView.h"
#import "DDComparatorGLView.h"
#import "DDMesh.h"
#import "Logging.h"
#import "SceneNode.h"


@implementation DDComparatorView

- (void)dealloc
{
	[formatter release];
	
	[super dealloc];
}


- (void)awakeFromNib
{
	if (!_haveSetSelfUp)
	{
		_haveSetSelfUp = YES;
		[NSBundle loadNibNamed:@"DDComparatorView" owner:self];
	}
	else
	{
		DDComparatorGLView			*view;
		
		[self addSubview:contentView];
		[contentView setFrame:[self bounds]];
		
		view = [[DDComparatorGLView alloc] initWithFrame:[glView frame]];
		[view setAutoresizingMask:[glView autoresizingMask]];
		
		[[glView superview] replaceSubview:glView with:view];
		glView = view;
		[view release];
	}
}


- (void)setMesh:(DDMesh *)inMesh radius:(float)inRadius
{
	SceneNode				*sceneRoot;
	
	// Set display info
	[lengthField setFloatValue:[inMesh length]];
	[widthField setFloatValue:[inMesh width]];
	[heightField setFloatValue:[inMesh height]];
	
	// Build a scene graph
	sceneRoot = [inMesh sceneGraphForMesh];
	
	[glView setSceneRoot:sceneRoot];
	[glView setObjectSize:inRadius];
}


- (DDComparatorGLView *)glView
{
	return [[glView retain] autorelease];
}


- (float)cameraDistance
{
	return [glView cameraDistance];
}


- (void)setCameraDistance:(float)inZ
{
	[glView setCameraDistance:inZ];
}


- (Matrix)transformationMatrix
{
	return [glView transformationMatrix];
}


- (void)setTransformationMatrix:(Matrix)inMatrix
{
	[glView setTransformationMatrix:inMatrix];
}

@end
