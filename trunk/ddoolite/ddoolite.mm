/*
	ddoolite.m
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

#define ENABLE_TRACE 1


#import "ddoolite.h"

#import <getopt.h>
#import <sys/param.h>

#import "DDModelDocument.h"
#import "DDProblemReportManager.h"
#import "DDUtilities.h"
#import "Logging.h"

static void PrintUsage(const char *inCall) __attribute__((noreturn));
static void PrintHelp(void);
static BOOL ProcessFile(NSURL *inSourceFile, DDFormat inSourceFormat, NSURL *inOutFile, DDFormat inOutFormat, BOOL inQuiet);
static NSString *WorkingDirectory(void);


int main(int argc, char **argv)
{
	// Command line options definitions for getopt_long()
	const struct option		longOpts[] =
							{
								{ "quiet",		no_argument,		NULL, 'q' },
								{ "format",		required_argument,	NULL, 'f' },
								{ "srcFormat",	required_argument,	NULL, 'F' },
								{ "out",		required_argument,	NULL, 'o' },
								{ "help",		no_argument,		NULL, '?' },
								{0}
							};
	int						option;
	NSAutoreleasePool		*rootPool;
	BOOL					quiet = NO, help = NO, stop = NO;
	NSString				*outFile = nil, *inFile = nil;
	DDFormat				srcFormat = kDDFormat_unknown, format = kDDFormat_DAT;
	
	rootPool = [[NSAutoreleasePool alloc] init];
	
	if (argc < 2) PrintUsage(argv[0]);
	
	for (;;)
	{
		option = getopt_long(argc, argv, "qf:F:o:?", longOpts, NULL);
		if (-1 == option) break;
		
		switch (option)
		{
			case 'q':
				quiet = YES;
				break;
			
			case 'f':
				if (!strcasecmp("dat", optarg)) format = kDDFormat_DAT;
				else if (!strcasecmp("obj", optarg)) format = kDDFormat_OBJ;
				else if (!strcasecmp("mesh", optarg)) format = kDDFormat_Mesh;
				else if (!strcasecmp("ddock", optarg)) format = kDDFormat_DryDock;
				else
				{
					EPrint(@"Invalid format specifier %s.\n", optarg);
					help = YES;
					stop = YES;
				}
				break;
			
			case 'F':
				if (!strcasecmp("dat", optarg)) srcFormat = kDDFormat_DAT;
				else if (!strcasecmp("obj", optarg)) srcFormat = kDDFormat_OBJ;
				else if (!strcasecmp("mesh", optarg)) srcFormat = kDDFormat_Mesh;
				else if (!strcasecmp("ddock", optarg)) srcFormat = kDDFormat_DryDock;
				else
				{
					EPrint(@"Invalid format specifier %s.\n", optarg);
					help = YES;
					stop = YES;
				}
				break;
			
			case 'o':
				// FIXME: assumes UTF-8
				outFile = [NSString stringWithUTF8String:optarg];
				break;
			
			case '?':	// Either help or unknown.
				help = YES;
				Print(@"Got --help option.\n");
				break;
		}
	}
	
	argc -= optind;
	argv += optind;
	
	switch (argc)
	{
		case 0:
			if (!help)
			{
				EPrint(@"No input file specified.\n");
				help = YES;
				stop = YES;
			}
			break;
		
		case 1:
			// FIXME: assumes UTF-8
			inFile = [NSString stringWithUTF8String:argv[0]];
			if (kDDFormat_unknown == srcFormat)
			{
				srcFormat = DDFormatForFileName(inFile);
				if (kDDFormat_unknown == srcFormat)
				{
					EPrint(@"Can't guess format of %@ from file name extension; specify explicitly using -F.\n");
					stop = YES;
				}
			}
			break;
		
		default:
			EPrint(@"Multiple input files specified. Currently only one file at a time is supported.\n");
			stop = YES;
			help = YES;
	}
	
	if (help) PrintHelp();
	if (nil != inFile && !stop)
	{
		if (nil == outFile)
		{
			outFile = [[inFile stringByDeletingPathExtension] stringByAppendingPathExtension:ExtensionForDDFormat(format)];
		}
		
	/*	if (![inFile isAbsolutePath]) inFile = [WorkingDirectory() stringByAppendingPathComponent:inFile];
		if (![outFile isAbsolutePath]) outFile = [WorkingDirectory() stringByAppendingPathComponent:outFile];
	*/	
		if ([outFile isEqual:inFile])
		{
			EPrint(@"Input and output file paths are identical, aborting.\n");
		}
		else
		{
			stop = !ProcessFile([NSURL fileURLWithPath:inFile], srcFormat, [NSURL fileURLWithPath:outFile], format, quiet);
		}
	}
	
	[rootPool release];
	
	return stop ? EXIT_FAILURE : EXIT_SUCCESS;
}


static BOOL ProcessFile(NSURL *inSourceFile, DDFormat inSourceFormat, NSURL *inOutFile, DDFormat inOutFormat, BOOL inQuiet)
{
	DDModelDocument			*document;
	DDProblemReportManager	*issues;
	BOOL					OK = YES;
	
//	if (!inQuiet) Print(@"Converting %@ from %@ to %@ and writing to %@\n", [inSourceFile absoluteString], NameForDDFormat(inSourceFormat), NameForDDFormat(inOutFormat), [inOutFile absoluteString]);
	
	document = [DDModelDocument alloc];
	issues = [[[DDProblemReportManager alloc] init] autorelease];
	switch (inSourceFormat)
	{
		case kDDFormat_DAT:
			document = [document initWithOoliteDAT:inSourceFile issues:issues];
			break;
		
		case kDDFormat_OBJ:
			document = [document initWithLightwaveOBJ:inSourceFile issues:issues];
			break;
		
		case kDDFormat_Mesh:
			EPrint(@"Meshwork format is currently unsupported for import.\n");
			OK = NO;
			break;
		
		case kDDFormat_DryDock:
			document = [document initWithDryDockDocument:inSourceFile issues:issues];
			break;
		
		default:
			EPrint(@"Unknown input format %@.\n", NameForDDFormat(inSourceFormat));
			OK = NO;
	}
	[document autorelease];
	if (!OK) return NO;
	
	LogMessage(@"Loaded %@", document);
	
	[issues setContext:kContextOpen];
	if (![issues showReportCommandLineQuietMode:inQuiet]) return NO;
	[issues clear];
	[issues setContext:kContextSave];
	
	switch (inOutFormat)
	{
		case kDDFormat_DAT:
			[document gatherIssues:issues withWritingOoliteDATToURL:inOutFile];
			if ([issues showReportCommandLineQuietMode:inQuiet])
			{
				OK = [document writeOoliteDATToURL:inOutFile issues:issues];
				OK = OK && [issues showReportCommandLineQuietMode:inQuiet];
			}
			else OK = NO;
			break;
		
		case kDDFormat_OBJ:
			[document gatherIssues:issues withWritingLightwaveOBJToURL:inOutFile];
			if ([issues showReportCommandLineQuietMode:inQuiet])
			{
				OK = [document writeLightwaveOBJToURL:inOutFile finalLocationURL:inOutFile issues:issues];
				OK = OK && [issues showReportCommandLineQuietMode:inQuiet];
			}
			else OK = NO;
			break;
		
		case kDDFormat_Mesh:
			EPrint(@"Meshwork format is currently unsupported for export.\n");
			OK = NO;
			break;
		
		case kDDFormat_DryDock:
			[document gatherIssues:issues withWritingDryDockDocumentToURL:inOutFile];
			if ([issues showReportCommandLineQuietMode:inQuiet])
			{
				OK = [document writeDryDockDocumentToURL:inOutFile issues:issues];
				OK = OK && [issues showReportCommandLineQuietMode:inQuiet];
			}
			else OK = NO;
			break;
		
		default:
			EPrint(@"Unknown output format %@.\n", NameForDDFormat(inSourceFormat));
			OK = NO;
	}
	
	return OK;
}


static void PrintUsage(const char *inCall)
{
	Print(@"Usage: %s [-q] [-f format] [-o outfile] sourcefile\n"
			"%s --help", inCall, inCall);
	
	exit(0);
}


static void PrintHelp(void)
{
	Print(@"%@, copyright 2006 Jens Ayton\n"
			"Format conversion and verification tool for Oolite\n"
			"\n"
			"Usage: ddoolite [-q] [-f format] [-F sourceformat] [-o outfile] sourcefile\n"
			"       ddoolite --help\n"
			"\n"
			"    -q, --quiet  Suppress note and warning messages, and the associated \"do\n"
			"                 you wish to continue\" messages.\n"
			"   -f, --format  Format to convert to. If not specified, dat is assumed.\n"
			"                     Possible values:\n"
			"                     dat   Oolite DAT format.\n"
			"                     obj   Lightwave OBJ format (with accompanying MTL file).\n"
//			"                     mesh  Meshwork document.\n"
			"                     ddock Dry Dock for Oolite document.\n"
			"-F, --srcFormat  Format to convert from (same values as -f). If not specified,\n"
			"                 a guess will be made based on the file name extension.\n"
			"      -o, --out  Name of file to write to. If not specified, the input\n"
			"                 file name will be modified with the appropriate extension.\n"
			"     -?, --help  Display this help message.\n",
		ApplicationNameAndVersionString());
}


void Print(NSString *inFormat, ...)
{
	va_list				args;
	
	va_start(args, inFormat);
	Printv(inFormat, args);
	va_end(args);
}


void Printv(NSString *inFormat, va_list inArgs)
{
	NSString			*string;
	
	string = [[NSString alloc] initWithFormat:inFormat arguments:inArgs];
	puts([string UTF8String]);	// Data will be autoreleased… do we need a pool just for this?
	[string release];
}



void EPrint(NSString *inFormat, ...)
{
	va_list				args;
	
	va_start(args, inFormat);
	EPrintv(inFormat, args);
	va_end(args);
}


void EPrintv(NSString *inFormat, va_list inArgs)
{
	NSString			*string;
	
	string = [[NSString alloc] initWithFormat:inFormat arguments:inArgs];
	fputs([string UTF8String], stderr);	// Data will be autoreleased… do we need a pool just for this?
	[string release];
}


NSString *ExtensionForDDFormat(DDFormat inFormat)
{
	switch (inFormat)
	{
		case kDDFormat_DAT:
			return @"dat";
		
		case kDDFormat_OBJ:
			return @"obj";
		
		case kDDFormat_Mesh:
			return @"mesh";
		
		case kDDFormat_DryDock:
			return @"drydock";
		
		default:
			return nil;
	}
}


NSString *NameForDDFormat(DDFormat inFormat)
{
	switch (inFormat)
	{
		case kDDFormat_DAT:
			return @"Oolite DAT";
		
		case kDDFormat_OBJ:
			return @"Lightwave OBJ";
		
		case kDDFormat_Mesh:
			return @"Meshwork";
		
		case kDDFormat_DryDock:
			return @"Dry Dock document";
		
		default:
			return [NSString stringWithFormat:@"<invalid enumerant %i>", inFormat];
	}
}


DDFormat DDFormatForExtension(NSString *inExtension)
{
	if ([inExtension hasPrefix:@"."]) inExtension = [inExtension substringFromIndex:1];
	
	if (![inExtension caseInsensitiveCompare:@"dat"]) return kDDFormat_DAT;
	if (![inExtension caseInsensitiveCompare:@"obj"]) return kDDFormat_OBJ;
	if (![inExtension caseInsensitiveCompare:@"mesh"]) return kDDFormat_Mesh;
	if (![inExtension caseInsensitiveCompare:@"drydock"]) return kDDFormat_DryDock;
	
	return kDDFormat_unknown;
}


DDFormat DDFormatForFileName(NSString *inName)
{
	return DDFormatForExtension([inName pathExtension]);
}


static NSString *WorkingDirectory(void)
{
	static NSString			*result = nil;
	
	if (nil == result)
	{
		char					cwdBuf[MAXPATHLEN];
		
		getwd(cwdBuf);
		// FIXME: assumes UTF-8
		result = [[NSString alloc] initWithUTF8String:cwdBuf];
	}
	
	return result;
}


#ifndef DDOLITE_MACOSX
void CFShow(void *obj)
{
	Print(@"%@", obj);
}
#endif
