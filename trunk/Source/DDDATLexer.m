/*
	DDDATLexer.m
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2010 Jens Ayton

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

#import "DDDATLexer.h"
#import "DDProblemReportManager.h"
#import "DDErrorDescription.h"
#import "Logging.h"


static inline BOOL ParseUnsignedInt(const char *string, size_t length, unsigned *value) __attribute__((always_inline));


@interface DDDATLexer (Private)

- (BOOL)advance;

- (NSString *)describeToken;

@end


@implementation DDDATLexer

- (id)initWithURL:(NSURL *)inURL issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	if ([inURL isFileURL])
	{
		NSError *error = nil;
		NSData *data = [[NSData alloc] initWithContentsOfURL:inURL options:0 error:&error];
		if (data == nil)
		{
			[ioIssues addStopIssueWithKey:@"noReadFile" localizedFormat:@"The document could not be loaded, because an error occurred: %@", [error localizedDescription]];
			return nil;
		}
		return [self initWithData:data issues:ioIssues];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"DDDATLexer does not support non-file URLs such as %@", [inURL absoluteURL]];
	}
	
	TraceExit();
	return nil;
}


- (id)initWithPath:(NSString *)inPath issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	return [self initWithURL:[NSURL fileURLWithPath:inPath] issues:ioIssues];
	
	TraceExit();
	return self;
}


- (id)initWithData:(NSData *)inData issues:(DDProblemReportManager *)ioIssues
{
	if ([inData length] == 0)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_data = [inData retain];
		_cursor = [inData bytes];
		_end = _cursor + [inData length];
		_tokenLength = 0;
		_lineNumber = 1;
	}
	
	return self;
}


- (void)dealloc
{
	TraceEnter();
	
	[_data release];
	[_tokenString release];
	
	[super dealloc];
	TraceExit();
}


- (unsigned) lineNumber
{
	return _lineNumber;
}


- (NSString *) currentTokenString
{
	TraceEnter();
	
	if (_tokenString == nil)
	{
		_tokenString = [[NSString alloc] initWithBytes:_cursor length:_tokenLength encoding:NSUTF8StringEncoding];
		if (_tokenString == nil)
		{
			_tokenString = [[NSString alloc] initWithBytes:_cursor length:_tokenLength encoding:NSISOLatin1StringEncoding];
		}
	}
	TraceExit();
	
	return _tokenString;
}


- (NSString *)nextToken
{
	TraceEnter();
	
	if ([self advance])
	{
		return [self currentTokenString];
	}
	
	TraceExit();
	
	return nil;
}


- (BOOL) expectLiteral:(const char *)literal
{
	TraceEnter();
	
	if ([self advance])
	{
		return (strncmp(literal, _cursor, _tokenLength) == 0);
	}
	
	TraceExit();
	return NO;
}


- (BOOL)readInteger:(unsigned *)outInt
{
	TraceEnter();
	
	NSParameterAssert(outInt != NULL);
	
	[self advance];
	return ParseUnsignedInt(_cursor, _tokenLength, outInt);
	
	TraceExit();
	return YES;
}


- (BOOL)readReal:(float *)outReal
{
	TraceEnter();
	
	NSParameterAssert(outReal != NULL);
	
	NSString *token = [self nextToken];
	if (token == nil)  return NO;
	
	*outReal = [token floatValue];
	
	TraceExit();
	return YES;
}


- (BOOL)readString:(NSString **)outString
{
	TraceEnter();
	
	NSParameterAssert(outString != NULL);
	
	NSString *token = [self nextToken];
	if (token == nil)  return NO;
	
	*outString = [[token retain] autorelease];
	
	TraceExit();
	return YES;
}


static inline BOOL IsSeparatorChar(char c)
{
	return c == ' ' || c == ',' || c == '\t' || c == '\r' || c == '\n';
}


static inline BOOL IsLineEndChar(char c)
{
	return c == '\r' || c == '\n';
}


- (BOOL) advance
{
	TraceEnter();
	
	_cursor += _tokenLength;
	NSAssert(_cursor <= _end, @"Lexer passed end of buffer");
	
	[_tokenString release];
	_tokenString = nil;
	
#define EOF_BREAK()  do { if (__builtin_expect(_cursor == _end, 0))  return NO; } while (0)
#define COMMENT_AT(loc)  (*(loc) == '#' || (*(loc) == '/' && (loc) + 1 < _end && *((loc) + 1) == '/'))
	
	/*	SKIP_WHILE: skip characters matching predicate, returning if we reach
		end of data, and counting lines as we go.
	*/
#define SKIP_WHILE(predicate)  do { while (predicate) { \
			if (!IsLineEndChar(*_cursor))  lastIsCR = NO; \
			else \
			{ \
				if (!lastIsCR || *_cursor != '\n') \
				{ \
					_lineNumber++; \
					lastIsCR = NO; \
				} \
				if (*_cursor == '\r')  lastIsCR = YES; \
			} \
			_cursor++; \
			EOF_BREAK(); \
		}} while (0)
	
	EOF_BREAK();
	BOOL lastIsCR = NO;
	
	// Find beginning of next token.
	for (;;)
	{
		SKIP_WHILE(IsSeparatorChar(*_cursor));
		
		// Skip comments.
		if (COMMENT_AT(_cursor))
		{
			SKIP_WHILE(!IsLineEndChar(*_cursor));
		}
		else
		{
			break;
		}
	}
	
	// Find length of current token.
	const char *endCursor = _cursor + 1;
	while (endCursor < _end && !IsSeparatorChar(*endCursor) && !COMMENT_AT(endCursor))
	{
		endCursor++;
	}
	
	_tokenLength = endCursor - _cursor;
	
#undef EOF_BREAK
#undef SKIP_WHILE
#undef COMMENT_AT
	
	TraceMessage(@"Got token %@.", [self currentTokenString]);
	TraceExit();
	return YES;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{next token = \"%@\"}", [self class], self, [self currentTokenString]];
}

@end


/*	ParseUnsignedInt()
 *	What it says. Based on BSD strtoul(), but takes an explicit length and
 *	only handles decimal integers.
 *
 *
 * Copyright (c) 1990, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>

/*
 * Convert a string to an unsigned long integer.
 *
 * Assumes that the upper and lower case
 * alphabets and digits are each contiguous.
 */
static inline BOOL ParseUnsignedInt(const char *string, size_t length, unsigned *value)
{
	NSCParameterAssert(value != NULL);
	if (__builtin_expect(length == 0, 0))
	{
		return NO;
	}
	
	const char *s = string;
	size_t r = length;
	unsigned long acc = 0;
	BOOL any = NO;
	
	/*
	 * Compute the cutoff value between legal numbers and illegal
	 * numbers.  That is the largest legal value, divided by the
	 * base.  An input number that is greater than this value, if
	 * followed by a legal input character, is too big.  One that
	 * is equal to this value may be valid or not; the limit
	 * between valid and invalid numbers is then based on the last
	 * digit.
	 */
	unsigned long cutoff = UINT_MAX / 10;
	int cutlim = UINT_MAX % 10;
	
	for (;;)
	{
		char c = *s++;
		
		if (__builtin_expect(c >= '0' && c <= '9', 1))  c -= '0';
		else  break;
		
		if (__builtin_expect(any < 0 || acc > cutoff || (acc == cutoff && c > cutlim), 0))  return NO;
		else
		{
			any = YES;
			acc *= 10;
			acc += c;
		}
		
		if (--r == 0)  break;
	}
	
	if (__builtin_expect(!any, 0))  return NO;
	
	*value = acc;
	return YES;
}
