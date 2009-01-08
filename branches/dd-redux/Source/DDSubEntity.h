//
//  DDSubEntity.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-19.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDEntityWithMesh.h"
#import	"phystypes.h"


@interface DDSubEntity: DDEntityWithMesh
#if !__OBJC2__
{
@private
	Vector						_position;
}
#endif

- (id) initWithMesh:(OOMesh *)mesh position:(Vector)position;

@property (nonatomic) Vector position;

@end
