/*
	DDEntity.h
	Dry Dock Redux
	Root class for model objects corresponding to Oolite entities.
	
	Created by Jens Ayton on 2008-12-19.
	Copyright 2008 Jens Ayton. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@class OOMesh;


@interface DDEntity: NSObject

- (void) postAppearanceModifiedNotification;

@end


extern NSString * const kDDEntityAppearanceModifiedNotification;
