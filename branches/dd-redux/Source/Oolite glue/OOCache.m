//
//  OOCache.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOCache.h"


@implementation OOCache

- (id) init
{
	[self release];
	return nil;
}


// Don't need to be implemented since they can never be called
@dynamic name, autoPrune, pruneThreshold;


- (id) objectForKey:(NSString *)key
{
	return nil;
}


- (void) setObject:(id)object forKey:(NSString *)key
{
	
}

@end
