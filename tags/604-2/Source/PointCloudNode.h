//
//  PointCloudNode.h
//  Dry Dock
//
//  Created by Jens Ayton on 2005-12-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SceneNode.h"


// Debugging node to help find the camera when it’s lost…
@interface PointCloudNode: SceneNode
{
	float				_size;
	unsigned			_divisions;
}

+ (SceneNode *)node;		// Defaults: 10, 11
+ (PointCloudNode *)nodeWithSize:(float)inSize divisions:(unsigned)inDivisions;
- (id)initWithSize:(float)inSize divisions:(unsigned)inDivisions;

@end
