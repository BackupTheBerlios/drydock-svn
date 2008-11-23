//
//  main.m
//  Dry Dock
//
//  Created by Jens Ayton on 2005-04-17.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "DDUtilities.h"

static int VersionCheck(void);


int main(int argc, char *argv[])
{
	int			result;
	
	result = VersionCheck();
    if (EXIT_SUCCESS == result)  result = NSApplicationMain(argc, (const char **) argv);
	
	return result;
}


#if LEOPARD_OR_LATER
#define ERR_STR		CFSTR("Dry Dock requires Mac OS X 10.5 or later.")
#define EXPL_STR	CFSTR("It is not possible to use Dry Dock on versions of Mac OS X prior to Mac OS X 10.5.")
#define ALERT_PARAM_REC_VERSION_2	1
#else
#define	ERR_STR		CFSTR("Dry Dock requires Mac OS X 10.4 or later.")
#define EXPL_STR	CFSTR("It is not possible to use Dry Dock on versions of Mac OS X prior to Mac OS X 10.4.")
#define ALERT_PARAM_REC_VERSION_2	0
#endif


static int VersionCheck(void)
{
	int						result;
	OSStatus				err;
	SInt32					version = 0;
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
#if ALERT_PARAM_REC_VERSION_2
		,NULL		// icon
#endif
	};
	DialogRef				alert = NULL;
	
	err = Gestalt(gestaltSystemVersion, &version);
	if (err || version < 0x1050)
	{
		result = EXIT_FAILURE;
		if (err) NSLog(@"Version check: error %i from Gestalt(), treating as pre-Tiger system.", (int)err);
		else NSLog(@"gestaltSystemVersion = %.4X", version);
		
		errStr = CFCopyLocalizedString(ERR_STR, NULL);
		explStr = CFCopyLocalizedString(EXPL_STR, NULL);
		
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
