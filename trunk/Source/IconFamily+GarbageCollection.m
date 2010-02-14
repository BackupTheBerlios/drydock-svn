//
//  IconFamily+GarbageCollection.m
//  Dry Dock
//
//  Created by Jens Ayton on 2008-11-23.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "IconFamily+GarbageCollection.h"


@implementation IconFamily (GarbageCollection)

- (void) finalize
{
	/*	"Starting with Mac OS X v10.3, Memory Manager is thread safe"
		-- Memory Manager Reference
	*/
	DisposeHandle((Handle)hIconFamily);
	hIconFamily = NULL;
	
	[super finalize];
}

@end
