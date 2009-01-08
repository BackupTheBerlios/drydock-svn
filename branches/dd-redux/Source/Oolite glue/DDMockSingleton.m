//
//  DDMockSingleton.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDMockSingleton.h"


static DDMockSingletonContext *sCurrentContext = nil;


@implementation DDMockSingletonContext

@synthesize owner = _owner;


- (id) initWithOwner:(id)owner
{
	if (owner == nil)  return nil;
	
	if ((self = [super init]))
	{
		_owner = owner;
	}
	
	return self;
}


- (id) mockSingletonOfClass:(Class)aClass
{
	NSParameterAssert([aClass isSubclassOfClass:[DDMockSingleton class]]);
	
	NSValue *key = [NSValue valueWithPointer:aClass];
	id result = [_mockSingletons objectForKey:key];
	if (result == nil)
	{
		result = [[aClass alloc] initWithContext:self];
		if (result != nil)
		{
			if (_mockSingletons == nil)  _mockSingletons = [NSMutableDictionary dictionary];
			[_mockSingletons setObject:result forKey:key];
		}
	}
	
	return result;
}


+ (DDMockSingletonContext *) currentContext
{
	return sCurrentContext;
}


+ (void) setCurrentContext:(DDMockSingletonContext *)context
{
	sCurrentContext = context;
}

@end


@implementation DDMockSingleton

@synthesize mockSingletonContext = _context;

+ (id) sharedInstance
{
	return [[DDMockSingletonContext currentContext] mockSingletonOfClass:self];
}


- (id) initWithContext:(DDMockSingletonContext *)context
{
	if ((self == [super init]))
	{
		_context = context;
	}
	return self;
}

@end
