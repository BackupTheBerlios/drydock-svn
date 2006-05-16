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


#define RUN_PROBLEM_REPORTER_EXAMLE		0


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

#if TIGER_OR_LATER
	#define MySCRCanInstall		UnsanitySCR_CanInstall
	#define MySCRInstall		UnsanitySCR_Install
	#define UnloadSCR()			do {} while (0)
#else
	static Boolean MySCRCanInstall(Boolean* outOptionalAuthenticationWillBeRequired);
	static OSStatus MySCRInstall(UInt32 inInstallFlags);
	static void UnloadSCR(void);
#endif


#if RUN_PROBLEM_REPORTER_EXAMLE
static void RunProblemReporterExample(void);
#endif


static void RegisterMyHelpBook(void);


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
		
		// Other stuff that has to be done more or less at loading time:
		// Register help book. This is necessary for help buttons to work.
		RegisterMyHelpBook();
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
	
	if (nil == [defaults objectForKey:@"UKUpdateChecker:CheckAtStartup"])
	{
		toRun |= kFirstRunStage_askCheckForUpdates;
	}
	else
	{
		firstRunMask |= kFirstRunStage_askCheckForUpdates;
		[defaults setInteger:firstRunMask forKey:@"first run status"];
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
	
	#if RUN_PROBLEM_REPORTER_EXAMLE
		RunProblemReporterExample();
	#else
		if (0 == [[[NSDocumentController sharedDocumentController] documents] count]) [[NSApp delegate] runOpenPanel];
	#endif
	
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


#if !TIGER_OR_LATER

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
			
			sSCRHandle = dlopen([path fileSystemRepresentation], RTLD_NOW | RTLD_LOCAL);
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


#if RUN_PROBLEM_REPORTER_EXAMLE
#import "DDProblemReportManager.h"


static void RunProblemReporterExample(void)
{
	DDProblemReportManager		*mgr;
	
	mgr = [[DDProblemReportManager alloc] init];
#if 1	// English
	[mgr addWarningIssueWithKey:@"testWarningMessage" localizedFormat:[NSString stringWithUTF8String:"Things aren’t going too well. You really ought to know about it."]];
	[mgr addStopIssueWithKey:@"testStopMessage" localizedFormat:[NSString stringWithUTF8String:"Something terrible has happened! I just can’t go on like this."]];
#else	// Swedish
	[mgr addWarningIssueWithKey:@"testWarningMessage" localizedFormat:[NSString stringWithUTF8String:"Saker och ting går inte så bra, det skall du veta."]];
	[mgr addStopIssueWithKey:@"testStopMessage" localizedFormat:[NSString stringWithUTF8String:"Något hemskt har hänt! Jag klarar inte av det här."]];
#endif
	[mgr showReportApplicationModal];
	[mgr release];
}

#endif


static void RegisterMyHelpBook(void)
{
	NSURL						*url;
	FSRef						ref;
	
	url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	if (nil != url)
	{
		if (CFURLGetFSRef((CFURLRef)url, &ref))
		{
			AHRegisterHelpBook(&ref);
		}
	}
}
