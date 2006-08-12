//
//  DDTextureInspectorController.h
//  Dry Dock
//
//  Created by Jens Ayton on 2006-08-11.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DDTextureBuffer;


@interface DDTextureInspectorController: NSObject
{
	IBOutlet NSTableView		*table;
	IBOutlet NSImageView		*preview;
	IBOutlet NSTextField		*fileField;
	IBOutlet NSTextField		*sizeField;
	IBOutlet NSTextField		*refCountField;
	IBOutlet NSTextField		*keyField;
}

@end
