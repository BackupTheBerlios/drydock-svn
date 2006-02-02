/*
	DDMesh.mm
	Dry Dock for Oolite
	
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

#import "DDMesh.h"
#import "Logging.h"
#import "DDMaterial.h"
#import "BS-HOM.h"
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"


NSString *kNotificationDDMeshModified = @"de.berlios.drydock kNotificationDDMeshModified";

@interface DDMesh (Private)

- (id)initAsCopyOf:(DDMesh *)inMesh;

@end


@implementation DDMesh


- (id)initAsCopyOf:(DDMesh *)inMesh
{
	BOOL				OK = YES;
	Vector				*vertices = NULL;
	DDMeshFaceData		*faces = NULL;
	NSDictionary		*materials = nil;
	NSDictionary		*materialsByURL = nil;
	unsigned			i, materialCount;
	id					*keys, *values;
	NSArray				*keyArray;
	id					key;
	NSZone				*zone;
	size_t				vertsSize, facesSize;
	
	self = [super init];
	if (nil == self) OK = NO;
	
	zone = [self zone];
	
	if (OK)
	{
		vertsSize = sizeof(Vector) * inMesh->_vertexCount;
		facesSize = sizeof(DDMeshFaceData) * inMesh->_faceCount;
		
		vertices = (Vector *)malloc(vertsSize);
		faces = (DDMeshFaceData *)malloc(facesSize);
		
		OK = nil != vertices && nil != faces;
	}
	
	if (OK)
	{
		// Copy materials
		materialCount = [inMesh->_materials count];
		if (0 != materialCount)
		{
			keys = (id *)alloca(materialCount * sizeof(id));
			values = (id *)alloca(materialCount * sizeof(id));
			keyArray = [inMesh->_materials allKeys];
			
			for (i = 0; i != materialCount; ++i)
			{
				key = [keyArray objectAtIndex:i];
				keys[i] = [key copy];
				values[i] = [[inMesh->_materials objectForKey:key] copy];
			}
			@try
			{
				materials = [NSDictionary dictionaryWithObjects:values forKeys:keys count:materialCount];
			}
			@catch (id whatever) {}
			if (nil == materials) OK = NO;
			
			if (OK)
			{
				// Create material-URL-to-material mapping
				for (i = 0; i != materialCount; ++i)
				{
					[keys[i] release];
					key = [values[i] diffuseMapURL];
					if (nil == key) key = [NSNull null];
					keys[i] = [key copy];
				}
				@try
				{
					materialsByURL = [NSDictionary dictionaryWithObjects:values forKeys:keys count:materialCount];
				}
				@catch (id whatever) {}
				if (nil == materialsByURL) OK = NO;
			}
			
			for (i = 0; i != materialCount; ++i)
			{
				[keys[i] release];
				[values[i] release];
			}
		}
	}
	
	if (OK)
	{
		bcopy(inMesh->_vertices, vertices, vertsSize);
		bcopy(inMesh->_faces, faces, facesSize);
		
		_vertexCount = inMesh->_vertexCount;
		_faceCount = inMesh->_faceCount;
		_xMin = inMesh->_xMin;
		_xMax = inMesh->_xMax;
		_yMin = inMesh->_yMin;
		_yMax = inMesh->_yMax;
		_zMin = inMesh->_zMin;
		_zMax = inMesh->_zMax;
		_rMax = inMesh->_rMax;
		_hasNonTriangles = inMesh->_hasNonTriangles;
		_name = [inMesh->_name copyWithZone:zone];
		
		// Go over faces, replacing material references
		for (i = 0; i != _faceCount; ++i)
		{
			key = [faces[i].material diffuseMapURL];
			if (nil == key) key = [NSNull null];
			faces[i].material = [materialsByURL objectForKey:key];
		}
	}
	
	if (OK)
	{
		_vertices = vertices;
		_faces = faces;
		_materials = [materials retain];
	}
	
	if (!OK)
	{
		if (vertices) free(vertices);
		if (faces) free(faces);
		[self release];
		self = nil;
	}
	
	return self;
}


- (void)dealloc
{
	if (NULL != _vertices) free(_vertices);
	if (NULL != _faces) free(_faces);
	[_materials release];
	[_name release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:kNotificationDDMeshModified object:self];
	
	[super dealloc];
}


- (id)copyWithZone:(NSZone *)inZone
{
	DDMesh					*copy;
	
	copy = [[[self class] allocWithZone:inZone] initAsCopyOf:self];
	return copy;
}


- (void)recalculateNormals
{
	// Calculate new normal for each face.
	unsigned				i;
	DDMeshFaceData		*face;
	Vector					v0, v1, v2,
							a, b,
							n;
	
	/*
		Calculation is as follows:
		Given a polygon with S sides, verts[0]..vers[S - 1], find three adjacent vertices. (v0, v1, v2)
		Subtract the outer of these from the central one to get vectors along two adjacent edges. (a, b)
		Take cross product and normalise. (n)
	*/
	
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		v0 = _vertices[face->verts[0]];
		v1 = _vertices[face->verts[1]];
		v2 = _vertices[face->verts[face->vertexCount - 1]];
		
		a = v1 - v0;
		b = v2 - v0;
		
		n = (a % b);
		
		face->normal = n.Normalize();
		
		++face;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
}


- (void)reverseWinding
{
	// Reverse winding direction by changing the order of vertices in each face.
	unsigned				i, j, faceVerts;
	DDMeshFaceData		*face;
	uint16_t				tempVerts[kMaxVertsPerFace];
	float					tempTex_s[kMaxVertsPerFace],
							tempTex_t[kMaxVertsPerFace];
	
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		faceVerts = face->vertexCount;
		
		// Build reversed list
		for (j = 0; j != faceVerts; ++j)
		{
			tempVerts[j] = face->verts[faceVerts - j - 1];
			tempTex_s[j] = face->tex_s[faceVerts - j - 1];
			tempTex_t[j] = face->tex_t[faceVerts - j - 1];
		}
		
		// Copy reversed list to face
		for (j = 0; j != faceVerts; ++j)
		{
			face->verts[j] = tempVerts[j];
			face->tex_s[j] = tempTex_s[j];
			face->tex_t[j] = tempTex_t[j];
		}
		
		++face;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
}


- (void)triangulate
{
	unsigned			i, j, k, count, total, subCount;
	DDMeshFaceData		*newFaces;
	
	// Count the number of triangles we’ll end up with
	
	count = _faceCount;
	total = 0;
	for (i = 0; i != count; ++i)
	{
		assert(3 <= _faces[i].vertexCount);
		total += _faces[i].vertexCount - 2;
	}
	
	newFaces = (DDMeshFaceData *)malloc(sizeof(DDMeshFaceData) * total);
	for (i = 0; i != count; ++i)
	{
		if (_faces[i].vertexCount == 3)
		{
			newFaces[j++] = _faces[i];
		}
		else
		{
			// Convert face into triangle fan
			subCount = _faces[i].vertexCount - 2;
			for (k = 0; k != subCount; ++k)
			{
				newFaces[j].normal = _faces[i].normal;
				newFaces[j].color[0] = _faces[i].color[0];
				newFaces[j].color[1] = _faces[i].color[1];
				newFaces[j].color[2] = _faces[i].color[2];
				newFaces[j].vertexCount = 3;
				
				newFaces[j].verts[0] = _faces[i].verts[0];
				newFaces[j].verts[1] = _faces[i].verts[k + 1];
				newFaces[j].verts[2] = _faces[i].verts[k + 2];
				
				newFaces[j].tex_s[0] = _faces[i].tex_s[0];
				newFaces[j].tex_s[1] = _faces[i].tex_s[k + 1];
				newFaces[j].tex_s[2] = _faces[i].tex_s[k + 2];
				
				newFaces[j].tex_t[0] = _faces[i].tex_t[0];
				newFaces[j].tex_t[1] = _faces[i].tex_t[k + 1];
				newFaces[j].tex_t[2] = _faces[i].tex_t[k + 2];
				
				newFaces[j].material = _faces[i].material;
				++j;
			}
		}
	}
	
	free(_faces);
	_faces = newFaces;
	_faceCount = total;
	_hasNonTriangles = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
}


- (void)flipX
{
	// Negate X co-ordinate of each vertex, and each face normal, and also X extremes
	unsigned			i;
	float				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].x *= -1.0;
	}
	for (i = 0; i != _faceCount; ++i)
	{
		_faces[i].normal.x *= -1.0;
	}
	
	temp = _xMax;
	_xMin = -_xMax;
	_xMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
}


- (void)flipY
{
	// Negate Y co-ordinate of each vertex, and each face normal, and also Y extremes
	unsigned			i;
	float				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].y *= -1.0;
	}
	for (i = 0; i != _faceCount; ++i)
	{
		_faces[i].normal.y *= -1.0;
	}
	
	temp = _yMax;
	_yMin = -_yMax;
	_yMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
}


- (void)flipZ
{
	// Negate Z co-ordinate of each vertex, and each face normal, and also Z extremes
	unsigned			i;
	float				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].z *= -1.0;
	}
	for (i = 0; i != _faceCount; ++i)
	{
		_faces[i].normal.z *= -1.0;
	}
	
	temp = _zMax;
	_zMin = -_zMax;
	_zMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
}


- (void)recenter
{
	unsigned			i;
	Vector				v, centre;
	float				r = 0, magSq;
	
	// Average all the vertices together
	for (i = 0; i != _vertexCount; ++i)
	{
		centre += _vertices[i];
	}
	centre /= _vertexCount;
	
	// Shift all the vertices over, and recalculate extremes
	_rMax = 0;
	_xMin = INFINITY; _xMax = -INFINITY;
	_yMin = INFINITY; _yMax = -INFINITY;
	_zMin = INFINITY; _zMax = -INFINITY;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		v = _vertices[i] - centre;
		_vertices[i] = v;
		
		magSq = v.SquareMagnitude();
		
		if (magSq < _xMin) _xMin = magSq;
		if (_xMax < magSq) _xMax = magSq;
		if (magSq < _yMin) _yMin = magSq;
		if (_yMax < magSq) _yMax = magSq;
		if (magSq < _zMin) _zMin = magSq;
		if (_zMax < magSq) _zMax = magSq;
		
		r = v.SquareMagnitude();
		if (_rMax < r) _rMax = r;
	}
	
	_xMin = sqrt(_xMin); _xMax = sqrt(_xMax);
	_yMin = sqrt(_yMin); _yMax = sqrt(_yMax);
	_zMin = sqrt(_zMin); _zMax = sqrt(_zMax);
	_rMax = sqrt(_rMax);
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{\"%@\", %u vertices, %u faces}", [self className], self, _name ?: @"", _vertexCount, _faceCount];
}


- (float)length
{
	return _zMax - _zMin;
}


- (float)width
{
	return _xMax - _xMin;
}


- (float)height
{
	return _yMax - _yMin;
}


- (float)maxR
{
	return _rMax;
}


- (BOOL)hasNonTriangles
{
	return _hasNonTriangles;
}


- (unsigned)vertexCount
{
	return _vertexCount;
}


- (unsigned)faceCount
{
	return _faceCount;
}


- (NSString *)name
{
	return _name;
}

@end
