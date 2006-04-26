/*
	DDPantherCompatibility.h
	Dry Dock for Oolite
	$Id$
	
	Stuff for backport from Mac OS X 10.4 to Mac OS X 10.3.9.
	
	Copyright © 2006 Jens Ayton

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the “Software”), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all copies or
	substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <Cocoa/Cocoa.h>


#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4

// Various Tiger-only declarations
enum
{
	NSAutosaveOperation						= 3,
	NSDeviceIndependentModifierFlagsMask	= 0xFFFF0000UL,
	NSUserCancelledError					= 3072
};


#define NSCocoaErrorDomain NSCocoaErrorDomainCompat
FOUNDATION_EXPORT NSString *const NSCocoaErrorDomain;

#define LSItemContentType LSItemContentTypeCompat
FOUNDATION_EXPORT const CFStringRef kLSItemContentType;


@interface NSDocument (TigerMethods)

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError;
- (BOOL)writeSafelyToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError;
- (NSURL *)fileURL;

@end


// Doesn’t use CGL_MACRO_CACHE_RENDERER - slight efficiency loss compared to using Tiger headers
#define CGL_MACRO_DECLARE_VARIABLES() CGLContextObj CGL_MACRO_CONTEXT = CGLGetCurrentContext();

#endif	/* MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4 */


@interface NSError (DDPantherCompatibility)

- (NSString *)localizedFailureReasonCompat;
- (NSString *)localizedRecoverySuggestionCompat;

@end


@interface NSString (DDPantherCompatibility)

// Note: these will always set error to NULL on pre-Tiger systems.
+ (id)stringWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)enc errorCompat:(NSError **)error;
+ (id)stringWithContentsOfURL:(NSURL *)url usedEncoding:(NSStringEncoding *)enc errorCompat:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc errorCompat:(NSError **)error;

@end


@interface NSData (DDPantherCompatibility)

// Note: these will always set error to NULL on pre-Tiger systems.
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile errorCompat:(NSError **)error;
+ (id)dataWithContentsOfURL:(NSURL *)url options:(unsigned)readOptionsMask errorCompat:(NSError **)error;

@end
