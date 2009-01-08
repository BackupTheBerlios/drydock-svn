/*
	SGConditionalTag.m
	$Id$
	
	Copyright © 2006 Jens Ayton
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "SGConditionalTag.h"


@implementation SGConditionalTag

#pragma mark NSObject

- (void)dealloc
{
	self.conditionKey = nil;
	self.comparator = nil;
	self.resultKey = nil;
	self.trueValue = nil;
	self.falseValue = nil;
	
	[super dealloc];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{%@}", [self className], self, [self expressionDescription]];
}


#pragma mark SGSceneTag

- (void)apply:(NSMutableDictionary *)ioState
{
	if (nil != _resultKey) [ioState setObject:[self evaluateWithState:ioState] forKey:_resultKey];
}


- (id)name
{
	return [NSString stringWithFormat:@"conditional %@", self.resultKey];
}


#pragma mark SGConditionalTag

+ (id)tagWithComparator:(id)inComparator operation:(NSComparisonResult)inOperation conditionKey:(NSString *)inConditionKey resultKey:(NSString *)inResultKey
{
	return [[[self alloc] initWithComparator:inComparator operation:inOperation conditionKey:inConditionKey resultKey:inResultKey] autorelease];
}


- (id)initWithComparator:(id)inComparator operation:(NSComparisonResult)inOperation conditionKey:(NSString *)inConditionKey resultKey:(NSString *)inResultKey
{
	self = [self init];
	if (nil != self)
	{
		self.comparator = inComparator;
		self.operation = inOperation;
		self.conditionKey = inConditionKey;
		self.resultKey = inResultKey;
	}
	return self;
}


- (BOOL)evaluateExpressionWithState:(NSDictionary *)inState
{
	return [self evaluateExpressionWithValue:[inState objectForKey:_conditionKey]];
}


- (BOOL)evaluateExpressionWithValue:(id)inValue
{
	BOOL							result = NO;
	
	if (_operation == NSOrderedSame)
	{
		result = [_comparator isEqual:inValue];
	}
	else if ([_comparator respondsToSelector:@selector(compare:)])
	{
		result = [_comparator compare:inValue];
	}
	
	return result;
}


- (id)evaluateWithState:(NSDictionary *)inState
{
	return [self evaluateExpressionWithState:inState] ? self.trueValue : self.falseValue;
}


- (id)evaluateWithValue:(id)inValue
{
	return [self evaluateExpressionWithValue:inValue] ? self.trueValue : self.falseValue;
}


- (NSString *)expressionDescription
{
	NSString					*opString = nil;
	NSString					*result = nil;
	
	switch ([self operation])
	{
		case NSOrderedAscending:
			opString = @">";
			break;
		
		case NSOrderedSame:
			opString = @"==";
			break;
		
		case NSOrderedDescending:
			opString = @"<";
			break;
		
		default:
			opString = @"[unknown operation]";
	}
	
	result =  [NSString stringWithFormat:@"%@ = (%@ %@ %@)",
										 self.resultKey,
										 self.conditionKey,
										 opString,
										 self.comparator];
	
	if (self.trueValue != nil || self.falseValue != nil)
	{
		result = [result stringByAppendingFormat:@" ? %@ : %@",
												 self.trueValue,
												 self.falseValue];
	}
	return result;
}


- (NSString *)conditionKey
{
	return _conditionKey;
}


- (void)setConditionKey:(NSString *)inConditionKey
{
	if (inConditionKey != _conditionKey)
	{
		[_conditionKey autorelease];
		_conditionKey = [inConditionKey copy];
		[self becomeDirty];
	}
}


- (NSComparisonResult)operation
{
	return _operation;
}


- (void)setOperation:(NSComparisonResult)inOperation
{
	if (_operation != inOperation)
	{
		if (NSOrderedAscending <= inOperation && inOperation <= NSOrderedDescending)
		{
			_operation = inOperation;
			[self becomeDirty];
		}
		else
		{
			NSLog(@"%s: invalid operation %i.", __FUNCTION__, inOperation);
		}
	}
}


- (id)comparator
{
	return _comparator;
}


- (void)setComparator:(id)inComparator
{
	if (_comparator != inComparator)
	{
		[_comparator autorelease];
		_comparator = [inComparator retain];
		[self becomeDirty];
	}
}


- (NSString *)resultKey
{
	return _resultKey;
}


- (void)setResultKey:(NSString *)inResultKey
{
	if (_resultKey != inResultKey)
	{
		[_resultKey autorelease];
		_resultKey = [inResultKey copy];
		[self becomeDirty];
	}
}


- (id)trueValue
{
	return _trueValue ?: $true;
}


- (void)setTrueValue:(id)inValue
{
	if (_trueValue != inValue)
	{
		[_trueValue autorelease];
		_trueValue = [inValue retain];
		[self becomeDirty];
	}
}


- (id)falseValue
{
	return _falseValue ?: $false;
}


- (void)setFalseValue:(id)inValue
{
	if (_falseValue != inValue)
	{
		[_falseValue autorelease];
		_falseValue = [inValue retain];
		[self becomeDirty];
	}
}

@end
