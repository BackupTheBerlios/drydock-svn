/*
	NSData+Deflate.mm
	Dry Dock for Oolite
	$Id$
	
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

#import "NSData+Deflate.h"
#import <zlib.h>
#import "DDErrorDescription.h"
#import "Logging.h"


@implementation NSData (Deflate)

- (NSData *)deflatedData
{
	return [self deflatedDataPrefixedWith:nil level:Z_DEFAULT_COMPRESSION];
}


- (NSData_InflateResult)inflatedData:(NSData **)outData outputSize:(size_t)inSize;
{
	return [self inflatedData:outData outputSize:inSize ifPrefixedWith:nil];
}


- (NSData *)deflatedDataPrefixedWith:(NSData *)inPrefix level:(int)inLevel
{
	TraceEnter();
	
	unsigned				prefixLength, selfLength;
	unsigned long long		bfrSize;
	int						zResult;
	void					*bytes = NULL, *bytes2;
	uLongf					resultSize;
	
	selfLength = [self length];
	bfrSize = selfLength;
	bfrSize = bfrSize * 1001 / 1000 + 12;
	
	prefixLength = [inPrefix length];
	bytes = malloc(bfrSize + prefixLength);
	if (NULL == bytes)
	{
		LogMessage(@"Failed to allocate compression buffer (%u bytes).", bfrSize + prefixLength);
		return nil;
	}
	
	resultSize = bfrSize;
	zResult = compress2(((Bytef *)bytes) + prefixLength, &resultSize, [self bytes], selfLength, inLevel);
	if (Z_OK != zResult)
	{
		LogMessage(@"Compression failed (%@).", ZLibErrorToNSString(zResult));
		free(bytes);
		return nil;
	}
	
	if (0 != prefixLength) bcopy([inPrefix bytes], bytes, prefixLength);
	
	bytes2 = realloc(bytes, prefixLength + resultSize);
	if (NULL != bytes2) bytes = bytes2;
	
	return [NSData dataWithBytesNoCopy:bytes length:prefixLength + resultSize freeWhenDone:YES];
	TraceExit();
}


- (NSData_InflateResult)inflatedData:(NSData **)outData outputSize:(size_t)inSize ifPrefixedWith:(NSData *)inPrefix;
{
	TraceEnter();
	
	NSData_InflateResult	result = kInflateSuccess;
	unsigned				prefixLength, selfLength;
	int						zResult;
	void					*bytes = NULL;
	uLongf					size;
	
	if (NULL == outData) result = kInflateParamError;
	
	selfLength = [self length];
	if (nil != inPrefix)
	{
		// Test whether prefix matches.
		prefixLength = [inPrefix length];
		if (selfLength < prefixLength || ![[self subdataWithRange:NSMakeRange(0, prefixLength)] isEqualToData:inPrefix])
		{
			result = kInflatePrefixMismatch;
		}
	}
	
	if (kInflateSuccess == result)
	{
		bytes = malloc(inSize);
		if (NULL == bytes) result = kInflateAllocationFailure;
	}
	
	if (kInflateSuccess == result)
	{
		size = inSize;
		zResult = uncompress(bytes, &size, [self bytes], selfLength);
		if (Z_OK != zResult)
		{
			LogMessage(@"Decompression failed (%@).", ZLibErrorToNSString(zResult));
			result = kInflateDecompressionFailure;
		}
	}
	
	if (kInflateSuccess == result)
	{
		*outData = [NSData dataWithBytesNoCopy:bytes length:inSize freeWhenDone:YES];
		if (nil == *outData)
		{
			free(bytes);
			result = kInflateAllocationFailure;
		}
	}
	
	return result;
	TraceExit();
}

@end
