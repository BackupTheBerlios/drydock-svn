/*
	DDApplication.mm
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

#import "DDApplication.h"
#import "DDInspectorController.h"
#import "Logging.h"


@implementation DDApplication


- (IBAction)orderFrontStandardAboutPanel:(id)sender
{
	NSDictionary			*options = nil;
	NSString				*displayName;
	
	displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	if (nil != displayName) options = [NSDictionary dictionaryWithObject:displayName forKey:@"ApplicationName"];
	
	[self orderFrontStandardAboutPanelWithOptions:options];
}


- (IBAction)showInspector:sender
{
	[inspectorController bringInspectorToFront];
}


- (IBAction)showReleaseNotes:sender
{
	if (!_haveLoadedReleaseNotes)
	{
		NSString			*path;
		
		path = [[NSBundle mainBundle] pathForResource:@"Read Me" ofType:@"rtf"];
		if (![releaseNotesView readRTFDFromFile:path]) return;
		_haveLoadedReleaseNotes = YES;
	}
	
	[releaseNotesWindow makeKeyAndOrderFront:nil];
}

@end

