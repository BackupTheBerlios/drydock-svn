//
//  DDDocumentSceneView.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDSceneView.h"

@class DDMockSingletonContext;
@class OOMesh;
@class SGSimpleTag;


@interface DDDocumentSceneView: DDSceneView
{
@private
	DDMockSingletonContext		*_singletonContext;
	OOMesh						*_mesh;
	
	SGSimpleTag					*_showWireframeTag;
	SGSimpleTag					*_showFacesTag;
	SGSimpleTag					*_showNormalsTag;
	SGSimpleTag					*_showBBoxTag;
}

@property (nonatomic) DDMockSingletonContext *singletonContext;

- (void) setMesh:(OOMesh *)mesh;

@property BOOL showingWireframe;
@property BOOL showingFaces;
@property BOOL showingNormals;
@property BOOL showingBoundingBox;

@end
