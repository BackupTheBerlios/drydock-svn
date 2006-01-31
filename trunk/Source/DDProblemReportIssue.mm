/*
	DDProblemReportIssue.mm
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

#import "DDProblemReportIssue.h"


@implementation DDProblemReportIssue

+ (id)noteIssueWithKey:(NSString *)inKey format:(NSString *)inFormat, ...
{
	va_list				args;
	id					result;
	
	va_start(args, inFormat);
	result = [[[self alloc] initIssueOfType:kNoteIssueType withKey:inKey format:inFormat arguments:args] autorelease];
	va_end(args);
	
	return result;
}


+ (id)warningIssueWithKey:(NSString *)inKey format:(NSString *)inFormat, ...
{
	va_list				args;
	id					result;
	
	va_start(args, inFormat);
	result = [[[self alloc] initIssueOfType:kWarningIssueType withKey:inKey format:inFormat arguments:args] autorelease];
	va_end(args);
	
	return result;
}


+ (id)stopIssueWithKey:(NSString *)inKey format:(NSString *)inFormat, ...
{
	va_list				args;
	id					result;
	
	va_start(args, inFormat);
	result = [[[self alloc] initIssueOfType:kStopIssueType withKey:inKey format:inFormat arguments:args] autorelease];
	va_end(args);
	
	return result;
}


- (id)initIssueOfType:(IssueType)inType withKey:(NSString *)inKey Format:(NSString *)inFormat, ...
{
	va_list				args;
	
	va_start(args, inFormat);
	self = [self initIssueOfType:inType withKey:inKey format:inFormat arguments:args];
	va_end(args);
	
	return self;
}


- (id)initIssueOfType:(IssueType)inType withKey:(NSString *)inKey format:(NSString *)inFormat arguments:(va_list)inArgs
{
	NSString			*string;
	
	string = [[[NSString alloc] initWithFormat:inFormat arguments:inArgs] autorelease];
	return [self initIssueOfType:inType withKey:inKey string:string];
}


// Designated initialiser
- (id)initIssueOfType:(IssueType)inType withKey:(NSString *)inKey string:(NSString *)inString
{
	if (kIssueTypeCount <= inType || nil == inString)
	{
		[self release];
		self = nil;
	}
	else
	{
		self = [super init];
		if (nil != self)
		{
			_type = inType;
			_string = [inString copy];
			_key = [inKey copy];
		}
	}
	
	return self;
}


- (void)dealloc
{
	[_string autorelease];
	[_key autorelease];
	
	[super dealloc];
}


- (IssueType)type
{
	return _type;
}


- (NSString *)string
{
	return _string;
}


- (NSString *)key
{
	return _key;
}


- (NSString *)description
{
	const char			*typeString;
	
	switch (_type)
	{
		case kNoteIssueType:
			typeString = "Note";
			break;
		
		case kWarningIssueType:
			typeString = "Warning";
			break;
		
		case kStopIssueType:
			typeString = "Stop";
			break;
		
		default:
			typeString = "Unkown Type";
			break;
	}
	
	return [NSString stringWithFormat:@"<%@, %p>{%s, %@, \"%@\"}", [self className], self, typeString, _key, _string];
}

@end
