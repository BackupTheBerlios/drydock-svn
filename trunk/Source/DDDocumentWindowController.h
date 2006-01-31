/*
	DDDocumentWindowController.h
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

#import <Cocoa/Cocoa.h>

@class DDPreviewView;
@class SceneNode, DDMeshNode, SimpleTag;
@class DDMesh;


enum
{
	kArrowTool,
	kRotateTool,
	
	kToolCount
};


@interface DDDocumentWindowController: NSWindowController<NSUserInterfaceValidations>
{
	IBOutlet NSView				*leftView,
								*rightView;
	IBOutlet DDPreviewView		*glView;
	IBOutlet NSTextField		*nameField;
	IBOutlet NSTextField		*lengthField;
	IBOutlet NSTextField		*breadthField;
	IBOutlet NSTextField		*heightField;
	IBOutlet NSTextField		*verticesField;
	IBOutlet NSTextField		*facesField;
	IBOutlet NSOutlineView		*outlineView;
	IBOutlet NSMatrix			*toolMatrix;
	
	DDMesh						*_mesh;
	
	SceneNode					*_sceneRoot;
	DDMeshNode					*_meshNode;
	SimpleTag					*_showWireframeTag,
								*_showFacesTag,
								*_showNormalsTag;
	
	float						_objectRadius;
	
	unsigned					_tool;
}

- (IBAction)nameAction:sender;
- (IBAction)toolSelectAction:sender;

- (SceneNode *)sceneRoot;

- (void)setNeedsDisplay;

- (void)setMesh:(DDMesh *)inMesh;

- (BOOL)showWireframe;
- (void)setShowWireframe:(BOOL)inFlag;
- (BOOL)showFaces;
- (void)setShowFaces:(BOOL)inFlag;
- (BOOL)showNormals;
- (void)setShowNormals:(BOOL)inFlag;

- (unsigned)tool;
- (void)setTool:(unsigned)inTool;

@end
