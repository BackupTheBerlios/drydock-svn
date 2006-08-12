/*
	DDMesh.h
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

#import <Foundation/Foundation.h>
#import "phystypes.h"
#import "DDPropertyListRepresentation.h"

@class DDMaterial;
@class DDProblemReportManager;
@class SceneNode;


#define USE_SHORT_INDICES		1

#if USE_SHORT_INDICES
	typedef uint_least16_t		DDMeshIndex;
#else
	typedef uint_least32_t		DDMeshIndex;
#endif


enum
{
	#if USE_SHORT_INDICES
		kDDMeshIndexMax			= UINT_LEAST16_MAX - 1,
		kDDMeshIndexNotFound	= UINT_LEAST16_MAX,
	#else
		kDDMeshIndexMax			= UINT_LEAST32_MAX - 1,
		kDDMeshIndexNotFound	= UINT_LEAST32_MAX,
	#endif
	kMaxVertsPerFace			= 16	// Hard-coded limit from Oolite
};


typedef enum
{
	kDDMeshRecenterNone,
	kDDMeshRecenterByAveragingVertices,
	kDDMeshRecenterUsingBoundingBox,
	kDDMeshRecenterMethodCount
} DDMeshRecenterMethod;


typedef struct DDMeshFaceData
{
	DDMeshIndex				normal;
	DDMeshIndex				material;
	unsigned				firstVertex;	// Index into _faceVertexIndices, _faceTexCoordIndices and _vertexNormalIndices
	uint8_t					vertexCount;
	uint8_t					nonCoplanar;
	uint8_t					nonConvex;
	uint8_t					smoothingGroup;
} DDMeshFaceData;


@interface DDMesh: NSObject<NSCopying>
{
	DDMeshIndex				_vertexCount;
	Vector					*_vertices;
	
	DDMeshIndex				_normalCount;
	Vector					*_normals;
	
	DDMeshIndex				_faceCount;
	DDMeshFaceData			*_faces;
	
	DDMeshIndex				_materialCount;
	DDMaterial				**_materials;
	
	DDMeshIndex				_texCoordCount;
	Vector2					*_texCoords;
	
	unsigned				_faceVertexIndexCount;
	DDMeshIndex				*_faceVertexIndices;
	DDMeshIndex				*_faceTexCoordIndices;
	DDMeshIndex				*_vertexNormalIndices;
	
	// Axis-aligned bounds
	Scalar					_xMin, _xMax,
							_yMin, _yMax,
							_zMin, _zMax;
	
	// Greatest distance from origin
	Scalar					_rMax;
	
	NSString				*_name;
	NSURL					*_sourceFile;
	
	BOOL					_hasNonTriangles;
	BOOL					_hasBadPolygons;
}

- (Scalar)length;
- (Scalar)width;
- (Scalar)height;
- (Scalar)maxR;

- (unsigned)vertexCount;
- (unsigned)faceCount;

- (NSString *)name;

- (void)recalculateNormals;
- (void)reverseWinding;
- (void)triangulate;
- (void)flipX;
- (void)flipY;
- (void)flipZ;
- (void)recenterWithMethod:(DDMeshRecenterMethod)inMethod;
- (void)scaleX:(Scalar)inX y:(Scalar)inY z:(Scalar)inZ;
- (void)coalesceVertices;

- (BOOL)hasNonTriangles;
- (BOOL)hasBadPolygons;		// “Bad polygons” are not coplanar or not convex.

// This is mostly used by loaders and manipulators. Returns NO for serious errors.
- (BOOL)findBadPolygonsWithIssues:(DDProblemReportManager *)ioManager;

@end


@interface DDMesh (OoliteDATSupport)

- (id)initWithOoliteDAT:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;

- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingOoliteDATToURL:(NSURL *)inFile;
- (BOOL)writeOoliteDATToURL:(NSURL *)inFile issues:(DDProblemReportManager *)ioManager;

@end


@interface DDMesh (WaveFrontOBJSupport)

- (id)initWithWaveFrontOBJ:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;

- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingWaveFrontOBJToURL:(NSURL *)inFile;
- (BOOL)writeWaveFrontOBJToURL:(NSURL *)inFile finalLocationURL:(NSURL *)inFinalLocation issues:(DDProblemReportManager *)ioManager;

@end


@interface DDMesh (GLRendering)

- (void)glRenderShaded;
- (void)glRenderWireframe;
- (void)glRenderNormals;
- (void)glRenderBadPolygons;
- (void)glRenderBoundingBox;

@end


@interface DDMesh (Utilities)

- (SceneNode *)sceneGraphForMesh;

@end


@interface DDMesh (PropertyListRepresentation) <DDPropertyListRepresentation>

@end


extern NSString *kNotificationDDMeshModified;
