//
//  DDDATLexer.m
//  Dry Dock
//
//  Created by Jens Ayton on 2006-02-16.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DDDATLexer.h"
#import "DDProblemReportManager.h"

DDDATLexer			*sDDDATLexerActive = nil;


@interface DDDATLexer (Private)

- (void)advance;
- (NSString *)describeToken;

@end


@implementation DDDATLexer

- (id)initWithURL:(NSURL *)inURL
{
	if ([inURL isFileURL])
	{
		return [self initWithPath:[[inURL absoluteURL] path]];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"DDDATLexer does not support non-file URLs such as %@", [inURL absoluteURL]];
	}
}


- (id)initWithPath:(NSString *)inPath
{
	if (nil != sDDDATLexerActive) [NSException raise:NSInternalInconsistencyException format:@"Only one DDDATLexer may be active at a time."];
	
	self = [super init];
	if (nil != self)
	{
		_file = fopen([inPath fileSystemRepresentation], "rb");
		if (NULL != _file)
		{
			OoliteDAT_SetInputFile(_file);
			[self advance];
			sDDDATLexerActive = self;
		}
		else
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (void)dealloc
{
	if (NULL != _file) fclose(_file);
	if (sDDDATLexerActive == self) sDDDATLexerActive = nil;
	
	[super dealloc];
}


- (void)setProblemReportManager:(DDProblemReportManager *)inIssues
{
	[_issues autorelease];
	_issues = [inIssues retain];
}


- (void)advance
{
	_nextToken = OoliteDAT_yylex();
}


- (int)nextToken:(NSString **)outToken
{
	int result = _nextToken;
	if (NULL != outToken) *outToken = [NSString stringWithUTF8String:OoliteDAT_yytext];
	[self advance];
	return result;
}


- (void)skipLineBreaks
{
	while (KOoliteDatToken_EOL == _nextToken) [self advance];
}


- (BOOL)passAtLeastOneLineBreak
{
	if (KOoliteDatToken_EOL != _nextToken)
	{
		[_issues addStopIssueWithKey:@"parse_error" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber, NSLocalizedString(@"end of line", NULL), [self describeToken]];
		return NO;
	}
	do
	{
		[self advance];
	} while (KOoliteDatToken_EOL == _nextToken);
	return YES;
}


- (BOOL)readInteger:(int *)outInt
{
	if (KOoliteDatToken_INTEGER == _nextToken)
	{
		if (NULL != outInt) *outInt = atoi(OoliteDAT_yytext);
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outInt) *outInt = 0;
		[_issues addStopIssueWithKey:@"parse_error" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber, NSLocalizedString(@"integer", NULL), [self describeToken]];
		return NO;
	}
}


- (BOOL)readReal:(double *)outReal
{
	if (KOoliteDatToken_REAL == _nextToken || KOoliteDatToken_INTEGER == _nextToken)
	{
		if (NULL != outReal) *outReal = atof(OoliteDAT_yytext);
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outReal) *outReal = 0.0;
		[_issues addStopIssueWithKey:@"parse_error" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber, NSLocalizedString(@"number", NULL), [self describeToken]];
		return NO;
	}
}


- (BOOL)readString:(NSString **)outString
{
	if (KOoliteDatToken_NVERTS <= _nextToken && _nextToken <= KOoliteDatToken_STRING)
	{
		if (NULL != outString) *outString = [NSString stringWithUTF8String:OoliteDAT_yytext];
		[self advance];
		return YES;
	}
	else
	{
		if (NULL != outString) *outString = nil;
		[_issues addStopIssueWithKey:@"parse_error" localizedFormat:@"Parse error on line %u: expected %@, got %@.", OoliteDAT_LineNumber, NSLocalizedString(@"name", NULL), [self describeToken]];
		return NO;
	}
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
		stringToQuote = [NSString stringWithFormat:NSLocalizedString(@"%@...", NULL), stringToQuote];
	}
	
	return [NSString stringWithFormat:NSLocalizedString(@"\"%@\"", NULL), stringToQuote];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%s %p>{file = %p, next token = %@}", object_getClassName(self), self, _file, [self describeToken]];
}

@end
