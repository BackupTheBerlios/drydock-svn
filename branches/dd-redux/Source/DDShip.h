/*
	DDShip.h
	Dry Dock Redux
	Model object representing a ship.
	
	Created by Jens Ayton on 2008-12-19.
	Copyright 2008 Jens Ayton. All rights reserved.
*/

#import "DDEntityWithMesh.h"

@class DDSubEntity, DDFlasher;


@interface DDShip: DDEntityWithMesh
{
@private
	NSMutableArray				*_subEntities;
	NSMutableArray				*_flashers;
}

@property (nonatomic, copy) NSArray *subEntities;
- (void) addSubEntity:(DDSubEntity *)subEntity;
- (void) removeSubEntity:(DDSubEntity *)subEntity;

@property (nonatomic, copy) NSArray *flashers;
- (void) addFlasher:(DDFlasher *)flasher;
- (void) removeFlasher:(DDFlasher *)flasher;

// To-many KVC accessors for subEntities and flashers
@property (nonatomic, readonly) NSUInteger countOfSubEntities;
- (DDSubEntity *) objectInSubEntitiesAtIndex:(NSUInteger)index;
- (void) insertObject:(DDSubEntity *)subEntity inSubEntitiesAtIndex:(NSUInteger)index;
- (void) removeObjectFromSubEntitiesAtIndex:(NSUInteger)index;

@property (nonatomic, readonly) NSUInteger countOfFlashers;
- (DDFlasher *) objectInFlashersAtIndex:(NSUInteger)index;
- (void) insertObject:(DDFlasher *)flashers inFlashersAtIndex:(NSUInteger)index;
- (void) removeObjectFromFlashersAtIndex:(NSUInteger)index;

@end
