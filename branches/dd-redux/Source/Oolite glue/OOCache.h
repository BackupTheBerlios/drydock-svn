//
//  OOCache.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// Mock OOCache which doesn't allow itself to be instantiated.
@interface OOCache: NSObject

@property (copy) NSString *name;
@property BOOL autoPrune;
@property NSUInteger pruneThreshold;

- (id) objectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *)key;

@end
