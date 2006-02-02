/*
	SceneTag.mm
	Dry Dock for Oolite
	$Id$
	
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
#import "SceneNode.h"


@implementation SceneTag

+ (SceneTag *)tag
{
	return [[[self alloc] init] autorelease];
}


#if OBJECTIVESCENE_IMPLEMENT_CODING

- (void)encodeWithCoder:(NSCoder *)inCoder
{
	if (![inCoder allowsKeyedCoding])
	{
		[NSException raise:NSGenericException format:@"SceneTags archiving requires keyed coding."];
	}
	
	// We’re to abstract to do anything about it.
}


- (id)initWithCoder:(NSCoder *)inDecoder
{
	if (![inDecoder allowsKeyedCoding])
	{
		[self release];
		[NSException raise:NSGenericException format:@"SceneTags archiving requires keyed coding."];
	}
	return self;
}

#endif	// OBJECTIVESCENE_IMPLEMENT_CODING


- (void)apply:(NSMutableDictionary *)ioState
{
	
}


- (void)unapply
{
	
}


- (NSString *)name
{
	return NSLocalizedString(@"unnamed", NULL);
}


- (void)becomeDirty
{
	[owner becomeDirty];
	[owner becomeDirtyDownwards];
}


- (void)setOwner:(SceneNode *)inOwner
{
	if (owner == inOwner) return;
	
	if (nil != owner)
	{
		[[self retain] autorelease];
		SceneNode *temp = owner;
		owner = nil;
		[temp removeTag:self];
	}
	owner = inOwner;
}


- (SceneNode *)owner
{
	return owner;
}

@end
