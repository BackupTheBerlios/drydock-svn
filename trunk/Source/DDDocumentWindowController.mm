/*
	DDDocumentWindowController.mm
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

#define ENABLE_TRACE 0

#import "DDDocument.h"
#import "DDDocumentWindowController.h"
#import "DDPreviewView.h"
#import "SceneNode.h"
#import "DisplayListCacheNode.h"
#import "DDMeshNode.h"
#import "DDMesh.h"
#import "Logging.h"
#import "SimpleTag.h"


#define kMinPaneSize 200.0f


NSString		*kToolbarShowInspector				= @"de.berlios.drydock toolbar showInspector";
NSString		*kToolbarToggleWireframe			= @"de.berlios.drydock toolbar toggleWireframe";
NSString		*kToolbarToggleFaces				= @"de.berlios.drydock toolbar toggleFaces";
NSString		*kToolbarToggleNormals				= @"de.berlios.drydock toolbar toggleNormals";
NSString		*kToolbarCompare					= @"de.berlios.drydock toolbar compare";


@interface DDDocumentWindowController (Private)

- (void)updateDimensionFields;

@end


@implementation DDDocumentWindowController

- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (nil != self)
	{
		_objectRadius = 1.0;
		_showFaces = YES;
	}
	return self;
}


- (void)dealloc
{
	TraceMessage(@"Deallocating controller.");
	TraceIndent();
	
	[[glView openGLContext] makeCurrentContext];
	[_sceneRoot release];
	[_mesh release];
	[NSOpenGLContext clearCurrentContext];
	[formatter release];
	[glView setController:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
	TraceOutdent();
}


- (void)awakeFromNib
{
	NSWindow					*window;
	DDPreviewView				*view;
	NSToolbar					*toolbar;
	NSString					*meterFormat;
	NSSplitView					*splitView;
	NSRect						frame;
	
	TraceMessage(@"Setting up document window controller.");
	TraceIndent();
	
	window = [self window];
	[window useOptimizedDrawing:YES];
	
	// Set up split view
	frame = [window frame];
	splitView = [[NSSplitView alloc] initWithFrame:frame];
	[splitView addSubview:leftView];
	[splitView addSubview:rightView];
	[splitView setDelegate:self];
	[splitView setVertical:YES];
	[splitView setIsPaneSplitter:YES];
	[window setContentView:splitView];
	
	// Set up GL view
	// At this point, glView is a placeholder NSView, because creating NSOpenGLViews in NIBs is severely broken.
	view = [[DDPreviewView alloc] initWithFrame:[glView frame]];
	[view setAutoresizingMask:[glView autoresizingMask]];
	[view setController:self];
	
	[[glView superview] replaceSubview:glView with:view];
	glView = view;
	[view release];
	
	// Set up tool bar
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"drydock document window"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[window setToolbar:toolbar];
	[toolbar release];
	
	[self setTool:kRotateTool];
	
	[nameField setObjectValue:[[self document] modelName]];
	[self updateDimensionFields];
	
	[glView setObjectSize:_objectRadius];
	
	TraceOutdent();
}


- (IBAction)nameAction:sender
{
	
}


- (IBAction)toolSelectAction:sender
{
	[self setTool:[[sender selectedCell] tag]];
}

- (unsigned)tool
{
	return _tool;
}


- (void)setTool:(unsigned)inTool
{
	if (kToolCount <= inTool) inTool = kToolCount - 1;
	
	[[toolMatrix cellWithTag:_tool] setIntValue:0];
	[[toolMatrix cellWithTag:inTool] setIntValue:1];
	_tool = inTool;
	
	[self setNeedsDisplay];
}


- (SceneNode *)sceneRoot
{
	if (nil == _sceneRoot)
	{
		_sceneRoot = [[_mesh sceneGraphForMesh] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneModified:) name:kNotificationSceneNodeModified object:_sceneRoot];
		
		_showWireframeTag = [SimpleTag tagWithKey:@"wireframe" boolValue:_showWireframe];
		_showFacesTag = [SimpleTag tagWithKey:@"shading" boolValue:_showFaces];
		_showNormalsTag = [SimpleTag tagWithKey:@"normals" boolValue:_showNormals];
		[_sceneRoot addTag:_showWireframeTag];
		[_sceneRoot addTag:_showFacesTag];
		[_sceneRoot addTag:_showNormalsTag];
		
		[outlineView reloadData];
	}
	
	return [[_sceneRoot retain] autorelease];
}


- (void)invalidateSceneGraph
{
	[_sceneRoot release];
	_sceneRoot = nil;
	
	_showWireframeTag = nil;
	_showFacesTag = nil;
	_showNormalsTag = nil;
}


- (void)setNeedsDisplay
{
	[glView setNeedsDisplay:YES];
}


- (void)sceneModified:notification
{
	[self setNeedsDisplay];
	[self updateDimensionFields];
}


- (void)setMesh:(DDMesh *)inMesh
{
	TraceMessage(@"Called.");
	TraceIndent();
	
	if (_mesh != inMesh)
	{
		[_mesh release];
		
		_mesh = [inMesh retain];
		_objectRadius = [_mesh maxR];
		if (_objectRadius < 1.0) _objectRadius = 1.0;
		
		[self invalidateSceneGraph];
		[self updateDimensionFields];
		[self setNeedsDisplay];
	}
	
	TraceOutdent();
}


- (BOOL)showWireframe
{
	return _showWireframe;
}


- (void)setShowWireframe:(BOOL)inFlag
{
	if (inFlag != [_showWireframeTag boolValue])
	{
		_showWireframe = inFlag;
		[_showWireframeTag setBoolValue:inFlag];
		[[[self window] toolbar] validateVisibleItems];
	}
}


- (BOOL)showFaces
{
	return _showFaces;
}


- (void)setShowFaces:(BOOL)inFlag
{
	if (inFlag != [_showFacesTag boolValue])
	{
		_showFaces = inFlag;
		[_showFacesTag setBoolValue:inFlag];
		[[[self window] toolbar] validateVisibleItems];
	}
}


- (BOOL)showNormals
{
	return _showNormals;
}


- (void)setShowNormals:(BOOL)inFlag
{
	if (inFlag != [_showNormalsTag boolValue])
	{
		_showNormals = inFlag;
		[_showNormalsTag setBoolValue:inFlag];
		[[[self window] toolbar] validateVisibleItems];
	}
}


- (IBAction)toggleWireframe:sender
{
	[self setShowWireframe:!_showWireframe];
	
	// Ensure either faces or wireframe are visible
	if (!_showWireframe && ![self showFaces])
	{
		[self setShowFaces:YES];
	}
}


- (IBAction)toggleFaces:sender
{
	[self setShowFaces:!_showFaces];
	
	// Ensure either faces or wireframe are visible
	if (!_showFaces && ![self showWireframe])
	{
		[self setShowWireframe:YES];
	}
}


- (IBAction)toggleNormals:sender
{
	[self setShowNormals:!_showNormals];
}


- (void)updateDimensionFields
{
	// Set length, width and breadth fields
	float l, w, h;
	if (nil != _mesh)
	{
		l = [_mesh length];
		w = [_mesh width];
		h = [_mesh height];
	}
	else
	{
		// Because the 0 result when passing a message to nil only applies for general-purpose registers
		l = w = h = 0.0;
	}
	
	[lengthField setFloatValue:l];
	[breadthField setFloatValue:w];
	[heightField setFloatValue:h];
	[verticesField setIntValue:[_mesh vertexCount]];
	[facesField setIntValue:[_mesh faceCount]];
}


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)inItem
{
	NSMenuItem				*item;
	SEL						action;
	BOOL					enabled;
	
	action = [inItem action];
	enabled = [self respondsToSelector:action];
	
	if ([(NSObject *)inItem isKindOfClass:[NSMenuItem class]])
	{
		item = (NSMenuItem *)inItem;
		
		if (action == @selector(toggleWireframe:))
		{
			[item setState:[self showWireframe]];
		}
		else if (action == @selector(toggleFaces:))
		{
			[item setState:[self showFaces]];
		}
		else if (action == @selector(toggleNormals:))
		{
			[item setState:[self showNormals]];
		}
	}
	
	return enabled;
}


- (float)splitView:(NSSplitView *)inSender constrainMaxCoordinate:(float)proposedCoord ofSubviewAt:(int)offset
{
	return ([inSender bounds].size.width - [inSender dividerThickness] - kMinPaneSize);
}


- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedCoord ofSubviewAt:(int)offset
{
	return kMinPaneSize;
}


- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return YES;
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem			*result = nil;
	NSString				*label = nil,
							*paletteLabel = nil,
							*imageName = nil;
	SEL						action = NULL;
	id						target = self;
	
	if ([itemIdentifier isEqual:kToolbarShowInspector])
	{
		label = @"Show Inspector";
		imageName = @"Inspector Toolbar Item";
		action = @selector(showInspector:);
		target = [NSApplication sharedApplication];
	}
	else if ([itemIdentifier isEqual:kToolbarToggleWireframe])
	{
		label = [self showWireframe] ? @"Hide Wireframe" : @"Show Wireframe";
		paletteLabel = @"Show/Hide Wireframe";
		imageName = @"Wireframe Toolbar Item";
		action = @selector(toggleWireframe:);
	}
	else if ([itemIdentifier isEqual:kToolbarToggleFaces])
	{
		label = [self showFaces] ? @"Hide Faces" : @"Show Faces";
		paletteLabel = @"Show/Hide Faces";
		imageName = @"Faces Toolbar Item";
		action = @selector(toggleFaces:);
	}
	else if ([itemIdentifier isEqual:kToolbarToggleNormals])
	{
		label = [self showNormals] ? @"Hide Normals" : @"Show Normals";
		paletteLabel = @"Show/Hide Normals";
		imageName = @"Normals Toolbar Item";
		action = @selector(toggleNormals:);
	}
	else if ([itemIdentifier isEqual:kToolbarCompare])
	{
		label = @"Compare...";
		imageName = @"Compare Toolbar Item";
		action = @selector(doCompareDialog:);
		target = [self document];
	}
	else
	{
		LogMessage(@"Unknown identifier %@", itemIdentifier);
	}
	
	if (nil != label)
	{
		label = NSLocalizedString(label, NULL);
		if (nil == paletteLabel) paletteLabel = label;
		else paletteLabel = NSLocalizedString(paletteLabel, NULL);
		
		result = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		if (nil != result)
		{
			[result autorelease];
			
			[result setLabel:label];
			[result setPaletteLabel:paletteLabel];
			[result setImage:[NSImage imageNamed:imageName]];		// Some image caching wouldn’t hurt
			if (NULL != action)
			{
				[result setTarget:target];
				[result setAction:action];
			}
		}
	}
	
	return result;
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	static NSArray			*array = nil;
	
	if (nil == array) array = [[NSArray alloc] initWithObjects:
								kToolbarShowInspector,
								NSToolbarSeparatorItemIdentifier,
								kToolbarToggleWireframe,
								kToolbarToggleFaces,
								kToolbarToggleNormals,
								NSToolbarSeparatorItemIdentifier,
								kToolbarCompare,
								NSToolbarFlexibleSpaceItemIdentifier,
								NSToolbarCustomizeToolbarItemIdentifier,
							nil];
	return array;
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	static NSArray			*array = nil;
	
	if (nil == array) array = [[NSArray alloc] initWithObjects:
								kToolbarShowInspector,
								kToolbarToggleWireframe,
								kToolbarToggleFaces,
								kToolbarToggleNormals,
								kToolbarCompare,
								NSToolbarCustomizeToolbarItemIdentifier,
								NSToolbarSeparatorItemIdentifier,
								NSToolbarSpaceItemIdentifier,
								NSToolbarFlexibleSpaceItemIdentifier,
							nil];
	return array;
}


- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	NSString				*identifier,
							*rename = nil;
	
	identifier = [theItem itemIdentifier];
	if ([identifier isEqual:kToolbarToggleWireframe])
	{
		rename = [self showWireframe] ? @"Hide Wireframe" : @"Show Wireframe";
	}
	else if ([identifier isEqual:kToolbarToggleFaces])
	{
		rename = [self showFaces] ? @"Hide Faces" : @"Show Faces";
	}
	else if ([identifier isEqual:kToolbarToggleNormals])
	{
		rename = [self showNormals] ? @"Hide Normals" : @"Show Normals";
	}
	
	if (nil != rename)
	{
		rename = NSLocalizedString(rename, NULL);
		[theItem setLabel:rename];
		[theItem setPaletteLabel:rename];
	}
	
	return YES;
}


// Outline view for displaying scene graph (currently for debugging)

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (nil == item) return [self sceneRoot];
	return [item childAtIndex:index];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (nil == item) return YES;
	return 0 != [item numberOfChildren];
}


- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (nil == item) return 1;
	return [item numberOfChildren];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [item name];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	NSLog(@"%@", item);
	return YES;
}

@end
