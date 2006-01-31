//
//  main.m
//  Dry Dock
//
//  Created by Jens Ayton on 2005-04-17.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

static int VersionCheck(void);


int main(int argc, char *argv[])
{
	int			result;
	
	result = VersionCheck();
    if (EXIT_SUCCESS == result) result = NSApplicationMain(argc, (const char **) argv);
	
	return result;
}


static int VersionCheck(void)
{
	int						result;
	OSStatus				err;
	long					version;
	CFStringRef				errStr, explStr;
	AlertStdCFStringAlertParamRec alertParam =
							{
								kStdCFStringAlertVersionOne,
								true,		// moveable
								false,		// helpButton
								(CFStringRef)kAlertDefaultOKText,
								NULL,		// cancelText
								NULL,		// otherText
								kAlertStdAlertOKButton,
								0,			// cancelButton
								kWindowDefaultPosition,
								0			// flags
							};
	DialogRef				alert = NULL;
	
	err = Gestalt(gestaltSystemVersion, &version);
	if (err || version < 0x1040)
	{
		result = EXIT_FAILURE;
		if (err) NSLog(@"Version check: error %i from Gestalt(), treating as pre-Tiger system.", (int)err);
		else NSLog(@"gestaltSystemVersion = %.4X", version);
		
		errStr = CFCopyLocalizedString(CFSTR("Dry Dock requires Mac OS X 10.4 or later."), NULL);
		explStr = CFCopyLocalizedString(CFSTR("Dry Dock uses certain features specific to Mac OS X 10.4. If you feel this is a problem, please e-mail a request that this change."), NULL);
		
		err = CreateStandardAlert(kAlertStopAlert, errStr, explStr, &alertParam, &alert);
		if (!err) err = RunStandardAlert(alert, NULL, NULL);
		
		if (err) NSLog(@"Version check: error %i showing alert.");
	}
	else
	{
		result = EXIT_SUCCESS;
	}
	
	return result;
}
