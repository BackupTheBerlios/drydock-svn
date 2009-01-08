//
//  OOMesh+Wireframe.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-04.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOMesh+Wireframe.h"
#import "GLUtilities.h"


@implementation OOMesh (Wireframe)

- (void) renderWireframe
{
	glPushAttrib(GL_POLYGON_BIT | GL_TEXTURE_BIT | GL_CURRENT_BIT | GL_ENABLE_BIT);
	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_LIGHTING);
	
	glColor3f(0.4f, 0.4f, 0.0f);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3, GL_FLOAT, 0, _meshData.vertexArray);
	
	size_t size = 0;
	switch (_meshData.indexType)
	{
		case GL_UNSIGNED_BYTE:
			size = sizeof (GLubyte);
			break;
		case GL_UNSIGNED_SHORT:
			size = sizeof (GLushort);
			break;
		case GL_UNSIGNED_INT:
			size = sizeof (GLuint);
			break;
			
		default:
			if (!_brokenInRender)
			{
				OOLog(@"mesh.meshData.badFormat", @"Data for %@ has invalid indexType (%u).", self, _meshData.indexType);
				_brokenInRender = YES;
			}
	}
	if (!_brokenInRender)
	{
		for (NSUInteger i = 0; i < _meshData.materialCount; i++)
		{
			char *start = (char *)_meshData.indexArray;
			start += size * _meshData.materialIndexOffsets[i];
			NSUInteger count = _meshData.materialIndexCounts[i];
			
			glDrawElements(GL_TRIANGLES, count, _meshData.indexType, start);
		}
	}
	
	glColor3f(1.0f, 1.0f, 0.2f);
	glDrawArrays(GL_POINTS, 0, _meshData.elementCount);
	
	glPopAttrib();
}


- (void) renderNormals
{
	glPushAttrib(GL_TEXTURE_BIT | GL_CURRENT_BIT | GL_ENABLE_BIT);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_LIGHTING);
	
	GLuint i;
	float scale = [self collisionRadius] / 25.0f;
	glColor3f(0.0f, 0.6f, 0.6f);
	
	// Draw normals.
	glBegin(GL_LINES);
	for (i = 0; i != _meshData.elementCount; i++)
	{
		Vector start = _meshData.vertexArray[i];
		Vector end = start + _meshData.normalArray[i] * scale;
		
		start.glVertex();
		end.glVertex();
	}
	glEnd();
	
	scale /= 3.0f;
	glColor3f(0.0f, 0.5f, 0.0f);
	
	// Draw tangents.
	glBegin(GL_LINES);
	for (i = 0; i != _meshData.elementCount; i++)
	{
		Vector start = _meshData.vertexArray[i];
		Vector end = start + _meshData.tangentArray[i] * scale;
		
		start.glVertex();
		end.glVertex();
	}
	glEnd();
	
	glPopAttrib();
}

@end
