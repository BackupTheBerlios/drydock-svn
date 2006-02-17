//
//  DDDATLexer.h
//  Dry Dock
//
//  Created by Jens Ayton on 2006-02-16.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdio.h>
#import "OoliteDATTokens.h"

@class DDProblemReportManager;


@interface DDDATLexer: NSObject
{
	int						_nextToken;
	FILE					*_file;
	DDProblemReportManager	*_issues;
}

- (id)initWithURL:(NSURL *)inURL;
- (id)initWithPath:(NSString *)inPath;

- (void)setProblemReportManager:(DDProblemReportManager *)inIssues;

- (int)nextToken:(NSString **)outToken;
- (void)skipLineBreaks;				// Skips zero or more EOL tokens
- (BOOL)passAtLeastOneLineBreak;	// Skips one or more EOL tokens

- (BOOL)readInteger:(int *)outInt;
- (BOOL)readReal:(double *)outReal;
- (BOOL)readString:(NSString **)outString;

@end
