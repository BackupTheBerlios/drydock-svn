/*
	DDFaceVertexBuffer.mm
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

#import "DDFaceVertexBuffer.h"
#import "Logging.h"


@implementation DDFaceVertexBuffer

+ (id)bufferForFaceCount:(DDMeshIndex)inCount
{
	return [[[self alloc] initForFaceCount:inCount] autorelease];
}


- (id)initForFaceCount:(DDMeshIndex)inCount
{
	TraceEnter();
	
	self = [super init];
	if (nil != self)
	{
		max = inCount * 31 / 10;	// Estimate 3 vertices per face, plus 10%
		if (max < 100) max = 100;
		vertIndices = (DDMeshIndex *)calloc(sizeof(DDMeshIndex), max);
		texIndices = (DDMeshIndex *)calloc(sizeof(DDMeshIndex), max);
		normIndices = (DDMeshIndex *)calloc(sizeof(DDMeshIndex), max);
		faceCount = inCount;
		
		if (NULL == vertIndices || NULL == texIndices || NULL == normIndices)
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
	TraceExit();
}


- (void)dealloc
{
	TraceEnter();
	
	if (NULL != vertIndices) free(vertIndices);
	if (NULL != texIndices) free(texIndices);
	if (NULL != normIndices) free(normIndices);
	
	[super dealloc];
	TraceExit();
}


- (unsigned)addVertexIndices:(DDMeshIndex *)inVertIndices texCoordIndices:(DDMeshIndex *)inTexIndices vertexNormals:(DDMeshIndex *)inNormalIndices count:(DDMeshIndex)inCount
{
	TraceEnter();
	
	unsigned				result;
	float					ratio;
	DDMeshIndex				*temp;
	
	assert(3 <= inCount);
	assert(NULL != inVertIndices && NULL != inTexIndices);
	
	if (max <= inCount + count)
	{
	//	LogMessage(@"Growing DDFaceVertexBuffer.");
		
		ratio = (float)count / (float)facesSoFar;
		ratio *= 1.1f;
		
		max = (unsigned)(ratio * (float)faceCount);
		assert(inCount + count < max);
		
		// Note: temp is required so the buffers will be released after a grow failure.
		temp = (DDMeshIndex *)realloc(vertIndices, sizeof (DDMeshIndex) * max);
		if (NULL != temp) vertIndices = temp;
		temp = (DDMeshIndex *)realloc(texIndices, sizeof (DDMeshIndex) * max);
		if (NULL != temp) texIndices = temp;
		temp = (DDMeshIndex *)realloc(normIndices, sizeof (DDMeshIndex) * max);
		if (NULL != temp) normIndices = temp;
		if (NULL == vertIndices || NULL == texIndices || NULL == normIndices) [NSException raise:NSMallocException format:@"%s: failed to grow a DDTexCoordSet (out of memory).", __FUNCTION__];
	}
	
	bcopy(inVertIndices, vertIndices + count, sizeof (DDMeshIndex) * inCount);
	bcopy(inTexIndices, texIndices + count, sizeof (DDMeshIndex) * inCount);
	bcopy(inNormalIndices, normIndices + count, sizeof (DDMeshIndex) * inCount);
	
	result = count;
	count += inCount;
	++facesSoFar;
	
	return result;
	TraceExit();
}


- (void)setTexCoordIndices:(DDMeshIndex *)inTexIndices startingAt:(unsigned)inStart count:(DDMeshIndex)inCount
{
	TraceEnter();
	
	if (count < inStart + inCount)
	{
		[NSException raise:NSRangeException format:@"%s: attempt to modify texture co-ordinate range [%u-%u] out of %u.", __PRETTY_FUNCTION__, inStart, inStart + inCount - 1, count];
	}
	assert(NULL != inTexIndices);
	
	bcopy(inTexIndices, texIndices + inStart, sizeof (DDMeshIndex) * inCount);
	
	TraceExit();
}


- (void)getVertexIndices:(DDMeshIndex **)outVertIndices textureCoordIndices:(DDMeshIndex **)outTexIndices vertexNormals:(DDMeshIndex **)outNormalIndices andCount:(unsigned *)outCount
{
	TraceEnter();
	
	if (0 == max)
	{
		[NSException raise:NSGenericException format:@"Attempt to read DDFaceVertexBuffer twice."];
	}
	
	*outVertIndices = (DDMeshIndex *)realloc(vertIndices, count * sizeof(DDMeshIndex));
	if (NULL == *outVertIndices) *outVertIndices = vertIndices;
	vertIndices = NULL;
	*outTexIndices = (DDMeshIndex *)realloc(texIndices, count * sizeof(DDMeshIndex));
	if (NULL == *outTexIndices) *outTexIndices = texIndices;
	texIndices = NULL;
	*outNormalIndices = (DDMeshIndex *)realloc(normIndices, count * sizeof(DDMeshIndex));
	if (NULL == *outNormalIndices) *outNormalIndices = normIndices;
	normIndices = NULL;
	
	*outCount = count;
	count = max = 0;
	
	TraceExit();
}

@end
