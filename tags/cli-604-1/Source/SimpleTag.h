/*
	SimpleTag.h
	Dry Dock for Oolite
	$Id$
	
	Simple key-value implementation of SceneTag.
	
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

#import "SceneTag.h"


@interface SimpleTag: SceneTag
{
	NSString				*name;
	NSString				*key;
	id						value;
}

- (id)initWithKey:(NSString *)inKey andName:(NSString *)inName;
- (id)initWithKey:(NSString *)inKey;		// Name will be Localizable.strings version of key

// Conveniences
+ (id)tagWithKey:(NSString *)inKey value:(id)inValue;
+ (id)tagWithKey:(NSString *)inKey intValue:(int)inValue;
+ (id)tagWithKey:(NSString *)inKey doubleValue:(double)inValue;
+ (id)tagWithKey:(NSString *)inKey boolValue:(bool)inValue;
- (id)initWithKey:(NSString *)inKey value:(id)inValue;
- (id)initWithKey:(NSString *)inKey intValue:(int)inValue;
- (id)initWithKey:(NSString *)inKey doubleValue:(double)inValue;
- (id)initWithKey:(NSString *)inKey boolValue:(bool)inValue;

- (id)value;
- (void)setValue:inValue;

- (int)intValue;
- (void)setIntValue:(int)inValue;
- (double)doubleValue;
- (void)setDoubleValue:(double)inValue;
- (BOOL)boolValue;
- (void)setBoolValue:(BOOL)inValue;

@end
