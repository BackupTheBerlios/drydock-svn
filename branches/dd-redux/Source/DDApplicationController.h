//
//  DDApplicationController.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DDApplicationController: NSObject
{
	
}

+ (id) sharedController;

- (IBAction) showInspector:(id)sender;
- (IBAction) runShipComparison:(id)sender;

@end
