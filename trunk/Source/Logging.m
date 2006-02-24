/*
	Logging.m
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

#import "Logging.h"
#import <stdarg.h>

#if ENABLE_LOGGING

static unsigned			sIndent = 0;


void LogIndent(void)
{
	++sIndent;
}


void LogOutdent(void)
{
	if (!sIndent--) sIndent = 0;
}


void LogMessage_(NSString *inFormat, const char *inFile, const char *inFunction, int inLine, ...)
{
	va_list				args;
	NSString			*formatted;
	NSString			*annotated;
	NSString			*indented;
	NSAutoreleasePool	*pool;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	va_start(args, inLine);
	formatted = [[NSString alloc] initWithFormat:inFormat arguments:args];
	va_end(args);
	
	if (NULL == inFile && NULL == inFunction)
	{
		annotated = formatted;
	}
	else
	{
		#if LOGGING_SHOW_FUNCTION
			#if LOGGING_SHOW_FILE_AND_LINE
				annotated = [NSString stringWithFormat:@"%s (%s:%u): %@", inFunction, inFile, inLine, formatted];
			#else
				annotated = [NSString stringWithFormat:@"%s: %@", inFunction, formatted];
			#endif
		#else
			#if LOGGING_SHOW_FILE_AND_LINE
				annotated = [NSString stringWithFormat:@"%s:%u: %@", inFile, inLine, formatted];
			#else
				annotated = formatted;
			#endif
		#endif
	}
	
	if (0 != sIndent)
	{
		#define kMaxIndent 64
		
		unsigned			indent;
							// String of 64 spaces (null-terminated)
		const char			spaces[kMaxIndent + 1] =
							"                                                                ";
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
	
	[formatted release];
	[pool release];
}

#endif /* ENABLE_LOGGING */
