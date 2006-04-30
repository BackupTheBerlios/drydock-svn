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
#import "Logging.h"
#import "DDUtilities.h"
#import "ddoolite.h"
#import <unistd.h>
#import <termios.h>


@implementation DDProblemReportManager

- (void)dealloc
{
	TraceEnter();
	
	[_issues release];
	
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
	id					result;
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
	id					result;
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
	id					result;
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


- (void)clear
{
	[_issues release];
	_issues = nil;
	_highestType = kNoteIssueType;
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


- (BOOL)showReportCommandLineQuietMode:(BOOL)inQuiet
{
	NSArray					*toDisplay;
	NSMutableArray			*errors;
	NSEnumerator			*issuesEnum;
	DDProblemReportIssue	*issue;
	uint32_t				count;
	int						answer;
	struct termios			term, old;
	
	if (inQuiet && _highestType < kStopIssueType) return YES;
	
	if (!inQuiet) toDisplay = _issues;
	else
	{
		errors = [NSMutableArray arrayWithCapacity:[_issues count]];
		for (issuesEnum = [_issues objectEnumerator]; issue = [issuesEnum nextObject]; )
		{
			if (kStopIssueType <= [issue type]) [errors addObject:issue];
		}
		toDisplay = errors;
	}
	
	count = [toDisplay count];
	if (0 == count)
	{
		return YES;
	}
	
	if (1 == count)
	{
		Print(@"An issue arose while %s:\n", (_context == kContextOpen) ? "reading" : "writing");
	}
	else
	{
		Print(@"The following issues arose while %s\n", (_context == kContextOpen) ? "reading" : "writing");
	}
	
	for (issuesEnum = [_issues objectEnumerator]; issue = [issuesEnum nextObject]; )
	{
		switch ([issue type])
		{
			case kNoteIssueType:
				Print(@"     Note: ");
				break;
			
			case kWarningIssueType:
				Print(@"  Warning: ");
				break;
			
			case kStopIssueType:
				Print(@"    Error: ");
				break;
			
			default:
				Print(@"       ??: ");
				break;
		}
		
		Print(@"%@\n", [issue string]);
	}
	
	if (kStopIssueType <= _highestType)
	{
		Print(@"\nThe nature of these issues is such that it is impossible to continue.\n");
		return NO;
	}
	else
	{
		if (isatty(0))
		{
			Print(@"\nDo you wish to continue? [Y/n]\n");
			
			tcgetattr(0, &term);
			old = term;
			cfmakeraw(&term);
			tcsetattr(0, TCSANOW, &term);
			answer = getchar();
			tcsetattr(0, TCSANOW, &old);
			
			if ('n' == answer || 'N' == answer) return NO;
		}
	}
	return YES;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{issues = %@}", [self className], self, _issues];
}

@end
