/*
	DDInspectorController.mm
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

#import "DDInspectorController.h"
#import "Logging.h"


@interface DDInspectorController(Private)

- (void)updateInspector;

@end


@implementation DDInspectorController

- (void)awakeFromNib
{
	NSNotificationCenter		*nctr;
	
	nctr = [NSNotificationCenter defaultCenter];
	[nctr addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:nil];
}


- (void)bringInspectorToFront
{
	[self updateInspector];
	[window makeKeyAndOrderFront:nil];
}


- (void)windowDidBecomeMain:(NSNotification *)notification
{
	NSWindow					*newMain;
	
	newMain = [notification object];
	if (newMain != _mainWindow)
	{
		_mainWindow = newMain;
		if ([window isVisible]) [self updateInspector];
	}
}


- (void)updateInspector
{
	NSView						*inspector = nil;
	NSView						*temp;
	NSRect						frame;
	
	inspector = [[_mainWindow objectToInspect] inspector];
	
	if (nil == inspector) inspector = defaultView;
	
	if (_activeInspectorView != inspector)
	{
		frame = [inspector frame];
		temp = [[[NSView alloc] initWithFrame:frame] autorelease];
		[window setContentView:temp];
		[window setContentSize:frame.size];
		[window setContentView:inspector];
	}
}

@end


@implementation NSWindow (InspectorSupport)

- (id<DDInspectable>)objectToInspect
{
	return nil;
}

@end
