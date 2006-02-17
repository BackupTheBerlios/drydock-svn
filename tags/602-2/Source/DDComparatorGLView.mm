/*
	DDComparatorGLView.mm
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

#import "DDComparatorGLView.h"
#import "SceneNode.h"


@implementation DDComparatorGLView

- (void)dealloc
{
	[_sceneRoot release];
	
	[super dealloc];
}


- (SceneNode *)sceneRoot
{
	return _sceneRoot;
}


- (void)setSceneRoot:(SceneNode *)inNode
{
	if (_sceneRoot != inNode)
	{
		[_sceneRoot autorelease];
		_sceneRoot = [inNode retain];
		[self noteSceneRootChanged];
	}
}


- (unsigned)filterModifiers:(unsigned)inModifiers forDragActionForEvent:(NSEvent *)inEvent
{
	// Always treat as though option is held down, i.e. invoke rotate too.
	if (0 == [inEvent buttonNumber]) inModifiers |= NSAlternateKeyMask;
	
	return inModifiers;
}

@end
