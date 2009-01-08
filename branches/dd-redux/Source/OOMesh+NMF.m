//
//  OOMesh+NMF.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-02.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOMesh+NMF.h"
#import "NmFileIO.h"


@interface OOMesh (NMFInternal)

- (NmRawTriangle *) generateNMFRawTriangles;

@end


@implementation OOMesh (NMF)

- (BOOL) writeNMFToFile:(NSString *)path
{
	FILE *file = fopen(path.fileSystemRepresentation, "wb");
	if (file == NULL)
	{
		// FIXME: error handling
		return NO;
	}
	
	NmRawTriangle *triangles = [self generateNMFRawTriangles];
	if (triangles == NULL)
	{
		// FIXME: error handling
		return NO;
	}
	
	BOOL success = NmWriteTriangles(file, [self faceCount], triangles);
	free(triangles);
	
	if (!success)
	{
		// FIXME: error handling
		return NO;
	}
	
	return YES;
}


- (NmRawTriangle *) generateNMFRawTriangles
{
	NSUInteger i, j, count = [self faceCount];
	
	NmRawTriangle *triangles = malloc(sizeof (NmRawTriangle) * count);
	if (triangles == NULL)  return NULL;
	
	for (i = 0; i < count; ++i)
	{
		for (j = 0; j < 3; ++j)
		{
			NSUInteger element;
			if (EXPECT_NOT(!OOMeshDataGetElementIndex(&_meshData, i * 3 + j, &element)))
			{
				free(triangles);
				return NULL;
			}
			
			triangles[i].vert[j].x = _meshData.vertexArray[element].x;
			triangles[i].vert[j].y = _meshData.vertexArray[element].y;
			triangles[i].vert[j].z = _meshData.vertexArray[element].z;
			triangles[i].norm[j].x = _meshData.normalArray[element].x;
			triangles[i].norm[j].y = _meshData.normalArray[element].y;
			triangles[i].norm[j].z = _meshData.normalArray[element].z;
			triangles[i].texCoord[j].u = _meshData.textureUVArray[element * 2];
			triangles[i].texCoord[j].v = _meshData.textureUVArray[element * 2 + 1];
		}
	}
	
	return triangles;
}

@end
