/*
	DDFirstRunController.mm
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

#define ENABLE_TRACE 1

#import "DDFirstRunController.h"
#import "Logging.h"
#import "SmartCrashReportsInstall.h"
#import "DDApplicationDelegate.h"


/*	The steps of first-run configuration are recorded as a bitmask in user preferences. This allows
	new steps to be inserted in any sequence, and only new steps will be run for new versions.
*/
enum
{
	kFirstRunStage_askInstallSCR			= 0x00000001UL,
	kFirstRunStage_askCheckForUpdates		= 0x00000002UL
};


// Identifiers for tab view items in first-run wizard
static NSString *kFirstRunTab_askInstallSCR			= @"install SCR";
static NSString *kFirstRunTab_askCheckForUpdates	= @"check for updates";


@interface DDFirstRunController (Private)

- (void)runFirstRunWizardPane:(NSString *)inPane isLastPane:(BOOL)inIsLast;
- (void)doFirstRunIfAppropriate;

@end


@implementation DDFirstRunController

- (void)dealloc
{
	[firstRunWindow release];
	
	[super dealloc];
}


- (void)awakeFromNib
{
	TraceEnter();
	
	[[NSApp delegate] inhibitOpenPanel];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:NSApp];
	
	TraceExit();
}


- (void)applicationDidFinishLaunching:(NSNotification *)inNotification
{
	TraceEnter();
	
	if ([NSApp isActive]) [self doFirstRunIfAppropriate];
	else [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:NSApp];
	
	TraceExit();
}


- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	TraceEnter();
	
	[self doFirstRunIfAppropriate];
	
	TraceExit();
}


- (void)doFirstRunIfAppropriate
{
	TraceEnter();
	
	NSUserDefaults			*defaults;
	unsigned				firstRunMask;
	unsigned				toRun;
	unsigned				count = 0;
	BOOL					installSCR;
	BOOL					checkForUpdates;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	defaults = [NSUserDefaults standardUserDefaults];
	firstRunMask = [defaults integerForKey:@"first run status"];
	if ([defaults boolForKey:@"first-run test mode"])
	{
		firstRunMask = 0;
	}
	
	// Look for first-run actions which have not been performed
	if (!(firstRunMask & kFirstRunStage_askInstallSCR))
	{
		if (UnsanitySCR_CanInstall(NULL))
		{
			++count;
			toRun |= kFirstRunStage_askInstallSCR;
		}
	}
	
	if (!(firstRunMask & kFirstRunStage_askCheckForUpdates))
	{
		/*	Check for presence of "UKUpdateChecker:CheckAtStartup" key. This will have been set
			without the first run status being set if the user has previously run version 0.06.
			Since 0.06 is an early release with (at the time of writing) 7 downloads, this check
			can probably be removed eventually.
		*/
		
		if (nil != [defaults objectForKey:@"UKUpdateChecker:CheckAtStartup"])
		{
			firstRunMask |= kFirstRunStage_askCheckForUpdates;
		}
		else
		{
			++count;
			toRun |= kFirstRunStage_askCheckForUpdates;
		}
	}
	
	// Run "Install SCR" pane if required
	if (toRun & kFirstRunStage_askInstallSCR)
	{
		[self runFirstRunWizardPane:kFirstRunTab_askInstallSCR isLastPane:!--count];
		if (nil != firstRunInstallSCRMatrix)
		{
			installSCR = [[firstRunInstallSCRMatrix selectedCell] tag];
			if (installSCR)
			{
				UnsanitySCR_Install(kUnsanitySCR_GlobalInstall | kUnsanitySCR_DoNotPresentInstallUI);
			}
			
			// Record the fact that we've done this
			firstRunMask |= kFirstRunStage_askInstallSCR;
			[defaults setInteger:firstRunMask forKey:@"first run status"];
			[defaults synchronize];
		}
	}
	
	// Run "Check for Updates" pane if required
	if (toRun & kFirstRunStage_askCheckForUpdates)
	{
		[self runFirstRunWizardPane:kFirstRunTab_askCheckForUpdates isLastPane:!--count];
		if (nil != firstRunCheckForUpdatesMatrix)
		{
			checkForUpdates = [[firstRunCheckForUpdatesMatrix selectedCell] tag];
			[defaults setInteger:checkForUpdates forKey:@"UKUpdateChecker:CheckAtStartup"];
			
			// Record the fact that we've done this
			firstRunMask |= kFirstRunStage_askCheckForUpdates;
			[defaults setInteger:firstRunMask forKey:@"first run status"];
			[defaults synchronize];
		}
	}
	
	[firstRunWindow release];
	firstRunWindow = nil;
	
	[[NSApp delegate] uninhibitOpenPanel];
	[[NSApp delegate] runOpenPanel];
	
	[self release];
	
	TraceExit();
}


- (void)runFirstRunWizardPane:(NSString *)inPane isLastPane:(BOOL)inIsLast
{
	TraceEnterMsg(@"Called for %@", inPane);
	
	if (nil == firstRunWindow)
	{
		// Load first run window
		[NSBundle loadNibNamed:@"DDFirstRun" owner:self];
	}
	
	TraceExit();
}


- (IBAction)firstRunNextButtonAction:sender
{
	
}


- (IBAction)firstRunQuitButtonAction:sender
{
	
}

@end
