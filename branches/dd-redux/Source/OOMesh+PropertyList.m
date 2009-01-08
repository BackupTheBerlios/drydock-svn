//
//  OOMesh+PropertyList.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-07.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOMesh+PropertyList.h"
#import "OOCollectionExtractors.h"


#define kModelDataKeyFormatTag			@"format tag"
#define kModelDataKeyFormatTagValue		@"org.oolite.drydock.oomesh-plist"
#define kModelDataKeyFormatVersion		@"format version"
#define kModelDataKeyFormatVersionValue	1
#define kModelDataKeyIndices			@"index deltas"
#define kModelDataKeyVertices			@"vertices"
#define kModelDataKeyNormals			@"normals"
#define kModelDataKeyTangents			@"tangents"
#define kModelDataKeyTextureCoordinates	@"texture coordinates"
#define kModelDataKeyMaterialOffsets	@"material offsets"
#define kModelDataKeyMaterialCounts		@"material counts"
#define kModelDataKeyMaterialKeys		@"material keys"


static NSArray *PListFromIndexArray(OOMeshData *data);
static NSArray *PListFromVectorArray(GLuint count, Vector *array);
static NSArray *PListFromFloatArray(GLuint count, GLfloat *array);
static NSArray *PListFromIntegerArray(GLuint count, GLuint *array);


@implementation OOMesh (PropertyList)

- (id) propertyListRepresentation
{
	return PropertyListFromOOMeshData(&_meshData);
}

@end


id PropertyListFromOOMeshData(OOMeshData *data)
{
	if (data == NULL)  return nil;
	
	NSNumber *formatVersion = [NSNumber numberWithUnsignedInt:kModelDataKeyFormatVersionValue];
	NSArray *indexArray = PListFromIndexArray(data);
	NSArray *vertexArray = PListFromVectorArray(data->elementCount, data->vertexArray);
	NSArray *normalArray = PListFromVectorArray(data->elementCount, data->normalArray);
	NSArray *tangentArray = PListFromVectorArray(data->elementCount, data->tangentArray);
	NSArray *textureUVArray = PListFromFloatArray(data->elementCount * 2, data->textureUVArray);
	NSArray *materialIndexOffsets = PListFromIntegerArray(data->materialCount, data->materialIndexOffsets);
	NSArray *materialIndexCounts = PListFromIntegerArray(data->materialCount, data->materialIndexCounts);
	
	if (formatVersion == nil ||
		indexArray == nil ||
		vertexArray == nil ||
		normalArray == nil ||
		tangentArray == nil ||
		textureUVArray == nil ||
		materialIndexOffsets == nil ||
		materialIndexCounts == nil ||
		data->materialKeys == nil)
	{
		return nil;
	}
	
	return $dict(kModelDataKeyFormatTag, kModelDataKeyFormatTagValue,
				 kModelDataKeyFormatVersion, formatVersion,
				 kModelDataKeyIndices, indexArray,
				 kModelDataKeyVertices, vertexArray,
				 kModelDataKeyNormals, normalArray,
				 kModelDataKeyTangents, tangentArray,
				 kModelDataKeyTextureCoordinates, textureUVArray,
				 kModelDataKeyMaterialOffsets, materialIndexOffsets,
				 kModelDataKeyMaterialCounts, materialIndexCounts,
				 kModelDataKeyMaterialKeys, data->materialKeys);
}


static NSArray *PListFromIndexArray(OOMeshData *data)
{
	GLuint i;
	
	if (data == NULL)  return nil;
	if (data->indexCount == 0)  return [NSArray array];
	if (OOMeshDataIndexSize(data->indexType) == 0)  return nil;
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:data->indexCount];
	
	GLuint element, last = 0;
	for (i = 0; i < data->indexCount; i++)
	{
		if (!OOMeshDataGetElementIndex(data, i, &element))  return nil;
		// Store deltas to improve compressibility (a delta of 1 is common).
		[result addInteger:(NSInteger)element - (NSInteger)last];
		last = element;
	}
	
	return [[result copy] autorelease];
}


static NSArray *PListFromVectorArray(GLuint count, Vector *array)
{
	GLuint i;
	
	if (array == NULL)  return nil;
	if (count == 0)  return [NSArray array];
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	
	for (i = 0; i != count; ++i)
	{
		[result addObject:OOPropertyListFromVector(array[i])];
	}
	
	return [[result copy] autorelease];
}


static NSArray *PListFromFloatArray(GLuint count, GLfloat *array)
{
	GLuint i;
	
	if (array == NULL)  return nil;
	if (count == 0)  return [NSArray array];
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	
	for (i = 0; i != count; ++i)
	{
		[result addObject:[NSNumber numberWithFloat:array[i]]];
	}
	
	return [[result copy] autorelease];
}


static NSArray *PListFromIntegerArray(GLuint count, GLuint *array)
{
	GLuint i;
	
	if (array == NULL)  return nil;
	if (count == 0)  return [NSArray array];
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	
	for (i = 0; i != count; ++i)
	{
		[result addObject:[NSNumber numberWithUnsignedInt:array[i]]];
	}
	
	return [[result copy] autorelease];
}
