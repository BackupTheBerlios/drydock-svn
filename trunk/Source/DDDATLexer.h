/*
	DDDATLexer.h
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
#import <stdio.h>

@class DDProblemReportManager;


@interface DDDATLexer: NSObject
{
@private
	const char				*_cursor;
	const char				*_end;
	size_t					_tokenLength;
	NSData					*_data;
	unsigned				_lineNumber;
	NSString				*_tokenString;
}

- (id)initWithURL:(NSURL *)inURL issues:(DDProblemReportManager *)ioIssues;
- (id)initWithPath:(NSString *)inPath issues:(DDProblemReportManager *)ioIssues;
- (id)initWithData:(NSData *)inData issues:(DDProblemReportManager *)ioIssues;

- (unsigned) lineNumber;

- (NSString *) currentTokenString;

- (NSString *)nextToken;

// Somewhat more efficient than comparing an NSString.
- (BOOL) expectLiteral:(const char *)literal;

- (BOOL)readInteger:(unsigned *)outInt;
- (BOOL)readReal:(float *)outReal;
- (BOOL)readString:(NSString **)outString;

@end
