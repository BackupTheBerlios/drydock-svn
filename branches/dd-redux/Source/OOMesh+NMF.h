/*
	OOMesh+NMF.h
	
	Support for writing NMF, the custom format of ATi's normal mapping tools.
*/

#import "OOMesh.h"


@interface OOMesh (NMF)

// This will trash the specified path on failure; caller is responsible for setting up a temp path.
- (BOOL) writeNMFToFile:(NSString *)path;

@end
