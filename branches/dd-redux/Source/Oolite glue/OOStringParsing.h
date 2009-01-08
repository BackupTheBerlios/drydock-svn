#import "OOMaths.h"


BOOL ScanVectorFromString(NSString *xyzString, Vector *outVector);
BOOL ScanQuaternionFromString(NSString *wxyzString, Quaternion *outQuaternion);


@interface NSString (OOUtilities)

// Case-insensitive match of [self pathExtension]
- (BOOL)pathHasExtension:(NSString *)extension;
- (BOOL)pathHasExtensionInArray:(NSArray *)extensions;

@end
