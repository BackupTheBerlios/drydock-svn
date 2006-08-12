/*
	DDRecenterDialogController.mm
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

#import "DDRecenterDialogController.h"
#import "DDDocument.h"
#import "DDMesh.h"
#import "DDComparatorGLView.h"
#import "SceneNode.h"
#import "DDMeshNode.h"
#import "DDModelDocument.h"

@interface DDRecenterDialogController (Private)

- (id)initForDocument:(DDDocument *)inDocument;
- (void)run;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)updateDisplay;

@end


@implementation DDRecenterDialogController

+ (void)runRecenterDialogForDocument:(DDDocument *)inDocument
{
	DDRecenterDialogController	*controller;
	
	controller = [[self alloc] initForDocument:inDocument];
	[controller run];
	[controller release];
}


- (id)initForDocument:(DDDocument *)inDocument
{
	self = [super init];
	if (nil != self)
	{
		document = [inDocument retain];
		method = kDDMeshRecenterByAveragingVertices;
	}
	return self;
}


- (void)dealloc
{
	[window release];
	[document release];
	// initialMesh is not retained
	// meshNode is not retained
	// recenteredMesh is not retained
	
	[super dealloc];
}


- (void)run
{
	DDComparatorGLView			*sceneView;
	SceneNode					*scene;
	
	[NSBundle loadNibNamed:@"DDRecenterDialog" owner:self];
	if (nil == window) return;
	
	sceneView = [[DDComparatorGLView alloc] initWithFrame:[glView frame]];
	[sceneView setAutoresizingMask:[glView autoresizingMask]];
	
	[[glView superview] replaceSubview:glView with:sceneView];
	glView = sceneView;
	[sceneView release];
	
	initialMesh = [document mesh];
	scene = [initialMesh sceneGraphForMesh];
	[glView setSceneRoot:scene];
	meshNode = [[scene firstChild] firstChild];
	
	[self updateDisplay];
	
	[self retain];
	[NSApp beginSheet:window modalForWindow:[document windowForSheet] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:nil];
	[self release];
}


- (void)updateDisplay
{
	if (kDDMeshRecenterMethodCount <= method) method = kDDMeshRecenterMethodCount - 1;
	
	[methodSelectionMatrix selectCellWithTag:method];
	recenteredMesh = [initialMesh copy];
	[recenteredMesh recenterWithMethod:(DDMeshRecenterMethod)method];
	
	[meshNode setMesh:recenteredMesh];
	[recenteredMesh release];
	
	[glView setNeedsDisplay:YES];
}


- (IBAction)cancelAction:sender
{
	[NSApp endSheet:window];
}


- (IBAction)okAction:sender
{
	[document completeAsynchronousMeshReplacingActionWithName:@"Recentre" mesh:recenteredMesh];
	[NSApp endSheet:window];
}


- (IBAction)setMethodAction:sender
{
	unsigned			selected;
	
	selected = [[sender selectedCell] tag];
	if (selected < kDDMeshRecenterMethodCount && selected != method)
	{
		method = selected;
		[self updateDisplay];
	}
}

@end
