//
//  DDEntityWithMesh.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-20.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDEntityWithMesh.h"
#import "OOMesh.h"


@interface DDEntityWithMesh ()

@property (nonatomic, readwrite, assign) OOMesh *mesh;

@end


@implementation DDEntityWithMesh

@synthesize mesh = _mesh, name = _name;


- (id) initWithMesh:(OOMesh *)mesh
{
	if (mesh == nil)  return nil;
	
	self = [super init];
	if (self != nil)
	{
		self.mesh = mesh;
		self.name = [mesh.modelName stringByDeletingPathExtension];
	}
	return self;
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"\"%@\"", self.name);
}

@end
