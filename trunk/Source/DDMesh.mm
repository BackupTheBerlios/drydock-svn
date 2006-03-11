/*
	DDMesh.mm
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
#import "DDMaterial.h"
#import "BS-HOM.h"
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"
#import "DDNormalSet.h"
#import "DDUtilities.h"
#import "DDFaceVertexBuffer.h"


NSString *kNotificationDDMeshModified = @"de.berlios.drydock DDMeshModified";

@interface DDMesh (Private)

- (id)initAsCopyOf:(DDMesh *)inMesh;

@end


@implementation DDMesh


- (id)initAsCopyOf:(DDMesh *)inMesh
{
	TraceEnter();
	
	BOOL				OK = YES;
	Vector				*vertices = NULL;
	Vector				*normals = NULL;
	DDMeshFaceData		*faces = NULL;
	DDMaterial			**materials = NULL;
	Vector2				*texCoords = NULL;
	DDMeshIndex			*faceVertexIndices = NULL;
	DDMeshIndex			*faceTexCoordIndices = NULL;
	unsigned			i, materialCount;
	id					*keys, *values;
	NSArray				*keyArray;
	id					key;
	NSZone				*zone;
	size_t				vertsSize, facesSize, normalsSize, materialsSize, texCoordsSize, indexBufferSize;
	
	self = [super init];
	if (nil == self) OK = NO;
	
	zone = [self zone];
	
	if (OK)
	{
		vertsSize = sizeof (Vector) * inMesh->_vertexCount;
		normalsSize = sizeof (Vector) * inMesh->_normalCount;
		facesSize = sizeof (DDMeshFaceData) * inMesh->_faceCount;
		materialsSize = sizeof (DDMaterial *) * inMesh->_materialCount;
		texCoordsSize = sizeof (Vector2) * inMesh->_texCoordCount;
		indexBufferSize = sizeof (DDMeshIndex) * inMesh->_faceVertexIndexCount;
		
		vertices = (Vector *)malloc(vertsSize);
		normals = (Vector *)malloc(normalsSize);
		faces = (DDMeshFaceData *)malloc(facesSize);
		materials = (DDMaterial **)malloc(materialsSize);
		texCoords = (Vector2 *)malloc(texCoordsSize);
		faceVertexIndices = (DDMeshIndex *)malloc(indexBufferSize);
		faceTexCoordIndices = (DDMeshIndex *)malloc(indexBufferSize);
		
		OK = NULL != vertices && NULL != normals && NULL != faces && NULL != materials &&
				NULL != texCoords && NULL != faceVertexIndices && NULL != faceTexCoordIndices;
	}
	
	if (OK)
	{
		// Copy materials
		for (i = 0; i != inMesh->_materialCount; ++i)
		{
			materials[i] = [inMesh->_materials[i] copyWithZone:zone];
		}
	}
	
	if (OK)
	{
		bcopy(inMesh->_vertices, vertices, vertsSize);
		bcopy(inMesh->_normals, normals, normalsSize);
		bcopy(inMesh->_faces, faces, facesSize);
		bcopy(inMesh->_texCoords, texCoords, texCoordsSize);
		bcopy(inMesh->_texCoords, texCoords, texCoordsSize);
		bcopy(inMesh->_faceVertexIndices, faceVertexIndices, indexBufferSize);
		bcopy(inMesh->_faceTexCoordIndices, faceTexCoordIndices, indexBufferSize);
		
		_vertices = vertices;
		_normals = normals;
		_faces = faces;
		_materials = materials;
		_texCoords = texCoords;
		_faceVertexIndices = faceVertexIndices;
		_faceTexCoordIndices = faceTexCoordIndices;
		
		_vertexCount = inMesh->_vertexCount;
		_normalCount = inMesh->_normalCount;
		_faceCount = inMesh->_faceCount;
		_materialCount = inMesh->_materialCount;
		_texCoordCount = inMesh->_texCoordCount;
		_faceVertexIndexCount = inMesh->_faceVertexIndexCount;
		
		_xMin = inMesh->_xMin;
		_xMax = inMesh->_xMax;
		_yMin = inMesh->_yMin;
		_yMax = inMesh->_yMax;
		_zMin = inMesh->_zMin;
		_zMax = inMesh->_zMax;
		_rMax = inMesh->_rMax;
		
		_hasNonTriangles = inMesh->_hasNonTriangles;
		_name = [inMesh->_name copyWithZone:zone];
	}
	
	if (!OK)
	{
		if (vertices) free(vertices);
		_vertices = NULL;
		if (normals) free(normals);
		_normals = NULL;
		if (faces) free(faces);
		_faces = NULL;
		if (materials) free(materials);
		_materials = NULL;
		if (texCoords) free(texCoords);
		_texCoords = NULL;
		
		[self release];
		self = nil;
	}
	
	return self;
	TraceExit();
}


- (void)dealloc
{
	TraceEnter();
	
	if (NULL != _vertices) free(_vertices);
	if (NULL != _normals) free(_normals);
	if (NULL != _faces) free(_faces);
	if (NULL != _texCoords) free(_texCoords);
	if (NULL != _materials)
	{
		for (int i = 0; i != _materialCount; ++i)
		{
			[_materials[i] release];
		}
	}
	[_name release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:kNotificationDDMeshModified object:self];
	
	[super dealloc];
	TraceExit();
}


- (id)copyWithZone:(NSZone *)inZone
{
	DDMesh					*copy;
	
	copy = [[[self class] allocWithZone:inZone] initAsCopyOf:self];
	return copy;
}


- (void)recalculateNormals
{
	TraceEnter();
	
	// Calculate new normal for each face.
	unsigned				i;
	DDMeshFaceData			*face;
	Vector					v0, v1, v2,
							a, b,
							n;
	DDNormalSet				*normals;
	unsigned				vertIdx;
	
	/*
		Calculation is as follows:
		Given a polygon with S sides, verts[0]..vers[S - 1], find three adjacent vertices. (v0, v1, v2)
		Subtract the outer of these from the central one to get vectors along two adjacent edges. (a, b)
		Take cross product and normalise. (n)
	*/
	
	free(_normals);
	normals = [DDNormalSet setWithCapacity:_faceCount];
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		vertIdx = face->firstVertex;
		v0 = _vertices[_faceVertexIndices[vertIdx]];
		v1 = _vertices[_faceVertexIndices[vertIdx + 1]];
		v2 = _vertices[_faceVertexIndices[vertIdx + face->vertexCount - 1]];
		
		a = v1 - v0;
		b = v2 - v0;
		
		n = (a % b);
		
		face->normal = [normals indexForVector:n];
		
		++face;
	}
	[normals getArray:&_normals andCount:&_normalCount];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)reverseWinding
{
	TraceEnter();
	
	// Reverse winding direction by changing the order of vertices in each face.
	unsigned				i, faceVerts, count;
	DDMeshFaceData			*face;
	unsigned				hiVIdx, loVIdx;
	DDMeshIndex				temp;
	
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		faceVerts = face->vertexCount;
		count = faceVerts >> 1;
		
		loVIdx = face->firstVertex;
		hiVIdx = loVIdx + faceVerts - 1;
		
		do
		{
			temp = _faceVertexIndices[loVIdx];
			_faceVertexIndices[loVIdx] = _faceVertexIndices[hiVIdx];
			_faceVertexIndices[hiVIdx] = temp;
			
			temp = _faceTexCoordIndices[loVIdx];
			_faceTexCoordIndices[loVIdx] = _faceTexCoordIndices[hiVIdx];
			_faceTexCoordIndices[hiVIdx] = temp;
			
			++loVIdx;
			--hiVIdx;
		} while (--count);
		
		++face;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)triangulate
{
	TraceEnter();
	
	unsigned				i, j, k, count, total, subCount;
	DDMeshFaceData			*newFaces;
	DDMeshIndex				verts[3], texCoords[3];
	unsigned				vertIdx;
	DDFaceVertexBuffer		*buffer;
	
	// Count the number of triangles we’ll end up with
	count = _faceCount;
	total = 0;
	for (i = 0; i != count; ++i)
	{
		assert(3 <= _faces[i].vertexCount);
		total += _faces[i].vertexCount - 2;
	}
	
	buffer = [[DDFaceVertexBuffer alloc] initForFaceCount:total];
	newFaces = (DDMeshFaceData *)malloc(sizeof(DDMeshFaceData) * total);
	if (nil == buffer || NULL == newFaces)
	{
		[buffer release];
		if (newFaces) free(newFaces);
		return;
	}
	
	j = 0;
	for (i = 0; i != count; ++i)
	{
		// Convert face into triangle fan
		subCount = _faces[i].vertexCount - 2;
		vertIdx = _faces[i].firstVertex;
		
		for (k = 0; k != subCount; ++k)
		{
			newFaces[j].normal = _faces[i].normal;
			newFaces[j].vertexCount = 3;
			
			verts[0] = _faceVertexIndices[vertIdx];
			verts[1] = _faceVertexIndices[vertIdx + k + 1];
			verts[2] = _faceVertexIndices[vertIdx + k + 2];
			
			texCoords[0] = _faceTexCoordIndices[vertIdx];
			texCoords[1] = _faceTexCoordIndices[vertIdx + k + 1];
			texCoords[2] = _faceTexCoordIndices[vertIdx + k + 2];
			
			newFaces[j].firstVertex = [buffer addVertexIndices:verts texCoordIndices:texCoords count:3];
			newFaces[j].material = _faces[i].material;
			++j;
		}
	}
	
	free(_faces);
	free(_faceVertexIndices);
	free(_faceTexCoordIndices);
	
	_faces = newFaces;
	_faceCount = total;
	[buffer getVertexIndices:&_faceVertexIndices textureCoordIndices:&_faceTexCoordIndices andCount:&_faceVertexIndexCount];
	
	_hasNonTriangles = NO;
	_hasBadPolygons = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)flipX
{
	TraceEnter();
	
	// Negate X co-ordinate of each vertex, and each face normal, and also X extremes
	unsigned			i;
	Scalar				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].x *= -1.0;
	}
	for (i = 0; i != _normalCount; ++i)
	{
		_normals[i].x *= -1.0;
	}
	
	temp = _xMax;
	_xMin = -_xMax;
	_xMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)flipY
{
	TraceEnter();
	
	// Negate Y co-ordinate of each vertex, and each face normal, and also Y extremes
	unsigned			i;
	Scalar				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].y *= -1.0;
	}
	for (i = 0; i != _normalCount; ++i)
	{
		_normals[i].y *= -1.0;
	}
	
	temp = _yMax;
	_yMin = -_yMax;
	_yMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)flipZ
{
	TraceEnter();
	
	// Negate Z co-ordinate of each vertex, and each face normal, and also Z extremes
	unsigned			i;
	Scalar				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].z *= -1.0;
	}
	for (i = 0; i != _normalCount; ++i)
	{
		_normals[i].z *= -1.0;
	}
	
	temp = _zMax;
	_zMin = -_zMax;
	_zMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)recenter
{
	TraceEnter();
	
	unsigned			i;
	Vector				v, centre(0, 0, 0);
	Scalar				r;
	
	// Average all the vertices together
	for (i = 0; i != _vertexCount; ++i)
	{
		centre += _vertices[i];
	}
	centre /= _vertexCount;
	
	// Shift all the vertices over, and recalculate rMax
	_rMax = 0;
	_xMin -= centre.x; _xMax -= centre.x;
	_yMin -= centre.y; _yMax -= centre.y;
	_zMin -= centre.z; _zMax -= centre.z;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		v = _vertices[i] - centre;
		_vertices[i] = v;
		
		r = v.SquareMagnitude();
		if (_rMax < r) _rMax = r;
	}
	
	_rMax = sqrt(_rMax);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)scaleX:(Scalar)inX y:(Scalar)inY z:(Scalar)inZ
{
	TraceEnter();
	
	unsigned			i;
	Scalar				r;
	
	if (1.0f == inX && 1.0f == inY && 1.0f == inZ) return;
	
	_rMax = 0;
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].x *= inX;
		_vertices[i].y *= inY;
		_vertices[i].z *= inZ;
		
		r = _vertices[i].SquareMagnitude();
		if (_rMax < r) _rMax = r;
	}
	
	_rMax = sqrt(_rMax);
	
	_xMin *= inX;
	_xMax *= inX;
	_yMin *= inY;
	_yMax *= inY;
	_zMin *= inZ;
	_zMax *= inZ;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDMeshModified object:self];
	
	TraceExit();
}


- (void)findBadPolygonsWithIssues:(DDProblemReportManager *)ioManager
{
	unsigned				i, count;
	
	// These values will be regenerated.
	_hasNonTriangles = NO;
	_hasBadPolygons = NO;
	
	count = _faceCount;
	for (i = 0; i != count; ++i)
	{
		if (3 != _faces[i].vertexCount)
		{
			_hasNonTriangles = YES;
			
			// TODO: test coplanarity.
		}
	}
}


- (Scalar)length
{
	return _zMax - _zMin;
}


- (Scalar)width
{
	return _xMax - _xMin;
}


- (Scalar)height
{
	return _yMax - _yMin;
}


- (Scalar)maxR
{
	return _rMax;
}


- (BOOL)hasNonTriangles
{
	return _hasNonTriangles;
}


- (BOOL)hasBadPolygons
{
	return _hasBadPolygons;
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


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{\"%@\", %u vertices, %u normals, %u faces}", [self className], self, _name ?: @"", _vertexCount, _normalCount, _faceCount];
}

@end
