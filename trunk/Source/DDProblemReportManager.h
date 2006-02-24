/*
	DDProblemReportManager.h
	Dry Dock for Oolite
	$Id$
	
	Collects DDProblemReportIssues and presents them as a dialog.
	
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
#import "DDProblemReportIssue.h"


typedef enum
{
	kContextSave = 0UL,
	kContextOpen,
	
	kContextCount
} ProblemReportContext;


@interface DDProblemReportManager: NSObject
{
	IBOutlet NSPanel			*issuesPanel;
	IBOutlet NSButton			*continueButton;
	IBOutlet NSButton			*cancelButton;
	IBOutlet NSButton			*cancelButton2;
	IBOutlet NSTextField		*titleField;
	IBOutlet NSTextField		*questionField;
	IBOutlet NSScrollView		*scrollView;
	IBOutlet NSTableView		*tableView;
	IBOutlet NSTextView			*layoutProxyTextView;
	
	NSMutableArray				*_issues;
	
	ProblemReportContext		_context;
	
	NSImage						*_noteImage,
								*_warnImage,
								*_stopImage;
	
	id							_modalDelegate;
	SEL							_selector;
	
	float						*_heights;
	
	IssueType					_highestType;
}

- (void)addIssue:(DDProblemReportIssue *)inIssue;
- (void)addNoteIssueWithKey:(NSString *)inKey localizedFormat:(NSString *)inFormat, ...;
- (void)addWarningIssueWithKey:(NSString *)inKey localizedFormat:(NSString *)inFormat, ...;
- (void)addStopIssueWithKey:(NSString *)inKey localizedFormat:(NSString *)inFormat, ...;

- (void)mergeIssues:(DDProblemReportManager *)inSource;

- (void)setContext:(ProblemReportContext)inContext;

// isDoneSelector should have the signature -(void)problemReport:(DDProblemReportManager*)inManager doneWithResult:(BOOL)inResult;
- (void)runReportModalForWindow:(NSWindow *)inWindow modalDelegate:(id)inDelegate isDoneSelector:(SEL)inSelector;
- (BOOL)showReportApplicationModal;

- (IBAction)continueAction:sender;
- (IBAction)cancelAction:sender;
- (IBAction)helpAction:sender;

- (void)clear;

@end
