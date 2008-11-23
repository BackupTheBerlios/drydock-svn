/*
	DDDATLexer.m
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

#import "DDDATLexer.h"
#import "DDProblemReportManager.h"
#import "DDErrorDescription.h"
#import "Logging.h"

DDDATLexer			*sDDDATLexerActive = nil;


#if ENABLE_TRACE

static const char *TokenString(int inToken);

#endif


@interface DDDATLexer (Private)

- (void)advance;
- (NSString *)describeToken;

@end


@implementation DDDATLexer

- (id)initWithURL:(NSURL *)inURL issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	if ([inURL isFileURL])
	{
		return [self initWithPath:[[inURL absoluteURL] path] issues:ioIssues];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"DDDATLexer does not support non-file URLs such as %@", [inURL absoluteURL]];
		return nil;
	}
	
	TraceExit();
}


- (id)initWithPath:(NSString *)inPath issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	if (nil != sDDDATLexerActive) [NSException raise:NSInternalInconsistencyException format:@"Only one DDDATLexer may be active at a time."];
	
	self = [super init];
	if (nil != self)
	{
		_file = fopen([inPath fileSystemRepresentation], "rb");
		if (NULL != _file)
		{
			_issues = [ioIssues retain];
			OoliteDAT_SetInputFile(_file);
			[self advance];
			sDDDATLexerActive = self;
		}
		else
		{
			[ioIssues addStopIssueWithKey:@"noReadFilePOSIX" localizedFormat:@"The document could not be loaded, because a POSIX error of type %@ occured.", ErrnoAsNSString()];
			[self release];
			self = nil;
		}
	}
	
	return self;
	TraceExit();
}


- (void)dealloc
{
	TraceEnter();
	
	if (NULL != _file) fclose(_file);
	if (sDDDATLexerActive == self) sDDDATLexerActive = nil;
	[_issues release];
	
	[super dealloc];
	TraceExit();
}


- (void)advance
{
	TraceIndent();
	TraceMessage(@"Got token %s (%@).", TokenString(_nextToken), [self describeToken]);
	TraceOutdent();
	
	_nextToken = OoliteDAT_yylex();
}


- (OoliteDATLexToken)nextToken:(NSString **)outToken
{
	TraceEnter();
	
	OoliteDATLexToken result = _nextToken;
	if (NULL != outToken) *outToken = [NSString stringWithUTF8String:OoliteDAT_yytext];
	[self advance];
	return result;
	
	TraceExit();
}


- (OoliteDATLexToken)nextTokenDesc:(NSString **)outToken
{
	TraceEnter();
	
	OoliteDATLexToken result = _nextToken;
	if (NULL != outToken) *outToken = [self describeToken];
	[self advance];
	return result;
	
	TraceExit();
}


- (void)skipLineBreaks
{
	TraceEnter();
	
	while (KOoliteDatToken_EOL == _nextToken) [self advance];
	
	TraceExit();
}


- (BOOL)passAtLeastOneLineBreak
{
	TraceEnter();
	
	if (KOoliteDatToken_EOL != _nextToken)
	{
		[_issues addStopIssueWithKey:@"parseError" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber(), NSLocalizedString(@"end of line", NULL), [self describeToken]];
		return NO;
	}
	do
	{
		[self advance];
	} while (KOoliteDatToken_EOL == _nextToken);
	return YES;
	
	TraceExit();
}


- (BOOL)readInteger:(unsigned *)outInt
{
	TraceEnter();
	
	if (KOoliteDatToken_INTEGER == _nextToken)
	{
		// Note that the lexer only recognises unsigned integers
		if (NULL != outInt) *outInt = atoi(OoliteDAT_yytext);
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outInt) *outInt = 0;
		[_issues addStopIssueWithKey:@"parseError" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber(), NSLocalizedString(@"integer", NULL), [self describeToken]];
		return NO;
	}
	
	TraceExit();
}


- (BOOL)readReal:(float *)outReal
{
	TraceEnter();
	
	if (KOoliteDatToken_REAL == _nextToken || KOoliteDatToken_INTEGER == _nextToken)
	{
		if (NULL != outReal) *outReal = atof(OoliteDAT_yytext);
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outReal) *outReal = 0.0;
		[_issues addStopIssueWithKey:@"parseError" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber(), NSLocalizedString(@"number", NULL), [self describeToken]];
		return NO;
	}
	
	TraceExit();
}


- (BOOL)readString:(NSString **)outString
{
	TraceEnter();
	
	if (KOoliteDatToken_NVERTS <= _nextToken && _nextToken <= KOoliteDatToken_STRING)
	{
		if (NULL != outString) *outString = [NSString stringWithUTF8String:OoliteDAT_yytext];
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outString) *outString = nil;
		[_issues addStopIssueWithKey:@"parseError" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber(), NSLocalizedString(@"name", NULL), [self describeToken]];
		return NO;
	}
	
	TraceExit();
}


- (NSString *)describeToken
{
	NSString		*stringToQuote = nil;
	
	switch (_nextToken)
	{
		case KOoliteDatToken_EOF:
			return NSLocalizedString(@"end of file", NULL);
		
		case KOoliteDatToken_EOL:
			return NSLocalizedString(@"end of line", NULL);
		
		case KOoliteDatToken_VERTEX_SECTION:
			stringToQuote = @"VERTEX";
			break;
		
		case KOoliteDatToken_FACES_SECTION:
			stringToQuote = @"FACES";
			break;
		
		case KOoliteDatToken_TEXTURES_SECTION:
			stringToQuote = @"TEXTURES";
			break;
		
		case KOoliteDatToken_END_SECTION:
			stringToQuote = @"END";
			break;
		
		case KOoliteDatToken_NVERTS:
			stringToQuote = @"NVERTS";
			break;
		
		case KOoliteDatToken_NFACES:
			stringToQuote = @"NFACES";
			break;
		
		default:
			stringToQuote = [NSString stringWithUTF8String:OoliteDAT_yytext];
	}
	
	if (nil == stringToQuote) stringToQuote = @"";
	else if (100 < [stringToQuote length])
	{
		stringToQuote = [NSString stringWithFormat:NSLocalizedString(@"%@...", NULL), [stringToQuote substringToIndex:100]];
	}
	
	return stringToQuote;//[NSString stringWithFormat:NSLocalizedString(@"\"%@\"", NULL), stringToQuote];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%s %p>{file = %p, next token = %@}", object_getClassName(self), self, _file, [self describeToken]];
}

@end


#if ENABLE_TRACE

static const char *TokenString(int inToken)
{
	#define CASE(foo) case KOoliteDatToken_ ## foo: return #foo;
	
	switch (inToken)
	{
		CASE(EOF);
		CASE(EOL);
		CASE(VERTEX_SECTION);
		CASE(FACES_SECTION);
		CASE(TEXTURES_SECTION);
		CASE(END_SECTION);
		CASE(NVERTS);
		CASE(NFACES);
		CASE(INTEGER);
		CASE(REAL);
		CASE(STRING);
		
		default: return "??";
	}
	
	#undef CASE
}

#endif
