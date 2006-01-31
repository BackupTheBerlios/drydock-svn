/*	Based on code from cocoadev.com, with the comment: “Feel free to use this code for anything you
	want, although it’d be nice if you credited the original author (Thomas Castiglione).”
*/

#import <Foundation/Foundation.h>
#import "BSTrampoline.h"


@interface NSArray(HigherOrderMessaging)

- (id)do;
- (id)collect;
- (id)select;
- (id)reject;
- (id)countTo:(unsigned *)outCounter;

@end


@interface NSSet(HigherOrderMessaging)

- (id)do;
- (id)collect;
- (id)select;
- (id)reject;
- (id)countTo:(unsigned *)outCounter;

@end


// Useful tests
@interface NSArray(HOMPredicates)

- (BOOL)firstObjectEquals:(id)inObject;

@end
