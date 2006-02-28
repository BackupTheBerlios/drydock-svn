/*
	DDNormalSet.mm
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

#define ENABLE_TRACE 0

#import "DDNormalSet.h"
#import "Logging.h"


@implementation DDNormalSet

+ (id)setWithCapacity:(unsigned)inCapacity
{
	return [[[self alloc] initWithCapacity:inCapacity] autorelease];
}


- (id)initWithCapacity:(unsigned)inCapacity
{
	TraceEnter();
	
	self = [super init];
	if (nil != self)
	{
		rev = [[NSMutableDictionary alloc] initWithCapacity:inCapacity];
		array = (Vector *)calloc(sizeof(Vector), inCapacity);
		max = inCapacity;
		
		if (nil == rev || NULL == array)
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
	TraceExit();
}


- (void)dealloc
{
	TraceEnter();
	
	[rev release];
	if (NULL != array) free(array);
	
	[super dealloc];
	TraceExit();
}


- (unsigned)indexForVector:(Vector)inVector
{
	TraceEnter();
	
	NSNumber			*index;
	NSValue				*key;
	unsigned			result;
	
	inVector.Normalize().CleanZeros();
	
	key = [[NSValue alloc] initWithBytes:&inVector objCType:@encode(Vector)];
	index = [rev objectForKey:key];
	if (nil == index)
	{
		// Not found
		if (count == max)
		{
			[key release];
			[NSException raise:NSRangeException format:@"Overflow in DDNormalSet of capacity %u.", max];
		}
		
		result = count++;
		
		index = [[NSNumber alloc] initWithUnsignedInt:result];
		[rev setObject:index forKey:key];
		[index release];
		
		array[result] = inVector;
	}
	else
	{
		// Duplicate value
		result = [index unsignedIntValue];
	}
	[key release];
	
	return result;
	TraceExit();
}


- (void)getArray:(Vector **)outArray andCount:(unsigned *)outCount
{
	TraceEnter();
	
	if (0 == max)
	{
		[NSException raise:NSGenericException format:@"Attempt to read DDNormalSet twice."];
	}
	
	*outArray = (Vector *)realloc(array, count * sizeof(Vector));
	if (NULL == *outArray) *outArray = array;
	array = NULL;
	
	*outCount = count;
	count = max = 0;
	
	[rev release];
	rev = nil;
	
	TraceExit();
}

@end
