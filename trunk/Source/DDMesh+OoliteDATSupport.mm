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

#define ENABLE_TRACE 1

#import "DDMesh.h"
#import "Logging.h"
#import "DDMaterial.h"
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"
#import "DDUtilities.h"
#import "DDPantherCompatibility.h"
#import "DDDATLexer.h"


// Hard-coded limits from Oolite
enum
{
	kMaxDATVertices			= 320,
	kMaxDATFaces			= 512,
	kMaxDATMaterials		= 8
};


@implementation DDMesh (OoliteDATSupport)

- (id)initWithOoliteDAT:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnterMsg(@"Called for %@", inFile);
	
	BOOL					OK = YES;
	unsigned				i, j, lineCount;
	NSScanner				*scanner = nil;
	unsigned				vertexCount, faceCount;
	Vector					*vertices = NULL;
	DDMeshFaceData			*faces = NULL;
	float					x, y, z;
	unsigned				faceVerts;
	float					xMin = 0, xMax = 0,
							yMin = 0, yMax = 0,
							zMin = 0, zMax = 0,
							rMax = 0, r;
	NSMutableDictionary		*materials = nil;
	NSURL					*texURL;
	NSCharacterSet			*whiteSpaceAndNL, *whiteSpace;
	NSString				*texFileName;
	DDMaterial				*material;
	float					s, t, max_s, max_t;
	NSError					*error;
	DDDATLexer				*lexer;
	NSString				*tokString;
	int						tok;
	BOOL					readTextures;
	
	assert(nil != inFile && nil != ioIssues);
	
	self = [super init];
	if (nil == self) return nil;
	
//	[NSException raise:NSGenericException format:@"This is a long and pointless string. Loooooong. And very very pointless. As pointless as a pointless and long thing. A thing which is long and has no point, other than being long."];
	
	TraceMessage(@"Loading file.");
	_name = [[inFile displayString] retain];
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
		else if (kMaxDATVertices < vertexCount)
		{
			[ioIssues addWarningIssueWithKey:@"tooManyVerticesForOolite" localizedFormat:@"This document has %u vertices. It will not be possible to open it with Oolite, which has a limit of %u vertices.", vertexCount, kMaxDATVertices];
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
		else if (kMaxDATFaces < faceCount)
		{
			[ioIssues addWarningIssueWithKey:@"tooManyFacesForOolite" localizedFormat:@"This document has %u faces. It will not be possible to open it with Oolite, which has a limit of %u faces.", faceCount, kMaxDATFaces];
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
	if (OK) OK = (KOoliteDatToken_VERTEX_SECTION == [lexer nextToken:NULL]);
	if (OK)
	{
		vertices = (Vector *)calloc(sizeof(Vector), vertexCount);
		if (NULL == vertices)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This may be due to a memory shortage or a faulty input file."];
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
			
			x = -x;		// Dunno why, but it does the right thing.
			
			vertices[i].Set(x, y, z);
			
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
	if (OK) OK = (KOoliteDatToken_FACES_SECTION == [lexer nextToken:NULL]);
	if (OK)
	{
		faces = (DDMeshFaceData *)calloc(sizeof(DDMeshFaceData), faceCount);
		if (NULL == faces)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This may be due to a memory shortage or a faulty input file."];
		}
		
		if (OK)
		{
			TraceMessage(@"Reading %u faces.", faceCount);
			for (i = 0; i != faceCount; ++i)
			{
				unsigned		r, g, b;
				
				// read colour
				if (![lexer readInteger:&r] ||
					![lexer readInteger:&g] ||
					![lexer readInteger:&b])
				{
					[ioIssues addStopIssueWithKey:@"noColorLoaded" localizedFormat:@"Colour data could not be read for face line %u.", i + 1];
					TraceMessage(@"** Failed to read colour for face index %u.", i + 1);
					OK = NO;
					break;
				}
				
				if (255 < r) r = 255;
				faces[i].color[0] = r;
				if (255 < g) g = 255;
				faces[i].color[1] = g;
				if (255 < b) b = 255;
				faces[i].color[2] = b;
				
				// Read normal
				if (![lexer readReal:&x] ||
					![lexer readReal:&y] ||
					![lexer readReal:&z])
				{
					[ioIssues addStopIssueWithKey:@"noNormalLoaded" localizedFormat:@"Normal data could not be read for face line %u.", i + 1];
					TraceMessage(@"** Failed to read normal for face index %u.", i + 1);
					OK = NO;
					break;
				}
				
				faces[i].normal.Set(-x, y, z);
				
				// Read vertex count
				if (![lexer readInteger:&faceVerts])
				{
					[ioIssues addStopIssueWithKey:@"noVertexCountLoaded" localizedFormat:@"Vertex count could not be read for face line %u.", i + 1];
					TraceMessage(@"** Failed to read vertex count for face index %u.", i + 1);
					OK = NO;
					break;
				}
				
				if (faceVerts != 3)
				{
					if (faceVerts < 3 || kMaxVertsPerFace < faceVerts)
					{
						[ioIssues addStopIssueWithKey:@"vertexCountRange" localizedFormat:@"Invalid vertex count (%u) for face line %u. Each face must have at least 3 and no more than %u vertices.", vertexCount, i + 1, kMaxVertsPerFace];
						TraceMessage(@"** Vertex count (%u) out of range for face index %u.", faceVerts, i + 1);
						OK = NO;
						break;
					}
					_hasNonTriangles = YES;
				}
				
				faces[i].vertexCount = faceVerts;
				
				for (j = 0; j != faceVerts; ++j)
				{
					unsigned index;
					if (![lexer readInteger:&index])
					{
						[ioIssues addStopIssueWithKey:@"noVertexDataLoaded" localizedFormat:@"Vertex data could not be read for face line %u.", i + 1];
						TraceMessage(@"** Failed to read vertex index %u for face index %u.", j + 1, i + 1);
						OK = NO;
						break;
					}
					if (index < 0 || vertexCount <= index)
					{
						[ioIssues addStopIssueWithKey:@"vertexRange" localizedFormat:@"Face line %u specifies a vertex index of %u, but there are only %u vertices in the document.", i + 1, index + 1, vertexCount];
						TraceMessage(@"** Out-of-range vertex index (%U) for face index %u.", index, i + 1);
						OK = NO;
						break;
					}
					faces[i].verts[j] = index;
				}
				
				if (OK) OK = [lexer passAtLeastOneLineBreak];
				if (!OK) break;
			}
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
			materials = [NSMutableDictionary dictionary];
			if (nil == materials) OK = NO;
			
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
					
					material = [materials objectForKey:texFileName];
					if (nil == material)
					{
						material = [DDMaterial materialWithName:texFileName relativeTo:inFile issues:ioIssues];
						if (nil == material)
						{
							TraceMessage(@"** Failed to create material for face index %u.", i + 1);
							OK = NO;
							break;
						}
						[materials setObject:material forKey:texFileName];
					}
					
					faces[i].material = material;
					
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
						faces[i].tex_s[j] = s / max_s;
						faces[i].tex_t[j] = t / max_t;
					}
					if (OK) OK = [lexer passAtLeastOneLineBreak];
					if (!OK) break;
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
		
		_faceCount = faceCount;
		_faces = faces;
		
		_xMin = xMin;
		_xMax = xMax;
		_yMin = yMin;
		_yMax = yMax;
		_zMin = zMin;
		_zMax = zMax;
		_rMax = rMax;
		
		_materials = [materials retain];
	}
	else
	{
		free(vertices);
		free(faces);
		
		[self release];
		self = nil;
	}
	
	return self;
	TraceExit();
}


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingOoliteDATToURL:(NSURL *)inFile
{
	NSEnumerator			*materialEnum;
	DDMaterial				*material;
	NSString				*name;
	NSCharacterSet			*whiteSpace, *miscChars;
	unsigned				materialCount;
	
	if (_hasNonTriangles)
	{
		[ioManager addWarningIssueWithKey:@"nonTriangularFaces" localizedFormat:@"This document contains non-triangular faces. In order to save it in the selected format, Dry Dock will triangulate it."];
	}
	
	if (kMaxDATVertices < _vertexCount)
	{
		[ioManager addStopIssueWithKey:@"tooManyVertices" localizedFormat:@"This document contains %u vertices; the selected format allows no more than %u.", _vertexCount, kMaxDATVertices];
	}
	if (kMaxDATFaces < _faceCount)
	{
		[ioManager addStopIssueWithKey:@"tooManyFaces" localizedFormat:@"This document contains %u faces; the selected format allows no more than %u.", _faceCount, kMaxDATFaces];
	}
	materialCount = [_materials count];
	if (kMaxDATMaterials < materialCount)
	{
		[ioManager addStopIssueWithKey:@"tooManyMaterials" localizedFormat:@"This document contains %u materials; the selected format allows no more than %u.", materialCount, kMaxDATMaterials];
	}
	
	// Check for invalid texture names
	whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	miscChars = [NSCharacterSet characterSetWithCharactersInString:@",#"];
	for (materialEnum = [_materials objectEnumerator]; material = [materialEnum nextObject]; )
	{
		name = [material keyName];
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
	NSEnumerator			*texEnum;
	NSString				*texKey;
	unsigned				i, j, faceVerts;
	DDMeshFaceData			*face;
	NSString				*texName;
	DDMaterial				*material;
	
	if (_hasNonTriangles) [self triangulate];
	
	dataString = [NSMutableString string];
	
	// Get formatted date string for header comment
	formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];	// ISO date format
	dateString = [formatter stringForObjectValue:[NSDate date]];
	[formatter release];
	
	// Build texture list string
	for (texEnum = [_materials objectEnumerator]; material = [texEnum nextObject]; )
	{
		texName = [material keyName];
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
								[self length], [self height], [self length],
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
	for (i = 0; i != _faceCount; ++i)
	{
		face = _faces + i;
		faceVerts = face->vertexCount;
		
		[dataString appendFormat:@"\n%u,%u,%u,\t%10f,%10f,%10f,\t%u",
			face->color[0], face->color[1], face->color[2], -face->normal.x, face->normal.y, face->normal.z, faceVerts];
		
		for (j = 0; j != faceVerts; ++j)
		{
			[dataString appendFormat:@",%s%u", j ? "" : "\t", face->verts[j]];
		}
	}
	
	// Write textures
	[dataString appendString:@"\n\nTEXTURES"];
	for (i = 0; i != _faceCount; ++i)
	{
		face = _faces + i;
		faceVerts = face->vertexCount;
		
		// Really ought to build material pointer -> UTF8String CFDictionary
		[dataString appendFormat:@"\n%-16s\t1.0 1.0   ", [[face->material keyName] UTF8String]];
		
		for (j = 0; j != faceVerts; ++j)
		{
			[dataString appendFormat:@" %f %f", face->tex_s[j], face->tex_t[j]];
		}
	}
	[dataString appendString:@"\n\nEND\n"];
	
	// Finish up
	if (OK)
	{
		OK = [dataString writeToURL:inFile atomically:NO encoding:NSUTF8StringEncoding errorCompat:&error];
	}
	
	if (!OK)
	{
		if (nil != error) [ioManager addStopIssueWithKey:@"write_failed" localizedFormat:@"The document could not be saved. %@", [error localizedFailureReasonCompat]];
		else [ioManager addStopIssueWithKey:@"write_failed" localizedFormat:@"The document could not be saved, because an unknown error occured."];
	}
	return OK;
}


@end
