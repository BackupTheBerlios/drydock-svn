//
//  DDShip.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-19.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDShip.h"


@implementation DDShip

- (NSArray *) subEntities
{
	if (_subEntities == nil)  return [NSArray array];
	else  return [_subEntities copy];
}


- (void) setSubEntities:(NSArray *)array
{
	_subEntities = [array mutableCopy];
	[self postAppearanceModifiedNotification];
}


- (void) addSubEntity:(DDSubEntity *)subEntity
{
	if (subEntity != nil)
	{
		[self insertObject:subEntity inSubEntitiesAtIndex:_subEntities.count];
	}
}


- (void) removeSubEntity:(DDSubEntity *)subEntity
{
	if (subEntity != nil)
	{
		NSUInteger index = [_subEntities indexOfObject:subEntity];
		if (index != NSNotFound)
		{
			[self removeObjectFromSubEntitiesAtIndex:index];
		}
	}
}


- (NSArray *) flashers
{
	if (_flashers == nil)  return [NSArray array];
	else  return [_flashers copy];
}


- (void) setFlashers:(NSArray *)array
{
	_flashers = [array mutableCopy];
	[self postAppearanceModifiedNotification];
}


- (void) addFlasher:(DDFlasher *)flasher
{
	if (flasher != nil)
	{
		[self insertObject:flasher inFlashersAtIndex:_flashers.count];
	}
}


- (void) removeFlasher:(DDFlasher *)flasher
{
	if (flasher != nil)
	{
		NSUInteger index = [_flashers indexOfObject:flasher];
		if (index != NSNotFound)
		{
			[self removeObjectFromFlashersAtIndex:index];
		}
	}
}


- (NSUInteger) countOfSubEntities
{
	return _subEntities.count;
}


- (DDSubEntity *) objectInSubEntitiesAtIndex:(NSUInteger)index
{
	return [_subEntities objectAtIndex:index];
}


- (void) insertObject:(DDSubEntity *)subEntity inSubEntitiesAtIndex:(NSUInteger)index
{
	if (_subEntities == nil)  _subEntities = [NSMutableArray array];
	[_subEntities insertObject:subEntity atIndex:index];
	[self postAppearanceModifiedNotification];
}


- (void) removeObjectFromSubEntitiesAtIndex:(NSUInteger)index
{
	[_subEntities removeObjectAtIndex:index];
	[self postAppearanceModifiedNotification];
}


- (NSUInteger) countOfFlashers
{
	return _flashers.count;
}


- (DDFlasher *) objectInFlashersAtIndex:(NSUInteger)index
{
	return [_flashers objectAtIndex:index];
}


- (void) insertObject:(DDFlasher *)flasher inFlashersAtIndex:(NSUInteger)index
{
	if (_flashers == nil)  _flashers = [NSMutableArray array];
	[_flashers insertObject:flasher atIndex:index];
	[self postAppearanceModifiedNotification];
}


- (void) removeObjectFromFlashersAtIndex:(NSUInteger)index
{
	[_flashers removeObjectAtIndex:index];
	[self postAppearanceModifiedNotification];
}

@end
