/*
	DDDocument.mm
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

#import "DDDocument.h"
#import "DDDocumentWindowController.h"
#import "DDMesh.h"
#import "DDCompareDialogController.h"
#import "DDError.h"
#import "DDProblemReportManager.h"
#import "Logging.h"
#import "DDScaleDialogController.h"
#import "DDPantherCompatibility.h"
#import "NSData+Deflate.h"
#import "DDUtilities.h"


@interface DDDocument(Private)

- (void)setNameFromURL:(NSURL *)inURL;
- (void)undoAction:(NSString *)inName replacingMesh:(DDMesh *)inMesh;
- (void)setUpMeshReplacingUndoActionNamed:(NSString *)inName;
- (BOOL)writeDryDockDocumentToURL:(NSURL *)inAbsoluteURL issues:ioIssues;

@end


@implementation DDDocument

- (id)init
{
    self = [super init];
    if (self)
	{
		
    }
    return self;
}


- (void)dealloc
{
	[_mesh autorelease];
	[_controller autorelease];
	[_name autorelease];
	
	[super dealloc];
}


- (void)makeWindowControllers
{
	_controller = [[DDDocumentWindowController alloc] initWithWindowNibName:@"DDDocument"];
	[self addWindowController:_controller];
	[_controller setMesh:_mesh];
}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	TraceEnterMsg(@"Called with absoluteURL=%@, typeName=\"%@\"", absoluteURL, typeName);
	
	BOOL					success;
	DDProblemReportManager	*problemManager;
	
	if (NULL != outError) *outError = nil;
	
	[_mesh release];
	_mesh = nil;
	[_name release];
	_name = nil;
	
	problemManager = [[DDProblemReportManager alloc] init];
	[problemManager setContext:kContextOpen];
	
	NS_DURING
	{
		if ([typeName isEqual:@"Oolite Model"])
		{
			_mesh = [[DDMesh alloc] initWithOoliteDAT:absoluteURL issues:problemManager];
			success = (nil != _mesh);
		}
		else if ([typeName isEqual:@"Lightwave OBJ Model"])
		{
			_mesh = [[DDMesh alloc] initWithLightwaveOBJ:absoluteURL issues:problemManager];
			success = (nil != _mesh);
		}
		else
		{
			[problemManager addStopIssueWithKey:@"unknownFormat" localizedFormat:@"The document could not be opened, because the file type could not be recognised."];
		}
	}
	//@catch (id localException)
	NS_HANDLER
	{
		LogMessage(@"Caught %@", localException);
		
		NSString			*desc;
		
		if ([localException isKindOfClass:[NSException class]])
		{
			desc = [NSString stringWithFormat:@"%@: %@", [localException name], [localException reason]];
		}
		else
		{
			desc = [localException description];
		}
		
		[problemManager addStopIssueWithKey:@"exception" localizedFormat:@"An uncaught exception occurred. This is almost certainly a programming error; please report it.\n%@", desc];
	}
	NS_ENDHANDLER
	
	success = [problemManager showReportApplicationModal];
	if (!success && NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
	
	[problemManager release];
	
	if (success && nil == _mesh)
	{
		TraceMessage(@"Document loading failed.");
		success = NO;
	}
	
	if (success)
	{
		TraceMessage(@"Document successfully loaded.");
		_name = [_mesh name];
		if (nil == _name) [self setNameFromURL:absoluteURL];
		
		[_controller setMesh:_mesh];
	}
	
    return success;
	TraceExit();
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
{
	TraceEnterMsg(@"Called with absoluteOriginalContentsURL=%@, absoluteURL=%@, typeName=\"%@\"",
					absoluteOriginalContentsURL, absoluteURL, typeName);
	
	BOOL					OK = NO;
	DDProblemReportManager	*problemManager;
	
	if (NULL != outError) *outError = nil;
	if (nil == _mesh) return NO;
	
	// Auto-saving and split files like OBJ won’t go well together… revisit this. Should possibly
	// return Dry Dock Document from autosavingFileType when implemented.
	if (NSAutosaveOperation == (int)saveOperation) return NO;
	
	problemManager = [[DDProblemReportManager alloc] init];
	
	//@try
	NS_DURING
	{
		if ([typeName isEqual:@"Dry Dock Document"])
		{
			[self gatherIssuesWithGeneratingPropertyListRepresentation:problemManager];
			OK = [problemManager showReportApplicationModal];
			if (OK)
			{
				[problemManager clear];
				OK = [self writeDryDockDocumentToURL:absoluteURL issues:problemManager];
				[problemManager showReportApplicationModal];
			}
			if (!OK)
			{
				if (NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
			}
		}
		else if ([typeName isEqual:@"Oolite Model"])
		{
			[_mesh gatherIssues:problemManager withWritingOoliteDATToURL:absoluteURL];
			OK = [problemManager showReportApplicationModal];
			if (OK)
			{
				[problemManager clear];
				OK = [_mesh writeOoliteDATToURL:absoluteURL issues:problemManager];
				[problemManager showReportApplicationModal];
			}
			if (!OK)
			{
				if (NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
			}
		}
		else if ([typeName isEqual:@"Lightwave OBJ Model"])
		{
			[_mesh gatherIssues:problemManager withWritingLightwaveOBJToURL:absoluteURL];
			OK = [problemManager showReportApplicationModal];
			if (OK)
			{
				[problemManager clear];
				OK = [_mesh writeLightwaveOBJToURL:absoluteURL finalLocationURL:absoluteOriginalContentsURL issues:problemManager];
				[problemManager showReportApplicationModal];
			}
			if (!OK)
			{
				if (NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
			}
		}
		else
		{
			NSLog(@"Can't write to file %@ of unknown type %@.", absoluteURL, typeName);
			OK = NO;
		}
	}
	//@catch (id localException)
	NS_HANDLER
	{
		LogMessage(@"Caught %@", localException);
		
		NSString			*desc;
		
		if ([localException isKindOfClass:[NSException class]])
		{
			desc = [NSString stringWithFormat:@"%@: %@", [localException name], [localException reason]];
		}
		else
		{
			desc = [localException description];
		}
		
		[problemManager addStopIssueWithKey:@"exception" localizedFormat:@"An uncaught exception occurred. This is almost certainly a programming error; please report it.\n%@", desc];
	}
	NS_ENDHANDLER
	
	[problemManager release];
	
	return OK;
	TraceExit();
}


- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
{
	TraceEnterMsg(@"Called with typeName=\"%@\"", typeName);
	
	NSMutableDictionary		*result = nil;
	OSType					type = 0;
	
	if (nil == result) result = [[NSMutableDictionary alloc] init];
	
	if ([typeName isEqual:@"Dry Dock Document"])
	{
		type = 'DryD';
	}
	else if ([typeName isEqual:@"Oolite Model"])
	{
		type = 'OoDa';
	}
	else if ([typeName isEqual:@"Lightwave OBJ Model"])
	{
	//	type = 'OBJ ';
		type = 'TEXT';
	}
	else if ([typeName isEqual:@"Meshwork Model"])
	{
		type = 'Mesh';
	}
	
	if (NSSaveOperation != saveOperation) [result setObject:[NSNumber numberWithUnsignedLong:'DryD'] forKey:NSFileHFSCreatorCode];
	if (0 != type) [result setObject:[NSNumber numberWithUnsignedLong:type] forKey:NSFileHFSTypeCode];
	
	TraceMessage(@"Returning %@", result);
	return [result autorelease];
	TraceExit();
}


// Panther compatibility methods
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)typeName
{
	TraceEnterMsg(@"Called with fileName=\"%@\", typeName=\"%@\"",
					fileName, typeName);
	
	BOOL					result;
	
	result = [self readFromURL:[NSURL fileURLWithPath:fileName] ofType:typeName error:NULL];
	
	return result;
	TraceExit();
}


- (BOOL)writeToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName originalFile:(NSString *)fullOriginalDocumentPath saveOperation:(NSSaveOperationType)saveOperationType
{
	TraceEnterMsg(@"Called with fullOriginalDocumentPath=\"%@\", fullDocumentPath=\"%@\", documentTypeName=\"%@\"",
					fullOriginalDocumentPath, fullDocumentPath, documentTypeName);
	
	BOOL					result;
	
	result = [self writeToURL:[NSURL fileURLWithPath:fullDocumentPath]
					   ofType:documentTypeName
			 forSaveOperation:saveOperationType
		  originalContentsURL:[NSURL fileURLWithPath:fullOriginalDocumentPath]
						error:NULL];
	
	return result;
	TraceExit();
}


- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType
{
	TraceEnterMsg(@"Called with fullDocumentPath\"%@\", documentTypeName=\"%@\"",
					fullDocumentPath, documentTypeName);
	
	NSDictionary			*result;
	NSURL					*url;
	
	url = [NSURL fileURLWithPath:fullDocumentPath];
	result = [self fileAttributesToWriteToURL:url
									   ofType:documentTypeName
							 forSaveOperation:saveOperationType
						  originalContentsURL:url
										error:NULL];
	
	return result;
	TraceExit();
}


- (NSString *)modelName
{
	if (nil == _name) _name = [[self displayName] retain];
	return [[_name retain] autorelease];
}


- (void)setModelName:(NSString *)inModelName
{
	if (_name != inModelName)
	{
		[_name release];
		_name = inModelName;
	}
}


- (void)setNameFromURL:(NSURL *)inURL
{
	NSString				*path;
	NSString				*displayName;
	NSString				*rawName;
	
	if ([inURL isFileURL])
	{
		path = [inURL path];
		displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
		rawName = [path lastPathComponent];
		if ([displayName isEqual:rawName])
		{
			_name = [[rawName stringByDeletingPathExtension] retain];
		}
		else
		{
			_name = [displayName retain];
		}
	}
}


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	[savePanel setTreatsFilePackagesAsDirectories:YES];
	return YES;
}


- (void)undoAction:(NSString *)inName replacingMesh:(DDMesh *)inMesh
{
	[self setUpMeshReplacingUndoActionNamed:inName];
	[_mesh release];
	_mesh = [inMesh retain];
	[_controller setMesh:_mesh];
}


- (void)setUpMeshReplacingUndoActionNamed:(NSString *)inName
{
	NSUndoManager			*undoer;
	
	undoer = [self undoManager];
	[[undoer prepareWithInvocationTarget:self] undoAction:inName replacingMesh:_mesh];
	[undoer setActionName:NSLocalizedString(inName, NULL)];
}


- (void)sendMeshMessage:(SEL)inMessage undoableWithName:(NSString *)inName
{
	DDMesh					*newMesh;
	NSError					*error;
	
	newMesh = [_mesh copy];
	if (newMesh)
	{
		[self setUpMeshReplacingUndoActionNamed:inName];
		[_mesh release];
		_mesh = newMesh;
		[_controller setMesh:_mesh];
		[_mesh performSelector:inMessage];
	}/*
	else
	{
		error = [DDError errorWithCode:kDDErrorAllocationFailed];
		[self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
	}*/
}


// For actions which are their own inverse
- (void)sendMeshMessage:(SEL)inMessage selfReversibleAction:(SEL)inAction withName:(NSString *)inName
{
	NSUndoManager			*undoer;
	
	// Reverse Winding is a self-reversing operation
	undoer = [self undoManager];
	[undoer registerUndoWithTarget:self selector:inAction object:nil];
	[undoer setActionName:NSLocalizedString(inName, NULL)];
	
	[_mesh performSelector:inMessage];
}


- (IBAction)recalcNormals:sender
{
	[self sendMeshMessage:@selector(recalculateNormals) undoableWithName:@"Recalculate Normals"];
}


- (IBAction)triangulate:sender
{
	[self sendMeshMessage:@selector(triangulate) undoableWithName:@"Triangulate"];
}


- (IBAction)recenter:sender
{
	[self sendMeshMessage:@selector(recenter) undoableWithName:@"Recentre"];
}


- (IBAction)flipX:sender
{
	[self sendMeshMessage:@selector(flipX) selfReversibleAction:_cmd withName:@"Flip X"];
}


- (IBAction)flipY:sender
{
	[self sendMeshMessage:@selector(flipY) selfReversibleAction:_cmd withName:@"Flip Y"];
}


- (IBAction)flipZ:sender
{
	[self sendMeshMessage:@selector(flipZ) selfReversibleAction:_cmd withName:@"Flip Z"];
}


- (void)scaleX:(float)inX y:(float)inY z:(float)inZ
{
	DDMesh					*newMesh;
	
	newMesh = [_mesh copy];
	if (nil != newMesh)
	{
		[self setUpMeshReplacingUndoActionNamed:@"Scale"];
		[newMesh scaleX:inX y:inY z:inZ];
		[_mesh release];
		_mesh = newMesh;
		[_controller setMesh:_mesh];
	}
}


- (IBAction)reverseWinding:sender
{
	[self sendMeshMessage:@selector(reverseWinding) selfReversibleAction:_cmd withName:@"Reverse Winding"];
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)inItem
{
	NSMenuItem				*item;
	SEL						action;
	BOOL					enabled;
	
	enabled = [super validateMenuItem:inItem];
	action = [inItem action];
	
	if ([(NSObject *)inItem isKindOfClass:[NSMenuItem class]])
	{
		item = (NSMenuItem *)inItem;
		
		if (action == @selector(triangulate:))
		{
			enabled = [_mesh hasNonTriangles];
		}
	}
	
	return enabled;
}


- (IBAction)doCompareDialog:sender
{
	[DDCompareDialogController runCompareDialogForDocument:self];
}


- (IBAction)doScaleDialog:sender
{
	[DDScaleDialogController runScaleDialogForDocument:self];
}


- (DDMesh *)mesh
{
	return _mesh;
}


typedef struct
{
	uint8_t				cookie[4];	// 'D', 'r', 'y', 'D'
	uint32_t			length;		// Decompressed length, little-endian
} DryDockDocumentHeader;


- (id)initWithPropertyListRepresentation:(id)inPList issues:(DDProblemReportManager *)ioIssues
{
	
}


- (void)gatherIssuesWithGeneratingPropertyListRepresentation:(DDProblemReportManager *)ioManager
{
	return [_mesh gatherIssuesWithGeneratingPropertyListRepresentation:ioManager];
}


- (id)propertyListRepresentationWithIssues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	id						plist;
	
	plist = [_mesh propertyListRepresentationWithIssues:ioIssues];
	if (nil == plist) return nil;
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
							plist, @"root mesh",
							[NSNumber numberWithInt:1], @"format",
							ApplicationNameAndVersionString(), @"generator",
							nil];
	
	TraceExit();
}


- (BOOL)writeDryDockDocumentToURL:(NSURL *)inAbsoluteURL issues:ioIssues
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

@end
