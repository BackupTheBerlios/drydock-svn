/*
	DDVertexSet.mm
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

#import "DDVertexSet.h"
#import "Logging.h"


@implementation DDVertexSet

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
		if (0 == inCapacity) inCapacity = 1;
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


- (DDMeshIndex)indexForVector:(Vector)inVector
{
	TraceEnter();
	
	NSNumber			*index;
	NSValue				*key;
	DDMeshIndex			result;
	
	inVector.CleanZeros();
	
	key = [[NSValue alloc] initWithBytes:&inVector objCType:@encode(Vector)];
	index = [rev objectForKey:key];
	if (nil == index)
	{
		// Not found
		if (count == max)
		{
		//	LogMessage(@"Growing DDVertexSet.");
			if (kDDMeshIndexMax == max) [NSException raise:NSRangeException format:@"%s: failed to grow a DDVertexSet (already at maximum size).", __FUNCTION__];
			
			if (kDDMeshIndexMax / 2 < max) max = kDDMeshIndexMax;
			else max *= 2;
			
			array = (Vector *)realloc(array, sizeof (Vector) * max);
			
			if (array == NULL) [NSException raise:NSMallocException format:@"%s: failed to grow a DDVertexSet (out of memory).", __FUNCTION__];
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


- (void)getArray:(Vector **)outArray andCount:(DDMeshIndex *)outCount
{
	TraceEnter();
	
	if (0 == max)
	{
		[NSException raise:NSGenericException format:@"Attempt to read DDVertexSet twice."];
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
