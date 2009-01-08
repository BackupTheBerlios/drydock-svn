//
//  DDFlasher.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-19.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDFlasher.h"
#import "OOMaths.h"


@implementation DDFlasher

@synthesize position = _position, hue = _hue, size = _size, frequency = _frequency, phase = _phase;

- (NSString *) descriptionComponents
{
	return $sprintf(@"position: %@, hue: %g°", VectorDescription(self.position), self.hue);
}

@end
