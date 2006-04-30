/*	Based on code from cocoadev.com, with the comment: “Feel free to use this code for anything you
	want, although it’d be nice if you credited the original author (Thomas Castiglione).”
	
	$Id$
*/

#import <Foundation/Foundation.h>

enum
{
	kDoMode,
	kCollectMode,
	kSelectMode,
	kRejectMode,
	kCountMode
};


@interface BSTrampoline: NSProxy
{
	NSEnumerator *enumerator;
	int mode;
	NSArray *temp;	// For returning from collect, select, reject
	unsigned *counter;
}

- (id)initWithEnumerator:(NSEnumerator *)inEnumerator mode:(int)operationMode;
- (id)initWithEnumerator:(NSEnumerator *)inEnumerator countingTo:(unsigned *)outCount;
- (NSArray *)fakeInvocationReturningTempArray;	//Like the name says
@end
