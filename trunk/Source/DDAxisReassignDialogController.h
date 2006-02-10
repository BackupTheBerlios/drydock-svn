//
//  DDAxisReassignDialogController.h
//  Dry Dock
//
//  Created by Jens Ayton on 2006-02-09.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DDAxisReassignDialogController: NSObject
{
	IBOutlet NSPanel			*window;
	IBOutlet NSView				*glView;
	
	IBOutlet NSTextField		*step1Description;
	IBOutlet NSTextField		*step2Description;
	IBOutlet NSTextField		*step3Description;
	
	IBOutlet NSMatrix			*axisSelectionMatrix;
	
	IBOutlet NSButton			*okButton;
}

@end
