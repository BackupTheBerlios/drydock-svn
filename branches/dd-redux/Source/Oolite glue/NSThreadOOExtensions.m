//
//  NSThreadOOExtensions.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "NSThreadOOExtensions.h"


@implementation NSThread (OOExtensions)

+ (void)ooSetCurrentThreadName:(NSString *)string
{
	[[NSThread currentThread] setName:string];
}

@end
