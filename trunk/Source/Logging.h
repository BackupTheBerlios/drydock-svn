/*
	Logging.h
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

#ifndef INCLUDED_LOGGING_h
#define INCLUDED_LOGGING_h

#ifndef ENABLE_LOGGING
#define ENABLE_LOGGING	!defined(NDEBUG)
#endif

// TraceMessage() is disabled by default; intended for observing call hierarchies
#ifndef ENABLE_TRACE
#define ENABLE_TRACE	0
#endif

#if ENABLE_LOGGING
#ifndef LOGGING_SHOW_FUNCTION
#define LOGGING_SHOW_FUNCTION		1
#endif
#ifndef LOGGING_SHOW_FILE_AND_LINE
#define LOGGING_SHOW_FILE_AND_LINE	0
#endif

#if __cplusplus
extern "C" {
#endif

#if __OBJC__
#import <Foundation/Foundation.h>
#define LOG_STRING_TYPE		NSString *
#else
#include <CoreFoundation/CoreFoundation.h>
#define LOG_STRING_TYPE		CFStringRef
#endif	/*__OBJC__ */

void LogMessage_(LOG_STRING_TYPE inFormat, const char *inFile, const char *inFunction, int inLine, ...);

#if LOGGING_SHOW_FUNCTION
	#if LOGGING_SHOW_FILE_AND_LINE
		#define LogMessage(format, ...) LogMessage_(format, __FILE__, __PRETTY_FUNCTION__, __LINE__, ## __VA_ARGS__)
	#else
		#define LogMessage(format, ...) LogMessage_(format, NULL, __PRETTY_FUNCTION__, 0, ## __VA_ARGS__)
	#endif
#else
	#if LOGGING_SHOW_FILE_AND_LINE
		#define LogMessage(format, ...) LogMessage_(format, __FILE__, NULL, __LINE__, ## __VA_ARGS__)
	#else
		#define LogMessage(format, ...) LogMessage_(format, NULL, NULL, 0, ## __VA_ARGS__)
	#endif
#endif	/* LOGGING_SHOW_FUNCTION */

void LogIndent(void);
void LogOutdent(void);

#if __cplusplus
}
#endif


#if __OBJC__
#if ENABLE_TRACE
#define TraceMessage		LogMessage
#define TraceIndent			LogIndent
#define TraceOutdent		LogOutdent

#define TraceEnterMsg(...)	TraceMessage(__VA_ARGS__); TraceIndent(); @try { do{} while (0)
#define TraceEnter()		TraceEnterMsg(@"Called. {")
#define TraceExit()			} @finally { TraceOutdent(); LogMessage_(@"}", NULL, NULL, 0); } do {} while (0)
#else
#define TraceMessage(...)	do {} while (0)
#define TraceIndent()		do {} while (0)
#define TraceOutdent()		do {} while (0)

#define TraceEnterMsg(...)	do {} while (0)
#define TraceEnter()		do {} while (0)
#define TraceExit()			do {} while (0)
#endif	/* ENABLE_TRACE */
#endif	/* __OBJC__ */

#else	/* ENABLE_LOGGING */

#define LogMessage(...)		do {} while (0)
#define LogIndent()			do {} while (0)
#define LogOutdent()		do {} while (0)

#if __OBJC__
#define TraceMessage(...)	do {} while (0)
#define TraceIndent()		do {} while (0)
#define TraceOutdent()		do {} while (0)
#endif	/* __OBJC__ */

#endif /* ENABLE_LOGGING */
#endif /* INCLUDED_LOGGING_h */
