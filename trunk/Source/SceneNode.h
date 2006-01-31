/*
	SceneNode.h
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2005-2006 Jens Ayton

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

@class SceneTag;

#ifndef OBJECTIVESCENE_IMPLEMENT_CODING
#define OBJECTIVESCENE_IMPLEMENT_CODING		0
#endif

#ifndef OBJECTIVESCENE_TRACE_RENDER
#define OBJECTIVESCENE_TRACE_RENDER			0
#endif


@interface SceneNode: NSObject
#if OBJECTIVESCENE_IMPLEMENT_CODING
	<NSCoding>
#endif
{
	Matrix						matrix;
	NSMutableArray				*tags;
	SceneNode					*parent;
	SceneNode					*firstChild;
	SceneNode					*nextSibling;
	NSString					*name;
	uint32_t					isDirty: 1,
								transformed: 1,
								childCount: 30;
}

- (id)init;
+ (id)node;
- (void)addChild:(SceneNode *)inNode;
- (void)insertChild:(SceneNode *)inNode after:(SceneNode *)inExistingChild;
- (void)removeChild:(SceneNode *)inChild;

- (SceneNode *)firstChild;
- (SceneNode *)nextSibling;
- (NSEnumerator *)childEnumerator;
- (uint32_t)numberOfChildren;
- (SceneNode *)childAtIndex:(uint32_t)inIndex;	// O(n)

- (SceneNode *)parent;

- (Matrix)matrix;
- (void)setMatrix:(const Matrix *)inMatrix;
- (void)setMatrixIdentity;

- (size_t)tagCount;
- (SceneTag *)tagAtIndex:(size_t)inIndex;
- (void)addTag:(SceneTag *)inTag;
- (void)insertTag:(SceneTag *)inTag atIndex:(size_t)inIndex;
- (void)removeTagAtIndex:(uint32_t)inIndex;
- (void)removeTag:(SceneTag *)inTag;

- (NSString *)name;
- (void)setName:(NSString *)inName;
- (void)setLocalizedName:(NSString *)inName;	// Looks inName up in Localizable.strings

- (void)becomeDirty;			// Dirtiness is passed up the tree
- (void)becomeDirtyDownwards;	// Dirtiness is passed down the tree
- (BOOL)isDirty;

- (void)render;
- (void)renderWithState:(NSDictionary *)inState;

// Subclasses should generally override this, not the above.
- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty;

@end


extern NSString *kNotificationSceneNodeModified;
