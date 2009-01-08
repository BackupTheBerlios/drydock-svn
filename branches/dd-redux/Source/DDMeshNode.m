//
//  DDMeshNode.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDMeshNode.h"
#import "OOMesh.h"
#import "OOMesh+Wireframe.h"
#import "Universe.h"


@implementation DDMeshNode

@synthesize mesh = _mesh;


- (id) initWithMesh:(OOMesh *)mesh
{
	if (mesh == nil)  return nil;
	
	self = [super init];
	if (self != nil)
	{
		_mesh = mesh;
		self.name = mesh.modelName.lastPathComponent;
	}
	return self;
}


- (void)performRenderWithState:(NSDictionary *)state dirty:(BOOL)dirty
{
	if ([state boolForKey:@"show faces"])
	{
		[self.mesh renderOpaqueParts];
	}
	
	if ([state boolForKey:@"show wireframes"])
	{
		[self.mesh renderWireframe];
	}
	
	if ([state boolForKey:@"show normals"])
	{
		[self.mesh renderNormals];
	}
}

@end
