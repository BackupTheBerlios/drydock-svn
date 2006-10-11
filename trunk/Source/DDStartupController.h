/*
	DDStartupController.h
	Dry Dock for Oolite
	$Id$
	
	Handles first-run configuration.
	
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

#import <Cocoa/Cocoa.h>

@class UKUpdateChecker;


@interface DDStartupController: NSObject
{
	IBOutlet NSWindow				*window;
	IBOutlet NSTabView				*stageTabView;
	IBOutlet NSButton				*continueButton;
	
	IBOutlet NSMatrix				*installSCRMatrix;
	IBOutlet NSTextField			*authorisationRequiredForSCRField;
	
	IBOutlet NSButton				*checkForUpdatesCheckBox;
	IBOutlet NSTextField			*updateFrequencyField;
	IBOutlet NSMatrix				*autoInstallMatrix;
	
	IBOutlet NSButton				*upgradeCheckForUpdatesCheckBox;
	IBOutlet NSTextField			*upgradeUpdateFrequencyField;
	IBOutlet NSMatrix				*upgradeAutoInstallMatrix;
	
	IBOutlet NSFormatter			*integerFormatter;
	
	BOOL							_haveAwoken;
	BOOL							_runningLastFirstRunPane;
}

- (IBAction)nextButtonAction:sender;
- (IBAction)quitButtonAction:sender;

- (IBAction)checkForUpdatesAction:sender;

@end
