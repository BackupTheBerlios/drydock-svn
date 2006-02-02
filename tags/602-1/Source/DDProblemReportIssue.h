/*
	DDProblemReportIssue.h
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

#import <Foundation/Foundation.h>
#import <stdarg.h>

typedef enum
{
	kNoteIssueType = 0UL,
	kWarningIssueType,
	kStopIssueType,
	
	kIssueTypeCount
} IssueType;


@interface DDProblemReportIssue: NSObject
{
	NSString				*_string;
	NSString				*_key;
	IssueType				_type;
}

+ (id)noteIssueWithKey:(NSString *)inKey format:(NSString *)inFormat, ...;
+ (id)warningIssueWithKey:(NSString *)inKey format:(NSString *)inFormat, ...;
+ (id)stopIssueWithKey:(NSString *)inKey format:(NSString *)inFormat, ...;

- (id)initIssueOfType:(IssueType)inType withKey:(NSString *)inKey format:(NSString *)inFormat, ...;
- (id)initIssueOfType:(IssueType)inType withKey:(NSString *)inKey format:(NSString *)inFormat arguments:(va_list)inArgs;
- (id)initIssueOfType:(IssueType)inType withKey:(NSString *)inKey string:(NSString *)inString;

- (IssueType)type;
- (NSString *)key;
- (NSString *)string;

@end
