//
//  SGSceneGraphOutlineViewDataSource.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "SGSceneGraphOutlineViewDataSource.h"
#import "SGSceneGraph.h"


@implementation SGSceneGraphOutlineViewDataSource

@synthesize outlineView = _outlineView;


- (SGSceneGraph *) sceneGraph
{
	return _sceneGraph;
}


- (void) setSceneGraph:(SGSceneGraph *)sceneGraph
{
	[_sceneGraph autorelease];
	_sceneGraph = [sceneGraph retain];
	[self.outlineView reloadData];
}


#pragma mark NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	id result = nil;
	if (item == nil)  result = self.sceneGraph.rootNode;
	else  result = [item childAtIndex:index];
	return result;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == nil)  return YES;
	return [item childCount] != 0;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil)  return 1;
	return [item childCount];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [item name];
}

@end
