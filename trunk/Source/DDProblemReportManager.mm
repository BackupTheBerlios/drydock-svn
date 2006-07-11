/*
	DDProblemReportManager.mm
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

#import "DDProblemReportManager.h"
#import "DDApplicationDelegate.h"
#import "Logging.h"
#import "IconFamily.h"
#import "DDUtilities.h"


@interface DDProblemReportManager (Private)

- (void)prepareDialog;

// Delegate method only in Tiger and later
- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row;

@end


@implementation DDProblemReportManager

- (void)dealloc
{
	TraceEnter();
	
	[_issues release];
	[_noteImage release];
	[_warnImage release];
	[_stopImage release];
	if (NULL != _heights) free(_heights);
	
	[super dealloc];
	
	TraceExit();
}


- (void)addIssue:(DDProblemReportIssue *)inIssue
{
	TraceEnterMsg(@"Called with %@", inIssue);
	
	IssueType			type;
	
	if (nil != inIssue)
	{	
		if (nil == _issues) _issues = [[NSMutableArray alloc] init];
	}
	
	[_issues addObject:inIssue];
	
	type = [inIssue type];
	if (_highestType < type) _highestType = type;
	
	TraceExit();
}


- (void)addNoteIssueWithKey:(NSString *)inKey localizedFormat:(NSString *)inFormat, ...
{
	TraceEnter();
	
	va_list				args;
	DDProblemReportIssue *issue;
	
	va_start(args, inFormat);
	issue = [[DDProblemReportIssue alloc] initIssueOfType:kNoteIssueType withKey:inKey format:NSLocalizedString(inFormat, NULL) arguments:args];
	va_end(args);
	
	[self addIssue:issue];
	[issue release];
	
	TraceExit();
}


- (void)addWarningIssueWithKey:(NSString *)inKey localizedFormat:(NSString *)inFormat, ...
{
	TraceEnter();
	
	va_list				args;
	DDProblemReportIssue *issue;
	
	va_start(args, inFormat);
	issue = [[DDProblemReportIssue alloc] initIssueOfType:kWarningIssueType withKey:inKey format:NSLocalizedString(inFormat, NULL) arguments:args];
	va_end(args);
	
	[self addIssue:issue];
	[issue release];
	
	TraceExit();
}


- (void)addStopIssueWithKey:(NSString *)inKey localizedFormat:(NSString *)inFormat, ...
{
	TraceEnter();
	
	va_list				args;
	DDProblemReportIssue *issue;
	
	va_start(args, inFormat);
	issue = [[DDProblemReportIssue alloc] initIssueOfType:kStopIssueType withKey:inKey format:NSLocalizedString(inFormat, NULL) arguments:args];
	va_end(args);
	
	[self addIssue:issue];
	[issue release];
	
	TraceExit();
}


- (void)setContext:(ProblemReportContext)inContext
{
	if (inContext < kContextCount) _context = inContext;
}


- (void)prepareDialog
{
	TraceEnter();
	
	NSString				*string, *contextString1, *contextString2;
	unsigned				count, iter;
	NSSize					iconSize = {32, 32};
	float					curr, biggest;
	
	count = [_issues count];
	_heights = (float *)calloc(sizeof (float), count);
	
	// Load icons.
	_noteImage = [[[IconFamily iconFamilyWithSystemIcon:kAlertNoteIcon] imageWithAllReps] retain];
	[_noteImage setSize:iconSize];
	if (kWarningIssueType <= _highestType)
	{
		_warnImage = [[[IconFamily iconFamilyWithSystemIcon:kAlertCautionIcon] imageWithAllReps] retain];
		[_warnImage setSize:iconSize];
	}
	if (kStopIssueType <= _highestType)
	{
		_stopImage = [[[IconFamily iconFamilyWithSystemIcon:kAlertStopIcon] imageWithAllReps] retain];
		[_stopImage setSize:iconSize];
	}
	
	// Load nib.
	[NSBundle loadNibNamed:@"DDProblemReportManager" owner:self];
	
	// Set strings in dialog. First, load contextual bits:
	switch (_context)
	{
		case kContextSave:
			contextString1 = @"save the document";
			contextString2 = @"saving";
			break;
		
		case kContextOpen:
			contextString1 = @"open the document";
			contextString2 = @"opening";
			break;
		
		default:
			contextString1 = [NSString stringWithFormat:@"<unknown context %u>", _context];
			contextString2 = @"??ing";
	}
	
	contextString1 = NSLocalizedString(contextString1, NULL);
	contextString2 = NSLocalizedString(contextString2, NULL);
	
	// Set “title” string.
	if (1 == count) string = NSLocalizedString(@"An issue arose while attempting to %@:", NULL);
	else string = NSLocalizedString(@"Some issues arose while attempting to %@:", NULL);
	
	[titleField setObjectValue:[NSString stringWithFormat:string, contextString1]];
	
	// Set “question” string.
	if (kStopIssueType <= _highestType) string = NSLocalizedString(@"The nature of these issues is such that it is impossible to continue %@.", NULL);
	else string = NSLocalizedString(@"Do you wish to continue %@?", NULL);
	
	[questionField setObjectValue:[NSString stringWithFormat:string, contextString2]];
	
	// Select the buttons to show.
	if (_highestType <= kWarningIssueType)
	{
		// Show (Cancel) (Continue)
		[cancelButton2 removeFromSuperview];
	}
	else
	{
		// Show (Cancel)
		[cancelButton removeFromSuperview];
		[continueButton removeFromSuperview];
	}
	
	// Fiddle with view used to lay out text
	NSSize size = [layoutProxyTextView frame].size;
	size.height = 42;
	[layoutProxyTextView setMinSize:size];
	size.height = 480;
	[layoutProxyTextView setMaxSize:size];
	[layoutProxyTextView setVerticallyResizable:YES];
	[layoutProxyTextView setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	
	if (!TigerOrLater())
	{
		/*	Variable-height tables (- tableView:heightOfRow:) not supported; find maximum row height
			and set table row height to this instead.
		*/
		biggest = 42;
		for (iter = 0; iter != count; ++iter)
		{
			curr = [self tableView:tableView heightOfRow:iter];
			if (biggest < curr) biggest = curr;
		}
		
		[tableView setRowHeight:biggest];
	}
	
	[tableView reloadData];
	
	TraceExit();
}


- (BOOL)showReportApplicationModal
{
	TraceEnter();
	
	int					val = YES;
	
	if (nil != _issues)
	{
		[[NSApp delegate] inhibitOpenPanel];
		[self prepareDialog];
		[self retain];
		val = YES == [NSApp runModalForWindow:issuesPanel];
		[tableView setDataSource:nil];
		[issuesPanel orderOut:self];
		issuesPanel = nil;
		[self release];
		[[NSApp delegate] uninhibitOpenPanel];
	}
	
	return val;
	TraceExit();
}


- (void)runReportModalForWindow:(NSWindow *)inWindow modalDelegate:(id)inDelegate isDoneSelector:(SEL)inSelector
{
	TraceEnter();
	
	BOOL result;
	result = [self showReportApplicationModal];
	if (nil != inDelegate && NULL != inSelector)
	{
		[inDelegate performSelector:inSelector withObject:self withObject:(id)result];
	}
	
	TraceExit();
}


- (IBAction)continueAction:sender
{
	[NSApp stopModalWithCode:YES];
}


- (IBAction)cancelAction:sender
{
	[NSApp stopModalWithCode:NO];
}


- (IBAction)helpAction:sender
{
	NSString				*anchor = nil;
	NSIndexSet				*selection;
	unsigned int			index;
	DDProblemReportIssue	*issue;
	OSStatus				err;
	static NSString			*helpBookName = nil;
	
	// Find first selected row
	selection = [tableView selectedRowIndexes];
	index = [selection firstIndex];
	
	if (((unsigned int)NSNotFound) != index)
	{
		// Create anchor string
		issue = [_issues objectAtIndex:index];
		anchor = [issue key];
		if (nil != anchor) anchor = [@"problem-" stringByAppendingString:anchor];
	}
	
	if (nil == helpBookName)
	{
		helpBookName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"] retain];
	}
	
	err = AHGotoPage((CFStringRef)helpBookName, (CFStringRef)@"html/reference-errors.html", (CFStringRef)anchor);
	if (noErr != err) LogMessage(@"Error %i trying to look up help anchor \"%@\".", err, anchor);
}


- (IBAction)copy:sender
{
	NSIndexSet				*selection;
	unsigned int			index;
	DDProblemReportIssue	*issue;
	NSMutableString			*string;
	NSString				*type;
	unsigned				count = 0;
	NSPasteboard			*pBoard;
	
	// Find selected rows
	selection = [tableView selectedRowIndexes];
	if (nil != selection)
	{
		string = [NSMutableString string];
		
		for (index = [selection firstIndex];
			((unsigned int)NSNotFound) != index;
			index = [selection indexGreaterThanIndex:index])
		{
			issue = [_issues objectAtIndex:index];
			switch ([issue type])
			{
				case kNoteIssueType:
					type = @"Note";
					break;
				
				case kWarningIssueType:
					type = @"Warning";
					break;
				
				case kStopIssueType:
					type = @"Error";
					break;
				
				default:
					type = [NSString stringWithFormat:@"%u", [issue type]];
			}
			[string appendFormat:@"%s[%@ %@]: %@\n", count++ ? "\n" : "", type, [issue key], [issue string]];
		}
	}
	
	if (0 != count)
	{
		pBoard = [NSPasteboard generalPasteboard];
		[pBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		if (![pBoard setString:string forType:NSStringPboardType]) count = 0;
	}
	
	if (0 == count) AlertSoundPlay();
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)inItem
{
	SEL						action;
	
	action = [inItem action];
	if (action == @selector(copy:))
	{
		return 0 != [tableView numberOfSelectedRows];
	}
	
	return [super validateMenuItem:inItem];
}


- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_issues count];
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString				*identifier;
	DDProblemReportIssue	*issue;
	
	identifier = [tableColumn identifier];
	issue = [_issues objectAtIndex:row];
	
	if ([identifier isEqual:@"icon"])
	{
		switch ([issue type])
		{
			case kNoteIssueType:		return _noteImage;
			case kWarningIssueType:		return _warnImage;
			case kStopIssueType:		return _stopImage;
			default:					return nil;
		}
	}
	else if ([identifier isEqual:@"description"])
	{
		return [issue string];
	}
	else
	{
		LogMessage(@"Unknown identifier %@", identifier);
		return nil;
	}
}


- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row
{
	float result = 0;
	if (NULL != _heights)
	{
		result = _heights[row];
		if (0 == result)
		{
			// Calculate and cache value
			NSString *string = [[_issues objectAtIndex:row] string];
			[layoutProxyTextView setString:string];
			[layoutProxyTextView sizeToFit];
			result = [layoutProxyTextView frame].size.height + 4;
			_heights[row] = result;
		}
	}
	
	if (result < 48) result = 48;
	
	return result;
}


- (void)clear
{
	[_issues release];
	_issues = nil;
	_highestType = kNoteIssueType;
	[tableView reloadData];
}


- (void)mergeIssues:(DDProblemReportManager *)inSource
{
	if (nil == _issues)
	{
		_issues = inSource->_issues;
		inSource->_issues = nil;
	}
	else
	{
		[_issues addObjectsFromArray:inSource->_issues];
	}
	if (_highestType < inSource->_highestType) _highestType = inSource->_highestType;
	[inSource clear];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{issues = %@}", [self className], self, _issues];
}

@end
