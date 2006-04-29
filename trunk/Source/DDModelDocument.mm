/*
	DDModelDocument.mm
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

#import "DDModelDocument.h"
#import "DDMesh.h"
#import "Logging.h"
#import "NSData+Deflate.h"
#import "DDUtilities.h"
#import "CocoaExtensions.h"
#import "DDProblemReportManager.h"
#import "DDPantherCompatibility.h"


NSString *kNotificationDDModelDocumentRootMeshChanged =				@"de.berlios.drydock DDModelDocumentRootMeshChanged";
NSString *kNotificationDDModelDocumentNameChanged =					@"de.berlios.drydock DDModelDocumentNameChanged";
NSString *kNotificationDDModelDocumentOverallDimensionsChanged =	@"de.berlios.drydock DDModelDocumentOverallDimensionsChanged";
NSString *kNotificationDDModelDocumentDestroyed =					@"de.berlios.drydock DDModelDocumentDestroyed";


typedef struct
{
	uint8_t				cookie[4];	// 'D', 'r', 'y', 'D'
	uint32_t			length;		// Decompressed length, little-endian
} DryDockDocumentHeader;


enum
{
	kMaxFormat			= 1
};


@implementation DDModelDocument

- (id)init
{
	return [self initWithMesh:nil];
}


- (id)initWithMesh:(DDMesh *)inMesh
{
	TraceEnter();
	
	self = [super init];
	if (nil != self)
	{
		[self setRootMesh:inMesh];
	}
	
	return self;
	TraceExit();
}


- (id)initWithOoliteDAT:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	DDMesh					*mesh;
	
	mesh = [[DDMesh alloc] initWithOoliteDAT:inFile issues:ioIssues];
	if (nil != mesh)
	{
		self = [self initWithMesh:mesh];
		if (nil != self) _name = [[mesh name] retain];
		else [ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
		[mesh release];
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
	TraceExit();
}


- (id)initWithLightwaveOBJ:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	DDMesh					*mesh;
	
	mesh = [[DDMesh alloc] initWithLightwaveOBJ:inFile issues:ioIssues];
	if (nil != mesh)
	{
		self = [self initWithMesh:mesh];
		if (nil != self) _name = [[mesh name] retain];
		else [ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
		[mesh release];
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
	TraceExit();
}


- (id)initWithPropertyListRepresentation:(id)inPList issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	BOOL					OK = YES;
	NSDictionary			*dict;
	id						object;
	int						format;
	
	if (![inPList isKindOfClass:[NSDictionary class]])
	{
		OK = NO;
		LogMessage(@"Input %@ is not a dictionary.", inPList);
		[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
	}
	
	if (OK)
	{
		dict = inPList;
		
		object = [dict objectForKey:@"format"];
		if (![object respondsToSelector:@selector(intValue)])
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
		}
		else
		{
			format = [object intValue];
			if (kMaxFormat < format || format < 1)
			{
				OK = NO;
				[ioIssues addStopIssueWithKey:@"outOfDateDryDock" localizedFormat:@"This document appears to be generated by a newer version of Dry Dock; it is in an incompatible format."];
			}
		}
	}
	
	if (OK)
	{
		object = [dict objectForKey:@"root mesh"];
		if (![object isKindOfClass:[NSDictionary class]])
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
		}
		else
		{
			object = [[DDMesh alloc] initWithPropertyListRepresentation:object issues:ioIssues];
			if (nil != object) [self setRootMesh:object];
			else OK = NO;
		}
	}
	
	if (OK)
	{
		object = [dict objectForKey:@"name"];
		if ([object isKindOfClass:[NSString class]]) _name = [object retain];
		if (nil == _name) _name = [[_rootMesh name] retain];
	}
	
	if (!OK)
	{
		[self release];
		self = nil;
	}
	
	return self;
	TraceExit();
}


- (id)initWithDryDockDocument:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnterMsg(@"Called for %@", inFile);
	
	BOOL					OK = YES;
	NSData					*data;
	NSError					*error;
	DryDockDocumentHeader	*header;
	uint32_t				rawLength, decompressedLength;
	NSData_InflateResult	result;
	id						plist;
	NSString				*errorDesc = nil;
	
	data = [NSData dataWithContentsOfURL:inFile options:0 errorCompat:&error];
	if (nil == data)
	{
		OK = NO;
		[ioIssues addStopIssueWithKey:@"noDataLoaded" localizedFormat:@"No data could be loaded from %@. %@", [inFile displayString], error ? [error localizedFailureReasonCompat] : @""];
	}
	
	if (OK)
	{
		rawLength = [data length];
		if (rawLength < sizeof *header) OK = NO;
		else
		{
			header = (DryDockDocumentHeader *)[data bytes];
			if (header->cookie[0] != 'D' || header->cookie[1] != 'r' || header->cookie[2] != 'y' || header->cookie[3] != 'D') OK = NO;
			else decompressedLength = CFSwapInt32LittleToHost(header->length);
		}
		if (!OK)
		{
			[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
		}
	}
	
	if (OK)
	{
		data = [data subdataWithRange:NSMakeRange(sizeof *header, rawLength - sizeof *header)];
		result = [data inflatedData:&data outputSize:decompressedLength ifPrefixedWith:nil];
		if (kInflateSuccess != result)
		{
			OK = NO;
			if (kInflateAllocationFailure == result)
			{
				[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage"];
			}
			else
			{
				[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", @""];
			}
		}
	}
	
	if (OK)
	{
		plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorDesc];
		if (nil == plist)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"notValidDryDock" localizedFormat:@"This is not a valid Dry Dock document. %@", errorDesc ? errorDesc : @""];
		}
	}
	
	if (OK)
	{
		self = [self initWithPropertyListRepresentation:plist issues:ioIssues];
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
	TraceExit();
}


- (void)dealloc
{
	TraceEnter();
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDModelDocumentDestroyed object:self];
	
	[_rootMesh autorelease];
	[_name autorelease];
	
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:nil object:self];
	[super dealloc];
	
	TraceExit();
}


- (void)gatherIssuesWithGeneratingPropertyListRepresentation:(DDProblemReportManager *)ioManager
{
	return [_rootMesh gatherIssuesWithGeneratingPropertyListRepresentation:ioManager];
}


- (void)rootMeshModified:notification
{
	Scalar						l, w, h;
	
	// Check for changes in dimensions
	l = [_rootMesh length];
	w = [_rootMesh width];
	h = [_rootMesh height];
	
	if (l != _length || w != _width || h != _height)
	{
		_length = l;
		_width = w;
		_height = h;
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDModelDocumentOverallDimensionsChanged object:self];
	}
}


- (void)setRootMesh:(DDMesh *)inMesh
{
	TraceEnter();
	
	NSNotificationCenter		*nctr;
	
	if (inMesh != _rootMesh)
	{
		nctr = [NSNotificationCenter defaultCenter];
		if (nil != _rootMesh)
		{
			[nctr removeObserver:self name:nil object:_rootMesh];
			[_rootMesh autorelease];
		}
		_rootMesh = [inMesh retain];
		[nctr addObserver:self selector:@selector(rootMeshModified:) name:kNotificationDDMeshModified object:_rootMesh];
		[self rootMeshModified:nil];
		[nctr postNotificationName:kNotificationDDModelDocumentRootMeshChanged object:self];
	}
	
	TraceExit();
}


- (DDMesh *)rootMesh
{
	return _rootMesh;
}


- (void)setName:(NSString *)inName
{
	TraceEnter();
	
	if (inName != _name)
	{
		[_name autorelease];
		_name = [inName retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDModelDocumentNameChanged object:self];
	}
	
	TraceExit();
}


- (NSString *)name
{
	return _name;
}


- (Scalar)length
{
	return _length;
}


- (Scalar)width
{
	return _width;
}


- (Scalar)height
{
	return _height;
}


- (id)propertyListRepresentationWithIssues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	id						plist;
	
	plist = [_rootMesh propertyListRepresentationWithIssues:ioIssues];
	if (nil == plist) return nil;
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
							plist, @"root mesh",
							[NSNumber numberWithInt:1], @"format",
							ApplicationNameAndVersionString(), @"generator",
							[NSDate date], @"modification date",
							_name, @"name",	// Note: _name could be nil, stopping the plist here!
							nil];
	
	TraceExit();
}


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingDryDockDocumentToURL:(NSURL *)inFile
{
	TraceEnter();
	
	return [self gatherIssuesWithGeneratingPropertyListRepresentation:ioManager];
	
	TraceExit();
}


- (BOOL)writeDryDockDocumentToURL:(NSURL *)inAbsoluteURL issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	BOOL					OK = YES;
	id						plist;
	NSData					*data;
	NSString				*errorDesc;
	NSError					*error;
	DryDockDocumentHeader	headerBytes = { 'D', 'r', 'y', 'D', 0 };
	NSData					*header = nil;
	BOOL					debugFormat;
	
	debugFormat = [[NSUserDefaults standardUserDefaults] boolForKey:@"debug format drydock documents"];
	
	plist = [self propertyListRepresentationWithIssues:ioIssues];
	if (nil == plist) OK = NO;
	
	if (OK)
	{
		data = [NSPropertyListSerialization dataFromPropertyList:plist format:debugFormat ? NSPropertyListXMLFormat_v1_0 : NSPropertyListBinaryFormat_v1_0 errorDescription:&errorDesc];
		if (nil == data)
		{
			OK = NO;
			[ioIssues addNoteIssueWithKey:@"noConvertToPList" localizedFormat:@"The data generated by the document could not be converted to the required format (%@).", errorDesc];
		}
	}
	
	if (OK)
	{
		headerBytes.length = CFSwapInt32LittleToHost([data length]);
		header = [NSData dataWithBytes:&headerBytes length:sizeof headerBytes];
		data = [data deflatedDataPrefixedWith:header level:debugFormat ? 0 : 9];
		if (nil == header || nil == data)
		{
			OK = NO;
			[ioIssues addStopIssueWithKey:@"allocFailed" localizedFormat:@"A memory allocation failed. This is probably due to a memory shortage."];
		}
	}
	
	if (OK)
	{
		OK = [data writeToURL:inAbsoluteURL atomically:NO errorCompat:&error];
		if (!OK)
		{
			if (nil != error) [ioIssues addStopIssueWithKey:@"writeFailed" localizedFormat:@"The document could not be saved. %@", [error localizedFailureReasonCompat]];
			else [ioIssues addStopIssueWithKey:@"writeFailed" localizedFormat:@"The document could not be saved, because an unknown error occured."];
		}
	}
	return OK;
	
	TraceExit();
}


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingOoliteDATToURL:(NSURL *)inFile
{
	return [_rootMesh gatherIssues:ioManager withWritingOoliteDATToURL:inFile];
}


- (BOOL)writeOoliteDATToURL:(NSURL *)inFile issues:(DDProblemReportManager *)ioManager
{
	return [_rootMesh writeOoliteDATToURL:inFile issues:ioManager];
}


- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingLightwaveOBJToURL:(NSURL *)inFile
{
	return [_rootMesh gatherIssues:ioManager withWritingLightwaveOBJToURL:inFile];
}


- (BOOL)writeLightwaveOBJToURL:(NSURL *)inFile finalLocationURL:(NSURL *)inFinalLocation issues:(DDProblemReportManager *)ioManager
{
	return [_rootMesh writeLightwaveOBJToURL:inFile finalLocationURL:inFinalLocation issues:ioManager];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{rootMesh=%@}", [self className], self, _rootMesh];
}

@end