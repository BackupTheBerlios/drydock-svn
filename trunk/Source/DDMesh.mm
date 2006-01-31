/*
	DDMesh.mm
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
#import "BS-HOM.h"
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"


#define LOG_MATERIAL_ATTRIBUTES		0


enum {
	kWarningSupressThreshold	= 5
};


typedef struct
{
	Scalar					u, v;
} UV;


NSString *kNotificationOoliteMeshModified = @"com.is-a-geek.ahruman.drydock kNotificationOoliteMeshModified";

static NSColor *ObjColorToNSColor(NSString *inColor);
static Vector ObjVertexToVector(NSString *inVertex);
static UV ObjUVToUV(NSString *inUV);
static NSArray *ObjFaceToArrayOfArrays(NSString *inData);
static DDMaterial *ObjLookUpMaterial(NSString *inName, NSDictionary *inDefs, NSMutableDictionary *ioLibrary, NSURL *inBaseURL, DDProblemReportManager *ioIssues);


@interface DDMesh (Private)

- (id)initAsCopyOf:(DDMesh *)inMesh;
- (NSMutableArray *)objTokenize:(NSURL *)inFile error:(NSError **)outError;
- (NSDictionary *)loadObjMaterialLibraryNamed:(NSString *)inString relativeTo:(NSURL *)inBase issues:(DDProblemReportManager *)ioIssues;

@end


@implementation DDMesh

- (id)initWithOoliteTextBasedMesh:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	BOOL					OK = YES;
	NSString				*dataString;
	NSMutableArray			*lines;
	NSArray					*parts;
	NSString				*line;
	unsigned				i, j, lineCount;
	NSScanner				*scanner = nil;
	int						vertexCount, faceCount;
	Vector					*vertices = NULL;
	DDMeshFaceData			*faces = NULL;
	float					x, y, z;
	int						faceVerts;
	float					xMin = 0, xMax = 0,
							yMin = 0, yMax = 0,
							zMin = 0, zMax = 0,
							rMax = 0, r;
	NSMutableDictionary		*materials;
	NSURL					*texURL;
	NSCharacterSet			*whiteSpaceAndNL, *whiteSpace;
	NSString				*texFileName;
	DDMaterial				*material;
	float					s, t, max_s, max_t;
	NSError					*error;
	
	assert(nil != inFile && nil != ioIssues);
	
	self = [super init];
	if (nil == self) return nil;
	
	dataString = [NSString stringWithContentsOfURL:inFile encoding:NSUTF8StringEncoding error:&error];
	if (nil == dataString) dataString = [NSString stringWithContentsOfURL:inFile usedEncoding:NULL error:&error];
	if (nil == dataString)
	{
		OK = NO;
		[ioIssues addStopIssueWithKey:@"noDataLoaded" localizedFormat:@"No data could be loaded from %@. %@", [inFile displayString], error ? [error localizedFailureReason] : @""];
	}
	
	if (OK)
	{
		lines = [NSMutableArray arrayWithArray:[dataString componentsSeparatedByString:@"\n"]];
		lineCount = [lines count];
		
		// strip out comments and commas between values
		for (i = 0; i != lineCount; ++i)
		{
			line = [lines objectAtIndex:i];
			parts = [line componentsSeparatedByString:@"#"];
			line = [parts objectAtIndex:0];
			parts = [line componentsSeparatedByString:@"//"];
			line = [parts objectAtIndex:0];
			line = [[line componentsSeparatedByString:@","] componentsJoinedByString:@" "];
			
			[lines replaceObjectAtIndex:i withObject:line];
		}
		
		dataString = [lines componentsJoinedByString:@"\n"];
		scanner = [NSScanner scannerWithString:dataString];
	}
	
	// Get number of vertices
	if (OK)
	{
		[scanner setScanLocation:0];
		if (![scanner scanString:@"NVERTS" intoString:NULL]) OK = NO;
		if (![scanner scanInt:&vertexCount]) OK = NO;
		if (!OK) [ioIssues addStopIssueWithKey:@"noDATNVERTS" localizedFormat:@"The required NVERTS line could not be found."];
	}
	
	// Get number of faces
	if (OK)
	{
		if (![scanner scanString:@"NFACES" intoString:NULL]) OK = NO;
		if (![scanner scanInt:&faceCount]) OK = NO;
		if (!OK) [ioIssues addStopIssueWithKey:@"noDATNFACES" localizedFormat:@"The required NFACES line could not be found."];
	}
	
	xMin = INFINITY;
	xMax = -INFINITY;
	yMin = INFINITY;
	yMax = -INFINITY;
	zMin = INFINITY;
	zMax = -INFINITY;
	
	// Load vertices
	if (vertexCount < 3 || 0xFFFF < vertexCount) OK = NO;
	if (OK)
	{
		vertices = (Vector *)malloc(sizeof(Vector) * vertexCount);
		if (NULL == vertices) OK = NO;
		
		if (OK && ![scanner scanString:@"VERTEX" intoString:NULL]) OK = NO;
		if (OK)
		{
			for (i = 0; i != vertexCount; ++i)
			{
				if (![scanner scanFloat:&x] ||
					![scanner scanFloat:&y] ||
					![scanner scanFloat:&z])
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
			}
		}
		if (!OK) [ioIssues addStopIssueWithKey:@"noVertexDataLoaded" localizedFormat:@"Vertex data could not be read for vertex line %u.", i + 1];
	}
	
	// Load faces
	if (faceCount < 1) OK = NO;
	if (OK)
	{
		faces = (DDMeshFaceData *)malloc(sizeof(DDMeshFaceData) * faceCount);
		if (NULL == faces) OK = NO;
		
		if (OK && ![scanner scanString:@"FACES" intoString:NULL]) OK = NO;
		if (OK)
		{
			for (i = 0; i != faceCount; ++i)
			{
				int				r, g, b;
				
				// read colour
				if (![scanner scanInt:&r] ||
					![scanner scanInt:&g] ||
					![scanner scanInt:&b])
				{
					[ioIssues addStopIssueWithKey:@"noColorLoaded" localizedFormat:@"Colour data could not be read for face line %u.", i + 1];
					OK = NO;
					break;
				}
				
				if (r < 0) r = 0;
				if (255 < r) r = 255;
				faces[i].color[0] = r;
				if (g < 0) g = 0;
				if (255 < g) g = 255;
				faces[i].color[1] = g;
				if (b < 0) b = 0;
				if (255 < b) b = 255;
				faces[i].color[2] = b;
				
				// Read normal
				if (![scanner scanFloat:&x] ||
					![scanner scanFloat:&y] ||
					![scanner scanFloat:&z])
				{
					[ioIssues addStopIssueWithKey:@"noNormalLoaded" localizedFormat:@"Normal data could not be read for face line %u.", i + 1];
					OK = NO;
					break;
				}
				
				faces[i].normal.Set(-x, y, z);
				
				// Read vertex count
				if (![scanner scanInt:&faceVerts])
				{
					[ioIssues addStopIssueWithKey:@"noVertexCountLoaded" localizedFormat:@"Vertex count could not be read for face line %u.", i + 1];
					OK = NO;
					break;
				}
				
				if (faceVerts != 3)
				{
					if (faceVerts < 3 || kMaxVertsPerFace < faceVerts)
					{
						[ioIssues addStopIssueWithKey:@"vertexCountRange" localizedFormat:@"Invalid vertex count (%u) for face line %u. Each face must have at least 3 and no more than %u vertices.", vertexCount, i + 1, kMaxVertsPerFace];
						OK = NO;
						break;
					}
					_hasNonTriangles = YES;
				}
				
				faces[i].vertexCount = faceVerts;
				
				for (j = 0; j != faceVerts; ++j)
				{
					int index;
					if (![scanner scanInt:&index])
					{
						[ioIssues addStopIssueWithKey:@"noVertexDataLoaded" localizedFormat:@"Vertex data could not be read for face line %u.", i + 1];
						OK = NO;
						break;
					}
					if (index < 0 || vertexCount <= index)
					{
						[ioIssues addStopIssueWithKey:@"vertexRange" localizedFormat:@"Face line %u specifies a vertex index of %u, but there are only %u vertices in the document.", i + 1, index + 1, vertexCount];
						OK = NO;
						break;
					}
					faces[i].verts[j] = index;
				}
				if (!OK) break;
			}
		}
	}
	
	// Load textures
	if (OK)
	{
		whiteSpaceAndNL = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		whiteSpace = [NSCharacterSet whitespaceCharacterSet];
		
		materials = [NSMutableDictionary dictionary];
		if (nil == materials) OK = NO;
		
		if (OK && ![scanner scanString:@"TEXTURES" intoString:NULL]) OK = NO;
		if (OK)
		{
			for (i = 0; i != faceCount; ++i)
			{
				[scanner scanCharactersFromSet:whiteSpaceAndNL intoString:NULL];
				if (![scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&texFileName])
				{
					[ioIssues addStopIssueWithKey:@"noTextureNameLoaded" localizedFormat:@"Texture name could not be read for face line %u.", i + 1];
					OK = NO;
					break;
				}
				
				material = [materials objectForKey:texFileName];
				if (nil == material)
				{
					material = [DDMaterial materialWithName:texFileName relativeTo:inFile issues:ioIssues];
					if (nil == material)
					{
						OK = NO;
						break;
					}
					[materials setObject:material forKey:texFileName];
				}
				
				faces[i].material = material;
				
				// Read texture scale
				if (![scanner scanFloat:&max_s] ||
					![scanner scanFloat:&max_t])
				{
					[ioIssues addStopIssueWithKey:@"noTextureScaleLoaded" localizedFormat:@"Texture scale could not be read for texture line %u.", i + 1];
					OK = NO;
					break;
				}
				
				// Read s/t co-ordinates for each vertex
				for (j = 0; j != faces[i].vertexCount; ++j)
				{
					if (![scanner scanFloat:&s] ||
						![scanner scanFloat:&t])
					{
						[ioIssues addStopIssueWithKey:@"noUVLoaded" localizedFormat:@"U/V pair could not be read for texture line %u.", i + 1];
						OK = NO;
						break;
					}
					faces[i].tex_s[j] = s / max_s;
					faces[i].tex_t[j] = t / max_t;
				}
				if (!OK) break;
			}
		}
	}
	
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
}


// A pretty good overview of OBJ files is at http://netghost.narod.ru/gff/graphics/summary/waveobj.htm
- (id)initWithOBJ:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	BOOL					OK = YES;
	NSMutableArray			*lines;
	NSArray					*line;
	NSCharacterSet			*spaceSet;
	NSRange					range;
	NSDictionary			*materials = NULL;
	unsigned				vertexCount, uvCount, normalCount, faceCount;
	unsigned				vertexIdx = 0, uvIdx = 0, normalIdx = 0, faceIdx = 0;
	Vector					*vertices = NULL;
	UV						*uv = NULL;
	DDMeshFaceData			*faces = NULL, *face;
	Vector					*normals = NULL;
	NSString				*keyword, *params;
	float					xMin = INFINITY, xMax = -INFINITY,
							yMin = INFINITY, yMax = -INFINITY,
							zMin = INFINITY, zMax = -INFINITY,
							rMax = 0, r;
	Vector					vec;
	NSEnumerator			*lineEnum;
	NSString				*currentMaterial = nil;
	NSArray					*faceData;
	NSArray					*vertexData;
	unsigned				faceVerts, fvIdx;
	NSMutableDictionary		*usedMaterials = nil;
	Vector					normal;
	NSMutableSet			*ignoredTypes = nil;
	NSError					*error;
	BOOL					warnedAboutNoNormals = NO;
	unsigned				badUVWarnings = 0;
	unsigned				badNormalWarnings = 0;
	NSAutoreleasePool		*pool = nil;
	
	self = [super init];
	if (nil == self) return nil;
	
	usedMaterials = [NSMutableDictionary dictionary];
	
	lines = [self objTokenize:inFile error:&error];
	if (!lines)
	{
		[ioIssues addStopIssueWithKey:@"noDataLoaded" localizedFormat:@"No data could be loaded from %@. %@", [inFile displayString], error ? [error localizedFailureReason] : @""];
		OK = NO;
	}
	
	if (OK)
	{
		// Count various line types
		[[lines countTo:&vertexCount] firstObjectEquals:@"v"];
		[[lines countTo:&uvCount] firstObjectEquals:@"vt"];
		[[lines countTo:&normalCount] firstObjectEquals:@"vn"];
		[[lines countTo:&faceCount] firstObjectEquals:@"f"];
		
	//	LogMessage(@"Counts: v=%u, vt=%u, vn=%u, f=%u", vertexCount, uvCount, normalCount, faceCount);
		
		vertices = (Vector *)malloc(sizeof(Vector) * vertexCount);
		uv = (UV *)malloc(sizeof(UV) * uvCount);
		normals = (Vector *)malloc(sizeof(Vector) * normalCount);
		faces = (DDMeshFaceData *)malloc(sizeof(DDMeshFaceData) * faceCount);
		
		if (!(vertices && uv && normals && faces))
		{
			OK = NO;
			if (vertices) { free(vertices); vertices = NULL; };
			if (uv) { free(uv); uv = NULL; };
			if (normals) { free(normals); normals = NULL; };
			if (faces) { free(faces); faces = NULL; };
			
			if (!OK) [ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This may be due to a memory shortage or a faulty input file."];
		}
	}
	
	if (OK)
	{
		lineEnum = [lines objectEnumerator];
		pool = [[NSAutoreleasePool alloc] init];
		
		while ((line = [lineEnum nextObject]))
		{
			keyword = [line objectAtIndex:0];
			params = [line objectAtIndex:1];
			
			if ([keyword isEqual:@"mtllib"])
			{
				// Material Library
				if (nil == materials)
				{
					materials = [[self loadObjMaterialLibraryNamed:params relativeTo:inFile issues:ioIssues] retain];
				}
				else
				{
					[ioIssues addNoteIssueWithKey:@"multipleMaterialLibraries" localizedFormat:@"The document contains multiple material library references. Currently, only one material library is supported. Ignoring reference to material library \"%@\".", params];
				}
			}
			else if ([keyword isEqual:@"v"])
			{
				// Vertex
				assert(vertexIdx < vertexCount);
				
				vec = ObjVertexToVector(params);
				vertices[vertexIdx++] = vec;
				
				// Maintain bounds
				if (vec.x < xMin) xMin = vec.x;
				if (xMax < vec.x) xMax = vec.x;
				if (vec.y < yMin) yMin = vec.y;
				if (yMax < vec.y) yMax = vec.y;
				if (vec.z < zMin) zMin = vec.z;
				if (zMax < vec.z) zMax = vec.z;
				
				r = vec.Magnitude();
				if (rMax < r) rMax = r;
				//LogMessage(@"Vertex: %@", vec.Description());
			}
			else if ([keyword isEqual:@"vt"])
			{
				// Vertex Texture (UV map)
				assert(uvIdx < uvCount);
				
				uv[uvIdx] = ObjUVToUV(params);
				//LogMessage(@"UV: {%g, %g}", uv[uvIdx].u, uv[uvIdx].v);
				++uvIdx;
			}
			else if ([keyword isEqual:@"vn"])
			{
				// Vertex Normal
				assert(normalIdx < normalCount);
				
				vec = ObjVertexToVector(params);
				//vec = ObjVertexToVector(params).Direction();
				normals[normalIdx++] = vec;
				//LogMessage(@"Normal: %@", vec.Description());
			}
			else if ([keyword isEqual:@"f"])
			{
				// Face
				assert(faceIdx < faceCount);
				
				BOOL			warnedUVThisLine = NO, warnedNormalThisLine = NO;
				
				normal.Set(0);
				faceData = ObjFaceToArrayOfArrays(params);
				faceVerts = [faceData count];
				if (3 <= faceVerts)
				{
					if (kMaxVertsPerFace < faceVerts)
					{
						OK = NO;
						[ioIssues addStopIssueWithKey:@"vertexCountRange" localizedFormat:@"Invalid vertex count (%u) for face line %u. Each face must have at least 3 and no more than %u vertices.", faceVerts, faceIdx + 1, kMaxVertsPerFace];
					}
					if (OK)
					{
						if (3 < faceVerts) _hasNonTriangles = YES;
						face = &faces[faceIdx++];
						
						face->vertexCount = faceVerts;
						face->material = ObjLookUpMaterial(currentMaterial, materials, usedMaterials, inFile, ioIssues);
						
						for (fvIdx = 0; fvIdx != faceVerts; ++fvIdx)
						{
							int				intVal, index;
							Vector			v, vn;
							UV				vt;
							NSArray			*elements;
							id				objVal;
							unsigned		elemCount;
							
							elements = [faceData objectAtIndex:fvIdx];
							elemCount = [elements count];
							
							if (0 == elemCount)
							{
								[ioIssues addStopIssueWithKey:@"noVertexDataRead" localizedFormat:@"Vertex data could not be read for face line %u.", faceIdx];
								OK = NO;
							}
							
							// Read vertex index
							if (OK)
							{
								objVal = [elements objectAtIndex:0];
								if (nil == objVal)
								{
									[ioIssues addStopIssueWithKey:@"noVertexDataRead" localizedFormat:@"Vertex data could not be read for face line %u.", faceIdx];
									OK = NO;
								}
							}
							if (OK)
							{
								intVal = [objVal intValue];
								if (0 == intVal)
								{
									[ioIssues addStopIssueWithKey:@"invalidVertexIndex" localizedFormat:@"Face line %u specifies an invalid vertex index %@.", faceIdx, objVal];
									OK = NO;
								}
							}
							if (OK)
							{
								if (intVal < 0) index = vertexIdx + intVal;
								else index = intVal - 1;
								if (vertexIdx <= index || index < 0)
								{
									[ioIssues addStopIssueWithKey:@"vertexRange" localizedFormat:@"Face line %u specifies a vertex index of %i, but there are only %u vertices in the document.", faceIdx, intVal, vertexIdx];
									OK = NO;
								}
								face->verts[fvIdx] = index;
							}
							
							// Read U/V index
							if (OK && 2 <= elemCount)
							{
								objVal = [elements objectAtIndex:1];
								if (nil == objVal || [@"" isEqual:objVal]) OK = NO;
								
								if (OK)
								{
									intVal = [objVal intValue];
									if (0 == intVal)
									{
										if (!warnedUVThisLine)
										{
											warnedUVThisLine = YES;
											if (badUVWarnings < kWarningSupressThreshold)
											{
												++badUVWarnings;
												[ioIssues addWarningIssueWithKey:@"invalidUVIndex" localizedFormat:@"Face line %u specifies an invalid U/V index %@.", faceIdx, objVal];
											}
											else if (badUVWarnings == kWarningSupressThreshold)
											{
												++badUVWarnings;
												[ioIssues addNoteIssueWithKey:@"UVSuppress" localizedFormat:@"Supressing further warnings about U/V indices."];
											}
										}
										OK = NO;
									}
								}
								if (OK)
								{
									if (intVal < 0) index = uvIdx + intVal;
									else index = intVal - 1;
									if (uvIdx <= index || index < 0)
									{
										if (!warnedUVThisLine)
										{
											warnedUVThisLine = YES;
											if (badUVWarnings < kWarningSupressThreshold)
											{
												++badUVWarnings;
												[ioIssues addWarningIssueWithKey:@"UVIndex" localizedFormat:@"Face line %u specifies a U/V index of %i, but there are only %u U/V pairs in the document.", faceIdx, intVal, vertexIdx];
											}
											else if (badUVWarnings == kWarningSupressThreshold)
											{
												++badUVWarnings;
												[ioIssues addNoteIssueWithKey:@"UVSuppress" localizedFormat:@"Supressing further warnings about U/V indices."];
											}
										}
										OK = NO;
									}
								}
								
								if (OK)
								{
									face->tex_s[fvIdx] = uv[index].u;
									face->tex_t[fvIdx] = 1.0 - uv[index].v;
								}
								else
								{
									face->tex_s[fvIdx] = 0.0;
									face->tex_t[fvIdx] = 0.0;
									OK = YES;	// Lack of U/V index is non-fatal
								}
							}
							
							// Read normal index
							if (OK && 3 <= elemCount)
							{
								objVal = [elements objectAtIndex:2];
								if (nil == objVal || [@"" isEqual:objVal]) OK = NO;
								
								if (OK)
								{
									intVal = [objVal intValue];
									if (0 == intVal)
									{
										if (!warnedNormalThisLine)
										{
											warnedNormalThisLine = YES;
											if (badNormalWarnings < kWarningSupressThreshold)
											{
												++badNormalWarnings;
												[ioIssues addWarningIssueWithKey:@"invalidNormalIndex" localizedFormat:@"Face line %u specifies an invalid normal index %@.", faceIdx, objVal];
											}
											else if (badNormalWarnings == kWarningSupressThreshold)
											{
												++badNormalWarnings;
												[ioIssues addNoteIssueWithKey:@"normalSuppress" localizedFormat:@"Supressing further warnings about normal indices."];
											}
										}
										OK = NO;
									}
								}
								if (OK)
								{
									if (intVal < 0) index = normalIdx + intVal;
									else index = intVal - 1;
									if (normalIdx <= index || index < 0)
									{
										if (!warnedNormalThisLine)
										{
											warnedNormalThisLine = YES;
											if (badNormalWarnings < kWarningSupressThreshold)
											{
												++badNormalWarnings;
												[ioIssues addWarningIssueWithKey:@"normalIndexRange" localizedFormat:@"Face line %u specifies a normal index of %i, but there are only %u normals in the document.", faceIdx, intVal, vertexIdx];
											}
											else if (badNormalWarnings == kWarningSupressThreshold)
											{
												++badNormalWarnings;
												[ioIssues addNoteIssueWithKey:@"normalSuppress" localizedFormat:@"Supressing further warnings about normal indices."];
											}
										}
										OK = NO;
									}
								}
								
								if (OK)
								{
									normal += normals[index];
								}
								else
								{
									OK = YES;	// Lack of U/V index is non-fatal
								}
							}
						}
						
						if (!warnedAboutNoNormals && Vector(0, 0, 0) == normal)
						{
							warnedAboutNoNormals = YES;
							[ioIssues addWarningIssueWithKey:@"invalidNormal" localizedFormat:@"Some or all faces in the document lack a valid normal specified. This is likely to lead to lighting problems. This issue can be rectified by selecting Recalculate Normals from the Tools menu."];
						}
						face->normal = normal.Direction();
					}
				}
				
				//LogMessage(@"Face: %@", params);
			}
			else if ([keyword isEqual:@"usemtl"])
			{
				// Use Material
				[currentMaterial release];
				currentMaterial = [params retain];
				//LogMessage(@"Using material: \"%@\"", currentMaterial);
			}
			else if ([keyword isEqual:@"o"])
			{
				// Object name
				if (nil == _name) _name = [params retain];
				//LogMessage(@"Object name: \"%@\"", _name);
			}
			else if ([keyword isEqual:@"g"])
			{
				// Group Name; ignore
				//LogMessage(@"Ignoring group: \"%@\"", params);
			}
			else
			{
				if (![ignoredTypes containsObject:keyword])
				{
					if (nil == ignoredTypes) ignoredTypes = [[NSMutableSet alloc] init];
					[ignoredTypes addObject:keyword];
					
					NSString		*key, *desc;
					key = [NSString stringWithFormat:@"OBJ_LINE %@", keyword];
					desc = NSLocalizedString(key, NULL);
					if ([desc isEqual:key])
					{
						[ioIssues addNoteIssueWithKey:@"unknownOBJLineType" localizedFormat:@"The document contains lines of unknown type \"%@\", which will be ignored.", keyword];
					}
					else
					{
						[ioIssues addNoteIssueWithKey:@"ignoredOBJLineType" localizedFormat:@"The document contains lines of type \"%@\" (%@), which will be ignored.", keyword, desc];
					}
				}
			}
			
			[pool release];
			pool = nil;
			if (!OK) break;
		}
	}
	[materials autorelease];
	[currentMaterial release];
	[ignoredTypes release];
	
	free(uv);
	free(normals);
	
	if (OK)
	{
		_vertexCount = vertexIdx;
		_vertices = vertices;
		
		_faceCount = faceIdx;
		_faces = faces;
		
		_xMin = xMin;
		_xMax = xMax;
		_yMin = yMin;
		_yMax = yMax;
		_zMin = zMin;
		_zMax = zMax;
		_rMax = rMax;
		
		_materials = [usedMaterials retain];
	}
	else
	{
		free(vertices);
		free(faces);
		
		[self release];
		self = nil;
	}
	
	return self;
}


- (id)initAsCopyOf:(DDMesh *)inMesh
{
	BOOL				OK = YES;
	Vector				*vertices = NULL;
	DDMeshFaceData		*faces = NULL;
	NSDictionary		*materials = nil;
	NSDictionary		*materialsByURL = nil;
	unsigned			i, materialCount;
	id					*keys, *values;
	NSArray				*keyArray;
	id					key;
	NSZone				*zone;
	size_t				vertsSize, facesSize;
	
	self = [super init];
	if (nil == self) OK = NO;
	
	zone = [self zone];
	
	if (OK)
	{
		vertsSize = sizeof(Vector) * inMesh->_vertexCount;
		facesSize = sizeof(DDMeshFaceData) * inMesh->_faceCount;
		
		vertices = (Vector *)malloc(vertsSize);
		faces = (DDMeshFaceData *)malloc(facesSize);
		
		OK = nil != vertices && nil != faces;
	}
	
	if (OK)
	{
		// Copy materials
		materialCount = [inMesh->_materials count];
		if (0 != materialCount)
		{
			keys = (id *)alloca(materialCount * sizeof(id));
			values = (id *)alloca(materialCount * sizeof(id));
			keyArray = [inMesh->_materials allKeys];
			
			for (i = 0; i != materialCount; ++i)
			{
				key = [keyArray objectAtIndex:i];
				keys[i] = [key copy];
				values[i] = [[inMesh->_materials objectForKey:key] copy];
			}
			@try
			{
				materials = [NSDictionary dictionaryWithObjects:values forKeys:keys count:materialCount];
			}
			@catch (id whatever) {}
			if (nil == materials) OK = NO;
			
			if (OK)
			{
				// Create material-URL-to-material mapping
				for (i = 0; i != materialCount; ++i)
				{
					[keys[i] release];
					key = [values[i] diffuseMapURL];
					if (nil == key) key = [NSNull null];
					keys[i] = [key copy];
				}
				@try
				{
					materialsByURL = [NSDictionary dictionaryWithObjects:values forKeys:keys count:materialCount];
				}
				@catch (id whatever) {}
				if (nil == materialsByURL) OK = NO;
			}
			
			for (i = 0; i != materialCount; ++i)
			{
				[keys[i] release];
				[values[i] release];
			}
		}
	}
	
	if (OK)
	{
		bcopy(inMesh->_vertices, vertices, vertsSize);
		bcopy(inMesh->_faces, faces, facesSize);
		
		_vertexCount = inMesh->_vertexCount;
		_faceCount = inMesh->_faceCount;
		_xMin = inMesh->_xMin;
		_xMax = inMesh->_xMax;
		_yMin = inMesh->_yMin;
		_yMax = inMesh->_yMax;
		_zMin = inMesh->_zMin;
		_zMax = inMesh->_zMax;
		_rMax = inMesh->_rMax;
		_hasNonTriangles = inMesh->_hasNonTriangles;
		_name = [inMesh->_name copyWithZone:zone];
		
		// Go over faces, replacing material references
		for (i = 0; i != _faceCount; ++i)
		{
			key = [faces[i].material diffuseMapURL];
			if (nil == key) key = [NSNull null];
			faces[i].material = [materialsByURL objectForKey:key];
		}
	}
	
	if (OK)
	{
		_vertices = vertices;
		_faces = faces;
		_materials = [materials retain];
	}
	
	if (!OK)
	{
		if (vertices) free(vertices);
		if (faces) free(faces);
		[self release];
		self = nil;
	}
	
	return self;
}


- (void)dealloc
{
	if (NULL != _vertices) free(_vertices);
	if (NULL != _faces) free(_faces);
	[_materials release];
	[_name release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:kNotificationOoliteMeshModified object:self];
	
	[super dealloc];
}


- (id)copyWithZone:(NSZone *)inZone
{
	DDMesh					*copy;
	
	copy = [[[self class] allocWithZone:inZone] initAsCopyOf:self];
	return copy;
}


- (NSMutableArray *)objTokenize:(NSURL *)inFile error:(NSError **)outError
{
	BOOL					OK = YES;
	NSString				*dataString, *line;
	NSMutableArray			*lines;
	unsigned				lineCount, i;
	NSCharacterSet			*spaceSet;
	NSRange					range;
	NSArray					*lineTokens;
	
	if (NULL != outError) *outError = nil;
	
	dataString = [NSString stringWithContentsOfURL:inFile encoding:NSUTF8StringEncoding error:outError];
	if (nil == dataString) dataString = [NSString stringWithContentsOfURL:inFile usedEncoding:NULL error:outError];
	if (nil == dataString)
	{
		OK = NO;
	}
	
	if (OK)
	{
		lines = (id)[dataString componentsSeparatedByString:@"\r"];
		dataString = [lines componentsJoinedByString:@"\n"];
		lines = [[dataString componentsSeparatedByString:@"\n"] mutableCopy];
		lineCount = [lines count];
		spaceSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
		
		LogIndent();
		// Split into arrays of {keyword, params}
		for (i = 0; i < lineCount; )
		{
			line = [lines objectAtIndex:i];
			
			if (0 == [line length] || '#' == [line characterAtIndex:0])
			{
				// Comment or blank line; ignore
				[lines removeObjectAtIndex:i];
				-- lineCount;
				continue;
			}
			
			range = [line rangeOfCharacterFromSet:spaceSet];
			if (NSNotFound != range.location)
			{
				lineTokens = [NSArray arrayWithObjects:
								[line substringToIndex:range.location],
								[[line substringFromIndex:range.location + 1] stringByTrimmingCharactersInSet:spaceSet],
								nil];
			}
			else
			{
				lineTokens = [NSArray arrayWithObjects: line, @"", nil];
			}
			
			[lines replaceObjectAtIndex:i++ withObject:lineTokens];
		}
		LogOutdent();
	}
	
	if (!OK) lines = nil;
	return lines;
}


- (NSDictionary *)loadObjMaterialLibraryNamed:(NSString *)inString relativeTo:(NSURL *)inBase issues:(DDProblemReportManager *)ioIssues
{
	BOOL					OK = YES;
	NSURL					*url;
	NSMutableArray			*lines;
	unsigned				lineCount, i = 0;
	NSArray					*line;
	NSString				*keyword, *params;
	NSMutableDictionary		*result = nil;
	NSMutableDictionary		*current;
	NSColor					*color;
	NSString				*currentName;
	NSError					*error;
	
	url = [NSURL URLWithString:[inString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:inBase];
	lines = [self objTokenize:url error:&error];
	if (nil == lines)
	{
		OK = NO;
		[ioIssues addNoteIssueWithKey:@"noMaterialLibraryLoaded" localizedFormat:@"No material library could be loaded from %@. %@", inString, error ? [error localizedFailureReason] : @""];
	}
	
	if (OK)
	{
		result = [NSMutableDictionary dictionary];
		lineCount = [lines count];
		
		// Scan for first "newmtl" line. It should be the first line.
		while (i < lineCount)
		{
			line = [lines objectAtIndex:i++];
			keyword = [line objectAtIndex:0];
			params = [line objectAtIndex:1];
			if ([keyword isEqual:@"newmtl"]) break;
		}
		
		// Iterate over materials
		while (i < lineCount)
		{
			LogIndent();
			current = [NSMutableDictionary dictionary];
			[current setObject:params forKey:@"material name"];
			currentName = params;
			
			// Iterate over material attributes
			while (i < lineCount)
			{
				line = [lines objectAtIndex:i++];
				keyword = [line objectAtIndex:0];
				params = [line objectAtIndex:1];
				
				if ([keyword isEqual:@"newmtl"]) break;
				else if ([keyword isEqual:@"map_Kd"])
				{
					#if LOG_MATERIAL_ATTRIBUTES
						LogMessage(@"Diffuse map: %@", params);
					#endif
					[current setObject:params forKey:@"diffuse map name"];
				}
				// The following attributes are currently ignored
				#if LOG_MATERIAL_ATTRIBUTES
				else if ([keyword isEqual:@"Ka"])
				{
					LogMessage(@"Ambient colour: %@", params);
					color = ObjColorToNSColor(params);
					if (nil != color) [current setObject:color forKey:@"ambient color"];
					else LogMessage(@"  Unreadable.");
				}
				else if ([keyword isEqual:@"Kd"])
				{
					LogMessage(@"Diffuse colour: %@", params);
					color = ObjColorToNSColor(params);
					if (nil != color) [current setObject:color forKey:@"diffuse color"];
					else LogMessage(@"  Unreadable.");
				}
				else if ([keyword isEqual:@"Ke"])
				{
					LogMessage(@"Emissive colour: %@", params);
					color = ObjColorToNSColor(params);
					if (nil != color) [current setObject:color forKey:@"emissive color"];
					else LogMessage(@"  Unreadable.");
				}
				else if ([keyword isEqual:@"Ks"])
				{
					LogMessage(@"Specular colour: %@", params);
					color = ObjColorToNSColor(params);
					if (nil != color) [current setObject:color forKey:@"Specular color"];
					else LogMessage(@"  Unreadable.");
				}
				else if ([keyword isEqual:@"Ns"])
				{
					LogMessage(@"Specular exponent: %@", params);
					[current setObject:[NSNumber numberWithFloat:[params floatValue]] forKey:@"Specular exponent"];
				}
				else if ([keyword isEqual:@"d"])
				{
					LogMessage(@"Dissolve factor: %@", params);
					[current setObject:[NSNumber numberWithFloat:[params floatValue]] forKey:@"dissolve factor"];
				}
				else if ([keyword isEqual:@"illum"])
				{
					LogMessage(@"Illumination mode: %@", params);
					[current setObject:[NSNumber numberWithInt:[params intValue]] forKey:@"illumination mode"];
				}
				else if ([keyword isEqual:@"map_Ka"])
				{
					LogMessage(@"Ambient map: %@", params);
					[current setObject:params forKey:@"ambient map name"];
				}
				else if ([keyword isEqual:@"map_Ks"])
				{
					LogMessage(@"Specular map: %@", params);
					[current setObject:params forKey:@"specular map name"];
				}
				else if ([keyword isEqual:@"map_Bump"])
				{
					LogMessage(@"Bump map: %@", params);
					[current setObject:params forKey:@"bump map name"];
				}
				else if ([keyword isEqual:@"map_d"])
				{
					LogMessage(@"Alpha map: %@", params);
					[current setObject:params forKey:@"alpha map name"];
				}
				else
				{
					LogMessage(@"Ignoring attribute %@=%@", keyword, params);
				}
				#endif
			}
			[result setObject:current forKey:currentName];
			LogOutdent();
		}
	}
	
	return result;
}


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingOoliteTextBasedMeshToURL:(NSURL *)inFile
{
	NSEnumerator			*materialEnum;
	DDMaterial				*material;
	NSString				*name;
	NSCharacterSet			*whiteSpace, *miscChars;
	
	if (_hasNonTriangles)
	{
		[ioManager addWarningIssueWithKey:@"nonTriangularFaces" localizedFormat:@"This document contains non-triangular faces. In order to save it in the selected format, Dry Dock will triangulate it."];
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


- (BOOL)writeOoliteTextBasedMeshToURL:(NSURL *)inFile error:(NSError **)outError
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
	
	if (NULL != outError) *outError = nil;
	
	if (_hasNonTriangles) [self triangulate];
	
	dataString = [NSMutableString string];
	
	// Get formatted date string for header comment
	formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];	// ISO date format
	dateString = [formatter stringFromDate:[NSDate date]];
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
	[dataString appendFormat:  @"//	Written by Dry Dock on %@\n"
								"//	\n"
								"//	Model dimensions: %g x %g x %g (w x h x l)\n"
								"//	Textures used: %@\n"
								"\n",
								dateString,
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
		OK = [dataString writeToURL:inFile atomically:YES encoding:NSUTF8StringEncoding error:outError];
	}
	
	if (!OK)
	{
		if (NULL != outError) *outError = error;
	}
	return OK;
}


- (void)glRenderWireframe
{
	WFModeContext			wfmc;
	unsigned				i, j;
	DDMeshFaceData		*face;
	
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
	DDMeshFaceData		*face;
	float					white[4] = { 1, 1, 1, 1 };
	DDMaterial				*currentTex = nil;
	
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, white);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white);
	
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		if (face->material != currentTex)
		{
			[face->material makeActive];
			currentTex = face->material;
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
	
	glBindTexture(GL_TEXTURE_2D, 0);
}


- (void)glRenderNormals
{
	WFModeContext			wfmc;
	unsigned				i, j;
	DDMeshFaceData		*face;
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


- (void)recalculateNormals
{
	// Calculate new normal for each face.
	unsigned				i;
	DDMeshFaceData		*face;
	Vector					v0, v1, v2,
							a, b,
							n;
	
	/*
		Calculation is as follows:
		Given a polygon with S sides, verts[0]..vers[S - 1], find three adjacent vertices. (v0, v1, v2)
		Subtract the outer of these from the central one to get vectors along two adjacent edges. (a, b)
		Take cross product and normalise. (n)
	*/
	
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		v0 = _vertices[face->verts[0]];
		v1 = _vertices[face->verts[1]];
		v2 = _vertices[face->verts[face->vertexCount - 1]];
		
		a = v1 - v0;
		b = v2 - v0;
		
		n = (a % b);
		
		face->normal = n.Normalize();
		
		++face;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOoliteMeshModified object:self];
}


- (void)reverseWinding
{
	// Reverse winding direction by changing the order of vertices in each face.
	unsigned				i, j, faceVerts;
	DDMeshFaceData		*face;
	uint16_t				tempVerts[kMaxVertsPerFace];
	float					tempTex_s[kMaxVertsPerFace],
							tempTex_t[kMaxVertsPerFace];
	
	face = _faces;
	for (i = 0; i != _faceCount; ++i)
	{
		faceVerts = face->vertexCount;
		
		// Build reversed list
		for (j = 0; j != faceVerts; ++j)
		{
			tempVerts[j] = face->verts[faceVerts - j - 1];
			tempTex_s[j] = face->tex_s[faceVerts - j - 1];
			tempTex_t[j] = face->tex_t[faceVerts - j - 1];
		}
		
		// Copy reversed list to face
		for (j = 0; j != faceVerts; ++j)
		{
			face->verts[j] = tempVerts[j];
			face->tex_s[j] = tempTex_s[j];
			face->tex_t[j] = tempTex_t[j];
		}
		
		++face;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOoliteMeshModified object:self];
}


- (void)triangulate
{
	unsigned			i, j, k, count, total, subCount;
	DDMeshFaceData		*newFaces;
	
	// Count the number of triangles we’ll end up with
	
	count = _faceCount;
	total = 0;
	for (i = 0; i != count; ++i)
	{
		assert(3 <= _faces[i].vertexCount);
		total += _faces[i].vertexCount - 2;
	}
	
	newFaces = (DDMeshFaceData *)malloc(sizeof(DDMeshFaceData) * total);
	for (i = 0; i != count; ++i)
	{
		if (_faces[i].vertexCount == 3)
		{
			newFaces[j++] = _faces[i];
		}
		else
		{
			// Convert face into triangle fan
			subCount = _faces[i].vertexCount - 2;
			for (k = 0; k != subCount; ++k)
			{
				newFaces[j].normal = _faces[i].normal;
				newFaces[j].color[0] = _faces[i].color[0];
				newFaces[j].color[1] = _faces[i].color[1];
				newFaces[j].color[2] = _faces[i].color[2];
				newFaces[j].vertexCount = 3;
				
				newFaces[j].verts[0] = _faces[i].verts[0];
				newFaces[j].verts[1] = _faces[i].verts[k + 1];
				newFaces[j].verts[2] = _faces[i].verts[k + 2];
				
				newFaces[j].tex_s[0] = _faces[i].tex_s[0];
				newFaces[j].tex_s[1] = _faces[i].tex_s[k + 1];
				newFaces[j].tex_s[2] = _faces[i].tex_s[k + 2];
				
				newFaces[j].tex_t[0] = _faces[i].tex_t[0];
				newFaces[j].tex_t[1] = _faces[i].tex_t[k + 1];
				newFaces[j].tex_t[2] = _faces[i].tex_t[k + 2];
				
				newFaces[j].material = _faces[i].material;
				++j;
			}
		}
	}
	
	free(_faces);
	_faces = newFaces;
	_faceCount = total;
	_hasNonTriangles = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOoliteMeshModified object:self];
}


- (void)flipX
{
	// Negate X co-ordinate of each vertex, and each face normal, and also X extremes
	unsigned			i;
	float				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].x *= -1.0;
	}
	for (i = 0; i != _faceCount; ++i)
	{
		_faces[i].normal.x *= -1.0;
	}
	
	temp = _xMax;
	_xMin = -_xMax;
	_xMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOoliteMeshModified object:self];
}


- (void)flipY
{
	// Negate Y co-ordinate of each vertex, and each face normal, and also Y extremes
	unsigned			i;
	float				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].y *= -1.0;
	}
	for (i = 0; i != _faceCount; ++i)
	{
		_faces[i].normal.y *= -1.0;
	}
	
	temp = _yMax;
	_yMin = -_yMax;
	_yMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOoliteMeshModified object:self];
}


- (void)flipZ
{
	// Negate Z co-ordinate of each vertex, and each face normal, and also Z extremes
	unsigned			i;
	float				temp;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		_vertices[i].z *= -1.0;
	}
	for (i = 0; i != _faceCount; ++i)
	{
		_faces[i].normal.z *= -1.0;
	}
	
	temp = _zMax;
	_zMin = -_zMax;
	_zMax = -temp;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOoliteMeshModified object:self];
}


- (void)recenter
{
	unsigned			i;
	Vector				v, centre;
	float				r = 0, magSq;
	
	// Average all the vertices together
	for (i = 0; i != _vertexCount; ++i)
	{
		centre += _vertices[i];
	}
	centre /= _vertexCount;
	
	// Shift all the vertices over, and recalculate extremes
	_rMax = 0;
	_xMin = INFINITY; _xMax = -INFINITY;
	_yMin = INFINITY; _yMax = -INFINITY;
	_zMin = INFINITY; _zMax = -INFINITY;
	
	for (i = 0; i != _vertexCount; ++i)
	{
		v = _vertices[i] - centre;
		_vertices[i] = v;
		
		magSq = v.SquareMagnitude();
		
		if (magSq < _xMin) _xMin = magSq;
		if (_xMax < magSq) _xMax = magSq;
		if (magSq < _yMin) _yMin = magSq;
		if (_yMax < magSq) _yMax = magSq;
		if (magSq < _zMin) _zMin = magSq;
		if (_zMax < magSq) _zMax = magSq;
		
		r = v.SquareMagnitude();
		if (_rMax < r) _rMax = r;
	}
	
	_xMin = sqrt(_xMin); _xMax = sqrt(_xMax);
	_yMin = sqrt(_yMin); _yMax = sqrt(_yMax);
	_zMin = sqrt(_zMin); _zMax = sqrt(_zMax);
	_rMax = sqrt(_rMax);
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{\"%@\", %u vertices, %u faces}", [self className], self, _name ?: @"", _vertexCount, _faceCount];
}


- (float)length
{
	return _zMax - _zMin;
}


- (float)width
{
	return _xMax - _xMin;
}


- (float)height
{
	return _yMax - _yMin;
}


- (float)maxR
{
	return _rMax;
}


- (BOOL)hasNonTriangles
{
	return _hasNonTriangles;
}


- (unsigned)vertexCount
{
	return _vertexCount;
}


- (unsigned)faceCount
{
	return _faceCount;
}


- (NSString *)name
{
	return _name;
}

@end


static NSColor *ObjColorToNSColor(NSString *inColor)
{
	NSArray				*components;
	float				r, g, b;
	
	components = [inColor componentsSeparatedByString:@" "];
	if (3 != [components count]) return nil;
	
	r = [[components objectAtIndex:0] floatValue];
	g = [[components objectAtIndex:1] floatValue];
	b = [[components objectAtIndex:2] floatValue];
	
	return [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
}


static Vector ObjVertexToVector(NSString *inVertex)
{
	NSArray				*components;
	Vector				result;
	
	components = [inVertex componentsSeparatedByString:@" "];
	if (3 == [components count])
	{
		result.x = [[components objectAtIndex:0] floatValue];
		result.y = [[components objectAtIndex:1] floatValue];
		result.z = [[components objectAtIndex:2] floatValue];
	}
	
	return result;
}


static UV ObjUVToUV(NSString *inUV)
{
	NSArray				*components;
	UV					result = {0, 0};
	
	components = [inUV componentsSeparatedByString:@" "];
	if (2 == [components count])
	{
		result.u = [[components objectAtIndex:0] floatValue];
		result.v = [[components objectAtIndex:1] floatValue];
	}
	
	return result;
}


static NSArray *ObjFaceToArrayOfArrays(NSString *inData)
{
	NSArray				*verts;
	NSMutableArray		*result;
	unsigned			i, vertCount;
	NSString			*vert;
	 
	verts = [inData componentsSeparatedByString:@" "];
	vertCount = [verts count];
	result = [NSMutableArray arrayWithCapacity:vertCount];
	
	for (i = 0; i != vertCount; ++i)
	{
		vert = [verts objectAtIndex:i];
		[result addObject:[vert componentsSeparatedByString:@"/"]];
	}
	
	return result;
}


static DDMaterial *ObjLookUpMaterial(NSString *inName, NSDictionary *inDefs, NSMutableDictionary *ioLibrary, NSURL *inBaseURL, DDProblemReportManager *ioIssues)
{
	DDMaterial			*result;
	NSDictionary		*definition;
	id					key;
	
	key = inName;
	if (nil == key) key = [NSNull null];
	
	result = [ioLibrary objectForKey:key];
	if (nil == result)
	{
		definition = [inDefs objectForKey:key];
		if (nil != definition)
		{
			@try
			{
				result = [DDMaterial materialWithName:[definition objectForKey:@"diffuse map name"] relativeTo:inBaseURL issues:ioIssues];
			}
			@catch (id whatever) {}
		}
		if (nil == result) result = [DDMaterial placeholderMaterialForFileName:inName];
		if (nil != result)
		{
			[result setDisplayName:inName];
			[ioLibrary setObject:result forKey:key];
		}
	}
	
	return result;
}
