/*
	DDMesh+Utilities.mm
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

#import "DDMesh.h"
#import "Logging.h"
#import "SceneNode.h"
#import "DDMeshNode.h"
#import "DisplayListCacheNode.h"
#import "DDExhaustPlumeNode.h"
#import "AxisNode.h"


@implementation DDMesh (Utilities)

- (SceneNode *)sceneGraphForMesh
{
	/*
		Set up simple scene graph:
		- root			Empty node used to rotate object
		  + cache		Display list node
			+  mesh		Ship being viewed
	*/
	SceneNode		*root,
					*cache;
	DDMeshNode		*mesh;
	
	root = [SceneNode node];
	cache = [DisplayListCacheNode node];
	mesh = [DDMeshNode nodeWithMesh:self];
	
	[root addChild:cache];
	[cache addChild:mesh];
	
	[root setName:@"Root"];
	
//	[root addChild:[AxisNode node]];
	
	return root;
}

@end
