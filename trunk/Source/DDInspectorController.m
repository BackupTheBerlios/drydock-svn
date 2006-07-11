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


static id		sSharedController = nil;
static BOOL		sHaveShownWindow = NO;


@interface DDInspectorController(Private)

- (void)updateInspector;
- (void)constrainWindowToScreen;

@end


@implementation DDInspectorController

- (id)init
{
	self = [super init];
	sSharedController = self;
	return self;
}


+ (id)sharedController
{
	return sSharedController;
}


- (void)awakeFromNib
{
	NSNotificationCenter		*nctr;
	NSUserDefaults				*prefs;
	
	nctr = [NSNotificationCenter defaultCenter];
	[nctr addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:nil];
	[nctr addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:nil];
	[nctr addObserver:self selector:@selector(windowDidMove:) name:NSWindowDidMoveNotification object:nil];
	
	prefs = [NSUserDefaults standardUserDefaults];
	if ([prefs boolForKey:@"inspector palette visible"])
	{
		// Wait until event cycle passes before showing
		[self performSelector:@selector(bringInspectorToFront) withObject:nil afterDelay:0.01];
	}
}


- (void)bringInspectorToFront
{
	NSUserDefaults				*prefs;
	NSArray						*position;
	NSPoint						point;
	NSRect						frame;
	NSRect						screenFrame;
	NSScreen					*screen;
	
	if (![window isVisible])
	{
		prefs = [NSUserDefaults standardUserDefaults];
		if (!sHaveShownWindow)
		{
			position = [prefs objectForKey:@"inspector palette position"];
			if (nil != position)
			{
				@try
				{
					point.x = [[position objectAtIndex:0] intValue];
					point.y = [[position objectAtIndex:1] intValue];
					
					frame = [window frame];
					frame.origin.x = point.x;
					frame.origin.y = point.y - frame.size.height;
					
					[window setFrame:frame display:NO];
					[self constrainWindowToScreen];
				}
				@catch (id foo) {}
			}
			else
			{
				// No stored position; generate default
				screen = [NSScreen mainScreen];
				screenFrame = [screen visibleFrame];
				frame = [window frame];
				
				// Default position is top right of main screen
				frame.origin.y = screenFrame.origin.y + screenFrame.size.height - frame.size.height - 6;
				frame.origin.x = screenFrame.origin.x + screenFrame.size.width - frame.size.width - 6;
				
				[window setFrame:frame display:NO];
			}
			sHaveShownWindow = YES;
		}
		[prefs setBool:YES forKey:@"inspector palette visible"];
	}
	
	[self updateInspector];
	[window makeKeyAndOrderFront:nil];
}


- (BOOL)windowShouldClose:(id)sender
{
	NSUserDefaults				*prefs;
	prefs = [NSUserDefaults standardUserDefaults];
	[prefs setBool:NO forKey:@"inspector palette visible"];
	return YES;
}


- (void)windowDidMove:(NSNotification *)notification
{
	NSRect						frame;
	NSPoint						topLeft;
	NSArray						*array;
	
	if (!sHaveShownWindow) return;
	
	frame = [window frame];
	topLeft = frame.origin;
	topLeft.y += frame.size.height;
	
	array = [NSArray arrayWithObjects:
			[NSNumber numberWithFloat:topLeft.x],
			[NSNumber numberWithFloat:topLeft.y],
			nil];
	
	[[NSUserDefaults standardUserDefaults] setObject:array forKey:@"inspector palette position"];
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


- (void)windowDidResignMain:(NSNotification *)notification
{
	NSWindow					*theWindow;
	
	theWindow = [notification object];
	if (_mainWindow == theWindow)
	{
		_mainWindow = nil;
		if ([window isVisible]) [self objectToInspectChanged];
	}
}


- (void)objectToInspectChanged
{
	// Wait until event cycle passes before updating
	[self performSelector:@selector(updateInspector) withObject:nil afterDelay:0.01];
}


- (void)updateInspector
{
	NSView					*inspectorView;
	NSRect					windowFrame, oldPaneFrame, newPaneFrame;
	float					deltaHeight;
	
	[_activeInspectorPane autorelease];
	_activeInspectorPane = [[[_mainWindow objectToInspect] inspector] retain];
	inspectorView = [_activeInspectorPane inspectorView];
	if (nil == inspectorView) inspectorView = defaultView;
	
	if (_activeInspectorView != inspectorView)
	{
		windowFrame = [window frame];
		if (nil != _activeInspectorView)
		{
			oldPaneFrame = [_activeInspectorView frame];
		}
		else
		{
			oldPaneFrame = [defaultView frame];
		}
		newPaneFrame = [inspectorView frame];
		deltaHeight = newPaneFrame.size.height - oldPaneFrame.size.height;
		windowFrame.size.height += deltaHeight;
		windowFrame.origin.y -= deltaHeight;
		
		[window setContentView:inspectorView];
		[window setFrame:windowFrame display:YES];
		
		if (0 < deltaHeight)
		{
			[self constrainWindowToScreen];
		}
		
		[_activeInspectorView autorelease];
		_activeInspectorView = [inspectorView retain];
	}
}


- (void)constrainWindowToScreen
{
	NSRect					frame;
	
	frame = [window frame];
	frame = [window constrainFrameRect:frame toScreen:[window screen]];
	[window setFrame:frame display:YES];
}

@end


@implementation NSWindow (InspectorSupport)

- (id<DDInspectable>)objectToInspect
{
	return [[self windowController] objectToInspect];
}

@end


@implementation NSWindowController (InspectorSupport)

- (id<DDInspectable>)objectToInspect
{
	return nil;
}

@end
