//
//  NSThreadOOExtensions.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSThread (OOExtensions)

+ (void)ooSetCurrentThreadName:(NSString *)string;

@end
