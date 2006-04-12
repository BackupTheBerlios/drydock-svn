/*
	DDMesh+GLRendering.mm
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
#import "DDMesh.h"
#import "Logging.h"
#import "GLUtilities.h"
#import "DDMaterial.h"
#import "DDPantherCompatibility.h"

#define CGL_MACRO_CACHE_RENDERER
#import <OpenGL/CGLMacro.h>


#define DRAW(vec)		do { Vector v = (vec); glVertex3f(v.x, v.y, v.z); } while (0)
#define NORMAL(vec)		do { Vector v = (vec); glNormal3f(v.x, v.y, v.z); } while (0)
#define TEXCOORDS(vec2)	do { Vector2 v = (vec2); glTexCoord2f(v.x, v.y); } while (0)


@implementation DDMesh (GLRendering)

- (void)glRenderWireframe
{
	WFModeContext			wfmc;
	unsigned				i;
	uint8_t					j;
	DDMeshFaceData			*face;
	unsigned				vertIdx;
	
	CGL_MACRO_DECLARE_VARIABLES();
	
	EnterWireframeMode(wfmc);
	
	glVertexPointer(3, GL_SCALAR, 0, _vertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	face = _faces;
	glColor3f(0.6f, 0.6f, 0.0f);
	for (i = 0; i != _faceCount; ++i)
	{
		glBegin(GL_LINE_LOOP);
		vertIdx = face->firstVertex;
		for (j = 0; j != face->vertexCount; ++j)
		{
			glArrayElement(_faceVertexIndices[vertIdx++]);
		}
		glEnd();
		face++;
	}
	
	glColor3f(1.0f, 1.0f, 0.0f);
	glBegin(GL_POINTS);
	for (i = 0; i != _vertexCount; ++i)
	{
		DRAW(_vertices[i]);
	}
	glEnd();
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glBindTexture(GL_TEXTURE_2D, 0);
	
	ExitWireframeMode(wfmc);
}


- (void)glRenderShaded
{
	unsigned				i, j, matIdx;
	DDMeshFaceData			*face;
	float					white[4] = { 1, 1, 1, 1 };
	DDMaterial				*currentMaterial = nil;
	Vector					*vertex, *normal;
	Vector2					*texCoords;
	unsigned				vertIdx;
	
	CGL_MACRO_DECLARE_VARIABLES();
	
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, white);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white);
	
	matIdx = _faces[0].material;
	currentMaterial = _materials[matIdx];
	[currentMaterial makeActive];
	
	glVertexPointer(3, GL_SCALAR, 0, _vertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	face = _faces;
	if (_hasNonTriangles)
	{
		// Render with one GL_POLYGON per face
		for (i = 0; i != _faceCount; ++i)
		{
			if (face->material != matIdx)
			{
				matIdx = face->material;
				currentMaterial = _materials[matIdx];
				[currentMaterial makeActive];
			}
			glBegin(GL_POLYGON);
			normal = &_normals[face->normal];
			NORMAL(*normal);
			
			vertIdx = face->firstVertex;
			for (j = 0; j != face->vertexCount; ++j)
			{
				TEXCOORDS(_texCoords[_faceTexCoordIndices[vertIdx]]);
				glArrayElement(_faceVertexIndices[vertIdx]);
				++vertIdx;
			}
			glEnd();
			++face;
		}
	}
	else
	{
		// Render with GL_TRIANGLES, starting a new set at each material transition.
		glBegin(GL_TRIANGLES);
		for (i = 0; i != _faceCount; ++i)
		{
			if (face->material != matIdx)
			{
				glEnd();
				matIdx = face->material;
				currentMaterial = _materials[matIdx];
				[currentMaterial makeActive];
				glBegin(GL_TRIANGLES);
			}
			
			normal = &_normals[face->normal];
			NORMAL(*normal);
			
			vertIdx = face->firstVertex;
			
			TEXCOORDS(_texCoords[_faceTexCoordIndices[vertIdx]]);
			glArrayElement(_faceVertexIndices[vertIdx]);
			
			TEXCOORDS(_texCoords[_faceTexCoordIndices[vertIdx + 1]]);
			glArrayElement(_faceVertexIndices[vertIdx + 1]);
			
			TEXCOORDS(_texCoords[_faceTexCoordIndices[vertIdx + 2]]);
			glArrayElement(_faceVertexIndices[vertIdx + 2]);
			
			++face;
		}
		glEnd();
	}
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glBindTexture(GL_TEXTURE_2D, 0);
}


- (void)glRenderNormals
{
	WFModeContext			wfmc;
	unsigned				i, j;
	DDMeshFaceData			*face;
	Vector					c;
	Scalar					normLength;
	unsigned				vertIdx;
	
	CGL_MACRO_DECLARE_VARIABLES();
	
	EnterWireframeMode(wfmc);
	glColor3f(0, 1, 1);
	normLength = _rMax / 16.0f;
	
	face = _faces;
	glBegin(GL_LINES);
	for (i = 0; i != _faceCount; ++i)
	{
		// Find centre of polygon by averaging vertices
		c.Set(0, 0, 0);
		vertIdx = face->firstVertex;
		for (j = 0; j != face->vertexCount; ++j)
		{
			c += _vertices[_faceVertexIndices[vertIdx++]];
		}
		c /= face->vertexCount;
		
		// Draw normal
		DRAW(c);
		DRAW((c + normLength * _normals[face->normal]));
		
		++face;
	}
	glEnd();
	
	ExitWireframeMode(wfmc);
}


- (void)glRenderBadPolygons
{
	uint32_t				count, j, vertIdx;
	DDMeshFaceData			*face;
	WFModeContext			wfmc;
	
	if (!_hasBadPolygons) return;
	
	CGL_MACRO_DECLARE_VARIABLES();
	
	EnterWireframeMode(wfmc);
	glColor3f(1, 0, 0);
	glLineWidth(2);
	
	glVertexPointer(3, GL_SCALAR, 0, _vertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	count = _faceCount;
	face = _faces;
	do
	{
		if (face->nonCoplanar || face->nonConvex)
		{
			glBegin(GL_LINE_LOOP);
			vertIdx = face->firstVertex;
			for (j = 0; j != face->vertexCount; ++j)
			{
				glArrayElement(_faceVertexIndices[vertIdx++]);
			}
			glEnd();
		}
		face++;
	} while (--count);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glLineWidth(1);
	ExitWireframeMode(wfmc);
}

@end
