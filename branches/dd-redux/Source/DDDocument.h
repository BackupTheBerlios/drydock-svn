//
//  DDDocument.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OOModelLoadingController.h"

@class DDDocumentSceneView;
@class SGSceneGraphOutlineViewDataSource;
@class DDMockSingletonContext;
@class DDShip;
@class DDEntityHierarchyViewDataSource;


@interface DDDocument: NSDocument <OOModelLoadingController>
{
@private
	DDDocumentSceneView		*_sceneView;
	IBOutlet SGSceneGraphOutlineViewDataSource *sgDataSource;
	IBOutlet DDEntityHierarchyViewDataSource *entityDataSource;
	
	DDMockSingletonContext	*_singletonContext;
	NSOpenGLContext			*_glContext;
	NSString				*_meshPath;
	NSString				*_basePath;
	NSMutableDictionary		*_searchPaths;
	
	BOOL					_showingWireframe;
	BOOL					_showingFaces;
	BOOL					_showingNormals;
	BOOL					_showingBoundingBox;
	
	DDShip					*_ship;
}

@property (nonatomic) BOOL showingWireframe;
@property (nonatomic) BOOL showingFaces;
@property (nonatomic) BOOL showingNormals;
@property (nonatomic) BOOL showingBoundingBox;
@property (readonly, nonatomic) DDMockSingletonContext *singletonContext;
@property (readonly, nonatomic) BOOL shadersSupported;
@property (readonly, nonatomic) DDShip *ship;

- (IBAction) toggleShowingWireframe:(id)sender;
- (IBAction) toggleShowingFaces:(id)sender;
- (IBAction) toggleShowingNormals:(id)sender;
- (IBAction) toggleShowingBoundingBox:(id)sender;
- (IBAction) runShipComparison:(id)sender;

- (NSString *) resolveResourcePathForFile:(NSString *)fileName nominalFolder:(NSString *)folder;

@end
