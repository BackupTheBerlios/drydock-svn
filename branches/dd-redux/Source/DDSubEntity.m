//
//  DDSubEntity.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-19.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDSubEntity.h"
#import "OOMaths.h"
#import "OOCocoa.h"


@implementation DDSubEntity

@synthesize position = _position;


- (id) initWithMesh:(OOMesh *)mesh position:(Vector)position
{
	if ((self = [super initWithMesh:mesh]))
	{
		self.position = position;
	}
	return self;
}


- (id) initWithMesh:(OOMesh *)mesh
{
	return [self initWithMesh:mesh position:kZeroVector];
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"%@ at %@", [super descriptionComponents], VectorDescription(self.position));
}

@end
