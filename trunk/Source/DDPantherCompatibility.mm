/*
	DDPantherCompatibility.mm
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

#import "DDPantherCompatibility.h"
#import "DDError.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4

@interface NSError (TigerMethods)

- (NSString *)localizedFailureReason;
- (NSString *)localizedRecoverySuggestion;

@end

@interface NSString (TigerMethods)

+ (id)stringWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)enc error:(NSError **)error;
+ (id)stringWithContentsOfURL:(NSURL *)url usedEncoding:(NSStringEncoding *)enc error:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError **)error;

@end


@interface NSData(TigerMethods)

- (BOOL)writeToURL:(NSURL *)url options:(unsigned)writeOptionsMask error:(NSError **)errorPtr;
+ (id)dataWithContentsOfURL:(NSURL *)url options:(unsigned)readOptionsMask error:(NSError **)error;

@end


enum
{
	NSAtomicWrite							= 1
};


NSString *const NSCocoaErrorDomain = @"NSCocoaErrorDomain";
const CFStringRef kLSItemContentType = (const CFStringRef)@"kLSItemContentType";

#endif


@implementation NSError (DDPantherCompatibility)

- (NSString *)localizedFailureReasonCompat
{
	NSString				*result = nil;
	
	if ([self respondsToSelector:@selector(localizedFailureReason)])
	{
		result = [self localizedFailureReason];
	}
	
	if (nil == result)
	{
		result = [[self userInfo] objectForKey:@"NSLocalizedFailureReason"];
	}
	
	if (nil == result)
	{
		result = [self localizedDescription];
	}
}


- (NSString *)localizedRecoverySuggestionCompat
{
	NSString				*result = nil;
	
	if ([self respondsToSelector:@selector(localizedRecoverySuggestion)])
	{
		result = [self localizedRecoverySuggestion];
	}
	
	if (nil == result)
	{
		result = [[self userInfo] objectForKey:@"NSLocalizedRecoverySuggestion"];
	}
	
	if (nil == result)
	{
		result = [self localizedDescription];
	}
}

@end


@implementation NSString (DDPantherCompatibility)

+ (id)stringWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)enc errorCompat:(NSError **)error
{
	NSString				*result = nil;
	
	if (NULL != error) *error = nil;
	
	if ([self respondsToSelector:@selector(stringWithContentsOfURL:encoding:error:)])
	{
		result = [self stringWithContentsOfURL:url encoding:enc error:error];
	}
	else
	{
		NSData				*data;
		data = [NSData dataWithContentsOfURL:url];
		if (nil != data)
		{
		result = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:enc] autorelease];
		}
	}
	
	return result;
}


+ (id)stringWithContentsOfURL:(NSURL *)url usedEncoding:(NSStringEncoding *)enc errorCompat:(NSError **)error
{
	NSString				*result = nil;
	
	if (NULL != error) *error = nil;
	
	if ([self respondsToSelector:@selector(stringWithContentsOfURL:usedEncoding:error:)])
	{
		result = [self stringWithContentsOfURL:url usedEncoding:enc error:error];
	}
	else
	{
		result = [NSString stringWithContentsOfURL:url];
		if (NULL != enc) *enc = [NSString defaultCStringEncoding];
	}
	
	return result;
}


- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc errorCompat:(NSError **)error
{
	BOOL					result = NO;
	
	if (NULL != error) *error = nil;
	
	if ([self respondsToSelector:@selector(writeToURL:atomically:encoding:error:)])
	{
		result = [self writeToURL:url atomically:useAuxiliaryFile encoding:enc error:error];
	}
	else
	{
		NSData				*data;
		
		data = [self dataUsingEncoding:enc];
		
		if (nil != data)
		{
			result = [data writeToURL:url atomically:useAuxiliaryFile];
		}
	}
	
	return result;
}

@end


@implementation NSData (DDPantherCompatibility)

- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile errorCompat:(NSError **)error
{
	BOOL					result = NO;
	
	if (NULL != error) *error = nil;
	
	if ([self respondsToSelector:@selector(writeToURL:options:error:)])
	{
		result = [self writeToURL:url options:(useAuxiliaryFile ? NSAtomicWrite : 0) error:error];
	}
	else
	{
		result = [self writeToURL:url atomically:useAuxiliaryFile];
	}
	
	return result;
}


+ (id)dataWithContentsOfURL:(NSURL *)url options:(unsigned)readOptionsMask errorCompat:(NSError **)error
{
	id						result = nil;
	
	if (NULL != error) *error = nil;
	
	if ([self respondsToSelector:@selector(dataWithContentsOfURL:options:error:)])
	{
		result = [self dataWithContentsOfURL:url options:readOptionsMask error:error];
	}
	else
	{
		result = [self dataWithContentsOfURL:url];
	}
	
	return result;
}

@end

