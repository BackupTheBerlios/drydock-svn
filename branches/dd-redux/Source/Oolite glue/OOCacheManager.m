//
//  OOCacheManager.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOCacheManager.h"


@implementation DDMockCacheManager

+ (id) sharedCache
{
	return [self sharedInstance];
}


- (id) objectForKey:(NSString *)key inCache:(NSString *)cache
{
	return nil;
}


- (void) setObject:(id)object forKey:(NSString *)key inCache:(NSString *)cache
{
	
}

@end
