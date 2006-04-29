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

#define ENABLE_TRACE 0

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
	TraceEnter();
	
	BOOL					OK = YES;
	NSDictionary			*dict;
	id						object;
	NSArray					*materialsArray = nil, *facesArray = nil;
	NSData					*verticesData = nil, *normalsData = nil, *texCoordsData = nil;
	unsigned				i, j;
	NSArray					*faceVerts;
	float					r;
	Vector					vec;
	unsigned				count;
	
	_xMin = INFINITY; _xMax = -INFINITY;
	_yMin = INFINITY; _yMax = -INFINITY;
	_zMin = INFINITY; _zMax = -INFINITY;
	
	if (![inPList isKindOfClass:[NSDictionary class]])
	{
		OK = NO;
		LogMessage(@"Input %@ is not a dictionary.", inPList);
		[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
	}
	
	if (OK)
	{
		dict = inPList;
		
		// Read optional keys
		object = [dict objectForKey:@"name"];
		if ([object isKindOfClass:[NSString class]]) _name = [object retain];
		object = [dict objectForKey:@"source file"];
		if ([object isKindOfClass:[NSString class]]) _sourceFile = [object retain];
		
		// Read mandatory elements
		object = [dict objectForKey:@"materials"];
		if ([object isKindOfClass:[NSArray class]]) materialsArray = object;
		object = [dict objectForKey:@"faces"];
		if ([object isKindOfClass:[NSArray class]]) facesArray = object;
		object = [dict objectForKey:@"vertices"];
		if ([object isKindOfClass:[NSData class]]) verticesData = object;
		object = [dict objectForKey:@"normals"];
		if ([object isKindOfClass:[NSData class]]) normalsData = object;
		object = [dict objectForKey:@"texture co-ordinates"];
		if ([object isKindOfClass:[NSData class]]) texCoordsData = object;
		
		// Ensure that we’ve got the mandatory elements
		if (nil == materialsArray || nil == facesArray || nil == verticesData || nil == normalsData || nil == texCoordsData)
		{
			OK = NO;
			LogMessage(@"Missing mandatory elements.");
			[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
		}
	}
	
	if (OK)
	{
		count = [verticesData length] / sizeof (Vector);
		if (kDDMeshIndexMax < count)
		{
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"vertices", NULL), count];
			OK = NO;
		}
	}
	
	// Set up vertices array
	if (OK)
	{
		_vertexCount = count;
		_vertices = (Vector *)malloc(sizeof (Vector) * _vertexCount);
		if (NULL == _vertices)
		{
			OK = NO;
			LogMessage(@"Failed to allocate vertices array (%u entries).", _vertexCount);
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
		else
		{
			bcopy([verticesData bytes], _vertices, sizeof (Vector) * _vertexCount);
			#if __BIG_ENDIAN__
				ByteSwap4Array(_vertices, _vertexCount * 3);
			#elif !__LITTLE_ENDIAN__
				#error Unknown byte sex!
			#endif
			
			for (i = 0; i != _vertexCount; ++i)
			{
				vec = _vertices[i];
				
				if (vec.x < _xMin) _xMin = vec.x;
				if (_xMax < vec.x) _xMax = vec.x;
				if (vec.y < _yMin) _yMin = vec.y;
				if (_yMax < vec.y) _yMax = vec.y;
				if (vec.z < _zMin) _zMin = vec.z;
				if (_zMax < vec.z) _zMax = vec.z;
				
				r = vec.Magnitude();
				if (_rMax < r) _rMax = r;
			}
		}
	}
	
	if (OK)
	{
		count = [normalsData length] / sizeof (Vector);
		if (kDDMeshIndexMax < count)
		{
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"normals", NULL), count];
			OK = NO;
		}
	}
	
	if (OK)
	{
		// Set up normals array
		_normalCount = count;
		_normals = (Vector *)malloc(sizeof (Vector) * _normalCount);
		if (NULL == _normals)
		{
			OK = NO;
			LogMessage(@"Failed to allocate normals array (%u entries).", _normalCount);
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
		else
		{
			bcopy([normalsData bytes], _normals, sizeof (Vector) * _normalCount);
			#if __BIG_ENDIAN__
				ByteSwap4Array(_normals, _normalCount * 3);
			#elif !__LITTLE_ENDIAN__
				#error Unknown byte sex!
			#endif
		}
	}
	
	if (OK)
	{
		count = [texCoordsData length] / sizeof (Vector2);
		if (kDDMeshIndexMax < count)
		{
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"texture co-ordinate pairs", NULL), count];
			OK = NO;
		}
	}
	
	if (OK)
	{
		// Set up texture co-ordinates array
		if (0 != count)
		{
			_texCoordCount = count;
			_texCoords = (Vector2 *)malloc(sizeof (Vector2) * _texCoordCount);
			if (NULL != _texCoords)
			{
				bcopy([texCoordsData bytes], _texCoords, sizeof (Vector2) * _texCoordCount);
				#if __BIG_ENDIAN__
					ByteSwap4Array(_texCoords, _texCoordCount * 2);
				#elif !__LITTLE_ENDIAN__
					#error Unknown byte sex!
				#endif
			}
		}
		else
		{
			_texCoordCount = 1;
			_texCoords = (Vector2 *)calloc(sizeof (Vector2), 1);
		}
		if (NULL == _texCoords)
		{
			OK = NO;
			LogMessage(@"Failed to allocate texture co-ordinates array (%u entries).", _texCoordCount);
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
	}
	
	if (OK)
	{
		count = [materialsArray count];
		if (kDDMeshIndexMax < count)
		{
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"materials", NULL), count];
			OK = NO;
		}
	}
	
	if (OK)
	{
		// Set up materials array
		_materialCount = count;
		_materials = (DDMaterial **)calloc(sizeof (DDMaterial *) , _materialCount);
		if (NULL == _vertices)
		{
			OK = NO;
			LogMessage(@"Failed to allocate materials array (%u entries).", _materialCount);
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
		else
		{
			for (i = 0; OK && i != _materialCount; ++i)
			{
				_materials[i] = [[DDMaterial alloc] initWithPropertyListRepresentation:[materialsArray objectAtIndex:i] issues:ioIssues];
				if (nil == _materials[i]) OK = NO;
			}
		}
	}
	
	if (OK)
	{
		count = [facesArray count];
		if (kDDMeshIndexMax < count)
		{
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"faces", NULL), count];
			OK = NO;
		}
	}
	
	#if 0
	if (OK)
	{
		// Load faces
		_faceCount = count;
		_faces = (DDMeshFaceData *)calloc(sizeof (DDMeshFaceData) , _faceCount);
		if (NULL == _vertices)
		{
			OK = NO;
			LogMessage(@"Failed to allocate faces array (%u entries).", _faceCount);
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
		else
		{
			for (i = 0; OK && i != _faceCount; ++i)
			{
				dict = [facesArray objectAtIndex:i];
				if (![dict isKindOfClass:[NSDictionary class]]) OK = NO;
				
				if (OK)
				{
					object = [dict objectForKey:@"material"];
					if (![object respondsToSelector:@selector(intValue)])
					{
						LogMessage(@"Failed to get material index for face %u (%@).", i, dict);
						OK = NO;
					}
				}
				
				if (OK)
				{
					_faces[i].material = [object intValue];
					if (_materialCount <= _faces[i].material) OK= NO;
					
					object = [dict objectForKey:@"normal"];
					if (![object respondsToSelector:@selector(intValue)])
					{
						LogMessage(@"Failed to get normal index for face %u (%@).", i, dict);
						OK = NO;
					}
				}
				
				if (OK)
				{
					_faces[i].normal = [object intValue];
					if (_normalCount <= _faces[i].normal) OK= NO;
					
					faceVerts = [dict objectForKey:@"vertices"];
					if (![faceVerts isKindOfClass:[NSArray class]])
					{
						LogMessage(@"Failed to get vertices array for face %u (%@).", i, dict);
						OK = NO;
					}
				}
				
				if (OK)
				{
					_faces[i].vertexCount = [faceVerts count];
					if (kMaxVertsPerFace < _faces[i].vertexCount)
					{
						LogMessage(@"Face %u has %u vertices; Dry Dock is limited to %u.", i, _faces[i].vertexCount, kMaxVertsPerFace);
						OK = NO;
					}
					
					for (j = 0; OK && j != _faces[i].vertexCount; ++j)
					{
						dict = [faceVerts objectAtIndex:j];
						if (![dict isKindOfClass:[NSDictionary class]])
						{
							LogMessage(@"Failed to get face dictionary for face %u.", i);
							OK = NO;
						}
						
						if (OK)
						{
							object = [dict objectForKey:@"vertex"];
							if (![object respondsToSelector:@selector(intValue)])
							{
								LogMessage(@"Failed to get vertex index for vertex %u of face %u (%@).", j, i, dict);
								OK = NO;
							}
						}
						
						if (OK)
						{
							_faces[i].verts[j] = [object intValue];
							if (_vertexCount <= _faces[i].verts[j])
							{
								LogMessage(@"Out-of-range vertex index %u (out of %u) for vertex %u of face %u (%@).", _faces[i].verts[j], _vertexCount, j, i, dict);
								OK = NO;
							}
						}
						
						if (OK)
						{
							object = [dict objectForKey:@"texture co-ordinates"];
							if (![object respondsToSelector:@selector(intValue)])
							{
								LogMessage(@"Failed to get texture co-ordinates index for vertex %u of face %u (%@).", j, i, dict);
								OK = NO;
							}
						}
						
						if (OK)
						{
							_faces[i].texCoords[j] = [object intValue];
							if (_texCoordCount <= _faces[i].texCoords[j])
							{
								LogMessage(@"Out-of-range texture co-ordinates index %u (out of %u) for vertex %u of face %u (%@).", _faces[i].texCoords[j], _texCoordCount, j, i, dict);
								OK = NO;
							}
						}
					}
				}
			}
			if (!OK) [ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
		}
	}
	#endif
	
	if (OK) [self findBadPolygonsWithIssues:ioIssues];
	
	if (!OK)
	{
		[self release];
		self = nil;
	}
	return self;
	TraceExit();
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
	NSMutableArray			*materialsArray;
	DDMaterial				*material;
	unsigned				i, j;
	NSEnumerator			*materialEnumerator;
	NSString				*name;
	id						plist;
	NSData					*vertexData = nil, *normalData = nil, *texCoordsData = nil;
	size_t					verticesSize, normalsSize, texCoordsSize;
	DDMeshFaceData			*face;
	NSMutableArray			*facesArray;
	NSMutableDictionary		*faceDict;
	NSMutableArray			*faceVerts;
	NSMutableDictionary		*vertDict;
	
	result = [[NSMutableDictionary alloc] initWithCapacity:7];
	if (nil == result)
	{
		OK = NO;
		[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
	}
	
	if (nil != _name) [result setObject:_name forKey:@"name"];
	if (nil != _sourceFile) [result setObject:_sourceFile forKey:@"source file"];
	
	// Add materials
	if (OK)
	{
		if (0 != _materialCount)
		{
			materialsArray = [[NSMutableArray alloc] initWithCapacity:_materialCount];
			if (nil == materialsArray)
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
				[materialsArray addObject:plist];
			}
			
			if (OK) [result setObject:materialsArray forKey:@"materials"];
			[NSMutableArray release];
		}
	}
	
	if (OK)
	{
		// Add vertices and normals
		verticesSize = sizeof (Vector) * _vertexCount;
		normalsSize = sizeof (Vector) * _normalCount;
		texCoordsSize = sizeof (Vector2) * _texCoordCount;
		#if __LITTLE_ENDIAN__
			vertexData = [NSData dataWithBytesNoCopy:_vertices length:verticesSize freeWhenDone:NO];
			normalData = [NSData dataWithBytesNoCopy:_normals length:normalsSize freeWhenDone:NO];
			texCoordsData = [NSData dataWithBytesNoCopy:_texCoords length:texCoordsSize freeWhenDone:NO];
		#elif __BIG_ENDIAN__
			void			*vertexBytes;
			void			*normalBytes;
			void			*texCoordsBytes;
			
			vertexBytes = malloc(verticesSize);
			normalBytes = malloc(normalsSize);
			texCoordsBytes = malloc(texCoordsSize);
			if (NULL == vertexBytes || NULL == normalBytes || NULL == texCoordsBytes)
			{
				OK = NO;
				if (NULL != vertexBytes) free(vertexBytes);
				if (NULL != normalBytes) free(normalBytes);
				if (NULL != texCoordsBytes) free(texCoordsBytes);
				[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
			}
			else
			{
				bcopy(_vertices, vertexBytes, verticesSize);
				bcopy(_normals, normalBytes, normalsSize);
				bcopy(_texCoords, texCoordsBytes, texCoordsSize);
				
				ByteSwap4Array(vertexBytes, verticesSize / sizeof (float));
				ByteSwap4Array(normalBytes, normalsSize / sizeof (float));
				ByteSwap4Array(texCoordsBytes, texCoordsSize / sizeof (float));
				
				vertexData = [NSData dataWithBytesNoCopy:vertexBytes length:verticesSize freeWhenDone:YES];
				normalData = [NSData dataWithBytesNoCopy:normalBytes length:normalsSize freeWhenDone:YES];
				texCoordsData = [NSData dataWithBytesNoCopy:texCoordsBytes length:texCoordsSize freeWhenDone:YES];
			}
		#else
			#error Unknown byte sex!
		#endif
		
		if (nil == vertexData || nil == normalData || nil == texCoordsData)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
	}
	if (OK)
	{
		[result setObject:vertexData forKey:@"vertices"];
		[result setObject:normalData forKey:@"normals"];
		[result setObject:texCoordsData forKey:@"texture co-ordinates"];
	}
	
	// Add faces
	#if 0
	if (OK)
	{
		face = _faces;
		facesArray = [[NSMutableArray alloc] initWithCapacity:_faceCount];
		if (nil == facesArray)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
		
		i = _faceCount;
		while (i-- && OK)
		{
			faceVerts = [[NSMutableArray alloc] initWithCapacity:face->vertexCount];
			if (nil == faceVerts)
			{
				OK = NO;
				[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
			}
			if (!OK) break;
			
			for (j = 0; j != face->vertexCount; ++j)
			{
				[faceVerts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:face->verts[j]], @"vertex",
										[NSNumber numberWithInt:face->texCoords[j]], @"texture co-ordinates",
										nil]];
			}
			
			[facesArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:face->normal], @"normal",
										[NSNumber numberWithInt:face->material], @"material",
										faceVerts, @"vertices",
										nil]];
			[faceVerts release];
			face++;
		}
		if (OK) [result setObject:facesArray forKey:@"faces"];
	}
	#endif
	
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
