/*
	DDDocumentInspector.mm
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

#import "DDDocumentInspector.h"
#import "DDUtilities.h"
#import "DDMesh.h"


NSMutableDictionary			*sInspectorsForDocuments = nil;


static inline id KeyForDocument(DDModelDocument *inDocument)
{
	return [NSNumber numberWithPointer:(uintptr_t)inDocument];
}


@interface DDDocumentInspector (Private)

- (id)initWithDocument:(DDModelDocument *)inDocument;
- (void)update;

@end


@implementation DDDocumentInspector

+ (id)inspectorForDocument:(DDModelDocument *)inDocument
{
	id					result;
	id					key;
	
	key = KeyForDocument(inDocument);
	result = [sInspectorsForDocuments objectForKey:key];
	if (nil == result)
	{
		result = [[[self alloc] initWithDocument:inDocument] autorelease];
		if (nil == sInspectorsForDocuments) sInspectorsForDocuments = [[NSMutableDictionary alloc] init];
		[sInspectorsForDocuments setObject:result forKey:key];
	}
	
	return result;
}


- (id)initWithDocument:(DDModelDocument *)inDocument
{
	NSNotificationCenter		*nctr;
	
	self = [super init];
	if (nil != self)
	{
		_document = inDocument;		// Not retained; we watch for death notifications instead.
		nctr = [NSNotificationCenter defaultCenter];
		[nctr addObserver:self selector:@selector(documentDestroyed:) name:kNotificationDDModelDocumentDestroyed object:_document];
		[nctr addObserver:self selector:@selector(documentPropertiesChanged:) name:kNotificationDDModelDocumentNameChanged object:_document];
		[nctr addObserver:self selector:@selector(documentPropertiesChanged:) name:kNotificationDDModelDocumentOverallDimensionsChanged object:_document];
	}
	
	return self;
}


- (void)dealloc
{
	[sInspectorsForDocuments removeObjectForKey:KeyForDocument(_document)];
	_document = nil;	// Not retained
	[view autorelease];
	[formatter autorelease];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)documentDestroyed:notification
{
	[[self retain] autorelease];
	[sInspectorsForDocuments removeObjectForKey:KeyForDocument(_document)];
	_document = nil;
	[self objectLost];
}


- (void)documentPropertiesChanged:notification
{
	[self update];
}


- (void)update
{
	[nameField setObjectValue:[_document name]];
	[lengthField setFloatValue:[_document length]];
	[widthField setFloatValue:[_document width]];
	[heightField setFloatValue:[_document height]];
	[vertexCountField setIntValue:[[_document rootMesh] vertexCount]];
	[faceCountField setIntValue:[[_document rootMesh] faceCount]];
}


- (IBAction)takeName:sender
{
	// FIXME: should be undoable (?)
	[_document setName:[sender objectValue]];
}


- (NSView *)inspectorView
{
	if (nil == view)
	{
		[NSBundle loadNibNamed:@"Document Inspector" owner:self];
	}
	[self update];
	return view;
}

@end


@implementation DDModelDocument (DDInspectable)

- (DDInspectorPane *)inspector
{
	return [DDDocumentInspector inspectorForDocument:self];
}

@end
