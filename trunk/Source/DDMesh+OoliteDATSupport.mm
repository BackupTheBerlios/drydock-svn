/*
	DDMesh+OoliteDATSupport.mm
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
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"
#import "DDUtilities.h"
#import "DDDATLexer.h"
#import "DDNormalSet.h"
#import "DDMaterialSet.h"
#import "DDTexCoordSet.h"
#import "DDFaceVertexBuffer.h"


// Hard-coded limits from Oolite
enum
{
	// Up to 1.68
	kMaxDATVerticesOld		= 320,
	kMaxDATFacesOld			= 512,
	kMaxDATMaterialsOld		= 7,
	
	// 1.69 and later
	kMaxDATVertices			= 500,
	kMaxDATFaces			= 800,
	kMaxDATMaterials		= 8
};


@implementation DDMesh (OoliteDATSupport)

- (id)initWithOoliteDAT:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnterMsg(@"Called for %@", inFile);
	
	BOOL					OK = YES;
	unsigned				i, j;
	unsigned				vertexCount, faceCount;
	Vector					*vertices = NULL;
	DDMeshFaceData			*faces = NULL;
	float					x, y, z;
	unsigned				faceVertexCount;
	float					xMin = 0, xMax = 0,
							yMin = 0, yMax = 0,
							zMin = 0, zMax = 0,
							rMax = 0, r;
	NSMutableDictionary		*materialDict = nil;
	DDMaterialSet			*materials = nil;
	NSString				*texFileName;
	DDMaterial				*material;
	float					s, t, max_s, max_t;
	DDDATLexer				*lexer;
	NSString				*tokString;
	int						tok;
	BOOL					readTextures = NO;
	DDNormalSet				*normals = nil;
	DDTexCoordSet			*texCoords = NULL;
	DDFaceVertexBuffer		*buffer = nil;
	DDMeshIndex				faceVertices[kMaxVertsPerFace];
	DDMeshIndex				faceTexCoords[kMaxVertsPerFace] = {0};
	DDMeshIndex				faceNormals[kMaxVertsPerFace];
	NSMutableDictionary		*smoothingGroups = nil;
	uint8_t					activeSmoothingGroup = 0;
	uint8_t					smoothingGroupsUsed = 0;
	NSNumber				*smoothingGroupObj, *smoothingGroupIDObj;
	unsigned				smoothingGroupID, lastSmoothingGroupID = 0, g, b;
	
	assert(nil != inFile);
	
	self = [super init];
	if (nil == self) return nil;
	
	TraceMessage(@"Loading file.");
	_name = [inFile displayString];
	if (NSOrderedSame == [[_name substringFromIndex:[_name length] - 4] caseInsensitiveCompare:@".dat"]) _name = [_name substringToIndex:[_name length] - 4];
	[_name retain];
	
	lexer = [[DDDATLexer alloc] initWithURL:inFile issues:ioIssues];
	OK = (nil != lexer);
	[lexer skipLineBreaks];
		
	// Get number of vertices
	if (OK)
	{
		OK = (KOoliteDatToken_NVERTS == [lexer nextToken:NULL]);
		if (OK) OK = [lexer readInteger:&vertexCount] && [lexer passAtLeastOneLineBreak];
		
		if (!OK)
		{
			[ioIssues addStopIssueWithKey:@"noDATNVERTS" localizedFormat:@"The required NVERTS line could not be found."];
			TraceMessage(@"** Failed to find \"NVERTS\".");
		}
		else if (kDDMeshIndexMax < vertexCount)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"vertices", NULL), vertexCount];
		}
		else if (kMaxDATVertices < vertexCount)
		{
			[ioIssues addWarningIssueWithKey:@"tooManyVerticesForOolite" localizedFormat:@"This document has %u %@. It will not be possible to open it with Oolite%@, which has a limit of %u %@.", vertexCount, NSLocalizedString(@"vertices", NULL), @"", kMaxDATVertices, NSLocalizedString(@"vertices", NULL)];
		}
		else if (kMaxDATVerticesOld < vertexCount)
		{
			[ioIssues addWarningIssueWithKey:@"tooManyVerticesForOoliteOld" localizedFormat:@"This document has %u %@. It will not be possible to open it with Oolite%@, which has a limit of %u %@.", vertexCount, NSLocalizedString(@"vertices", NULL), NSLocalizedString(@"1.68 and earlier", NULL), kMaxDATVerticesOld, NSLocalizedString(@"vertices", NULL)];
		}
	}
	
	// Get number of faces
	if (OK)
	{
		OK = (KOoliteDatToken_NFACES == [lexer nextToken:NULL]);
		if (OK) OK = [lexer readInteger:&faceCount] && [lexer passAtLeastOneLineBreak];
		
		if (!OK)
		{
			[ioIssues addStopIssueWithKey:@"noDATNFACES" localizedFormat:@"The required NFACES line could not be found."];
			TraceMessage(@"** Failed to find \"NFACES\".");
		}
		else if (kDDMeshIndexMax < faceCount)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"faces", NULL), faceCount];
		}
		else if (kMaxDATFaces < faceCount)
		{
			[ioIssues addWarningIssueWithKey:@"tooManyFacesForOolite" localizedFormat:@"This document has %u %@. It will not be possible to open it with Oolite%@, which has a limit of %u %@.", faceCount, NSLocalizedString(@"faces", NULL), @"", kMaxDATFaces, NSLocalizedString(@"faces", NULL)];
		}
		else if (kMaxDATFacesOld < faceCount)
		{
			[ioIssues addWarningIssueWithKey:@"tooManyFacesForOoliteOld" localizedFormat:@"This document has %u %@. It will not be possible to open it with Oolite%@, which has a limit of %u %@.", faceCount, NSLocalizedString(@"faces", NULL), NSLocalizedString(@"1.68 and earlier", NULL), kMaxDATFacesOld, NSLocalizedString(@"faces", NULL)];
		}
	}
	
	xMin = INFINITY;
	xMax = -INFINITY;
	yMin = INFINITY;
	yMax = -INFINITY;
	zMin = INFINITY;
	zMax = -INFINITY;
	if (OK && (vertexCount < 3 || faceCount < 1))
	{
		OK = NO;
		[ioIssues addStopIssueWithKey:@"insufficientParts" localizedFormat:@"The document is invalid; Oolite DAT documents must contain at least three vertices and one face."];
	}
	
	// Load vertices
	if (OK)
	{
		OK = (KOoliteDatToken_VERTEX_SECTION == [lexer nextToken:&tokString]);
		if (!OK) [ioIssues addStopIssueWithKey:@"parseError" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber(), @"VERTEX", tokString];
	}
	if (OK)
	{
		vertices = (Vector *)calloc(sizeof(Vector), vertexCount);
		if (NULL == vertices)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
		}
	}
	if (OK)
	{
		TraceMessage(@"Loading %u vertices.", vertexCount);
		for (i = 0; i != vertexCount; ++i)
		{
			if (![lexer readReal:&x] ||
				![lexer readReal:&y] ||
				![lexer readReal:&z])
			{
				OK = NO;
				break;
			}
			
			x = -x;		// Oolite uses a flipped co-ordinate system.
			
			vertices[i].Set(x, y, z).CleanZeros();
			
			// Maintain bounds
			if (x < xMin) xMin = x;
			if (xMax < x) xMax = x;
			if (y < yMin) yMin = y;
			if (yMax < y) yMax = y;
			if (z < zMin) zMin = z;
			if (zMax < z) zMax = z;
			
			r = vertices[i].Magnitude();
			if (rMax < r) rMax = r;
			
			OK = [lexer passAtLeastOneLineBreak];
		}
		if (!OK)
		{
			[ioIssues addStopIssueWithKey:@"noVertexDataLoaded" localizedFormat:@"Vertex data could not be read for vertex line %u.", i + 1];
			TraceMessage(@"** Vertex loading failed at vertex index %u.", i + 1);
		}
	}
	
	// Load faces
	if (OK)
	{
		OK = (KOoliteDatToken_FACES_SECTION == [lexer nextToken:&tokString]);
		if (!OK) [ioIssues addStopIssueWithKey:@"parseError" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber(), @"FACE", tokString];
	}
	if (OK)
	{
		faces = (DDMeshFaceData *)calloc(sizeof(DDMeshFaceData), faceCount);
		normals = [DDNormalSet setWithCapacity:faceCount];
		texCoords = [DDTexCoordSet setWithCapacity:faceCount];
		buffer = [DDFaceVertexBuffer bufferForFaceCount:faceCount];
		
		if (NULL == faces || nil == normals || nil == texCoords || nil == buffer)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
		}
		
		if (OK)
		{
			TraceMessage(@"Reading %u faces.", faceCount);
			for (i = 0; i != faceCount; ++i)
			{
				if (![lexer readInteger:&smoothingGroupID])
				{
					[ioIssues addStopIssueWithKey:@"noSmoothingGroupLoaded" localizedFormat:@"Smoothing group ID could not be read for face line %u.", i + 1];
					TraceMessage(@"** Failed to read smoothing group ID for face index %u.", i + 1);
					OK = NO;
					break;
				}
				
				if (smoothingGroupID != lastSmoothingGroupID || 0 == i)
				{
					// New smoothing group. We map file IDs to an internal range since file values aren’t explicitly clamped to uint8_t range.
					smoothingGroupIDObj = [NSNumber numberWithUnsignedInt:smoothingGroupID];
					smoothingGroupObj = [smoothingGroups objectForKey:smoothingGroupIDObj];
					if (nil != smoothingGroupObj)
					{
						activeSmoothingGroup = [smoothingGroupObj unsignedCharValue];
					}
					else
					{
						// New smoothing group
						if (smoothingGroupsUsed < 255)
						{
							activeSmoothingGroup = ++smoothingGroupsUsed;
							smoothingGroupObj = [NSNumber numberWithUnsignedChar:activeSmoothingGroup];
							if (nil == smoothingGroups) smoothingGroups = [NSMutableDictionary dictionary];
							[smoothingGroups setObject:smoothingGroupObj forKey:smoothingGroupIDObj];
						}
						else
						{
							OK = NO;
							[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u smoothing groups.", 255];
						}
					}
				}
				faces[i].smoothingGroup = activeSmoothingGroup;
				
				// read unused values (formerly face green and blue).
				if (OK && 
					![lexer readInteger:&g] ||
					![lexer readInteger:&b])
				{
					[ioIssues addStopIssueWithKey:@"noReservedFieldsLoaded" localizedFormat:@"Reserved fields could not be read for face line %u.", i + 1];
					TraceMessage(@"** Failed to read reserved fields for face index %u.", i + 1);
					OK = NO;
					break;
				}
				
				// Read normal
				if (OK &&
					![lexer readReal:&x] ||
					![lexer readReal:&y] ||
					![lexer readReal:&z])
				{
					[ioIssues addStopIssueWithKey:@"noNormalLoaded" localizedFormat:@"Normal data could not be read for face line %u.", i + 1];
					TraceMessage(@"** Failed to read normal for face index %u.", i + 1);
					OK = NO;
					break;
				}
				
				faces[i].normal = [normals indexForVector:Vector(-x, y, z)];
				
				// Read vertex count
				if (OK && ![lexer readInteger:&faceVertexCount])
				{
					[ioIssues addStopIssueWithKey:@"noVertexCountLoaded" localizedFormat:@"Vertex count could not be read for face line %u.", i + 1];
					TraceMessage(@"** Failed to read vertex count for face index %u.", i + 1);
					OK = NO;
					break;
				}
				
				if (OK && faceVertexCount != 3)
				{
					if (faceVertexCount < 3 || kMaxVertsPerFace < faceVertexCount)
					{
						[ioIssues addStopIssueWithKey:@"vertexCountRange" localizedFormat:@"Invalid vertex count (%u) for face line %u. Each face must have at least 3 and no more than %u vertices.", vertexCount, i + 1, kMaxVertsPerFace];
						TraceMessage(@"** Vertex count (%u) out of range for face index %u.", faceVertexCount, i + 1);
						OK = NO;
						break;
					}
				}
				
				faces[i].vertexCount = faceVertexCount;
				
				if (OK) for (j = 0; j != faceVertexCount; ++j)
				{
					unsigned index;
					if (![lexer readInteger:&index])
					{
						[ioIssues addStopIssueWithKey:@"noVertexDataLoaded" localizedFormat:@"Vertex data could not be read for face line %u.", i + 1];
						TraceMessage(@"** Failed to read vertex index %u for face index %u.", j + 1, i + 1);
						OK = NO;
						break;
					}
					if (vertexCount <= index)
					{
						[ioIssues addStopIssueWithKey:@"vertexRange" localizedFormat:@"Face line %u specifies a vertex index of %u, but there are only %u vertices in the document.", i + 1, index + 1, vertexCount];
						TraceMessage(@"** Out-of-range vertex index (%U) for face index %u.", index, i + 1);
						OK = NO;
						break;
					}
					faceVertices[j] = index;
					faceNormals[j] = faces[i].normal;
				}
				
				if (OK)
				{
					// Tex co-ords are set to 0 here, and will be filled in later if there’s a TEXTURES section.
					faces[i].firstVertex = [buffer addVertexIndices:faceVertices texCoordIndices:faceTexCoords vertexNormals:faceNormals count:faceVertexCount];
				}
				
				if (OK) OK = [lexer passAtLeastOneLineBreak];
				if (!OK) break;
			}
		}
	}
	
	if (OK && smoothingGroupsUsed < 2)
	{
		// All faces in the same smoothing group is equivalent to no smoothing group.
		for (i = 0; i != faceCount; ++i)
		{
			faces[i].smoothingGroup = 0;
		}
	}
	
	// Load textures
	if (OK)
	{
		readTextures = NO;
		tok = [lexer nextTokenDesc:&tokString];
		if (KOoliteDatToken_EOF == tok)
		{
			[ioIssues addWarningIssueWithKey:@"vertexRange" localizedFormat:@"The document is missing an END line. This is not serious, but should be fixed by resaving the document."];
		}
		else if (KOoliteDatToken_TEXTURES_SECTION == tok)
		{
			readTextures = YES;
		}
		else if (KOoliteDatToken_END_SECTION == tok)
		{
			// Do nothing
		}
		else
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"parseError" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber(), NSLocalizedString(@"TEXTURES or END", NULL), tokString];
		}
		
		if (OK && !readTextures)
		{
			[ioIssues addNoteIssueWithKey:@"noTextures" localizedFormat:@"The document does not specify any textures or u/v co-ordinates."];
		}
		
		if (readTextures)
		{
			materials = [DDMaterialSet setWithCapacity:faceCount];
			materialDict = [NSMutableDictionary dictionaryWithCapacity:faceCount];
			if (nil == materials || nil == materialDict)
			{
				OK = NO;
				[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
			}
			
			if (OK)
			{
				TraceMessage(@"Reading %u texture lines.", faceCount);
				for (i = 0; i != faceCount; ++i)
				{
					if (![lexer readString:&texFileName])
					{
						[ioIssues addStopIssueWithKey:@"noTextureNameLoaded" localizedFormat:@"Texture name could not be read for face line %u.", i + 1];
						TraceMessage(@"** Failed to read texture name for face index %u.", i + 1);
						OK = NO;
						break;
					}
					
					faces[i].material = [materials indexForName:texFileName];
					if (kDDMeshIndexNotFound == faces[i].material)
					{
						material = [DDMaterial materialWithName:texFileName];
						[material setDiffuseMap:texFileName relativeTo:inFile issues:ioIssues];
						if (nil == material)
						{
							TraceMessage(@"** Failed to create material for face index %u.", i + 1);
							OK = NO;
							[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
							break;
						}
						faces[i].material = [materials addMaterial:material];
					}
					
					// Read texture scale
					if (![lexer readReal:&max_s] ||
						![lexer readReal:&max_t])
					{
						[ioIssues addStopIssueWithKey:@"noTextureScaleLoaded" localizedFormat:@"Texture scale could not be read for texture line %u.", i + 1];
						TraceMessage(@"** Failed to read texture scale for face index %u.", i + 1);
						OK = NO;
						break;
					}
					
					// Read s/t co-ordinates for each vertex
					for (j = 0; j != faces[i].vertexCount; ++j)
					{
						if (![lexer readReal:&s] ||
							![lexer readReal:&t])
						{
							[ioIssues addStopIssueWithKey:@"noUVLoaded" localizedFormat:@"U/V pair could not be read for texture line %u.", i + 1];
							TraceMessage(@"** Failed to read u/v pair for vertex %u of face index %u.", j + 1, i + 1);
							OK = NO;
							break;
						}
						faceTexCoords[j] = [texCoords indexForVector:Vector2(s / max_s, t / max_t)];
					}
					if (OK)
					{
						[buffer setTexCoordIndices:faceTexCoords startingAt:faces[i].firstVertex count:faces[i].vertexCount];
						OK = [lexer passAtLeastOneLineBreak];
					}
					if (!OK) break;
				}
			}
			if (OK) [texCoords getArray:&_texCoords andCount:&_texCoordCount];
		}
		else if (OK)
		{
			// Create a dummy material. All the faces will have material index 0 because we calloc()ed the array.
			_materialCount = 1;
			_materials = (DDMaterial **)calloc(sizeof(DDMaterial *), 1);
			if (NULL != _materials) _materials[0] = [[DDMaterial materialWithName:@"$untextured"] retain];
			if (NULL == _materials || nil == _materials[0])
			{
				OK = NO;
				[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
			}
			
			if (OK)
			{
				_texCoordCount = 1;
				_texCoords = (Vector2 *)calloc(sizeof(Vector2), 1);
				if (NULL == _texCoords)
				{
					OK = NO;
					[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
				}
			}
		}
	}
	
	// Look for END
	if (OK && readTextures)
	{
		tok = [lexer nextToken:NULL];
		if (KOoliteDatToken_EOF == tok)
		{
			[ioIssues addWarningIssueWithKey:@"vertexRange" localizedFormat:@"The document is missing an END line. This is not serious, but should be fixed by resaving the document."];
		}
		else if (KOoliteDatToken_END_SECTION == tok)
		{
			// Do nothing
		}
		else
		{
			[ioIssues addWarningIssueWithKey:@"missedData" localizedFormat:@"The document continues beyond where it was expected to end. It may be of a newer format."];
		}
	}
	
	[lexer release];
	
	if (OK)
	{
		_vertexCount = vertexCount;
		_vertices = vertices;
		
		[normals getArray:&_normals andCount:&_normalCount];
		[buffer getVertexIndices:&_faceVertexIndices textureCoordIndices:&_faceTexCoordIndices vertexNormals:&_vertexNormalIndices andCount:&_faceVertexIndexCount];
		
		_faceCount = faceCount;
		_faces = faces;
		
		if (nil != materials) [materials getArray:&_materials andCount:&_materialCount];
		
		_xMin = xMin;
		_xMax = xMax;
		_yMin = yMin;
		_yMax = yMax;
		_zMin = zMin;
		_zMax = zMax;
		_rMax = rMax;
		
		[self findBadPolygonsWithIssues:ioIssues];
	}
	else
	{
		if (NULL != vertices) free(vertices);
		if (NULL != faces) free(faces);
		
		[self release];
		self = nil;
	}
	
	return self;
	TraceExit();
}


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingOoliteDATToURL:(NSURL *)inFile
{
	DDMaterial				*material;
	NSString				*name;
	NSCharacterSet			*whiteSpace, *miscChars;
	int						i;
	
	[self findBadPolygonsWithIssues:ioManager];
	
	if (_hasNonTriangles)
	{
		[ioManager addWarningIssueWithKey:@"nonTriangularFaces" localizedFormat:@"This document contains non-triangular faces. In order to save it in the selected format, Dry Dock will triangulate it."];
	}
	
	if (kMaxDATVertices < _vertexCount)
	{
		[ioManager addStopIssueWithKey:@"tooManyVertices" localizedFormat:@"This document contains %u %@; the selected format allows no more than %u.", _vertexCount, NSLocalizedString(@"vertices", NULL), kMaxDATVertices];
	}
	if (kMaxDATFaces < _faceCount)
	{
		[ioManager addStopIssueWithKey:@"tooManyFaces" localizedFormat:@"This document contains %u %@; the selected format allows no more than %u.", _faceCount, NSLocalizedString(@"faces", NULL), kMaxDATFaces];
	}
	if (kMaxDATMaterials < _materialCount)
	{
		[ioManager addStopIssueWithKey:@"tooManyMaterials" localizedFormat:@"This document contains %u %@; the selected format allows no more than %u.", _materialCount, NSLocalizedString(@"materials", NULL), kMaxDATMaterials];
	}
	
	// Check for invalid texture names
	whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	miscChars = [NSCharacterSet characterSetWithCharactersInString:@",#"];
	for (i = 0; i != _materialCount; ++i)
	{
		material = _materials[i];
		name = [material name];
		if ([name rangeOfCharacterFromSet:whiteSpace].length != 0
			|| [name rangeOfCharacterFromSet:miscChars].length != 0
			|| [name rangeOfString:@"//"].length != 0)
		{
			[ioManager addStopIssueWithKey:@"invalidTextureName" localizedFormat:@"This document contains a texture named \"%@\". The specified format does not support texture names containing spaces, commas, line breaks, \"#\" or \"//\".", name];
		}
	}
}


- (BOOL)writeOoliteDATToURL:(NSURL *)inFile issues:(DDProblemReportManager *)ioManager
{
	BOOL					OK =YES;
	NSError					*error = nil;
	NSMutableString			*dataString;
	NSDateFormatter			*formatter;
	NSString				*dateString;
	NSMutableString			*texNameString = nil;
	unsigned				i, j, faceVertexCount;
	DDMeshFaceData			*face;
	NSString				*texName;
	Vector					normal;
	Vector2					texCoords;
	unsigned				vertIdx;
	
	if (_hasNonTriangles) [self triangulate];
	
	dataString = [NSMutableString string];
	
	// Get formatted date string for header comment
	formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];	// ISO date format
	dateString = [formatter stringForObjectValue:[NSDate date]];
	[formatter release];
	
	// Build texture list string
	for (i = 0; i != _materialCount; ++i)
	{
		texName = [_materials[i] name];
		if (nil != texName)
		{
			if (nil == texNameString) texNameString = [texName mutableCopy];
			else [texNameString appendFormat: @", %@", texName];
		}
	}
	
	if (nil == texNameString) texNameString = @"none";
	
	// Write header comment
	[dataString appendFormat:  @"//	Written by %@ on %@\n"
								"//	\n"
								"//	Model dimensions: %g x %g x %g (w x h x l)\n"
								"//	Textures used: %@\n"
								"\n",
								ApplicationNameAndVersionString(), dateString,
								[self width], [self height], [self length],
								texNameString];
	
	// Write vertex and face counts
	[dataString appendFormat:@"NVERTS %u\nNFACES %u\n\nVERTEX\n", _vertexCount, _faceCount];
	
	// Write vertices
	for (i = 0; i != _vertexCount; ++i)
	{
		[dataString appendFormat:@"%10f,%10f,%10f\n", -_vertices[i].x, _vertices[i].y, _vertices[i].z];
	}
	
	// Write faces
	[dataString appendString:@"\nFACES"];
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		faceVertexCount = face->vertexCount;
		normal = _normals[face->normal];
		
		[dataString appendFormat:@"\n%u,%u,%u,\t%10f,%10f,%10f,\t%u",
			face->smoothingGroup, 0, 0, -normal.x, normal.y, normal.z, faceVertexCount];
		
		for (j = 0; j != faceVertexCount; ++j)
		{
			[dataString appendFormat:@",%s%u", j ? "" : "\t", _faceVertexIndices[face->firstVertex + j]];
		}
		++face;
	}
	
	// Write textures
	[dataString appendString:@"\n\nTEXTURES"];
	for (i = 0; i != _faceCount; ++i)
	{
		face = _faces + i;
		faceVertexCount = face->vertexCount;
		
		// Really ought to build material pointer -> UTF8String CFDictionary
		[dataString appendFormat:@"\n%-16s\t1.0 1.0   ", [[_materials[face->material] diffuseMapName] UTF8String]];
		
		vertIdx = face->firstVertex;
		for (j = 0; j != faceVertexCount; ++j)
		{
			texCoords = _texCoords[_faceTexCoordIndices[vertIdx++]];
			[dataString appendFormat:@" %f %f", texCoords.x, texCoords.y];
		}
	}
	[dataString appendString:@"\n\nEND\n"];
	
	// Finish up
	if (OK)
	{
		OK = [dataString writeToURL:inFile atomically:NO encoding:NSUTF8StringEncoding error:&error];
		if (!OK)
		{
			if (nil != error) [ioManager addStopIssueWithKey:@"writeFailed" localizedFormat:@"The document could not be saved. %@", [error localizedFailureReason]];
			else [ioManager addStopIssueWithKey:@"writeFailed" localizedFormat:@"The document could not be saved, because an unknown error occured."];
		}
	}
	return OK;
}


@end
