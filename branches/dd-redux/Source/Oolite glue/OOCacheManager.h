//
//  OOCacheManager.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDMockSingleton.h"

@interface DDMockCacheManager: DDMockSingleton

+ (id) sharedCache;

- (id) objectForKey:(NSString *)key inCache:(NSString *)cache;
- (void) setObject:(id)object forKey:(NSString *)key inCache:(NSString *)cache;

@end


@compatibility_alias OOCacheManager DDMockCacheManager;
