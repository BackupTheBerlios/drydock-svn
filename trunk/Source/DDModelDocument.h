/*
	DDModelDocument.h
	Dry Dock for Oolite
	$Id$
	
	Model object representing a Dry Dock document, as opposed to DDDocument which is a controller
	descended from NSDocument.
	
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

#import <Foundation/Foundation.h>
#import "DDPropertyListRepresentation.h"
#import "phystypes.h"

@class DDMesh;


@interface DDModelDocument: NSObject <DDPropertyListRepresentation>
{
	DDMesh					*_rootMesh;
	NSString				*_name;
	Scalar					_length, _width, _height;
}

- (id)init;
- (id)initWithMesh:(DDMesh *)inMesh;

- (void)setRootMesh:(DDMesh *)inMesh;
- (DDMesh *)rootMesh;

- (void)setName:(NSString *)inName;
- (NSString *)name;

// Total bounding dimensions of root mesh and subentities
- (Scalar)length;
- (Scalar)width;
- (Scalar)height;

- (id)initWithDryDockDocument:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;
- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingDryDockDocumentToURL:(NSURL *)inFile;
- (BOOL)writeDryDockDocumentToURL:(NSURL *)inAbsoluteURL issues:(DDProblemReportManager *)ioIssues;

- (id)initWithOoliteDAT:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;
- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingOoliteDATToURL:(NSURL *)inFile;
- (BOOL)writeOoliteDATToURL:(NSURL *)inFile issues:(DDProblemReportManager *)ioManager;

- (id)initWithLightwaveOBJ:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues;
- (void)gatherIssues:(DDProblemReportManager *)ioManager withWritingLightwaveOBJToURL:(NSURL *)inFile;
- (BOOL)writeLightwaveOBJToURL:(NSURL *)inFile finalLocationURL:(NSURL *)inFinalLocation issues:(DDProblemReportManager *)ioManager;

@end


extern NSString *kNotificationDDModelDocumentRootMeshChanged;	// Sent on setRootMesh:
extern NSString *kNotificationDDModelDocumentNameChanged;		// Sent on setName:
extern NSString *kNotificationDDModelDocumentOverallDimensionsChanged;
extern NSString *kNotificationDDModelDocumentDestroyed;			// Sent on dealloc
