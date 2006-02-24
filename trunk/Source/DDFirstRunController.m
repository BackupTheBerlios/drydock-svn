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

#define ENABLE_TRACE 0
#define DLOPEN_NO_WARN

#import "DDFirstRunController.h"
#import "Logging.h"
#import "SmartCrashReportsInstall.h"
#import "DDApplicationDelegate.h"
#import "DDUtilities.h"
#import "UKUpdateChecker.h"
#import <dlfcn.h>


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
static NSString *kFirstRunTab_finished				= @"finished";

#if TARGET_CPU_PPC
	static Boolean MySCRCanInstall(Boolean* outOptionalAuthenticationWillBeRequired);
	static OSStatus MySCRInstall(UInt32 inInstallFlags);
	static void UnloadSCR(void);
#else
	// OS X on non-PPC processors will always be Tiger or later, so we can hard-link SCR
	#define MySCRCanInstall		UnsanitySCR_CanInstall
	#define MySCRInstall		UnsanitySCR_Install
	#define UnloadSCR()			do {} while (0)
#endif


@interface DDFirstRunController (Private)

- (void)doFirstRunIfAppropriate;

- (void)loadWizard;	// Needed if setting things up before running the pane
- (void)runFirstRunWizardPane:(NSString *)inPane;
- (void)finishWizard;

@end


@implementation DDFirstRunController

- (void)dealloc
{
	[window release];
	
	[super dealloc];
}


- (void)awakeFromNib
{
	TraceEnter();
	
	if (!_haveAwoken)
	{
		_haveAwoken = YES;
		[[NSApp delegate] inhibitOpenPanel];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:NSApp];
	}
	
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
	unsigned				toRun = 0;
	BOOL					userResponse;
	Boolean					authRequired = NO;
	BOOL					canInstallSCR;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	defaults = [NSUserDefaults standardUserDefaults];
	firstRunMask = [defaults integerForKey:@"first run status"];
	
	// Look for first-run actions which have not been performed
	canInstallSCR = MySCRCanInstall(&authRequired);
	if (canInstallSCR && ([defaults boolForKey:@"installed SCR"] || !(firstRunMask & kFirstRunStage_askInstallSCR)))
	{
		toRun |= kFirstRunStage_askInstallSCR;
	}
	
	if (!(firstRunMask & kFirstRunStage_askCheckForUpdates))
	{
		/*	Check for presence of "UKUpdateChecker:CheckAtStartup" key. This will have been set
			without the first run status being set if the user has previously run version 0.06.
			Since 0.06 is an early release with (at the time of writing) 7 downloads, this check
			can probably be removed eventually.
		*/
		
		if (nil == [defaults objectForKey:@"UKUpdateChecker:CheckAtStartup"])
		{
			toRun |= kFirstRunStage_askCheckForUpdates;
		}
		else
		{
			firstRunMask |= kFirstRunStage_askCheckForUpdates;
			[defaults setInteger:firstRunMask forKey:@"first run status"];
		}
	}
	
	// Run "Install SCR" pane if required
	if (toRun & kFirstRunStage_askInstallSCR)
	{
		TraceMessage(@"Running Install SCR pane.");
		
		[self loadWizard];
		[authorisationRequiredForSCRField setHidden:!authRequired];
		[self runFirstRunWizardPane:kFirstRunTab_askInstallSCR];
		
		if (nil != installSCRMatrix)
		{
			userResponse = [[installSCRMatrix selectedCell] tag];
			if (userResponse)
			{
				MySCRInstall(kUnsanitySCR_DoNotPresentInstallUI);
			}
			
			// Record the fact that we've done this
			firstRunMask |= kFirstRunStage_askInstallSCR;
			[defaults setInteger:firstRunMask forKey:@"first run status"];
			[defaults setBool:YES forKey:@"installed SCR"];
		}
	}
	
	UnloadSCR();
	
	// Run "Check for Updates" pane if required
	if (toRun & kFirstRunStage_askCheckForUpdates)
	{
		TraceMessage(@"Running Ask for Updates pane.");
		
		[self runFirstRunWizardPane:kFirstRunTab_askCheckForUpdates];
		
		if (nil != checkForUpdatesMatrix)
		{
			userResponse = [[checkForUpdatesMatrix selectedCell] tag];
			[defaults setInteger:userResponse forKey:@"UKUpdateChecker:CheckAtStartup"];
			
			// Record the fact that we've done this
			firstRunMask |= kFirstRunStage_askCheckForUpdates;
			[defaults setInteger:firstRunMask forKey:@"first run status"];
		}
	}
	
	[defaults synchronize];
	[self finishWizard];
	
	TraceMessage(@"First run complete.");
	
	[[NSApp delegate] uninhibitOpenPanel];
	if (0 == [[[NSDocumentController sharedDocumentController] documents] count]) [[NSApp delegate] runOpenPanel];
	
	[self release];
	[updateChecker doLaunchStuff];
	
	TraceExit();
}


- (void)runFirstRunWizardPane:(NSString *)inPane
{
	TraceEnterMsg(@"Called for \"%@\"", inPane);
	
	BOOL					OK = YES;
	
	if (nil == window)
	{
		// Load first run window
		[self loadWizard];
		if (nil == window) OK = NO;
	}
	
	if (OK)
	{
		@try
		{
			[stageTabView selectTabViewItemWithIdentifier:inPane];
		}
		@catch (id whatever)
		{
			OK = NO;
		}
	}
	
	if (OK)
	{
		[NSApp runModalForWindow:window];
	}
	
	TraceExit();
}


- (void)loadWizard
{
	[NSBundle loadNibNamed:@"DDFirstRun" owner:self];
}


- (void)finishWizard
{
	if (nil != window)
	{
		[continueButton setTitle:NSLocalizedString(@"Done", NULL)];
		[self runFirstRunWizardPane:kFirstRunTab_finished];
		
		[window orderOut:nil];
		[window release];
		window = nil;
	}
}


- (IBAction)nextButtonAction:sender
{
	[NSApp stopModal];
}


- (IBAction)quitButtonAction:sender
{
	[NSApp terminate:nil];
}

@end


#if TARGET_CPU_PPC

typedef enum
{
	kState_unloaded,
	kState_unavailable,
	kState_available
} SCRLoadState;

static SCRLoadState			sSCRLoadState = kState_unloaded;
static void					*sSCRHandle = NULL;


static SCRLoadState LoadSCR(void);

static Boolean (*SCR_CanInstall)(Boolean* outOptionalAuthenticationWillBeRequired) = NULL;
static OSStatus (*SCR_Install)(UInt32 inInstallFlags) = NULL;


static Boolean MySCRCanInstall(Boolean* outOptionalAuthenticationWillBeRequired)
{
	TraceEnter();
	
	if (kState_available == LoadSCR())
	{
		return SCR_CanInstall(outOptionalAuthenticationWillBeRequired);
	}
	else
	{
		if (NULL != outOptionalAuthenticationWillBeRequired) *outOptionalAuthenticationWillBeRequired = NO;
		return NO;
	}
	TraceExit();
}


static OSStatus MySCRInstall(UInt32 inInstallFlags)
{
	TraceEnter();
	
	if (kState_available == LoadSCR())
	{
		return SCR_Install(inInstallFlags);
	}
	else
	{
		return unimpErr;
	}
	TraceExit();
}


SCRLoadState LoadSCR(void)
{
	TraceEnter();
	
	if (kState_unloaded == sSCRLoadState)
	{
		sSCRLoadState = kState_unavailable;
		
		if (TigerOrLater())
		{
			// On Tiger; try loading the library
			NSString			*path;
			
			path = [[NSBundle mainBundle] privateFrameworksPath];
			path = [path stringByAppendingPathComponent:@"libSmartCrashReportsInstall.dylib"];
			
			sSCRHandle = dlopen([path fileSystemRepresentation], RTLD_LAZY | RTLD_LOCAL);
			if (NULL == sSCRHandle)
			{
				LogMessage(@"Failed to load libSmartCrashReportsInstall (%s).", dlerror());
				sSCRLoadState = kState_unavailable;
			}
			else
			{
				SCR_CanInstall = dlsym(sSCRHandle, "UnsanitySCR_CanInstall");
				SCR_Install = dlsym(sSCRHandle, "UnsanitySCR_Install");
				if (NULL != SCR_CanInstall && NULL != SCR_Install)
				{
					TraceMessage(@"Successfully loaded libSmartCrashReportsInstall.");
					sSCRLoadState = kState_available;
				}
				else
				{
					LogMessage(@"Failed to load symbols from libSmartCrashReportsInstall (%s).", dlerror());
				}
			}
		}
	}
	
	return sSCRLoadState;
	TraceExit();
}


static void UnloadSCR(void)
{
	TraceEnter();
	
	if (NULL != sSCRHandle)
	{
		dlclose(sSCRHandle);
		sSCRHandle = NULL;
		SCR_CanInstall = NULL;
		SCR_Install = NULL;
		sSCRLoadState = kState_unloaded;
	}
	
	TraceExit();
}

#endif
