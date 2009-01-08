//
//  DDDocument.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDDocument.h"
#import "DDDocumentSceneView.h"
#import "SGSceneGraphOutlineViewDataSource.h"
#import "DDMockSingleton.h"
#import "OOMesh.h"
#import "OOMesh+NMF.h"
#import "OODATMeshLoader.h"
#import "OOBasicMaterial.h"
#import "OOSingleTextureMaterial.h"
#import "OOTexture.h"
#import "DDShip.h"


@interface DDDocument ()

@property (nonatomic) DDDocumentSceneView *sceneView;
@property (nonatomic) DDShip *ship;

- (BOOL) createOpenGLContext;

@end


@implementation DDDocument

@synthesize showingWireframe = _showingWireframe;
@synthesize showingFaces = _showingFaces;
@synthesize showingNormals = _showingNormals;
@synthesize showingBoundingBox = _showingBoundingBox;
@synthesize sceneView = _sceneView;
@synthesize singletonContext = _singletonContext;
@synthesize ship = _ship;


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		self.showingFaces = YES;
		_singletonContext = [[DDMockSingletonContext alloc] initWithOwner:self];
	}
	return self;
}


- (void) awakeFromNib
{
	[_sceneView setOpenGLContext:_glContext];
	[_sceneView setMesh:self.ship.mesh];
	
	[_sceneView bind:@"singletonContext"
			toObject:self
		 withKeyPath:@"singletonContext"
			 options:nil];
	
	[_sceneView bind:@"showingWireframe"
			toObject:self
		 withKeyPath:@"showingWireframe"
			 options:nil];
	
	[_sceneView bind:@"showingFaces"
			toObject:self
		 withKeyPath:@"showingFaces"
			 options:nil];
	
	[_sceneView bind:@"showingNormals"
			toObject:self
		 withKeyPath:@"showingNormals"
			 options:nil];
	
	[_sceneView bind:@"showingBoundingBox"
			toObject:self
		 withKeyPath:@"showingBoundingBox"
			 options:nil];
	
	[sgDataSource bind:@"sceneGraph"
			  toObject:_sceneView
		   withKeyPath:@"sceneGraph"
			   options:nil];
	
	[entityDataSource bind:@"rootEntity"
				  toObject:self
			   withKeyPath:@"ship"
				   options:nil];
}


- (NSString *)windowNibName
{
    return @"DDDocument";
}
- (BOOL) writeToURL:(NSURL *)absoluteURL
			 ofType:(NSString *)typeName
   forSaveOperation:(NSSaveOperationType)saveOperation
originalContentsURL:(NSURL *)absoluteOriginalContentsURL
			  error:(NSError **)outError
{
	NSError					*error = nil;
	BOOL					success = NO;
	
	if ([typeName isEqualToString:@"com.ati.nmf"])
	{
		if (absoluteURL.isFileURL)
		{
			success = [self.ship.mesh writeNMFToFile:absoluteURL.path];
		}
		else
		{
			// FIXME: set up error
		}
	}
	
	if (outError != NULL)  *outError = error;
    return success;
}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL				success = NO;
	OOMeshLoader		*loader = nil;
	NSError				*error = nil;
	OOMesh				*mesh = nil;
	
	if (!absoluteURL.isFileURL)  return NO;
	
	_meshPath = absoluteURL.path;
	_basePath = _meshPath.stringByDeletingLastPathComponent;
	
	// A context needs to be set up early for textures to load in
	if (![self createOpenGLContext])
	{
		// FIXME: error message
		LogWithFormat(@"Can't set up OpenGL context.");
		return NO;
	}
	
	[_glContext makeCurrentContext];
	[DDMockSingletonContext setCurrentContext:_singletonContext];
	
	if ([typeName isEqualToString:@"org.aegidian.oolite.mesh"])
	{
		loader = [[OODATMeshLoader alloc] initWithController:self
														path:absoluteURL.path];
		mesh = [[OOMesh alloc] initWithLoadingController:self
												  loader:loader];
		
		success = mesh != nil;
		self.ship = [[DDShip alloc] initWithMesh:mesh];
	}
	else
	{
		LogWithFormat(@"Can't handle type: %@", typeName);
	}
	
	[DDMockSingletonContext setCurrentContext:nil];
	[NSOpenGLContext clearCurrentContext];
	
	if (outError != NULL)  *outError = error;
	return success;
}


- (NSString *) resolveResourcePathForFile:(NSString *)fileName nominalFolder:(NSString *)folder
{
	if ([fileName hasPrefix:@"/"])  return fileName;
	
	if (_searchPaths == nil)  _searchPaths = [NSMutableDictionary dictionary];
	
	NSArray *searchPaths = [_searchPaths objectForKey:folder];
	if (searchPaths == nil)
	{
		NSString *parent = _basePath.stringByDeletingLastPathComponent;
		searchPaths = $array(_basePath, [_basePath stringByAppendingPathComponent:folder], parent, [parent stringByAppendingPathComponent:folder]);
		[_searchPaths setObject:searchPaths forKey:folder];
	}
	
	NSFileManager *fMgr = [NSFileManager defaultManager];
	for (NSString *path in searchPaths)
	{
		NSString *fullPath = [path stringByAppendingPathComponent:fileName];
		BOOL directory;
		if ([fMgr fileExistsAtPath:fullPath isDirectory:&directory] && !directory)  return fullPath;
	}
	
	// TODO: possibly ask for path
	return nil;
}


- (BOOL) createOpenGLContext
{
	const GLuint kAttributes[] =
	{
		NSOpenGLPFAWindow,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples,4,
		0
	};
	
	
	const GLuint kFallbackAttributes[] =
	{
		NSOpenGLPFAWindow,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFADepthSize, 24,
		0
	};
	
	NSOpenGLPixelFormat			*fmt = nil;
	
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kAttributes];
	if (nil == fmt) fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kFallbackAttributes];
	if (fmt == nil)  return NO;
	
	_glContext = [[NSOpenGLContext alloc] initWithFormat:fmt shareContext:nil];
	return _glContext != nil;
}


#if 0
+ (NSArray *) readableTypes
{
	NSArray *result = [super readableTypes];
	LogWithFormat(@"Readable types: %@", [result componentsJoinedByString:@", "]);
	return result;
}


+ (NSArray *) writableTypes
{
	NSArray *result = [super writableTypes];
	LogWithFormat(@"Writeable types: %@", [result componentsJoinedByString:@", "]);
	return result;
}


+ (BOOL) isNativeType:(NSString *)type
{
	BOOL result = [super isNativeType:type];
	LogWithFormat(@"Is \"%@\" native: %@", type, result ? @"YES" : @"NO");
	return result;
}


- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation
{
	NSArray *result = [super writableTypesForSaveOperation:saveOperation];
	LogWithFormat(@"Writeable types for operation %u: %@", saveOperation, [result componentsJoinedByString:@", "]);
	return result;
}
#endif


- (void) setShowingWireframe:(BOOL)flag
{
	_showingWireframe = flag;
	if (!_showingWireframe && !_showingFaces)  self.showingFaces = YES;
}


- (void) setShowingFaces:(BOOL)flag
{
	_showingFaces = flag;
	if (!_showingFaces && !_showingWireframe)  self.showingWireframe = YES;
}


- (BOOL) shadersSupported
{
	return _sceneView.shadersSupported;
}


- (IBAction) toggleShowingWireframe:(id)sender
{
	self.showingWireframe = !self.showingWireframe;
}


- (IBAction) toggleShowingFaces:(id)sender
{
	self.showingFaces = !self.showingFaces;
}


- (IBAction) toggleShowingNormals:(id)sender
{
	self.showingNormals = !self.showingNormals;
}


- (IBAction) toggleShowingBoundingBox:(id)sender
{
	self.showingBoundingBox = !self.showingBoundingBox;
}


- (IBAction) runShipComparison:(id)sender
{
	
}


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	NSString			*name = nil;
	
	if (item.action == @selector(toggleShowingWireframe:))
	{
		if (self.showingWireframe)  name = @"Hide Wireframe";
		else  name = @"Show Wireframe";
	}
	else if (item.action == @selector(toggleShowingFaces:))
	{
		if (self.showingFaces)  name = @"Hide Faces";
		else  name = @"Show Faces";
	}
	else if (item.action == @selector(toggleShowingNormals:))
	{
		if (self.showingNormals)  name = @"Hide Normals";
		else  name = @"Show Normals";
	}
	
	if (name != nil && [(id)item respondsToSelector:@selector(setLabel:)])
	{
		[(id)item setLabel:name];
	}
	
	return [super validateUserInterfaceItem:item];
}


#if 0
#pragma mark NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil)  return @"Root";
	return nil;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return item ? 0 : 1;
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return item;
}
#endif


#pragma mark OOModelLoadingController

- (void) reportProblemWithKey:(NSString *)key
						fatal:(BOOL)isFatal
					   format:(NSString *)format, ...
{
	va_list args;
	va_start(args, format);
	[self reportProblemWithKey:key
						 fatal:isFatal
						format:format
					 arguments:args];
	va_end(args);
}


- (void) reportProblemWithKey:(NSString *)key
						fatal:(BOOL)isFatal
					   format:(NSString *)format
					arguments:(va_list)args
{
	LogWithFormatAndArguments(format, args);
}


- (NSString *) pathForMeshNamed:(NSString *)name
{
	if ([name isEqualToString:_meshPath.lastPathComponent])
	{
		return _meshPath;
	}
	else  return nil;
}


- (OOMaterial *) loadMaterialWithKey:(NSString *)key
{
	OOMaterial *material = nil;
	
	if (![key isEqualToString:kOOPlaceholderMaterialName])
	{
		OOTexture *texture = [OOTexture textureWithName:key
											   inFolder:@"Textures"
												options:kOOTextureMinFilterMipMap | kOOTextureMagFilterLinear | kOOTextureNeverScale
											 anisotropy:1.0
												lodBias:kOOTextureDefaultLODBias];
		if (texture != nil)
		{
			material = [[OOSingleTextureMaterial alloc] initWithName:key
															 texture:texture
													   configuration:nil];
		}
		
		if (material == nil)
		{
			[self reportProblemWithKey:@"texture.load.failed"
								 fatal:NO
								format:@"The texture \"%@\" could not be loaded.", key];
		}
	}
	
	if (material == nil)
	{
		material = [[OOBasicMaterial alloc] initWithName:key
										   configuration:nil];
	}
	
	return material;
}


- (BOOL) shouldUseSmoothShading
{
	return NO;
}


- (BOOL) permitCacheRead
{
	return NO;
}


- (BOOL) permitCacheWrite
{
	return NO;
}

@end
