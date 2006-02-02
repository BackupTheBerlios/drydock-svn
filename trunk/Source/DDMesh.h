/*
	DDMesh.h
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

#import <Cocoa/Cocoa.h>
#import "phystypes.h"

@class DDMaterial;
@class DDProblemReportManager;
@class SceneNode;


enum
{
	kMaxVertsPerFace		= 16	// Hard-coded limit from Oolite
};


typedef struct DDMeshFaceData
{
	Vector					normal;
	GLubyte					color[3],
							vertexCount;
	uint32_t				verts[kMaxVertsPerFace];	// Indices
	float					tex_s[kMaxVertsPerFace],	
							tex_t[kMaxVertsPerFace];
	DDMaterial				*material;					// Not retained here; references kept in mesh
} DDMeshFaceData;


@interface DDMesh: NSObject<NSCopying>
{
	unsigned				_vertexCount;
	Vector					*_vertices;
	
	unsigned				_faceCount;
	DDMeshFaceData			*_faces;
	
	// Axis-aligned bounds
	float					_xMin, _xMax,
							_yMin, _yMax,
							_zMin, _zMax;
	
	// Greatest distance from origin
	float					_rMax;
	
	NSDictionary			*_materials;
	
	NSString				*_name;
	
	BOOL					_hasNonTriangles;
}

- (float)length;
- (float)width;
- (float)height;
- (float)maxR;

- (unsigned)vertexCount;
- (unsigned)faceCount;

- (NSString *)name;

- (void)recalculateNormals;
- (void)reverseWinding;
- (void)triangulate;
- (void)flipX;
- (void)flipY;
- (void)flipZ;
- (void)recenter;

- (BOOL)hasNonTriangles;

@end


@interface DDMesh (OoliteDATSupport)

- (id)initWithOoliteTextBasedMesh:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;

- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingOoliteTextBasedMeshToURL:(NSURL *)inFile;
- (BOOL)writeOoliteTextBasedMeshToURL:(NSURL *)inFile error:(NSError **)outError;

@end


@interface DDMesh (LightwaveOBJSupport)

- (id)initWithOBJ:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;

@end


@interface DDMesh (GLRendering)

- (void)glRenderShaded;
- (void)glRenderWireframe;
- (void)glRenderNormals;

@end


@interface DDMesh (Utilities)

- (SceneNode *)sceneGraphForMesh;

@end


extern NSString *kNotificationDDMeshModified;
