/*
	DDDocument.mm
	Dry Dock for Oolite
	
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

#import "DDDocument.h"
#import "DDDocumentWindowController.h"
#import "DDMesh.h"
#import "DDCompareDialogController.h"
#import "DDError.h"
#import "DDProblemReportManager.h"
#import "Logging.h"


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


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
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
			_mesh = [[DDMesh alloc] initWithOoliteTextBasedMesh:absoluteURL issues:problemManager];
			success = (nil != _mesh);
		}
		else if ([typeName isEqual:@"Lightwave OBJ Model"])
		{
			_mesh = [[DDMesh alloc] initWithOBJ:absoluteURL issues:problemManager];
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
	if (!success) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
	
	[problemManager release];
	
	if (success && nil == _mesh) success = NO;
	
	if (success)
	{
		_name = [_mesh name];
		if (nil == _name) [self setNameFromURL:absoluteURL];
		
		[_controller setMesh:_mesh];
	}
	
    return success;
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL					success = NO;
	OSType					type = 0;
	FSRef					file;
	FSCatalogInfo			catInfo;
	FileInfo				*info;
	DDProblemReportManager	*problemManager;
	
	if (NULL != outError) *outError = nil;
	if (nil == _mesh) return NO;
	
	problemManager = [[DDProblemReportManager alloc] init];
	
	//@try
	NS_DURING
	{
		if ([typeName isEqual:@"org.aegidian.oolite.mesh"])
		{
			[_mesh gatherIssues:problemManager withWritingOoliteTextBasedMeshToURL:absoluteURL];
			if ([problemManager showReportApplicationModal])
			{
				success = [_mesh writeOoliteTextBasedMeshToURL:absoluteURL error:outError];
				type = 'OoDa';
			}
			else
			{
				if (NULL != outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
			}
		}
		else
		{
			NSLog(@"Can't write to file %@ of type %@.", absoluteURL, typeName);
			success = NO;
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
	
	// Set type code
	if (success && 0 != type && [absoluteURL isFileURL])
	{
		success = CFURLGetFSRef((CFURLRef)absoluteURL, &file);
		if (success) success = !FSGetCatalogInfo(&file, kFSCatInfoFinderInfo, &catInfo, NULL, NULL, NULL);
		if (success)
		{
			info = (FileInfo *)catInfo.finderInfo;
			info->fileType = type;
			info->fileCreator = 'DryD';
			
			FSSetCatalogInfo(&file, kFSCatInfoFinderInfo, &catInfo);
		}
		
		success = YES;	// Failure to set type code is non-fatal
	}
	
	[problemManager release];
	
	return success;
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
	}
	else
	{
		error = [DDError errorWithCode:kDDErrorAllocationFailed];
		[self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
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


- (DDMesh *)mesh
{
	return _mesh;
}

@end
