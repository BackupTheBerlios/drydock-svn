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

#import "DDCompareDialogController.h"
#import "Logging.h"


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
	
	[super dealloc];
}


- (void)awakeFromNib
{
	
}


- (void)run
{
	[self retain];
	[NSApp beginSheet:dialog modalForWindow:[_doc windowForSheet] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
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
