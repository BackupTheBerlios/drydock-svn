//
//  DDMeshNode.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "SGSceneNode.h"

@class OOMesh;


@interface DDMeshNode: SGSceneNode
{
@private
	OOMesh				*_mesh;
}

- (id) initWithMesh:(OOMesh *)mesh;

@property (readonly, nonatomic) OOMesh *mesh;

@end
