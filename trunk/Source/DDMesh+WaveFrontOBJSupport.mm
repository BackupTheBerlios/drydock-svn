/*
	DDMesh+WaveFrontOBJSupport.mm
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
//#import "BS-HOM.h"
#import "DDProblemReportManager.h"
#import "CocoaExtensions.h"
#import "DDUtilities.h"
#import "DDError.h"
#import "DDNormalSet.h"
#import "DDMaterialSet.h"
#import "DDTexCoordSet.h"
#import "DDFaceVertexBuffer.h"


#define LOG_MATERIAL_ATTRIBUTES		0


enum {
	kWarningSupressThreshold	= 5
};


static Vector ObjVertexToVector(NSString *inVertex);
static Vector2 ObjUVToVector2(NSString *inUV);
static NSArray *ObjFaceToArrayOfArrays(NSString *inData);

#if 0
static NSColor *ObjColorToNSColor(NSString *inColor);
#endif


@interface DDMesh (WaveFrontOBJSupport_Private)

- (NSMutableArray *)objTokenize:(NSURL *)inFile error:(NSError **)outError;
- (NSDictionary *)loadObjMaterialLibraryNamed:(NSString *)inString relativeTo:(NSURL *)inBase issues:(DDProblemReportManager *)ioIssues;

@end


@interface DDMaterialSet (WaveFrontOBJSupport)

- (unsigned)addMaterialNamed:(NSString *)inName forOBJAttributes:(NSDictionary *)inAttributes relativeTo:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;

@end


@implementation DDMesh (WaveFrontOBJSupport)


// A pretty good overview of OBJ files is at http://netghost.narod.ru/gff/graphics/summary/waveobj.htm
// FIXME this code will choke on files using \ to escape newlines. I’ll fix this when doing the flex-based parser.
- (id)initWithWaveFrontOBJ:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnterMsg(@"Called for %@", inFile);
	
	BOOL					OK = YES;
	NSMutableArray			*lines;
	NSArray					*line;
	unsigned				vertexCount = 0, uvCount = 0, normalCount = 0, faceCount = 0;
	unsigned				vertexIdx = 0, uvIdx = 0, normalIdx = 0, faceIdx = 0;
	Vector					*vertices = NULL;
	DDMeshFaceData			*faces = NULL, *face;
	Vector					*normalArray = NULL;
	NSString				*keyword, *params;
	float					xMin = INFINITY, xMax = -INFINITY,
							yMin = INFINITY, yMax = -INFINITY,
							zMin = INFINITY, zMax = -INFINITY,
							rMax = 0, r;
	Vector					vec;
	NSEnumerator			*lineEnum;
	NSArray					*faceData;
	unsigned				faceVertexCount, fvIdx;
	Vector					normal, vtxNormal;
	NSMutableSet			*ignoredTypes = nil;
	NSError					*error;
	unsigned				badUVWarnings = 0;
	unsigned				badNormalWarnings = 0;
	BOOL					warnedAboutNoNormals = NO;
	BOOL					warnedAboutCall = NO;
	BOOL					warnedAboutShellScript = NO;
	DDNormalSet				*normals = nil;
	DDMaterialSet			*materials = nil;
	NSDictionary			*materialLibrary = nil;
	DDMeshIndex				currentMaterial = kDDMeshIndexNotFound;
	Vector2					*uv = NULL;
	DDTexCoordSet			*texCoords = nil;
	DDMeshIndex				faceVertices[kMaxVertsPerFace];
	DDMeshIndex				faceTexCoords[kMaxVertsPerFace];
	DDMeshIndex				vertexNormals[kMaxVertsPerFace];
	DDFaceVertexBuffer		*buffer = nil;
	NSMutableDictionary		*smoothingGroups = nil;
	uint8_t					activeSmoothingGroup = 0;
	uint8_t					smoothingGroupsUsed = 0;
	NSNumber				*smoothingGroupIndex;
	
	self = [super init];
	if (nil == self) return nil;
	
	lines = [self objTokenize:inFile error:&error];
	if (!lines)
	{
		OK = NO;
		[ioIssues addStopIssueWithKey:@"noDataLoaded" localizedFormat:@"No data could be loaded from %@. %@", [inFile displayString], error ? [error localizedFailureReason] : @""];
	}
	
	if (OK)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		// Count various line types
#if 0
		[[lines countTo:&vertexCount] firstObjectEquals:@"v"];
		[[lines countTo:&uvCount] firstObjectEquals:@"vt"];
		[[lines countTo:&normalCount] firstObjectEquals:@"vn"];
		[[lines countTo:&faceCount] firstObjectEquals:@"f"];
#else
		for (NSArray *line in lines)
		{
			NSString *first = [line objectAtIndex:0];
			if ([first isEqualToString:@"v"])  vertexCount++;
			else if ([first isEqualToString:@"vt"])  uvCount++;
			else if ([first isEqualToString:@"vn"])  normalCount++;
			else if ([first isEqualToString:@"f"])  faceCount++;
		}
#endif
		
		if (0 == uvCount) uvCount = 1;
		if (0 == normalCount) normalCount = 1;
		
		if (kDDMeshIndexMax < vertexCount)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"vertices", NULL), vertexCount];
		}
		else if (kDDMeshIndexMax < faceCount)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"faces", NULL), faceCount];
		}
		else if (kDDMeshIndexMax < uvCount)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"texture co-ordinate pairs", NULL), uvCount];
		}
		else if (kDDMeshIndexMax < normalCount)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u %@; this document has %u.", kDDMeshIndexMax + 1, NSLocalizedString(@"normals", NULL), normalCount];
		}
		
		
		[pool drain];
	}
	
	if (OK)
	{
		vertices = (Vector *)malloc(sizeof(Vector) * vertexCount);
		texCoords = [DDTexCoordSet setWithCapacity:uvCount];
		uv = (Vector2 *)malloc(sizeof(Vector2) * uvCount);
		normalArray = (Vector *)malloc(sizeof(Vector) * normalCount);
		normals = [DDNormalSet setWithCapacity:faceCount];
		faces = (DDMeshFaceData *)malloc(sizeof(DDMeshFaceData) * faceCount);
		buffer = [DDFaceVertexBuffer bufferForFaceCount:faceCount];
		
		if (!(vertices && texCoords && uv && normalArray && normals && faces && buffer))
		{
			OK = NO;
			if (vertices) { free(vertices); vertices = NULL; };
			if (faces) { free(faces); faces = NULL; };
			
			if (!OK) [ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
		}
	}
	
	if (OK)
	{
		lineEnum = [lines objectEnumerator];
		
		while ((line = [lineEnum nextObject]))
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			
			keyword = [line objectAtIndex:0];
			params = [line objectAtIndex:1];
			
			if ([keyword isEqual:@"mtllib"])
			{
				// Material Library
				if (nil == materialLibrary)
				{
					materialLibrary = [[self loadObjMaterialLibraryNamed:params relativeTo:inFile issues:ioIssues] retain];
					if (nil != materialLibrary) materials = [[DDMaterialSet alloc] initWithCapacity:[materialLibrary count]];
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
				vertices[vertexIdx++] = vec.CleanZeros();
				
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
				
				uv[uvIdx] = ObjUVToVector2(params);
				//LogMessage(@"UV: {%g, %g}", uv[uvIdx].Description());
				++uvIdx;
			}
			else if ([keyword isEqual:@"vn"])
			{
				// Vertex Normal
				assert(normalIdx < normalCount);
				
				vec = ObjVertexToVector(params);
				//vec = ObjVertexToVector(params).Direction();
				normalArray[normalIdx++] = vec.Normalize().CleanZeros();
				//LogMessage(@"Normal: %@", vec.Description());
			}
			else if ([keyword isEqual:@"f"])
			{
				// Face
				assert(faceIdx < faceCount);
				
				BOOL			warnedUVThisLine = NO, warnedNormalThisLine = NO;
				
				normal.Set(0);
				faceData = ObjFaceToArrayOfArrays(params);
				faceVertexCount = [faceData count];
				if (3 <= faceVertexCount)
				{
					if (kMaxVertsPerFace < faceVertexCount)
					{
						OK = NO;
						[ioIssues addStopIssueWithKey:@"vertexCountRange" localizedFormat:@"Invalid vertex count (%u) for face line %u. Each face must have at least 3 and no more than %u vertices.", faceVertexCount, faceIdx + 1, kMaxVertsPerFace];
					}
					if (OK)
					{
						face = &faces[faceIdx++];
						
						face->vertexCount = faceVertexCount;
						
						if (kDDMeshIndexNotFound == currentMaterial)
						{
							if (nil == materials) materials = [[DDMaterialSet alloc] initWithCapacity:1];
							currentMaterial = [materials addMaterial:[DDMaterial materialWithName:@"$untextured"]];
						}
						face->material = currentMaterial;
						
						for (fvIdx = 0; fvIdx != faceVertexCount; ++fvIdx)
						{
							int				intVal, index;
							Vector			v, vn;
							Vector2			vt;
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
								if ((int)vertexIdx <= index || index < 0)
								{
									[ioIssues addStopIssueWithKey:@"vertexRange" localizedFormat:@"Face line %u specifies a vertex index of %i, but there are only %u vertices in the document.", faceIdx, intVal, vertexIdx];
									index = 0;
									OK = NO;
								}
								faceVertices[fvIdx] = index;
							}
							
							// Read U/V index
							if (OK)
							{
								if (2 <= elemCount)
								{
									objVal = [elements objectAtIndex:1];
									if (nil == objVal || [@"" isEqual:objVal]) OK = NO;
								}
								else
								{
									OK = NO;	// Skip to fallback for no texture co-ords
								}
								
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
									if ((int)uvIdx <= index || index < 0)
									{
										if (!warnedUVThisLine)
										{
											warnedUVThisLine = YES;
											if (badUVWarnings < kWarningSupressThreshold)
											{
												++badUVWarnings;
												[ioIssues addWarningIssueWithKey:@"UVIndexRange" localizedFormat:@"Face line %u specifies a U/V index of %i, but there are only %u U/V pairs in the document.", faceIdx, intVal, vertexIdx];
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
									faceTexCoords[fvIdx] = [texCoords indexForVector:uv[index]];
								}
								else
								{
									faceTexCoords[fvIdx] = [texCoords indexForVector:Vector2(0, 0)];
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
									if ((int)normalIdx <= index || index < 0)
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
									vtxNormal = normalArray[index];
									vertexNormals[fvIdx] = [normals indexForVector:vtxNormal];
									normal += vtxNormal;
								}
								else
								{
									OK = YES;	// Lack of normal index is non-fatal
									vertexNormals[fvIdx] = [normals indexForVector:Vector(0, 0, 0)];
								}
							}
						}
						
						if (!warnedAboutNoNormals && Vector(0, 0, 0) == normal)
						{
							warnedAboutNoNormals = YES;
							[ioIssues addWarningIssueWithKey:@"invalidNormal" localizedFormat:@"Some or all faces in the document lack a valid normal specified. This is likely to lead to lighting problems. This issue can be rectified by selecting Recalculate Normals from the Tools menu."];
						}
						face->normal = [normals indexForVector:normal];
						face->smoothingGroup = activeSmoothingGroup;
						face->firstVertex = [buffer addVertexIndices:faceVertices texCoordIndices:faceTexCoords vertexNormals:vertexNormals count:faceVertexCount];
					}
				}
				
				//LogMessage(@"Face: %@", params);
			}
			else if ([keyword isEqual:@"usemtl"])
			{
				// Use Material
				if (nil == materials) materials = [[DDMaterialSet alloc] initWithCapacity:1];
				currentMaterial = [materials indexForName:params];
				if (kDDMeshIndexNotFound == currentMaterial)
				{
					currentMaterial = [materials addMaterialNamed:params forOBJAttributes:[materialLibrary objectForKey:params] relativeTo:inFile issues:ioIssues];
				}
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
			else if ([keyword isEqual:@"s"])
			{
				/*	Note: strictly, smoothing groups are required to be identified by number, with
					"off" being an alias for zero. Since no specific range is given for smoothing
					groups, we map them to uint8_ts. At this point, it becomes simpler to allow for
					arbitrary strings than to require numbers.
				*/
				if ([@"off" isEqual:params] || [@"0" isEqual:params])
				{
					activeSmoothingGroup = 0;
					//LogMessage(@"Disabling smoothing");
				}
				else
				{
					smoothingGroupIndex = [smoothingGroups objectForKey:params];
					if (nil != smoothingGroupIndex)
					{
						activeSmoothingGroup = [smoothingGroupIndex unsignedCharValue];
						//LogMessage(@"Switched to smoothing group %u", activeSmoothingGroup);
					}
					else
					{
						// New smoothing group
						if (smoothingGroupsUsed < 255)
						{
							activeSmoothingGroup = ++smoothingGroupsUsed;
							smoothingGroupIndex = [NSNumber numberWithUnsignedChar:activeSmoothingGroup];
							if (nil == smoothingGroups) smoothingGroups = [NSMutableDictionary dictionary];
							[smoothingGroups setObject:smoothingGroupIndex forKey:params];
							//LogMessage(@"Started smoothing group %u", activeSmoothingGroup);
						}
						else
						{
							OK = NO;
							[ioIssues addStopIssueWithKey:@"documentTooComplex" localizedFormat:@"This document is too complex to be loaded by Dry Dock. Dry Dock cannot handle models with more than %u smoothing groups.", 255];
						}
					}
				}
			}
			else if ([keyword isEqual:@"call"])
			{
				// External file inclusion
				if (!warnedAboutCall)
				{
					warnedAboutCall = YES;
					[ioIssues addNoteIssueWithKey:@"OBJCall" localizedFormat:@"The document contains one or more \"calls\" of external files. This feature is not supported by Dry Dock at present."];
				}
			}
			else if ([keyword isEqual:@"csh"])
			{
				// Shell script call
				if (!warnedAboutShellScript)
				{
					warnedAboutShellScript = YES;
					[ioIssues addNoteIssueWithKey:@"OBJShellScript" localizedFormat:@"The document contains one or more shell script commands. For security reasons, this feature is not supported by Dry Dock."];
				}
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
			
			[pool drain];
			pool = nil;
			if (!OK) break;
		}
	}
	[ignoredTypes release];
	
	free(uv);
	free(normalArray);
	
	if (OK)
	{
		_vertexCount = vertexIdx;
		_vertices = vertices;
		
		[normals getArray:&_normals andCount:&_normalCount];
		
		_faceCount = faceIdx;
		_faces = faces;
		
		[materials getArray:&_materials andCount:&_materialCount];
		[texCoords getArray:&_texCoords andCount:&_texCoordCount];
		[buffer getVertexIndices:&_faceVertexIndices textureCoordIndices:&_faceTexCoordIndices vertexNormals:&_vertexNormalIndices andCount:&_faceVertexIndexCount];
		
		_xMin = xMin;
		_xMax = xMax;
		_yMin = yMin;
		_yMax = yMax;
		_zMin = zMin;
		_zMax = zMax;
		_rMax = rMax;
		
		if (nil == _name)
		{
			_name = [inFile displayString];
			if (NSOrderedSame == [[_name substringFromIndex:[_name length] - 4] caseInsensitiveCompare:@".obj"]) _name = [_name substringToIndex:[_name length] - 4];
			[_name retain];
		}
		
		[self findBadPolygonsWithIssues:ioIssues];
	}
	else
	{
		free(vertices);
		free(faces);
		
		[self release];
		self = nil;
	}
	[materials release];
	
	return self;
	TraceExit();
}


- (NSMutableArray *)objTokenize:(NSURL *)inFile error:(NSError **)outError
{
	TraceEnterMsg(@"Called for %@", inFile);
	
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
	TraceExit();
}


- (NSDictionary *)loadObjMaterialLibraryNamed:(NSString *)inString relativeTo:(NSURL *)inBase issues:(DDProblemReportManager *)ioIssues
{
	TraceEnterMsg(@"Called for %@", inString);
	
	BOOL					OK = YES;
	NSURL					*url;
	NSMutableArray			*lines;
	unsigned				lineCount, i = 0;
	NSArray					*line;
	NSString				*keyword, *params = nil;
	NSMutableDictionary		*result = nil;
	NSMutableDictionary		*current = nil;
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
	TraceExit();
}


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingWaveFrontOBJToURL:(NSURL *)inFile
{
	// No issues to check for at this time. OBJ is the most expressive format supported.
}


- (BOOL)writeWaveFrontOBJToURL:(NSURL *)inFile finalLocationURL:(NSURL *)inFinalLocation issues:(DDProblemReportManager *)ioManager
{
	NSError					*error = nil;
	NSMutableString			*dataString;
	NSDateFormatter			*formatter;
	NSString				*dateString;
	NSString				*mtlName;
	NSURL					*mtlURL;
	unsigned				i, j, faceVertexCount, count, ni;
	NSNumber				*index;
	NSMutableDictionary		*materialToFaceArray;
	NSMutableArray			*facesForMaterial;
	id						materialKey;
	NSString				*materialName;
	NSEnumerator			*materialEnumerator;
	DDMeshFaceData			*currentFace;
	NSAutoreleasePool		*pool;
	NSArray					*materialsUsed;
	DDMaterial				*material;
	unsigned				vertIdx, materialIdx;
	uint8_t					activeSmoothingGroup = 0;
	
	/*	Build material library name. For “Foo.obj” or “Foo”, use “Foo.mtl”; for “Bar.baz”, use
		“Bar.baz.mtl”. Material library names can’t contain spaces (OBJ allows multiple material
		library names separated by space), so replace them with underscores.
	*/
	mtlName = [[inFile path] lastPathComponent];
	if ([[mtlName lowercaseString] hasSuffix:@".obj"])
	{
		mtlName = [mtlName substringToIndex:[mtlName length] - 4];
	}
	mtlName = [mtlName stringByAppendingString:@".mtl"];
	mtlName = [[mtlName componentsSeparatedByString:@" "] componentsJoinedByString:@"_"];
	
	// Get formatted date string for header comment
	formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO];	// ISO date format
	dateString = [formatter stringForObjectValue:[NSDate date]];
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
	[dataString appendFormat:@"\n# Vertices (%u):\n", _vertexCount];
	for (i = 0; i != _vertexCount; ++i)
	{
		[dataString appendFormat:@"v %f %f %f\n", _vertices[i].x, _vertices[i].y, _vertices[i].z];
	}
	
	//	Write texture co-ordinates.
	[dataString appendFormat:@"\n# Texture co-ordinates (%u):\n", _texCoordCount];
	for (i = 0; i != _texCoordCount; ++i)
	{
		[dataString appendFormat:@"vt %f %f\n", _texCoords[i].x, 1.0 - _texCoords[i].y];
	}
	
	// Write normals
	[dataString appendFormat:@"\n# Normals (%u):\n", _normalCount];
	for (i = 0; i != _normalCount; ++i)
	{
		[dataString appendFormat:@"vn %f %f %f\n", _normals[i].x, _normals[i].y, _normals[i].z];
	}
	
	/*	Sort faces by texture. Basic approach: create a dictionary keyed by material index, with
		mutable arrays as the values. These arrays are populated with indices into _faces, as
		NSNumbers.
	*/
	materialToFaceArray = [NSMutableDictionary dictionary];
	for (i = 0; i != _faceCount; ++i)
	{
		materialKey = [NSNumber numberWithUnsignedInt:_faces[i].material];
		facesForMaterial = [materialToFaceArray objectForKey:materialKey];
		if (nil == facesForMaterial)
		{
			facesForMaterial = [NSMutableArray array];
			[materialToFaceArray setObject:facesForMaterial forKey:materialKey];
		}
		[facesForMaterial addObject:[NSNumber numberWithInt:i]];
	}
	
	#if 0
	// FIXME: possibly ought to look for "$placeholder" material here?
	// Write faces with no texture, if any
	facesForMaterial = [materialToFaceArray objectForKey:[NSNull null]];
	if (nil != facesForMaterial)
	{
		count = [facesForMaterial count];
		[dataString appendFormat:@"\n# Untextured faces (%u):\ng untextured", count];
		for (i = 0; i != count; ++i)
		{
			index = [facesForMaterial objectAtIndex:i];
			currentFace = &_faces[[index intValue]];
			faceVertexCount = currentFace->vertexCount;
			[value release];
			ni = currentFace->normal + 1;
			vertIdx = currentFace->firstVertex;
			
			[dataString appendString:@"\nf"];
			for (j = 0; j != faceVertexCount; ++j)
			{
				[dataString appendFormat:@" %i//%i", _faceVertexIndices[vertIdx] + 1, ni];
			}
		}
		[dataString appendString:@"\n"];
		
		[materialToFaceArray removeObjectForKey:[NSNull null]];
	}
	#endif
	// Write faces for named textures
	for (materialEnumerator = [materialToFaceArray keyEnumerator]; (materialKey = [materialEnumerator nextObject]); )
	{
		facesForMaterial = [materialToFaceArray objectForKey:materialKey];
		materialIdx = [materialKey intValue];
		materialName = [_materials[materialIdx] name];
		if (nil == materialName) materialName = [NSString stringWithFormat:@"anon-%u", materialIdx];
		
		count = [facesForMaterial count];
		[dataString appendFormat:@"\n# Faces with texture %@ (%u):\ng %@\nusemtl %@", materialName, count, materialName, materialName];
		for (i = 0; i != count; ++i)
		{
			index = [facesForMaterial objectAtIndex:i];
			currentFace = &_faces[[index intValue]];
			faceVertexCount = currentFace->vertexCount;
			ni = currentFace->normal + 1;
			vertIdx = currentFace->firstVertex;
			
			if (activeSmoothingGroup != currentFace->smoothingGroup)
			{
				activeSmoothingGroup = currentFace->smoothingGroup;
				if (0 == activeSmoothingGroup)
				{
					[dataString appendString:@"\ns off"];
				}
				else
				{
					[dataString appendFormat:@"\ns %u", activeSmoothingGroup];
				}
			}
			
			[dataString appendString:@"\nf"];
			for (j = 0; j != faceVertexCount; ++j)
			{			
				[dataString appendFormat:@" %i/%i/%i", _faceVertexIndices[vertIdx] + 1, _faceTexCoordIndices[vertIdx] + 1, ni];
				++vertIdx;
			}
		}
		[dataString appendString:@"\n"];
	}
	
	// Write OBJ file
	if (![dataString writeToURL:inFile atomically:NO encoding:NSUTF8StringEncoding error:&error])
	{
		if (nil != error) [ioManager addStopIssueWithKey:@"writeFailed" localizedFormat:@"The document could not be saved. %@", [error localizedFailureReason]];
		else [ioManager addStopIssueWithKey:@"writeFailed" localizedFormat:@"The document could not be saved, because an unknown error occured."];
		return NO;
	}
	
	materialsUsed = [[materialToFaceArray allKeys] retain];
	[pool release];
	pool = [[NSAutoreleasePool alloc] init];
	[materialsUsed autorelease];
	count = [materialsUsed count];
	
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
		materialIdx = [[materialsUsed objectAtIndex:i] intValue];
		material = _materials[materialIdx];
		[dataString appendFormat:  @"newmtl %@\n"
									"map_Kd %@\n\n",
									[material name],
									[material diffuseMapName]];
	}
	
	// Write MTL file
	mtlURL = [NSURL URLWithString:mtlName relativeToURL:inFinalLocation];
	if (![dataString writeToURL:mtlURL atomically:YES encoding:NSUTF8StringEncoding error:&error])
	{
		if (nil != error) [ioManager addWarningIssueWithKey:@"mtllibWriteFailed" localizedFormat:@"The material library for the document could not be saved. %@", [error localizedFailureReason]];
		else [ioManager addWarningIssueWithKey:@"mtllibWriteFailed" localizedFormat:@"The material library for the document could not be saved, because an unknown error occured."];
	}
	[pool release];
	
	return YES;
}

@end


#if 0
static NSColor *ObjColorToNSColor(NSString *inColor)
{
	TraceEnter();
	
	NSArray				*components;
	float				r, g, b;
	
	components = [inColor componentsSeparatedByString:@" "];
	if (3 != [components count]) return nil;
	
	r = [[components objectAtIndex:0] floatValue];
	g = [[components objectAtIndex:1] floatValue];
	b = [[components objectAtIndex:2] floatValue];
	
	return [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
	TraceExit();
}
#endif


static Vector ObjVertexToVector(NSString *inVertex)
{
	TraceEnter();
	
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
	TraceExit();
}


static Vector2 ObjUVToVector2(NSString *inUV)
{
	TraceEnter();
	
	NSArray				*components;
	Vector2				result(0, 0);
	
	components = [inUV componentsSeparatedByString:@" "];
	if (2 == [components count])
	{
		result.x = [[components objectAtIndex:0] floatValue];
		result.y = 1.0 - [[components objectAtIndex:1] floatValue];
	}
	
	return result;
	TraceExit();
}


static NSArray *ObjFaceToArrayOfArrays(NSString *inData)
{
	TraceEnter();
	
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
	TraceExit();
}


@implementation DDMaterialSet (WaveFrontOBJSupport)

- (unsigned)addMaterialNamed:(NSString *)inName forOBJAttributes:(NSDictionary *)inAttributes relativeTo:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	NSString			*diffuseName;
	DDMaterial			*material;
	
	material = [DDMaterial materialWithName:inName];
	diffuseName = [inAttributes objectForKey:@"diffuse map name"];
	if (nil != diffuseName)
	{
		[material setDiffuseMap:diffuseName relativeTo:inFile issues:ioIssues];
	}
	return [self addMaterial:material];
}

@end
