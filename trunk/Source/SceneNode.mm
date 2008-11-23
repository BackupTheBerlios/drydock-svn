/*
	SceneNode.m
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

#define ENABLE_TRACE 0

#import "SceneNode.h"
#import "SceneTag.h"
#import "SimpleTag.h"
#import "Logging.h"

NSString *kNotificationSceneNodeModified = @"com.ahruman.is-a-geek ObjectiveSceneGraph kNotificationSceneNodeModified";


@interface SceneNode(Private)

- (void)setParent:(SceneNode *)inParent;

@end


@interface SceneTag(Private)

- (void)setOwner:(SceneNode *)inOwner;
- (SceneNode *)owner;

@end


@interface SceneNodeEnumerator: NSEnumerator
{
	SceneNode				*next;
}

- (id)initWithFirstNode:(SceneNode *)inNode;

@end


@implementation SceneNode

+ (id)node
{
	return [[[self alloc] init] autorelease];
}


- (id)init
{
	self = [super init];
	if (nil != self)
	{
		isDirty = YES;
		[self setLocalizedName:@"unnamed"];
	}
	return self;
}


- (void)dealloc
{
	NSEnumerator			*tagEnum;
	SceneTag				*tag;
	
	if (nil != parent)
	{
		[self retain];
		[parent removeChild:self];
		return;
	}
	while (firstChild)
	{
		[firstChild setParent:nil];
	}
	for (tagEnum = [tags objectEnumerator]; (tag = [tagEnum nextObject]); )
	{
		[tag setOwner:nil];
	}
	[tags release];
	[name release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:nil object:self];
	
	[super dealloc];
}


#if OBJECTIVESCENE_IMPLEMENT_CODING

- (void)encodeWithCoder:(NSCoder *)inCoder
{
	unsigned			i;
	NSMutableArray		*encodedMatrix;
	NSNumber			*number;
	
	if (![inCoder allowsKeyedCoding])
	{
		[NSException raise:NSGenericException format:@"SceneNodes archiving requires keyed coding."];
	}
	
	if (nil != name) [inCoder encodeObject:name forKey:@"SceneNode.name"];
	
	if (transformed)
	{
		// Encode matrix as an array of NSNumbers
		encodedMatrix = [NSMutableArray arrayWithCapacity:16];
		for (i = 0; i != 16; ++i)
		{
			#if PHYS_DOUBLE_PRECISION
				number = [NSNumber numberWithDouble:matrix[i]];
			#else
				number = [NSNumber numberWithFloat:matrix[i]];
			#endif
			
			[encodedMatrix addObject:number];
		}
		
		[inCoder encodeObject:encodedMatrix forKey:@"SceneNode.matrix"];
	}
	
	if (nil != tags) [inCoder encodeObject:tags forKey:@"SceneNode.tags"];
	if (nil != firstChild) [inCoder encodeObject:firstChild forKey:@"SceneNode.firstChild"];
	if (nil != nextSibling) [inCoder encodeObject:nextSibling forKey:@"SceneNode.nextSibling"];
}


- (id)initWithCoder:(NSCoder *)inDecoder
{
	unsigned			i;
	NSArray				*encodedMatrix;
	
	if (![inDecoder allowsKeyedCoding])
	{
		[self release];
		[NSException raise:NSGenericException format:@"SceneNodes archiving requires keyed coding."];
	}
	
	self = [self init];
	if (nil != self)
	{
		name = [[inDecoder decodeObjectForKey:@"SceneNode.name"] retain];
		NSLog(@"Unarchiving node \"%@\"", name);
		encodedMatrix = [inDecoder decodeObjectForKey:@"SceneNode.matrix"];
		if (nil != encodedMatrix)
		{
			for (i = 0; i != 16; ++i)
			{
				#if PHYS_DOUBLE_PRECISION
					matrix[i] = [[encodedMatrix objectAtIndex:i] doubleValue];
				#else
					matrix[i] = [[encodedMatrix objectAtIndex:i] floatValue];
				#endif
			}
		}
		tags = [[inDecoder decodeObjectForKey:@"SceneNode.tags"] mutableCopy];
		firstChild = [[inDecoder decodeObjectForKey:@"SceneNode.firstChild"] retain];
		nextSibling = [[inDecoder decodeObjectForKey:@"SceneNode.nextSibling"] retain];
	}
	return self;
}

#endif	// OBJECTIVESCENE_IMPLEMENT_CODING


- (void)addChild:(SceneNode *)inNode
{
	SceneNode				*child;
	
	if (nil == inNode) return;
	if (inNode->parent == self)
	{
		NSLog(@"%s: child already exists.", __FUNCTION__);
		return;
	}
	
	if (nil == firstChild)
	{
		firstChild = [inNode retain];
	}
	else
	{
		child = firstChild;
		while (child->nextSibling) child = child->nextSibling;
		
		child->nextSibling = [inNode retain];
	}
	[inNode setParent:self];
	inNode->nextSibling = nil;
	++childCount;
}


- (void)insertChild:(SceneNode *)inNode after:(SceneNode *)inExistingChild
{
	SceneNode				*child;
	
	if (inNode->parent == self)
	{
		NSLog(@"%s: child already exists.", __FUNCTION__);
		return;
	}
	if (nil != firstChild)
	{
		child = firstChild;
		while (child)
		{
			if (child == inExistingChild)
			{
				[inNode retain];
				[inNode setParent:self];
				inNode->nextSibling = child->nextSibling;
				child->nextSibling = inNode;
				++childCount;
				return;
			}
			child = child->nextSibling;
		}
	}
	
	NSLog(@"%s: reference child does not exist.", __FUNCTION__);
	return;
}


- (void)removeChild:(SceneNode *)inChild
{
	SceneNode				*child;
	
	if (inChild->parent != self)
	{
		NSLog(@"%s: no child of mine.", __FUNCTION__);
		return;
	}
	if (nil != firstChild)
	{
		if (firstChild == inChild)
		{
			firstChild = inChild->nextSibling;
			inChild->nextSibling = NULL;
			inChild->parent = NULL;
			[inChild autorelease];
			--childCount;
			return;
		}
		else
		{
			child = firstChild;
			while (child)
			{
				if (child->nextSibling == inChild)
				{
					child->nextSibling = inChild->nextSibling;
					inChild->nextSibling = NULL;
					inChild->parent = NULL;
					[inChild autorelease];
					--childCount;
					return;
				}
				child = child->nextSibling;
			}
		}
	}
	
	NSLog(@"%s: internal inconsistency: input node thinks it's a child, but it isn't in child list. Setting node's parent to nil.", __FUNCTION__);
	inChild->parent = nil;
}


- (uint32_t)numberOfChildren
{
	return childCount;
}


- (SceneNode *)childAtIndex:(uint32_t)inIndex
{
	SceneNode				*child;
	
	child = firstChild;
	while  (inIndex--) child = [child nextSibling];
	return [[child retain] autorelease];
}


- (void)setParent:(SceneNode *)inParent
{
	if (inParent == parent) return;
	
	[parent removeChild:self];
	self->parent = inParent;
}


- (id)firstChild
{
	return [[firstChild retain] autorelease];
}


- (id)nextSibling
{
	return [[nextSibling retain] autorelease];
}


- (NSEnumerator *)childEnumerator
{
	return [[[SceneNodeEnumerator alloc] initWithFirstNode:firstChild] autorelease];
}


- (SceneNode *)parent
{
	return [[parent retain] autorelease];
}


- (Matrix)matrix
{
	return matrix;
}


- (void)setMatrix:(const Matrix *)inMatrix
{
	#ifndef NDEBUG
		if (inMatrix == NULL)
		{
			[NSException raise:NSInvalidArgumentException format:@"%s: NULL matrix passed. This will crash non-debug builds. Receiver = %@", __FUNCTION__, self];
		}
	#endif
	
	matrix = *inMatrix;
	transformed = YES;
}


- (void)setMatrixIdentity
{
	matrix.SetIdentity();
	transformed = NO;
}


- (size_t)tagCount
{
	return [tags count];
}


- (SceneTag *)tagAtIndex:(size_t)inIndex
{
	return [tags objectAtIndex:inIndex];
}


- (void)addTag:(SceneTag *)inTag
{
	if (self == [inTag owner]) return;
	if (nil == tags) tags = [[NSMutableArray alloc] init];
	[tags addObject:inTag];
	[inTag setOwner:self];
	[self becomeDirty];
	[self becomeDirtyDownwards];
}


- (void)insertTag:(SceneTag *)inTag atIndex:(size_t)inIndex
{
	if (self == [inTag owner]) return;
	if (nil == tags) tags = [[NSMutableArray alloc] init];
	[tags insertObject:inTag atIndex:inIndex];
	[inTag setOwner:self];
	[self becomeDirty];
	[self becomeDirtyDownwards];
}


- (void)removeTagAtIndex:(uint32_t)inIndex
{
	[[tags objectAtIndex:inIndex] setOwner:nil];
	[tags removeObjectAtIndex:inIndex];
	[self becomeDirty];
	[self becomeDirtyDownwards];
}


- (void)removeTag:(SceneTag *)inTag
{
	unsigned			index;
	if (self != [inTag owner]) return;
	index = [tags indexOfObject:inTag];
	#ifndef NDEBUG
		if (NSNotFound == index) [NSException raise:NSInternalInconsistencyException format:@"%s: tag specifies self as owner, but is not in tag list.", __FUNCTION__];
	#endif
	[self removeTagAtIndex:index];
}


- (NSString *)name
{
	return [[name retain] autorelease];
}


- (void)setName:(NSString *)inName
{
	if (name != inName)
	{
		[name release];
		name = [inName retain];
	}
}


- (void)setLocalizedName:(NSString *)inName
{
	[self setName:NSLocalizedString(inName, NULL)];
}


- (void)becomeDirty
{
	if (!isDirty) [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSceneNodeModified object:self];
	
	isDirty = 1;
	[parent becomeDirty];
}


- (void)becomeDirtyDownwards
{
	NSEnumerator			*childEnumerator;
	SceneNode				*child;
	
	if (!isDirty) [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSceneNodeModified object:self];
	
	isDirty = 1;
	
	for (childEnumerator = [self childEnumerator]; (child = [childEnumerator nextObject]); )
	{
		[child becomeDirtyDownwards];
	}
}


- (BOOL)isDirty
{
	return isDirty;
}


- (void)render
{
	[self renderWithState:nil];
}


- (void)renderWithState:(NSDictionary *)inState
{
	TraceEnterMsg(@"Called for %@ {", [self name]);
	
	NSMutableDictionary		*state;
	NSEnumerator			*tagEnum, *childEnum;
	SceneTag				*tag;
	SceneNode				*child;
	BOOL					wasTransformed = transformed;
	
	// Apply transformation if necessary
	if (wasTransformed)
	{
		#if OBJECTIVESCENE_TRACE_RENDER
			LogMessage(@"Applying transformation");
		#endif
		glPushMatrix();
		matrix.glMult();
	}
	
	if (nil != tags)
	{
		@try
		{
			// Apply tags
			if (nil == inState) state = [[NSMutableDictionary alloc] init];
			else state = [inState mutableCopy];
			
			for (tagEnum = [tags objectEnumerator]; (tag = [tagEnum nextObject]); )
			{
				[tag apply:state];
			}
		}
		@catch (id whatever)
		{
			NSLog(@"Exception applying tags for %@.", self);
			@throw (whatever);
		}
	}
	else
	{
		state = [inState retain];
	}
	
	// Render
	#if OBJECTIVESCENE_TRACE_RENDER
		if (nil == state)
		{
			LogMessage(@"Rendering %@", [self name]);
		}
		else
		{
			LogMessage(@"Rendering %@ with state %@", [self name], state);
		}
		LogIndent();
	#endif
	
	@try
	{
		tag = [state objectForKey:@"visible"];
		if (nil == tag || [(SimpleTag *)tag boolValue])
		{
			[self performRenderWithState:state dirty:isDirty];
		}
	}
	@catch (id whatever)
	{
		LogMessage(@"Exception %@ performing self-render of %@.", whatever, self);
	}
	isDirty = NO;
	
	// Render children
	for (childEnum = [self childEnumerator]; (child = [childEnum nextObject]); )
	{
		[child renderWithState:state];
	}
	
	[state release];
	// Un-apply tags
	for (tagEnum = [tags objectEnumerator]; (tag = [tagEnum nextObject]); )
	{
		[tag unapply];
	}
	
	#if OBJECTIVESCENE_TRACE_RENDER
		LogOutdent();
	#endif
	
	// Revert transformation
	if (wasTransformed) glPopMatrix();
	
	TraceExit();
}


- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty
{
	// Do nothing, this is an abstract node
}


- (NSString*)description
{
	return [NSString stringWithFormat:@"<%@ %p>{\"%@\", childCount=%u, tags=%@}", [self className], self, [self name]?:@"", [self numberOfChildren], tags];
}

@end


@implementation SceneNodeEnumerator

- (id)initWithFirstNode:(SceneNode *)inNode
{
	self = [super init];
	if (nil != self)
	{
		next = [inNode retain];
	}
	return self;
}


- (void)dealloc
{
	[next release];
	
	[super dealloc];
}


- (id)nextObject
{
	SceneNode				*result;
	
	result = next;
	next = [[next nextSibling] retain];
	
	return [result autorelease];
}

@end
