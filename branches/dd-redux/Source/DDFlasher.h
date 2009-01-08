//
//  DDFlasher.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-19.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDEntity.h"
#import "phystypes.h"


@interface DDFlasher: DDEntity
#if !__OBJC2__
{
@private
	Vector					_position;
	float					_hue;
	float					_size;
	float					_frequency;
	float					_phase;
}
#endif

@property (nonatomic) Vector position;
@property (nonatomic) float hue;
@property (nonatomic) float size;
@property (nonatomic) float frequency;
@property (nonatomic) float phase;

@end
