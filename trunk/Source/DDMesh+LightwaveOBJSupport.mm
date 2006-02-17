/*
	DDMesh+LightwaveOBJSupport.mm
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
#import "DDMaterial.h"
#import "BS-HOM.h"
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"
#import "DDUtilities.h"
#import "DDError.h"


#define LOG_MATERIAL_ATTRIBUTES		0


enum {
	kWarningSupressThreshold	= 5
};


typedef struct
{
	Scalar					u, v;
} UV;

static NSColor *ObjColorToNSColor(NSString *inColor);
static Vector ObjVertexToVector(NSString *inVertex);
static UV ObjUVToUV(NSString *inUV);
static NSArray *ObjFaceToArrayOfArrays(NSString *inData);
static DDMaterial *ObjLookUpMaterial(NSString *inName, NSDictionary *inDefs, NSMutableDictionary *ioLibrary, NSURL *inBaseURL, DDProblemReportManager *ioIssues);


@interface DDMesh (LightwaveOBJSupport_Private)

- (NSMutableArray *)objTokenize:(NSURL *)inFile error:(NSError **)outError;
- (NSDictionary *)loadObjMaterialLibraryNamed:(NSString *)inString relativeTo:(NSURL *)inBase issues:(DDProblemReportManager *)ioIssues;

@end


@implementation DDMesh (LightwaveOBJSupport)


// A pretty good overview of OBJ files is at http://netghost.narod.ru/gff/graphics/summary/waveobj.htm
- (id)initWithLightwaveOBJ:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
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
									index = 0;
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
									index = 0;
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
										index = 0;
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
										index = 0;
										OK = NO;
									}
								}
								
								if (OK)
								{
									face->tex_s[fvIdx] = uv[index].u;
									face->tex_t[fvIdx] = uv[index].v;
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
										index = 0;
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
										index = 0;
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


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingLightwaveOBJToURL:(NSURL *)inFile
{
	// No issues to check for at this time. OBJ is the most expressive format supported.
}


- (BOOL)writeLightwaveOBJToURL:(NSURL *)inFile finalLocationURL:(NSURL *)inFinalLocation issues:(DDProblemReportManager *)ioManager
{
	BOOL					OK = YES;
	NSError					*error = nil;
	NSMutableString			*dataString;
	NSDateFormatter			*formatter;
	NSString				*dateString;
	NSString				*mtlName;
	NSURL					*mtlURL;
	unsigned				i, j, faceVerts, count, ni, ti;
	NSMutableArray			*texCoords;
	NSMutableDictionary		*texCoordsRev;
	NSMutableArray			*normals;
	NSMutableDictionary		*normalsRev;
	UV						uv;
	Vector					normal;
	NSValue					*value;
	NSNumber				*index;
	NSMutableDictionary		*materialToFaceArray;
	NSMutableArray			*facesForMaterial;
	id						materialKey;
	NSEnumerator			*materialEnumerator;
	DDMeshFaceData			*currentFace;
	NSAutoreleasePool		*pool;
	NSArray					*materialNames;
	DDMaterial				*material;
	
	// Build material library name. For "Foo.obj" or "Foo", use "Foo.mtl"; for "Bar.baz", use "Bar.baz.mtl".
	mtlName = [[inFile path] lastPathComponent];
	if ([[mtlName lowercaseString] hasSuffix:@".obj"])
	{
		mtlName = [mtlName substringToIndex:[mtlName length] - 4];
	}
	mtlName = [mtlName stringByAppendingString:@".mtl"];
	
	// Get formatted date string for header comment
	formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];	// ISO date format
	dateString = [formatter stringFromDate:[NSDate date]];
	[formatter release];
	NSString *version = ApplicationNameAndVersionString();
	
	pool = [[NSAutoreleasePool alloc] init];
	
	// Write header comment
	dataString = [NSMutableString string];
	[dataString appendFormat:  @"# Written by %@ on %@\n"
								"# \n"
								"# Model dimensions: %g x %g x %g (w x h x l)\n"
								"# %i vertices, %i faces\n"
								"\n",
								version, dateString,
								[self length], [self height], [self length],
								_vertexCount, _faceCount];
	
	// Write material library and object name
	[dataString appendFormat:@"mtllib %@\no %@\n", mtlName, [self name]];
	
	// Write vertices
	[dataString appendString:@"\n# Vertices:\n"];
	for (i = 0; i != _vertexCount; ++i)
	{
		[dataString appendFormat:@"v %f %f %f\n", _vertices[i].x, _vertices[i].y, _vertices[i].z];
	}
	
	/*	Write texture co-ordinates. To avoid duplicates, we create an NSArray of UV structs in
		NSValues, and a dictionary mapping each such NSValue to an array index (as an NSNumber).
	*/
	texCoords = [[NSMutableArray alloc] init];
	texCoordsRev = [NSMutableDictionary dictionary];
	count = 0;
	for (i = 0; i != _faceCount; ++i)
	{
		faceVerts = _faces[i].vertexCount;
		for (j = 0; j != faceVerts; ++j)
		{
			uv.u = _faces[i].tex_s[j];
			uv.v = _faces[i].tex_t[j];
			value = [[NSValue alloc] initWithBytes:&uv objCType:@encode(UV)];
			
			index = [texCoordsRev objectForKey:value];
			if (NULL == index)
			{
				// Previously unseen u/v pair
				[texCoords addObject:value];
				[texCoordsRev setObject:[NSNumber numberWithInt:count++] forKey:value];
			}
			[value release];
		}
	}
	// Actually write the co-ords
	[dataString appendString:@"\n# Texture co-ordinates:\n"];
	for (i = 0; i != count; ++i)
	{
		value = [texCoords objectAtIndex:i];
		[value getValue:&uv];
		
		[dataString appendFormat:@"vt %f %f\n", uv.u, 1.0 - uv.v];
	}
	[texCoords release];
	texCoords = nil;
	
	// Write normals. Same logic as for texture co-ords, only using a Vector.
	normals = [[NSMutableArray alloc] init];
	normalsRev = [NSMutableDictionary dictionary];
	count = 0;
	for (i = 0; i != _faceCount; ++i)
	{
		faceVerts = _faces[i].vertexCount;
		for (j = 0; j != faceVerts; ++j)
		{
			normal = _faces[i].normal;
			normal.CleanZeros();
			value = [[NSValue alloc] initWithBytes:&normal objCType:@encode(Vector)];
			
			index = [normalsRev objectForKey:value];
			if (NULL == index)
			{
				// Previously unseen u/v pair
				[normals addObject:value];
				[normalsRev setObject:[NSNumber numberWithInt:count++] forKey:value];
			}
			[value release];
		}
	}
	[dataString appendString:@"\n# Normals:\n"];
	// Actually write the co-ords
	for (i = 0; i != count; ++i)
	{
		value = [normals objectAtIndex:i];
		[value getValue:&normal];
		
		[dataString appendFormat:@"vn %f %f %f\n", normal.x, normal.y, normal.z];
	}
	[normals release];
	normals = nil;
	
	/*	Sort faces by texture. Basic approach: create a dictionary keyed by material name, with
		mutable arrays as the values. These arrays are populated with indices into _faces, as
		NSNumbers.
	*/
	materialToFaceArray = [NSMutableDictionary dictionary];
	for (i = 0; i != _faceCount; ++i)
	{
		materialKey = [_faces[i].material displayName];
		if (nil == materialKey) materialKey = [NSNull null];
		facesForMaterial = [materialToFaceArray objectForKey:materialKey];
		if (nil == facesForMaterial)
		{
			facesForMaterial = [NSMutableArray array];
			[materialToFaceArray setObject:facesForMaterial forKey:materialKey];
		}
		[facesForMaterial addObject:[NSNumber numberWithInt:i]];
	}
	
	// Write faces with no texture, if any
	facesForMaterial = [materialToFaceArray objectForKey:[NSNull null]];
	if (nil != facesForMaterial)
	{
		[dataString appendString:@"\n# Untextured faces:\ng untextured"];
		count = [facesForMaterial count];
		for (i = 0; i != count; ++i)
		{
			index = [facesForMaterial objectAtIndex:i];
			currentFace = &_faces[[index intValue]];
			faceVerts = currentFace->vertexCount;
			normal = currentFace->normal;
			normal.CleanZeros();
			value = [[NSValue alloc] initWithBytes:&normal objCType:@encode(Vector)];
			ni = [[normalsRev objectForKey:value] intValue];
			[value release];
			
			[dataString appendString:@"\nf"];
			for (j = 0; j != faceVerts; ++j)
			{
				[dataString appendFormat:@" %i//%i", currentFace->verts[j] + 1, ni + 1];
			}
		}
		[dataString appendString:@"\n"];
		
		[materialToFaceArray removeObjectForKey:[NSNull null]];
	}
	// Write faces for named textures
	for (materialEnumerator = [materialToFaceArray keyEnumerator]; materialKey = [materialEnumerator nextObject]; )
	{
		facesForMaterial = [materialToFaceArray objectForKey:materialKey];
		count = [facesForMaterial count];
		[dataString appendFormat:@"\n# Faces with texture %@:\ng %@\nusemtl %@", materialKey, materialKey, materialKey];
		for (i = 0; i != count; ++i)
		{
			index = [facesForMaterial objectAtIndex:i];
			currentFace = &_faces[[index intValue]];
			faceVerts = currentFace->vertexCount;
			normal = currentFace->normal;
			normal.CleanZeros();
			value = [[NSValue alloc] initWithBytes:&normal objCType:@encode(Vector)];
			ni = [[normalsRev objectForKey:value] intValue];
			[value release];
			
			[dataString appendString:@"\nf"];
			for (j = 0; j != faceVerts; ++j)
			{
				uv.u = currentFace->tex_s[j];
				uv.v = currentFace->tex_t[j];
				value = [[NSValue alloc] initWithBytes:&uv objCType:@encode(UV)];
				ti = [[texCoordsRev objectForKey:value] intValue];
				[value release];				
				[dataString appendFormat:@" %i/%i/%i", currentFace->verts[j] + 1, ti + 1, ni + 1];
			}
		}
		[dataString appendString:@"\n"];
	}
	
	// Write OBJ file
	if (![dataString writeToURL:inFile atomically:NO encoding:NSUTF8StringEncoding error:&error])
	{
		if (nil != error) [ioManager addStopIssueWithKey:@"write_failed" localizedFormat:@"The document could not be saved. %@", [error localizedFailureReason]];
		else [ioManager addStopIssueWithKey:@"write_failed" localizedFormat:@"The document could not be saved, because an unknown error occured."];
		return NO;
	}
	
	materialNames = [[materialToFaceArray allKeys] retain];
	[pool release];
	[materialNames autorelease];
	count = [materialNames count];
	
	// Create material library file
	dataString = [NSMutableString string];
	[dataString appendFormat:  @"# Written by %@ on %@\n"
								"# \n"
								"# %i materials\n"
								"\n",
								version, dateString,
								count];
	
	for (i = 0; i != count; ++i)
	{
		materialKey = [materialNames objectAtIndex:i];
		material = [_materials objectForKey:materialKey];
		[dataString appendFormat:  @"newmtl %@\n"
									"map_Kd %@\n\n",
									materialKey,
									[material diffuseMapName]];
	}
	
	// Write MTL file
	mtlURL = [NSURL URLWithString:mtlName relativeToURL:inFinalLocation];
	if (![dataString writeToURL:mtlURL atomically:YES encoding:NSUTF8StringEncoding error:&error])
	{
		if (nil != error) [ioManager addWarningIssueWithKey:@"mtllib_write_failed" localizedFormat:@"The material library for the document could not be saved. %@", [error localizedFailureReason]];
		else [ioManager addWarningIssueWithKey:@"mtllib_write_failed" localizedFormat:@"The material library for the document could not be saved, because an unknown error occured."];
	}
	
	return YES;
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
		result.v = 1.0 - [[components objectAtIndex:1] floatValue];
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
