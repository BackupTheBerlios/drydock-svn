/*
	Logging.h
	$Id$
	
	A set of logging functions, designed to be more informative and flexible
	than NSLog().
	
	The core function provided is LogWithFormat(), which is similar to NSLog()
	but is available to C code using CFStrings. It also provides a more useful
	prefix, specifying file and line, function, or both, or neither, depending
	on the setting of certain macros. Additionally, functions are provided to
	indent log output for easier readability of hierarchical contexts.
	
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

#ifndef INCLUDED_LOGGING_h
#define INCLUDED_LOGGING_h

#import <stdarg.h>


#if 0

/*	The following pseudo-declarations are intended for documentation purposes.
	They do not declare actual functions; macros are used instead.
*/

/*!
	@header
	@discussion		A set of logging functions, designed to be more informative and flexible
					than NSLog().
					
					The core function provided is LogWithFormat(), which is similar to NSLog()
					but is available to C code using CFStrings. It also provides a more useful
					prefix, specifying file and line, function, or both, or neither, depending
					on the setting of certain macros. Additionally, functions are provided to
					indent log output for easier readability of hierarchical contexts.
					
					Copyright &copy; 2006-2007 Jens Ayton
					
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
	
	@meta			name="author" content="Jens Ayton &lt;jens.ayton\@comhem.se&gt;"
	@copyright		2006-2007 Jens Ayton
*/


/*! @functiongroup	Basic logging interface */

/*!	@function	LogWithFormat
	@abstract	General logging function.
	@discussion	LogWithFormat() is the primary function of the logging
				library. Given a Foundation formatting string - like a
				printf() formatting string, but with the addition of %\@ for
				Cocoa and CoreFoundation objects - write the format string,
				with appropriate substitutions, to the log. Depending on
				which configuration macros are set, this can be preceeded by
				the name of the function calling LogWithFormat(), the file and
				line of the call, or both.
	@param		inFormat		A format string. If the calling code is in an
								Objective-C file, this is of type NSString *.
								In a C or C++ file, it is of type CFStringRef.
	@param		...				Substitution arguments.
*/
void LogWithFormat(NSString *inFormat, ...);


/*!	@function	LogWithFormatAndArguments
	@abstract	Logging function with va_list argument.
	@discussion	LogWithFormatAndArguments() is equivalent to LogWithFormat(),
				except that it takes substitution arguments in the form of a
				va_list. This is primarily useful in creating functions to
				wrap a logging call.
	@param		inFormat		A format string. If the calling code is in an
								Objective-C file, this is of type NSString *.
								In a C or C++ file, it is of type CFStringRef.
	@param		inArguments		Substitution arguments.
*/
void LogWithFormatAndArguments(NSString *inFormat, va_list inArguments);


/*!	@function	LogString
	@abstract	Unformatted logging function.
	@discussion	LogString() logs a string through LogWithFormat() without
				substitution. It is equivalent to
				LogWithFormat(\@"%\@\", string).<br>
				<b>NOTE:</b> it is not safe in the general case to call
				LogWithFormat(string).
	@param		inString		A string. If the calling code is in an
								Objective-C file, this is of type NSString *.
								In a C or C++ file, it is of type CFStringRef.
*/
void LogString(NSString *inString);


/*!	@function	LogWithFormatNoPrefix
	@abstract	General logging function, with no prefix.
	@discussion	LogWithFormatNoPrefix() works exactly like LogWithFormat(),
				except that the prefix (file and line and/or function
				information) is excluded, regardless of the settings of
				configuration macros.
	@param		inFormat		A format string. If the calling code is in an
								Objective-C file, this is of type NSString *.
								In a C or C++ file, it is of type CFStringRef.
	@param		...				Substitution arguments.
*/
void LogWithFormatNoPrefix(NSString *inFormat, ...);


/*!	@function	LogWithFormatAndArgumentsNoPrefix
	@abstract	Logging function with va_list argument, with no prefix.
	@discussion	LogWithFormatAndArgumentsNoPrefix() works exactly like
				LogWithFormatAndArguments(), except that the prefix (file and
				line and/or function information) is excluded, regardless of
				the settings of configuration macros.
	@param		inFormat		A format string. If the calling code is in an
								Objective-C file, this is of type NSString *.
								In a C or C++ file, it is of type CFStringRef.
	@param		inArguments		Substitution arguments.
*/
void LogWithFormatAndArgumentsNoPrefix(NSString *inFormat, va_list inArguments);


/*!	@function	LogStringNoPrefix
	@abstract	Unformatted logging function, with no prefix.
	@discussion	LogStringNoPrefix() works exactly like LogString(), except
				that the prefix (file and line and/or function information) is
				excluded, regardless of the settings of configuration macros.
	@param		inString		A string. If the calling code is in an
								Objective-C file, this is of type NSString *.
								In a C or C++ file, it is of type CFStringRef.
*/
void LogStringNoPrefix(NSString *inString);


/*! @functiongroup	Log message indentation */

/*!	@function	LogIndent
	@abstract	Increase the logging indent level.
	@discussion	LogIndent() increases the indent level by one. For each level
				of indentation, two spaces are prepended to strings by
				LogWithFormat() and releated functions. This can be used to
				provide a better overview of hierarchical operations.
				
				Calls to LogIndent() should be balanced with LogOutdent().
*/
void LogIndent(void);



/*!	@function	LogOutdent
	@abstract	Decrease the logging indent level.
	@discussion	LogOutdent() decreases the indent level by one. For each level
				of indentation, two spaces are prepended to strings by
				LogWithFormat() and releated functions. This can be used to
				provide a better overview of hierarchical operations.
				
				LogOutdent() should be used to balance calls to LogIndent().
*/
void LogOutdent(void);


/*! @functiongroup	Call hierarchy tracing */

/*!	@function	TraceEnter
	@abstract	Mark entry into a function or method.
	@discussion	At the simplest level, TraceEnter() calls
				LogString(\@"Called. {") followed by LogIndent(). This is
				balanced by TraceExit(), which calles LogOutdent() and prints
				\@"}". However, by means of magic (or evil hackery) with
				Objective-C's exception mechanism, no special handling is
				needed for exceptions and returns; it Just Works™.
				
				Message tracing (for Objective-C/Objective-C++ only) works as
				follows:
				<ul><li> At the entry of a function or method, add a call to
					TraceMessage().</li>
				<li> At the end of th function or method, add a call to
					TraceExit().</li>
				<li> #define ENABLE_TRACE 1 (ENABLE_LOGGING must also be
				on).</li></ul>
				
				Example:
<pre>int CalculateSomething(void)
{
    TraceEnter();
    
    id foo = [[SomethingCalculator alloc] init];
    if (nil == foo) [NSException raise:NSGenericException format:\@"Failed to create SomethingCalculator."];
    [foo autorelease];
    return [foo value];
    
    TraceExit();
}</pre>
				
				Each call to TraceEnter() must be balanced by a call to
				TraceExit(). Failing to do this will result in compilation
				errors as a TraceEnter()/TraceExit() pair constitutes an
				exception scope.
*/
void TraceEnter(void);



/*!	@function	TraceExit
	@abstract	Mark exit from a function or method.
	@discussion	TraceExit() balances a call to TraceEnter(), TraceEnterMsg()
				or TraceEnterMsgWithFormat().
				
				<b>Known problem:</b> use in functions/methods with a return
				value can result in the message “warning: control reaches end
				of non-void function.” This is spurious.
*/
void TraceExit(void);


/*!	@function	TraceEnterMsg
	@abstract	Mark exit from a function or method.
	@discussion	TraceEnterMsg() is equivalent to TraceEnter(), except it takes
				a custom string as a parameter.
	@param		inString		A string to display when entering the function
								or method.
*/
void TraceEnterMsg(NSString *inString);


/*!	@function	TraceEnterMsgWithFormat
	@abstract	Mark exit from a function or method.
	@discussion	TraceEnterMsgWithFormat() is equivalent to TraceEnter(),
				except it takes a format string and substitution arguments.
	@param		inFormat		A format string to display when entering the
								function or method.
	@param		...				Substitution arguments.
*/
void TraceEnterMsgWithFormat(NSString *inFormat, ...);


/*!	@function	TraceMsg
	@abstract	Unformatted logging function.
	@discussion	TraceMsg() is equivalent to LogString() if tracing is enabled,
				and a no-op otherwise.
*/
void TraceMsg(NSString *inString);


/*!	@function	TraceMsgWithFormat
	@abstract	Formatted logging function.
	@discussion	TraceMsgWithFormat() is equivalent to LogWithFormat() if
				tracing is enabled, and a no-op otherwise.
*/
void TraceMsgWithFormat(NSString *inFormat, ...);


/*! @functiongroup	Configuration macros */

/*! @constant		ENABLE_LOGGING
	@abstract		Master switch for logging.
	@discussion		If ENABLE_LOGGING is non-zero, logging will be performed.
					If it is zero, logging functions will be no-ops. Note,
					however, that ENABLE_LOGGING can be overridden with
					ENABLE_LOGGING_OVERRIDE.
					
					This macro is only set by Logging.h if it is not already
					set.
*/
#define ENABLE_LOGGING 1


/*! @constant		ENABLE_LOGGING_OVERRIDE
	@abstract		Override for master switch for logging.
	@discussion		If ENABLE_LOGGING_OVERRIDE is defined, ENABLE_LOGGING is
					reset to be the same as ENABLE_LOGGING_OVERRIDE. This
					simplifies turning logging on or off on a per-file basis.
					
					This macro is never set by Logging.h.
*/
#define ENABLE_LOGGING_OVERRIDE 1


/*! @constant		LOGGING_SHOW_FUNCTION
	@abstract		Specify whether function/method names should be shown when
					logging.
	@discussion		If LOGGING_SHOW_FUNCTION is non-zero, log (and trace)
					calls will print the name of the calling function.
					
					This macro is only set by Logging.h if it is not already
					set.
*/
#define LOGGING_SHOW_FUNCTION 1


/*! @constant		LOGGING_SHOW_FILE_AND_LINE
	@abstract		Specify whether file and line when logging.
	@discussion		If LOGGING_SHOW_FILE_AND_LINE is non-zero, log (and trace)
					calls will print the file and line from which they are
					called.
					
					This macro is only set by Logging.h if it is not already
					set.
*/
#define LOGGING_SHOW_FILE_AND_LINE 0


/*! @constant		ENABLE_TRACE
	@abstract		Master switch for call tracing.
	@discussion		If ENABLE_TRACE is non-zero, tracing (with TraceEnter()
					and family) will be performed. If it is zero, tracing
					macros will be no-ops. Note, however, that ENABLE_TRACE
					can be overridden with ENABLE_TRACE_OVERRIDE.
					
					This macro is only set by Logging.h if it is not already
					set.
*/
#define ENABLE_TRACE 0


/*! @constant		ENABLE_TRACE_OVERRIDE
	@abstract		Override for master switch for tracing.
	@discussion		If ENABLE_TRACE_OVERRIDE is defined, ENABLE_TRACE is
					reset to be the same as ENABLE_TRACE_OVERRIDE. This
					simplifies turning tracing on or off on a per-file basis.
					
					This macro is never set by Logging.h.
*/
#define ENABLE_TRACE_OVERRIDE 0

#endif


#ifdef ENABLE_LOGGING_OVERRIDE
	#ifdef ENABLE_LOGGING
		#undef ENABLE_LOGGING
	#endif
	#define ENABLE_LOGGING ENABLE_LOGGING_OVERRIDE
#endif

#ifndef ENABLE_LOGGING
	#define ENABLE_LOGGING	1
#endif

/* TraceMessage() is disabled by default; intended for observing call hierarchies. */
#ifdef ENABLE_TRACE_OVERRIDE
	#ifdef ENABLE_TRACE
		#undef ENABLE_TRACE
	#endif
	#define ENABLE_TRACE ENABLE_TRACE_OVERRIDE
#endif

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
	
	#ifndef LOGGING_FUNCTION_NAME
		#if defined (__GNUC__) && __GNUC__ >= 2
			#define LOGGING_FUNCTION_NAME	__PRETTY_FUNCTION__
		#elif 199901L <= __STDC_VERSION__
			#define LOGGING_FUNCTION_NAME	__func__
		#else
			#define LOGGING_FUNCTION_NAME	NULL
		#endif
	#endif
	
	void LogWithFormat_impl(LOG_STRING_TYPE inFormat, const char *inFile, const char *inFunction, int inLine, ...);
	void LogWithFormatAndArguments_impl(LOG_STRING_TYPE inFormat, const char *inFile, const char *inFunction, int inLine, va_list inArgs);
	void LogString_impl(LOG_STRING_TYPE inString, const char *inFile, const char *inFunction, int inLine);
	
	#if LOGGING_SHOW_FUNCTION
		#if LOGGING_SHOW_FILE_AND_LINE
			#define LOGGING_PREFIX_PARAMS					__FILE__, LOGGING_FUNCTION_NAME, __LINE__
		#else
			#define LOGGING_PREFIX_PARAMS					NULL, LOGGING_FUNCTION_NAME, 0
		#endif
	#else
		#if LOGGING_SHOW_FILE_AND_LINE
			#define LOGGING_PREFIX_PARAMS					__FILE__, NULL, __LINE__
		#else
			#define LOGGING_PREFIX_PARAMS					NULL, NULL, 0
		#endif
	#endif	/* LOGGING_SHOW_FUNCTION */
	#define LOGGING_NOPREFIX_PARAMS							NULL, NULL, 0
	
	
	#define LogWithFormat(format, ...)						LogWithFormat_impl(format, LOGGING_PREFIX_PARAMS, ## __VA_ARGS__)
	#define LogWithFormatAndArguments(format, args)			LogWithFormatAndArguments_impl(format, LOGGING_PREFIX_PARAMS, args)
	#define LogString(string)								LogString_impl(string, LOGGING_PREFIX_PARAMS)
	
	#define LogWithFormatNoPrefix(format, ...)				LogWithFormat_impl(format, LOGGING_NOPREFIX_PARAMS, ## __VA_ARGS__)
	#define LogWithFormatAndArgumentsNoPrefix(format, args)	LogWithFormatAndArguments_impl(format, LOGGING_NOPREFIX_PARAMS, args)
	#define LogStringNoPrefix(string)						LogString_impl(string, LOGGING_NOPREFIX_PARAMS)
	
	void LogIndent(void);
	void LogOutdent(void);
	
	#if __cplusplus
		}
	#endif
	
	
	#if __OBJC__
		#if ENABLE_TRACE
			#define TraceEnterMsgWithFormat(format, ...)	LogWithFormat(format, ## __VA_ARGS__); LogIndent(); @try { do{} while (0)
			#define TraceEnterMsg(string)					TraceEnterMsgWithFormat(@"%@", string)
			#if LOGGING_SHOW_FUNCTION
				#define TraceEnter()						TraceEnterMsg(@"Called. {")
			#else
				#define TraceEnter()						TraceEnterMsgWithFormat(@"%@: Called. {", LOGGING_FUNCTION_NAME)
			#endif
			#define TraceExit()								} @finally { LogOutdent(); LogStringNoPrefix(@"}"); }
			#define TraceMsgWithFormat						LogWithFormat
			#define TraceMsg								LogString
			#define TraceIndent								LogIndent
			#define TraceOutdent							LogOutdent
			
			#define TRACE_RETAIN_RELEASE \
						- (id)retain { TraceMsgWithFormat(@"Retaining -> %u", [self retainCount] + 1); return [super retain]; } \
						- (void)release { TraceMsgWithFormat(@"Releasing -> %u", [self retainCount] - 1); [super release]; } \
						- (id)autorelease { TraceMsgWithFormat(@"Autoreleasing @ %u", [self retainCount]); return [super autorelease]; }
		#else
			#define TraceEnterMsgWithFormat(f, ...)			do {} while (0)
			#define TraceEnterMsg(s)						do {} while (0)
			#define TraceEnter()							do {} while (0)
			#define TraceExit()								do {} while (0)
			#define TraceMsgWithFormat(f, ...)				do {} while (0)
			#define TraceMsg(s)								do {} while (0)
			#define TraceIndent()							do {} while (0)
			#define TraceOutdent()							do {} while (0)
			
			#define TRACE_RETAIN_RELEASE
		#endif	/* ENABLE_TRACE */
	#endif	/* __OBJC__ */
	
#else	/* ENABLE_LOGGING */
	
	#define LogWithFormat(...)								do {} while (0)
	#define LogWithFormatAndArguments(f, a)					do {} while (0)
	#define LogString(s)									do {} while (0)
	#define LogWithFormatNoPrefix()							do {} while (0)
	#define LogWithFormatAndArgumentsNoPrefix()				do {} while (0)
	#define LogStringNoPrefix(s)							do {} while (0)
	#define LogIndent()										do {} while (0)
	#define LogOutdent()									do {} while (0)
	
	#if __OBJC__
		#define TraceEnterMsgWithFormat(f, ...)				do {} while (0)
		#define TraceEnterMsg(s)							do {} while (0)
		#define TraceEnter()								do {} while (0)
		#define TraceExit()									do {} while (0)
		#define TraceMsgWithFormat(f, ...)					do {} while (0)
		#define TraceMsg(s)									do {} while (0)
		#define TraceIndent()								do {} while (0)
		#define TraceOutdent()								do {} while (0)
		
		#define TRACE_RETAIN_RELEASE
	#endif	/* __OBJC__ */
	
#endif /* ENABLE_LOGGING */

#endif /* INCLUDED_LOGGING_h */
