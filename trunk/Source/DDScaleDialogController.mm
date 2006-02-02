/*
	DDScaleDialogController.mm
	Dry Dock for Oolite
	
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

#import "DDScaleDialogController.h"
#import "DDDocument.h"

@interface DDScaleDialogController (Private)

- (id)initForDocument:(DDDocument *)inDocument;
- (void)run;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end


@implementation DDScaleDialogController

+ (void)runScaleDialogForDocument:(DDDocument *)inDocument
{
	DDScaleDialogController	*controller;
	
	controller = [[self alloc] initForDocument:inDocument];
	[controller run];
	[controller release];
}


- (id)initForDocument:(DDDocument *)inDocument
{
	self = [super init];
	if (nil != self)
	{
		_document = [inDocument retain];
	}
	return self;
}


- (void)dealloc
{
	[panel release];
	[formatter release];
	[_document release];
	
	[super dealloc];
}


- (void)run
{
	[NSBundle loadNibNamed:@"DDScaleDialog" owner:self];
	if (nil == panel) return;
	
	[xField setEnabled:NO];
	[yField setEnabled:NO];
	[zField setEnabled:NO];
	
	[self retain];
	[NSApp beginSheet:panel modalForWindow:[_document windowForSheet] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:nil];
	[self release];
}


- (IBAction)changeMode:(id)sender
{
	BOOL perAxis;
	
	perAxis = (0 != [[sender selectedCell] tag]);
	
	if (_perAxis != perAxis)
	{
		_perAxis = perAxis;
		[uniformField setEnabled:!perAxis];
		[xField setEnabled:perAxis];
		[yField setEnabled:perAxis];
		[zField setEnabled:perAxis];
	}
}


- (IBAction)OKAction:(id)sender
{
	float				x, y, z;
	
	if (!_perAxis)
	{
		x = y = z = [uniformField floatValue];
	}
	else
	{
		x = [xField floatValue];
		y = [yField floatValue];
		z = [zField floatValue];
	}
	[_document scaleX:x/100.f y:y/100.f z:z/100.f];
	
	[NSApp endSheet:panel];
}


- (IBAction)cancelAction:(id)sender
{
	[NSApp endSheet:panel];
}

@end
