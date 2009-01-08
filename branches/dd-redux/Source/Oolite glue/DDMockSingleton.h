/*
	DDMockSingleton.h
	Dry Dock for Oolite
 
	Several Oolite singletons are used by OOMesh and family, and we need to
	implement them on a per-document basis for Dry Dock. DDMockSingleton
	implements a fake singleton; DDMockSingletonContext manages a set of
	DDMockSingeltons associated with a document.
	
	
	Created by Jens Ayton on 2008-11-29.
	Copyright 2008 Jens Ayton. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@class DDDocument;


@interface DDMockSingletonContext: NSObject
{
@private
	DDDocument				*_owner;
	NSMutableDictionary		*_mockSingletons;
}

- (id) initWithOwner:(id)owner;

@property (readonly) DDDocument *owner;

+ (DDMockSingletonContext *) currentContext;
+ (void) setCurrentContext:(DDMockSingletonContext *)context;

@end


@interface DDMockSingleton: NSObject
{
@private
	DDMockSingletonContext	*_context;
}

+ (id) sharedInstance;

@property (readonly) DDMockSingletonContext *mockSingletonContext;

// Subclass initializer
- (id) initWithContext:(DDMockSingletonContext *)context;

@end
