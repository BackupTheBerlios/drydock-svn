//
//  DDDocumentSceneView.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDDocumentSceneView.h"
#import "SGSceneGraph.h"
#import "DDMockSingleton.h"
#import "DDMeshNode.h"
#import "SGDisplayListCacheNode.h"
#import "SGAxisNode.h"
#import "SGSceneGraph+GraphVizGeneration.h"
#import "OOMesh+PropertyList.h"


@interface DDDocumentSceneView ()

- (void) buildSceneGraph;

@end



@implementation DDDocumentSceneView

@synthesize singletonContext = _singletonContext;


- (unsigned) dragActionForEvent:(NSEvent *)inEvent
{
	return kDragAction_orbitCamera;
}


- (void)drawRect:(NSRect)inRect
{
	[DDMockSingletonContext setCurrentContext:self.singletonContext];
	if (self.sceneGraph.rootNode == nil)  [self buildSceneGraph];
	
	[super drawRect:inRect];
	
	[DDMockSingletonContext setCurrentContext:nil];
}


- (void) setMesh:(OOMesh *)mesh
{
	_mesh = mesh;
	[self setCameraDistance:mesh.collisionRadius * -3.0f];
	[self buildSceneGraph];
}


- (NSColor *) backgroundColor
{
	return [NSColor colorWithDeviceRed:0.05f
								 green:0.05f
								  blue:0.05f
								 alpha:1.0f];
}


- (void) buildSceneGraph
{
	SGSceneNode *root = [SGDisplayListCacheNode node];
	[root addChild:[SGAxisNode node]];
	
	if (_mesh != nil)
	{
		DDMeshNode *meshNode = [[DDMeshNode alloc] initWithMesh:_mesh];
		[meshNode addTag:[SGLineWidthTag tagWithWidth:0.5f]];
		[meshNode addTag:[SGPointSizeTag tagWithSize:2.0f]];
		[root addChild:meshNode];
	}
	
	_showWireframeTag = [SGSimpleTag tagWithKey:@"show wireframes" boolValue:NO];
	_showFacesTag = [SGSimpleTag tagWithKey:@"show faces" boolValue:NO];
	_showNormalsTag = [SGSimpleTag tagWithKey:@"show normals" boolValue:NO];
	_showBBoxTag = [SGSimpleTag tagWithKey:@"show bounding boxes" boolValue:NO];
	
	[root addTag:_showWireframeTag];
	[root addTag:_showFacesTag];
	[root addTag:_showNormalsTag];
	[root addTag:_showBBoxTag];
	
	self.sceneGraph.rootNode = root;
	
	[self.sceneGraph.lightManager removeAllLights];
	
	SGLight *light = [[SGLight alloc] init];
	light.diffuse = [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.85 alpha:1.0];
	light.specular = [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.8 alpha:1.0];
	light.ambient = [NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.2 alpha:1.0];
	light.position = Vector(1, 5, 2);
	light.name = @"Main light";
	
	[self.sceneGraph.lightManager addLight:light];
	
	light = [[SGLight alloc] init];
	light.diffuse = [NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.25 alpha:1.0];
	light.specular = [NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.3 alpha:1.0];
	light.position = Vector(-1, -5, -2);
	light.name = @"Fill light";
	
	[self.sceneGraph.lightManager addLight:light];
	
	[self.sceneGraph writeGraphVizToPath:@"~/Desktop/dump.dot"];
	[_mesh.propertyListRepresentation writeToFile:[@"~/Desktop/dump.plist" stringByExpandingTildeInPath] atomically:NO];
}


- (BOOL) showingWireframe
{
	if (_showWireframeTag == nil)  [self buildSceneGraph];
	
	return _showWireframeTag.boolValue;
}


- (void) setShowingWireframe:(BOOL)flag
{
	if (_showWireframeTag == nil)  [self buildSceneGraph];
	
	_showWireframeTag.boolValue = flag;
	[self setNeedsDisplay:YES];
}


- (BOOL) showingFaces
{
	if (_showFacesTag == nil)  [self buildSceneGraph];
	
	return _showFacesTag.boolValue;
}


- (void) setShowingFaces:(BOOL)flag
{
	if (_showFacesTag == nil)  [self buildSceneGraph];
	
	_showFacesTag.boolValue = flag;
	[self setNeedsDisplay:YES];
}


- (BOOL) showingNormals
{
	if (_showNormalsTag == nil)  [self buildSceneGraph];
	
	return _showNormalsTag.boolValue;
}


- (void) setShowingNormals:(BOOL)flag
{
	if (_showNormalsTag == nil)  [self buildSceneGraph];
	
	_showNormalsTag.boolValue = flag;
	[self setNeedsDisplay:YES];
}


- (BOOL) showingBoundingBox
{
	if (_showBBoxTag == nil)  [self buildSceneGraph];
	
	return _showBBoxTag.boolValue;
}


- (void) setShowingBoundingBox:(BOOL)flag
{
	if (_showBBoxTag == nil)  [self buildSceneGraph];
	
	_showBBoxTag.boolValue = flag;
	[self setNeedsDisplay:YES];
}

@end
