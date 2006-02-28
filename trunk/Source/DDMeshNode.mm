/*
	DDMeshNode.mm
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2004-2006 Jens Ayton

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

#import "DDMeshNode.h"
#import "DDMesh.h"
#import "Logging.h"


@implementation DDMeshNode

- (id)init
{
	self = [super init];
	if (nil != self)
	{
		[self setLocalizedName:@"DDMesh"];
	}
	
	return self;
}


+ (id)nodeWithMesh:(DDMesh *)inMesh
{
	return [[[self alloc] initWithMesh:inMesh] autorelease];
}


- (id)initWithMesh:(DDMesh *)inMesh
{
	self = [self init];
	if (nil != self)
	{
		[self setMesh:inMesh];
//		[self setName:[inMesh name]];
	}
	return self;
}


- (void)dealloc
{
	[_mesh release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}


- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty
{
	TraceEnter();
	
	BOOL			shading = YES;
	BOOL			wireframe = NO;
	BOOL			normals = NO;
	id				val;
	
	val = [inState objectForKey:@"wireframe"];
	if (val && [val respondsToSelector:@selector(boolValue)])
	{
		wireframe = [val boolValue];
	}
	
	val = [inState objectForKey:@"shading"];
	if (val && [val respondsToSelector:@selector(boolValue)])
	{
		shading = [val boolValue];
	}
	
	val = [inState objectForKey:@"normals"];
	if (val && [val respondsToSelector:@selector(boolValue)])
	{
		normals = [val boolValue];
	}
	
	if (shading)	[_mesh glRenderShaded];
	if (wireframe)	[_mesh glRenderWireframe];
	
	if (normals)	[_mesh glRenderNormals];
	
	TraceExit();
}


- (void)setMesh:(DDMesh *)inMesh
{
	NSNotificationCenter			*nc;
	
	if (inMesh != _mesh)
	{
		nc = [NSNotificationCenter defaultCenter];
		[nc removeObserver:self name:kNotificationDDMeshModified object:_mesh];
		
		[_mesh release];
		_mesh = [inMesh retain];
		[self becomeDirty];
		
		[nc addObserver:self selector:@selector(meshModified:) name:kNotificationDDMeshModified object:_mesh];
	}
}


- (void)meshModified:notification
{
	[self becomeDirty];
}

@end
