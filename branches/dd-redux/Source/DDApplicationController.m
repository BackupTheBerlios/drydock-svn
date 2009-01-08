//
//  DDApplicationController.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDApplicationController.h"
#import "OOCPUInfo.h"


static DDApplicationController *sSingleton = nil;


@interface DDApplicationController ()

- (id) reallyInit;

@end


@implementation DDApplicationController

+ (id)allocWithZone:(NSZone *)inZone
{
	if (sSingleton == nil)
	{
		sSingleton = [[super allocWithZone:inZone] reallyInit];
	}
	return sSingleton;
}


- (id)copyWithZone:(NSZone *)inZone
{
	return self;
}


- (id) init
{
	return self;
}


- (id) reallyInit
{
	srandomdev();
	OOCPUInfoInit();
	
	return [super init];
}


+ (id) sharedController
{
	return [[self alloc] init];
}


- (IBAction) showInspector:(id)sender
{
	
}


- (IBAction) runShipComparison:(id)sender
{
	[[[NSDocumentController sharedDocumentController] currentDocument] runShipComparison:sender];
}


#pragma mark NSApplication Delegate

@end
