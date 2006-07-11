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
#import "DDUtilities.h"
#import "DDModelDocument.h"


@interface DDDocument(Private)

- (void)setNameFromURL:(NSURL *)inURL;
- (void)undoAction:(NSString *)inName replacingMesh:(DDMesh *)inMesh;
- (void)setUpMeshReplacingUndoActionNamed:(NSString *)inName;

@end


@implementation DDDocument

- (id)init
{
    self = [super init];
    if (self)
	{
		_document = [[DDModelDocument alloc] init];
    }
    return self;
}


- (void)dealloc
{
	[_document autorelease];
	[_windowController setModelDocument:nil];
	
	[super dealloc];
}


- (void)makeWindowControllers
{
	_windowController = [[DDDocumentWindowController alloc] initWithWindowNibName:@"DDDocument"];
	[self addWindowController:_windowController];
	[_windowController release];
	[_windowController setModelDocument:_document];
}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	TraceEnterMsg(@"Called with absoluteURL=%@, typeName=\"%@\"", absoluteURL, typeName);
	
	BOOL					success;
	DDProblemReportManager	*problemManager;
	DDModelDocument			*document = nil;
	
	if (NULL != outError) *outError = nil;
	
	problemManager = [[DDProblemReportManager alloc] init];
	[problemManager setContext:kContextOpen];
	
	NS_DURING
	{
		if ([typeName isEqual:@"Oolite Model"])
		{
			document = [[DDModelDocument alloc] initWithOoliteDAT:absoluteURL issues:problemManager];
			success = (nil != document);
		}
		else if ([typeName isEqual:@"WaveFront OBJ Model"])
		{
			document = [[DDModelDocument alloc] initWithWaveFrontOBJ:absoluteURL issues:problemManager];
			success = (nil != document);
		}
		else if ([typeName isEqual:@"Dry Dock Document"])
		{
			document = [[DDModelDocument alloc] initWithDryDockDocument:absoluteURL issues:problemManager];
			success = (nil != document);
		}
		else
		{
			[problemManager addStopIssueWithKey:@"unknownFormat" localizedFormat:@"The document could not be opened, because the file type could not be recognised."];
		}
		if (nil != document)
		{
			[_document autorelease];
			_document = document;
			success = YES;
		}
		else success = NO;
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
		
		success = NO;
		[problemManager addStopIssueWithKey:@"exception" localizedFormat:@"An uncaught exception occurred. This is almost certainly a programming error; please report it.\n%@", desc];
	}
	NS_ENDHANDLER
	
	success = [problemManager showReportApplicationModal];
	if (!success && NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
	
	[problemManager release];
	
	if (success)
	{
		TraceMessage(@"Document successfully loaded.");
		[_windowController setModelDocument:document];
	}
	
    return success;
	TraceExit();
}


- (BOOL)writeSafelyToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError
{
	TraceEnterMsg(@"Called with absoluteURL=%@",
					absoluteURL);
	
	BOOL					result;
	
	_actualSaveDestination = [absoluteURL retain];
	result = [super writeSafelyToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
	[_actualSaveDestination release];
	_actualSaveDestination = nil;
	return result;
	
	TraceExit();
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
{
	TraceEnterMsg(@"Called with absoluteOriginalContentsURL=%@, absoluteURL=%@, fileURL=%@, actualSaveDestination=%@, typeName=\"%@\"",
					absoluteOriginalContentsURL, absoluteURL, [self fileURL], _actualSaveDestination, typeName);
	
	BOOL					OK = NO;
	DDProblemReportManager	*problemManager;
	
	if (NULL != outError) *outError = nil;
	
	// Auto-saving and split files like OBJ won’t go well together… revisit this. Should possibly
	// return Dry Dock Document from autosavingFileType when fully implemented.
	if (NSAutosaveOperation == (int)saveOperation) return NO;
	
	if (nil != _actualSaveDestination) absoluteOriginalContentsURL = _actualSaveDestination;
	
	problemManager = [[DDProblemReportManager alloc] init];
	
	//@try
	NS_DURING
	{
		if ([typeName isEqual:@"Dry Dock Document"])
		{
			[_document gatherIssuesWithGeneratingPropertyListRepresentation:problemManager];
			OK = [problemManager showReportApplicationModal];
			if (OK)
			{
				[problemManager clear];
				OK = [_document writeDryDockDocumentToURL:absoluteURL issues:problemManager];
				[problemManager showReportApplicationModal];
			}
			if (!OK)
			{
				if (NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
			}
		}
		else if ([typeName isEqual:@"Oolite Model"])
		{
			[[_document rootMesh] gatherIssues:problemManager withWritingOoliteDATToURL:absoluteURL];
			OK = [problemManager showReportApplicationModal];
			if (OK)
			{
				[problemManager clear];
				OK = [[_document rootMesh] writeOoliteDATToURL:absoluteURL issues:problemManager];
				[problemManager showReportApplicationModal];
			}
			if (!OK)
			{
				if (NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
			}
		}
		else if ([typeName isEqual:@"WaveFront OBJ Model"])
		{
			[[_document rootMesh] gatherIssues:problemManager withWritingWaveFrontOBJToURL:absoluteURL];
			OK = [problemManager showReportApplicationModal];
			if (OK)
			{
				[problemManager clear];
				OK = [[_document rootMesh] writeWaveFrontOBJToURL:absoluteURL finalLocationURL:absoluteOriginalContentsURL issues:problemManager];
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
	else if ([typeName isEqual:@"WaveFront OBJ Model"])
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


- (BOOL)writeWithBackupToFile:(NSString *)fullDocumentPath ofType:(NSString *)docType saveOperation:(NSSaveOperationType)saveOperationType
{
	TraceEnterMsg(@"Called with fullDocumentPath=\"%@\", docType=\"%@\"",
					fullDocumentPath, docType);
	
	BOOL					result;
	
	_actualSaveDestination = [[NSURL fileURLWithPath:fullDocumentPath] retain];
	result = [super writeWithBackupToFile:fullDocumentPath ofType:docType saveOperation:saveOperationType];
	[_actualSaveDestination release];
	_actualSaveDestination = nil;
	
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


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	[savePanel setTreatsFilePackagesAsDirectories:YES];
	return YES;
}


- (void)undoAction:(NSString *)inName replacingMesh:(DDMesh *)inMesh
{
	[self setUpMeshReplacingUndoActionNamed:inName];
	[_document setRootMesh:inMesh];
}


- (void)setUpMeshReplacingUndoActionNamed:(NSString *)inName
{
	NSUndoManager			*undoer;
	
	undoer = [self undoManager];
	[[undoer prepareWithInvocationTarget:self] undoAction:inName replacingMesh:[_document rootMesh]];
	[undoer setActionName:NSLocalizedString(inName, NULL)];
}


- (void)sendMeshMessage:(SEL)inMessage undoableWithName:(NSString *)inName
{
	DDMesh					*newMesh;
	
	newMesh = [[_document rootMesh] copy];
	if (newMesh)
	{
		[self setUpMeshReplacingUndoActionNamed:inName];
		[_document setRootMesh:newMesh];
		[newMesh performSelector:inMessage];
	}
}


// For actions which are their own inverse
- (void)sendMeshMessage:(SEL)inMessage selfReversibleAction:(SEL)inAction withName:(NSString *)inName
{
	NSUndoManager			*undoer;
	
	// Reverse Winding is a self-reversing operation
	undoer = [self undoManager];
	[undoer registerUndoWithTarget:self selector:inAction object:nil];
	[undoer setActionName:NSLocalizedString(inName, NULL)];
	
	[[_document rootMesh] performSelector:inMessage];
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
	
	newMesh = [[_document rootMesh] copy];
	if (nil != newMesh)
	{
		[self setUpMeshReplacingUndoActionNamed:@"Scale"];
		[newMesh scaleX:inX y:inY z:inZ];
		[_document setRootMesh:newMesh];
	}
}


- (IBAction)coalesceVertices:sender
{
	DDMesh					*newMesh;
	
	newMesh = [[_document rootMesh] copy];
	if (nil != newMesh)
	{
		[self setUpMeshReplacingUndoActionNamed:@"Coalesce Vertices"];
		[newMesh coalesceVertices];
		[_document setRootMesh:newMesh];
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
			enabled = [[_document rootMesh] hasNonTriangles];
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
	return [_document rootMesh];
}

@end
