//
//  DDEntityWithMesh.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-20.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDEntity.h"


@interface DDEntityWithMesh: DDEntity
#if !__OBJC2__
{
@private
	OOMesh						*_mesh;
	NSString					*_name;
}
#endif

- (id) initWithMesh:(OOMesh *)mesh;

@property (nonatomic, readonly) OOMesh *mesh;
@property (nonatomic, copy) NSString *name;

@end
