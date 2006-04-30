/*	Based on code from cocoadev.com, with the comment: “Feel free to use this code for anything you
	want, although it’d be nice if you credited the original author (Thomas Castiglione).”
	
	$Id$
*/

#import "BS-HOM.h"


@implementation NSArray(HigherOrderMessaging)

- (id)do {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kDoMode] autorelease];
}

- (id)collect {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kCollectMode] autorelease];
}

- (id)select {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kSelectMode] autorelease];
}

- (id)reject {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kRejectMode] autorelease];
}

- (id)countTo:(unsigned *)outCounter {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] countingTo:outCounter] autorelease];
}

@end


@implementation NSSet(HigherOrderMessaging)

- (id)do {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kDoMode] autorelease];
}

- (id)collect {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kCollectMode] autorelease];
}

- (id)select {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kSelectMode] autorelease];
}

- (id)reject {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] mode:kRejectMode] autorelease];
}

- (id)countTo:(unsigned *)outCounter {
    return [[[BSTrampoline alloc] initWithEnumerator:[self objectEnumerator] countingTo:outCounter] autorelease];
}

@end


@implementation NSArray(HOMPredicates)

- (BOOL)firstObjectEquals:(id)inObject
{
	return [[self objectAtIndex:0] isEqual:inObject];
}

@end
