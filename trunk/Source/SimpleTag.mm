/*
	SimpleTag.mm
	Dry Dock for Oolite
	
	Copyright © 2005-2006 Jens Ayton

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

#import "SimpleTag.h"


@implementation SimpleTag

+ (id)tagWithKey:(NSString *)inKey value:(id)inValue
{
	return [[[self alloc] initWithKey:inKey value:inValue] autorelease];
}


+ (id)tagWithKey:(NSString *)inKey intValue:(int)inValue
{
	return [[[self alloc] initWithKey:inKey intValue:inValue] autorelease];
}


+ (id)tagWithKey:(NSString *)inKey doubleValue:(double)inValue
{
	return [[[self alloc] initWithKey:inKey doubleValue:inValue] autorelease];
}


+ (id)tagWithKey:(NSString *)inKey boolValue:(bool)inValue
{
	return [[[self alloc] initWithKey:inKey boolValue:inValue] autorelease];
}



- (id)initWithKey:(NSString *)inKey
{
	self = [super init];
	if (nil != self)
	{
		if (nil == inKey)
		{
			[self release];
			self = nil;
		}
		key = [inKey retain];
	}
	return self;
}


- (id)initWithKey:(NSString *)inKey andName:(NSString *)inName
{
	self = [self initWithKey:inKey];
	if (nil != self)
	{
		name = [inName retain];
	}
	return self;
}


- (id)initWithKey:(NSString *)inKey value:(id)inValue
{
	self = [self initWithKey:inKey];
	if (nil != self)
	{
		[self setValue:inValue];
	}
	return self;
}


- (id)initWithKey:(NSString *)inKey intValue:(int)inValue
{
	return [self initWithKey:inKey value:[NSNumber numberWithInt:inValue]];
}


- (id)initWithKey:(NSString *)inKey doubleValue:(double)inValue
{
	return [self initWithKey:inKey value:[NSNumber numberWithDouble:inValue]];
}


- (id)initWithKey:(NSString *)inKey boolValue:(bool)inValue
{
	return [self initWithKey:inKey value:[NSNumber numberWithBool:inValue]];
}


#if OBJECTIVESCENE_IMPLEMENT_CODING

- (void)encodeWithCoder:(NSCoder *)inCoder
{
	[super encodeWithCoder:inCoder];
	
	if (nil != name) [inCoder encodeObject:name forKey:@"name"];
	if (nil != key) [inCoder encodeObject:name forKey:@"key"];
	if (nil != value) [inCoder encodeObject:name forKey:@"value"];
}


- (id)initWithCoder:(NSCoder *)inDecoder
{
	self = [super initWithCoder:inDecoder];
	if (nil != self)
	{
		name = [[inDecoder decodeObjectForKey:@"name"] retain];
		key = [[inDecoder decodeObjectForKey:@"key"] retain];
		value = [[inDecoder decodeObjectForKey:@"value"] retain];
	}
	return self;
}

#endif	// OBJECTIVESCENE_IMPLEMENT_CODING


- (void)dealloc
{
	[key release];
	[name release];
	[value release];
	
	[super dealloc];
}


- (id)value
{
	return [[value retain] autorelease];
}


- (void)setValue:inValue
{
	if (inValue != value)
	{
		[value release];
		value = [inValue retain];
		[self becomeDirty];
	}
}


- (int)intValue
{
	if ([value respondsToSelector:@selector(intValue)]) return [value intValue];
	return 0;
}


- (void)setIntValue:(int)inValue
{
	[self setValue:[NSNumber numberWithInt:inValue]];
}


- (double)doubleValue
{
	if ([value respondsToSelector:@selector(doubleValue)]) return [value doubleValue];
	if ([value respondsToSelector:@selector(floatValue)]) return [value floatValue];
	return 0.0f;
}


- (void)setDoubleValue:(double)inValue
{
	[self setValue:[NSNumber numberWithDouble:inValue]];
}


- (BOOL)boolValue
{
	if ([value respondsToSelector:@selector(boolValue)]) return [value boolValue];
	return NO;
}


- (void)setBoolValue:(BOOL)inValue
{
	[self setValue:[NSNumber numberWithBool:inValue]];
}


- (void)apply:(NSMutableDictionary *)ioState
{
	if (nil != value) [ioState setObject:value forKey:key];
}


- (NSString *)name
{
	if (nil == name) name = NSLocalizedString(key, NULL);
	return [[name retain] autorelease];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{\"%@\", key=%@, value=%@}", [self className], self, [self name], key, value];
}

@end
