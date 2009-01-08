//
//  DDEntityHierarchyViewDataSource.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-20.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDEntityHierarchyViewDataSource.h"
#import "DDShip.h"
#import "DDSubEntity.h"
#import "DDFlasher.h"


@interface DDEntity (HierarchyViewDataSource)

- (DDEntity *) outlineViewChildAtIndex:(NSUInteger)index;
- (NSUInteger) outlineViewChildCount;
- (NSString *) nameForOutlineView;

@end


@implementation DDEntityHierarchyViewDataSource

@synthesize outlineView = _outlineView;


- (DDEntity *) rootEntity
{
	return _root;
}


- (void) setRootEntity:(DDEntity *)root
{
	_root = root;
	[self.outlineView reloadData];
}


#pragma mark NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView
			child:(NSInteger)index
		   ofItem:(id)item
{
	id result = nil;
	if (item == nil)  result = self.rootEntity;
	else  result = [item outlineViewChildAtIndex:index];
	return result;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item
{
	if (item == nil)  return YES;
	return [item outlineViewChildCount] != 0;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item
{
	if (item == nil)  return 1;
	return [item outlineViewChildCount];
}


- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
		   byItem:(id)item
{
	if ([tableColumn.identifier isEqual:@"name"])
	{
		return [item nameForOutlineView];
	}
	else
	{
		return nil;
	}
}

@end


@implementation DDEntity (HierarchyViewDataSource)

- (DDEntity *) outlineViewChildAtIndex:(NSUInteger)index
{
	return nil;
}


- (NSUInteger) outlineViewChildCount
{
	return 0;
}


- (NSString *) nameForOutlineView
{
	return [self description];
}

@end


@implementation DDEntityWithMesh (HierarchyViewDataSource)

- (NSString *) nameForOutlineView
{
	return self.name;
}

@end


@implementation DDShip (HierarchyViewDataSource)

- (DDEntity *) outlineViewChildAtIndex:(NSUInteger)index
{
	if (index >= self.countOfSubEntities)
	{
		return [self objectInFlashersAtIndex:index - self.countOfSubEntities];
	}
	else
	{
		return [self objectInSubEntitiesAtIndex:index];
	}
}


- (NSUInteger) outlineViewChildCount
{
	return self.countOfSubEntities + self.countOfFlashers;
}

@end


@implementation DDSubEntity (HierarchyViewDataSource)

@end


@implementation DDFlasher (HierarchyViewDataSource)

- (NSString *) nameForOutlineView
{
	return @"Flasher";
}

@end
