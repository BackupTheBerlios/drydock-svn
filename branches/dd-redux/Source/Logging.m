/*
	Logging.m
	$Id$
	
	Copyright © 2006-2007 Jens Ayton

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "Logging.h"
#import <stdarg.h>

#if ENABLE_LOGGING

static unsigned			sIndent = 0;


static void DoLogString(LOG_STRING_TYPE inString, const char *inFile, const char *inFunction, int inLine);


void LogIndent(void)
{
	++sIndent;
}


void LogOutdent(void)
{
	if (!sIndent--) sIndent = 0;
}


void LogWithFormat_impl(LOG_STRING_TYPE inFormat, const char *inFile, const char *inFunction, int inLine, ...)
{
	va_list				args;
	
	va_start(args, inLine);
	LogWithFormatAndArguments_impl(inFormat, inFile, inFunction, inLine, args);
	va_end(args);
}


void LogWithFormatAndArguments_impl(LOG_STRING_TYPE inFormat, const char *inFile, const char *inFunction, int inLine, va_list inArgs)
{
	NSAutoreleasePool	*pool = nil;
	NSString			*formatted = nil;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	formatted = [[NSString alloc] initWithFormat:inFormat arguments:inArgs];
	DoLogString(formatted, inFile, inFunction, inLine);
	
	[formatted release];
	[pool release];
}


void LogString_impl(LOG_STRING_TYPE inString, const char *inFile, const char *inFunction, int inLine)
{
	NSAutoreleasePool	*pool = nil;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	DoLogString(inString, inFile, inFunction, inLine);
	
	[pool release];
}


static void DoLogString(LOG_STRING_TYPE inString, const char *inFile, const char *inFunction, int inLine)
{
	NSString			*annotated = nil;
	NSString			*indented = nil;
	
	if (NULL == inFile && NULL == inFunction)
	{
		annotated = inString;
	}
	else
	{
		#if LOGGING_SHOW_FUNCTION
			#if LOGGING_SHOW_FILE_AND_LINE
				annotated = [NSString stringWithFormat:@"%s (%s:%u): %@", inFunction, inFile, inLine, inString];
			#else
				annotated = [NSString stringWithFormat:@"%s: %@", inFunction, inString];
			#endif
		#else
			#if LOGGING_SHOW_FILE_AND_LINE
				annotated = [NSString stringWithFormat:@"%s:%u: %@", inFile, inLine, inString];
			#else
				annotated = inString;
			#endif
		#endif
	}
	
	if (0 != sIndent)
	{
		#define kMaxIndent 64
		
		unsigned			indent;
							// String of 64 spaces (null-terminated)
		const char			spaces[kMaxIndent + 1] =
							"                                                                \0";
		const char			*indentString;
		
		indent = sIndent * 2;	// Two spaces per indent level
		if (kMaxIndent < indent) indent = kMaxIndent;
		indentString = &spaces[kMaxIndent - indent * 2];
		
		indented = [NSString stringWithFormat:@"%s%@", indentString, annotated];
	}
	else
	{
		indented = annotated;
	}
	
	CFShow((CFStringRef)indented);
}

#endif /* ENABLE_LOGGING */
