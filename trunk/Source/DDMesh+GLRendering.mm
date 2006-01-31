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


@implementation DDMesh (GLRendering)

- (void)glRenderWireframe
{
	WFModeContext			wfmc;
	unsigned				i, j;
	DDMeshFaceData			*face;
	
	EnterWireframeMode(wfmc);
	
	face = _faces;
	glColor3f(0.6f, 0.6f, 0.0f);
	for (i = 0; i != _faceCount; ++i)
	{
		glBegin(GL_LINE_LOOP);
		for (j = 0; j != face->vertexCount; ++j)
		{
			_vertices[face->verts[j]].glDraw();
		}
		glEnd();
		face++;
	}
	
	glColor3f(1.0f, 1.0f, 0.0f);
	glBegin(GL_POINTS);
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].glDraw();
	}
	glEnd();
	
	ExitWireframeMode(wfmc);
}


- (void)glRenderShaded
{
	unsigned				i, j;
	DDMeshFaceData			*face;
	float					white[4] = { 1, 1, 1, 1 };
	DDMaterial				*currentMaterial = nil;
	
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, white);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white);
	
	currentMaterial = _faces[0].material;
	[currentMaterial makeActive];
	
	face = _faces;
	if (_hasNonTriangles)
	{
		// Render with one GL_POLYGON per face
		for (i = 0; i != _faceCount; ++i)
		{
			if (face->material != currentMaterial)
			{
				currentMaterial = face->material;
				[currentMaterial makeActive];
			}
			glBegin(GL_POLYGON);
			face->normal.glNormal();
			for (j = 0; j != face->vertexCount; ++j)
			{
				glTexCoord2f(face->tex_s[j], face->tex_t[j]);
				_vertices[face->verts[j]].glDraw();
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
			if (face->material != currentMaterial)
			{
				glEnd();
				currentMaterial = face->material;
				[currentMaterial makeActive];
				glBegin(GL_TRIANGLES);
			}
			
			face->normal.glNormal();
			
			glTexCoord2f(face->tex_s[0], face->tex_t[0]);
			_vertices[face->verts[0]].glDraw();
			glTexCoord2f(face->tex_s[1], face->tex_t[1]);
			_vertices[face->verts[1]].glDraw();
			glTexCoord2f(face->tex_s[2], face->tex_t[2]);
			_vertices[face->verts[2]].glDraw();
			
			++face;
		}
		glEnd();
	}
	
	glBindTexture(GL_TEXTURE_2D, 0);
}


- (void)glRenderNormals
{
	WFModeContext			wfmc;
	unsigned				i, j;
	DDMeshFaceData			*face;
	Vector					c;
	Scalar					normLength;
	
	EnterWireframeMode(wfmc);
	glColor3f(0, 1, 1);
	normLength = _rMax / 16.0f;
	
	face = _faces;
	glBegin(GL_LINES);
	for (i = 0; i != _faceCount; ++i)
	{
		// Find centre of polygon by averaging vertices
		c.Set(0, 0, 0);
		for (j = 0; j != face->vertexCount; ++j)
		{
			c += _vertices[face->verts[j]];
		}
		c /= face->vertexCount;
		
		// Draw normal
		c.glDraw();
		(c + normLength * face->normal).glDraw();
		
		++face;
	}
	glEnd();
	
	ExitWireframeMode(wfmc);
}

@end
