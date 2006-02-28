/*
	DDMaterialSet.mm
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

#import "DDMaterialSet.h"
#import "Logging.h"


@implementation DDMaterialSet

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
		array = (DDMaterial **)calloc(sizeof(DDMaterial *), inCapacity);
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
	if (NULL != array)
	{
		for (int i = 0; i != count; ++i)
		{
			[array[i] release];
		}
		free(array);
	}
	
	[super dealloc];
	TraceExit();
}


- (int)indexForName:(NSString *)inName
{
	TraceEnter();
	
	NSNumber			*index;
	int					result;
	
	index = [rev objectForKey:inName];
	if (nil != index)
	{
		result = [index unsignedIntValue];
	}
	else
	{
		result = NSNotFound;
	}
	
	return result;
	TraceExit();
}


- (int)addMaterial:(DDMaterial *)inMaterial
{
	TraceEnterMsg(@"Called for %@ {", inMaterial);
	
	NSNumber			*index;
	int					result;
	
	if (count == max) [NSException raise:NSRangeException format:@"Overflow in DDNormalSet of capacity %u.", max];
	result = [self indexForName:[inMaterial name]];
	if (nil != result)
	{
		result = count++;
		
		index = [[NSNumber alloc] initWithUnsignedInt:result];
		[rev setObject:index forKey:[inMaterial name]];
		[index release];
		
		array[result] = [inMaterial retain];
	}
	
	return result;
	TraceExit();
}


- (void)getArray:(DDMaterial ***)outArray andCount:(unsigned *)outCount
{
	TraceEnter();
	
	if (0 == max)
	{
		[NSException raise:NSGenericException format:@"Attempt to read DDNormalSet twice."];
	}
	
	*outArray = (DDMaterial **)realloc(array, count * sizeof(DDMaterial *));
	if (NULL == *outArray) *outArray = array;
	array = NULL;
	
	*outCount = count;
	count = max = 0;
	
	[rev release];
	rev = nil;
	
	TraceExit();
}

@end
