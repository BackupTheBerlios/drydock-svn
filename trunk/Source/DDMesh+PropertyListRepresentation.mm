/*
	DDMesh+PropertyListRepresentation.mm
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

#define ENABLE_TRACE 1

#import "DDMesh.h"
#import "Logging.h"
#import "DDProblemReportManager.h"
#import "DDMaterial.h"
#import <ppc_intrinsics.h>


#if __BIG_ENDIAN__
static void ByteSwap4Array(void *ioBuffer, size_t inCount);
#endif


@implementation DDMesh (PropertyListRepresentation)

- (id)initWithPropertyListRepresentation:(id)inPList issues:(DDProblemReportManager *)ioIssues
{
	return nil;
}


- (void)gatherIssuesWithGeneratingPropertyListRepresentation:(DDProblemReportManager *)ioManager
{
	NSEnumerator			*materialEnumerator;
	DDMaterial				*material;
	unsigned				i;
	
	for (i = 0; i != _materialCount; ++i)
	{
		[_materials[i] gatherIssuesWithGeneratingPropertyListRepresentation:ioManager];
	}
}


- (id)propertyListRepresentationWithIssues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	BOOL					OK = YES;
	NSMutableDictionary		*result;
	NSMutableDictionary		*materials;
	DDMaterial				*material;
	unsigned				i;
	NSEnumerator			*materialEnumerator;
	NSString				*name;
	id						plist;
	NSData					*vertexData = nil, *normalData = nil;
	size_t					verticesSize, normalsSize;
	
	result = [[NSMutableDictionary alloc] initWithCapacity:4];
	if (nil == result)
	{
		OK = NO;
		[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
	}
	
	if (nil != _name) [result setObject:_name forKey:@"name"];
	
	// Add materials
	if (OK)
	{
		if (0 != _materialCount)
		{
			materials = [[NSMutableDictionary alloc] initWithCapacity:_materialCount];
			if (nil == materials)
			{
				OK = NO;
				[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
			}
			
			for (i = 0; i != _materialCount; ++i)
			{
				material = _materials[i];
				plist = [material propertyListRepresentationWithIssues:ioIssues];
				if (nil == plist)
				{
					OK = NO;
					break;
				}
				[materials setObject:plist forKey:[material name]];
			}
			
			if (OK) [result setObject:materials forKey:@"materials"];
			[materials release];
		}
	}
	
	if (OK)
	{
		// Add vertices and normals
		verticesSize = sizeof (Vector) * _vertexCount;
		normalsSize = sizeof (Vector) * _normalCount;
		#if __LITTLE_ENDIAN__
			vertexData = [NSData dataWithBytesNoCopy:_vertices length:verticesSize freeWhenDone:NO];
			normalData = [NSData dataWithBytesNoCopy:_normals length:normalsSize freeWhenDone:NO];
		#elif __BIG_ENDIAN__
			void			*vertexBytes;
			void			*normalBytes;
			
			vertexBytes = malloc(verticesSize);
			normalBytes = malloc(sizeof(Vector) * _normalCount);
			if (NULL == vertexBytes || NULL == normalBytes)
			{
				OK = NO;
				if (NULL != vertexBytes) free(vertexBytes);
				if (NULL != normalBytes) free(normalBytes);
				[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
			}
			else
			{
				bcopy(_vertices, vertexBytes, verticesSize);
				bcopy(_normals, normalBytes, normalsSize);
				
				ByteSwap4Array(vertexBytes, verticesSize / sizeof (float));
				ByteSwap4Array(normalBytes, normalsSize / sizeof (float));
				
				vertexData = [NSData dataWithBytesNoCopy:vertexBytes length:verticesSize freeWhenDone:YES];
				normalData = [NSData dataWithBytesNoCopy:normalBytes length:normalsSize freeWhenDone:YES];
			}
		#else
			#error Unknown byte sex!
		#endif
		
		if (nil == vertexData || nil == normalData)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
	}
	if (OK)
	{
		[result setObject:vertexData forKey:@"vertices"];
		[result setObject:normalData forKey:@"normals"];
	}
	
	if (!OK)
	{
		[result release];
		result = nil;
	}
	
	return [result autorelease];
	TraceExit();
}

@end


#if __BIG_ENDIAN__
#if TARGET_CPU_PPC

static void ByteSwap4Array(void *ioBuffer, size_t inCount)
{
	uint32_t			*ptr;
	uint32_t			index;
	
	if (NULL == ioBuffer || 0 == inCount) return;
	
	index = 0;
	ptr = (uint32_t *)ioBuffer;
	do
	{
		*ptr++ = __lwbrx(ioBuffer, index);
		index += 4;
	} while (--inCount);
}

#else

static void ByteSwap4Array(void *ioBuffer, size_t inCount)
{
	uint32_t			*ptr, src, rev;
	
	if (NULL == ioBuffer || 0 == inCount) return;
	
	ptr = (uint32_t *)ioBuffer;
	do
	{
		src = *ptr;
		rev = src >> 24;
		rev |= src >> 8 & 0x0000FF00;
		rev |= src << 8 & 0x00FF0000;
		rev |= src << 24;
		*ptr++ = rev;
	} while (--inCount);
}

#endif	// TARGET_CPU_PPC
#endif	// __BIG_ENDIAN__
