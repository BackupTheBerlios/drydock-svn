/*
	DDCompareDialogController.mm
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

#import "DDDocument.h"
#import "DDCompareDialogController.h"
#import "DDMesh.h"
#import "DDProblemReportManager.h"
#import "Logging.h"
#import "CocoaExtensions.h"
#import "DDComparatorView.h"
#import "DDComparatorGLView.h"


@implementation DDCompareDialogController

+ (void)runCompareDialogForDocument:(DDDocument *)inDocument
{
	DDCompareDialogController	*controller;
	
	controller = [[self alloc] initWithDocument:inDocument];
	[controller run];
	[controller release];
}


- (id)initWithDocument:(DDDocument *)inDocument
{
	_doc = [inDocument retain];
	
	if (![NSBundle loadNibNamed:@"DDCompareDialog" owner:self])
	{
		[self release];
		self = nil;
	}
	
	return self;
}


- (void)dealloc
{
	[dialog release];
	[_doc release];
	[_leftMesh release];
	[_rightMesh release];
	
	[super dealloc];
}


- (void)awakeFromNib
{
	
}


- (void)run
{
	NSOpenPanel				*selectPanel;
	NSArray					*types;
	
	[self retain];
	
	selectPanel = [NSOpenPanel openPanel];
	[selectPanel setAllowsMultipleSelection:NO];
	[selectPanel setTreatsFilePackagesAsDirectories:YES];
	[selectPanel setMessage:NSLocalizedString(@"Please select a model to compare with.", NULL)];
	
	// There must be a better way… bug report submitted requesting UTI interface.
	types = [NSArray arrayWithObjects:@"obj", @"dat", NSFileTypeForHFSTypeCode('OoDa'), nil];
	
	// Possibly you should be able to select another open document?
	[selectPanel beginSheetForDirectory:nil file:nil types:types modalForWindow:[_doc windowForSheet] modalDelegate:self didEndSelector:@selector(selectPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)selectPanelDidEnd:(NSOpenPanel *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)ignored
{
	DDMesh					*compareMesh;
	DDProblemReportManager	*issues;
	CFStringRef				utiDAT, utiOBJ;
	NSString				*filePath, *fileUTI;
	NSURL					*fileURL;
	
	[inSheet orderOut:nil];
	
	if (NSOKButton == inReturnCode)
	{
		// Attempt to load the model to be compared to
		issues = [[DDProblemReportManager alloc] init];
		[issues setContext:kContextOpen];
		
		// This sucks rocks. Cocoa should have a sensible way of comparing file types… and Dry Dock should really be using some sort of content sniffing.
//		utiDAT = UTTypeCreatePreferredIdentifierForTag(CFSTR("com.apple.ostype"), CFSTR("OoDa"), NULL);
		utiDAT = CFSTR("org.aegidian.oolite.mesh");
		utiOBJ = UTTypeCreatePreferredIdentifierForTag(CFSTR("public.filename-extension"), CFSTR("obj"), NULL);
		
		filePath = [[inSheet filenames] objectAtIndex:0];
		fileURL = [[inSheet URLs] objectAtIndex:0];
		fileUTI = [[NSFileManager defaultManager] utiForItemAtPath:filePath];
		
		if (UTTypeEqual(utiDAT, (CFStringRef)fileUTI))
		{
			compareMesh = [[DDMesh alloc] initWithOoliteDAT:fileURL issues:issues];
		}
		else if (UTTypeEqual(utiOBJ, (CFStringRef)fileUTI))
		{
			compareMesh = [[DDMesh alloc] initWithLightwaveOBJ:fileURL issues:issues];
		}
		else
		{
			[issues addStopIssueWithKey:@"unknownFormat" localizedFormat:@"The document could not be opened, because the file type could not be recognised."];
		}
		
		if (nil != compareMesh)
		{
			_leftMesh = [[_doc mesh] copy];
			_rightMesh = compareMesh;	// Already retained
		}
		
		CFRelease(utiDAT);
		CFRelease(utiOBJ);
		
		[issues runReportModalForWindow:[_doc windowForSheet] modalDelegate:self isDoneSelector:@selector(problemReport:doneWithResult:)];
		[issues release];
	}
	else
	{
		[self release];
	}
}


-(void)problemReport:(DDProblemReportManager*)inManager doneWithResult:(BOOL)inResult
{
	float				maxR1, maxR2;
	
	if (inResult)
	{
		// And now… we can actually show the Compare sheet. After setting it up, of course.
		maxR1 = [_leftMesh maxR];
		maxR2 = [_rightMesh maxR];
		
		if (maxR1 < maxR2) maxR1 = maxR2;
		
		[leftView setMesh:_leftMesh radius:maxR1];
		[rightView setMesh:_rightMesh radius:maxR1];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(leftViewDidChange:) name:kNotificationDDSceneViewCameraOrLightChanged object:[leftView glView]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rightViewDidChange:) name:kNotificationDDSceneViewCameraOrLightChanged object:[rightView glView]];
		
		[[leftView glView] setLightController: [[rightView glView] lightController]];
		
		#if 0
			// Run app-modal. For some reason, the GL views stutter in this case.
			[NSApp runModalForWindow:dialog];
			[self release];
		#else
			// Run as sheet. Smooth animation, but resizing is broken.
			[NSApp beginSheet:dialog modalForWindow:[_doc windowForSheet] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		#endif
	}
	else
	{
		[self release];
	}
}


- (void)leftViewDidChange:ignored
{
	if (!_settingTransform)
	{
		_settingTransform = YES;
		[rightView setTransformationMatrix:[leftView transformationMatrix]];
		[rightView setCameraDistance:[leftView cameraDistance]];
		_settingTransform = NO;
	}
}


- (void)rightViewDidChange:ignored
{
	if (!_settingTransform)
	{
		_settingTransform = YES;
		[leftView setTransformationMatrix:[rightView transformationMatrix]];
		[leftView setCameraDistance:[rightView cameraDistance]];
		_settingTransform = NO;
	}
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[dialog orderOut:nil];
	[self release];
}


- (IBAction)OKAction:sender
{
	[NSApp endSheet:dialog];
}


- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	/*	Space out the left and right comparator view. Spacing is:
		|<-- 20 px -->[ left view ]<-- 8 px -- >[ right view ]<-- 20 px -->|
		
		Update: the sheet is no longer resizeable, because it flickers and leaves droppings (which
		would seem to be entirely AppKit’s fault), but I’m leaving this in in case it becomes
		resizeable again in future.
	*/
	
	NSRect				leftFrame, rightFrame;
	unsigned			sumWidth, leftWidth, rightWidth;
	
	leftFrame = [leftView frame];
	rightFrame = [rightView frame];
	
	sumWidth = (unsigned)frameSize.width - 48;
	leftWidth = sumWidth / 2;
	rightWidth = sumWidth - leftWidth;
	
	leftFrame.size.width = leftWidth;
	rightFrame.size.width = rightWidth;
	rightFrame.origin.x = 28 + leftWidth;
	
	[leftView setFrame:leftFrame];
	[rightView setFrame:rightFrame];
	
	return frameSize;
}

@end
