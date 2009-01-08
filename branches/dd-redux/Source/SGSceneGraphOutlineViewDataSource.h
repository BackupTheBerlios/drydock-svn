//
//  SGSceneGraphOutlineViewDataSource.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SGSceneGraph;


@interface SGSceneGraphOutlineViewDataSource: NSObject
{
@private
	SGSceneGraph			*_sceneGraph;
	NSOutlineView			*_outlineView;
}

@property (nonatomic, retain) SGSceneGraph *sceneGraph;
@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;

@end
