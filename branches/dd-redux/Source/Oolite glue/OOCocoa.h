#import <Cocoa/Cocoa.h>
#import "OOLogging.h"


typedef NSInteger OOInteger;
typedef NSUInteger OOUInteger;



@interface NSObject (OODescriptionComponents)

- (NSString *)descriptionComponents;
- (NSString *) shortDescription;
- (NSString *) shortDescriptionComponents;

@end
