//
//  DDEntityHierarchyViewDataSource.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-20.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DDEntity;


@interface DDEntityHierarchyViewDataSource: NSObject
{
@private
	DDEntity				*_root;
	NSOutlineView			*_outlineView;
}

@property (nonatomic, retain) DDEntity *rootEntity;
@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;

@end
