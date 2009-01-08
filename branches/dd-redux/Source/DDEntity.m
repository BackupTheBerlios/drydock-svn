//
//  DDEntity.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-19.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDEntity.h"


NSString * const kDDEntityAppearanceModifiedNotification = @"org.oolite.drydock.DDEntity appearance modified notification";


@implementation DDEntity

- (void) postAppearanceModifiedNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kDDEntityAppearanceModifiedNotification
														object:nil];
}

@end
