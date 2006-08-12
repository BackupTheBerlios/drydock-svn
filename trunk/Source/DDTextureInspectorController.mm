//
//  DDTextureInspectorController.m
//  Dry Dock
//
//  Created by Jens Ayton on 2006-08-11.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DDTextureInspectorController.h"
#import "DDTextureBuffer.h"
#import "Logging.h"


@interface DDTextureInspectorController(Private)

- (void)setSelection:(DDTextureBuffer *)buffer;

@end


@implementation DDTextureInspectorController

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	NSNotificationCenter *nctr;
	nctr = [NSNotificationCenter defaultCenter];
	[nctr addObserver:self selector:@selector(activeSetChanged:) name:kNotificationDDTextureBufferActiveSetChanged object:[DDTextureBuffer class]];
	// Note: refCountChanged is recieved for all DDTextureBuffers. The alternative turned out to be… complicated.
	[nctr addObserver:self selector:@selector(changeSelection:) name:kNotificationDDTextureBufferRefCountChanged object:[DDTextureBuffer class]];
	[nctr addObserver:self selector:@selector(changeSelection:) name:NSTableViewSelectionDidChangeNotification object:table];
	
	return self;
}


- (void)awakeFromNib
{
	[self setSelection:nil];
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}


- (void)activeSetChanged:(NSNotification *)notification
{
	[self setSelection:nil];
	[table reloadData];
}


- (void)changeSelection:(NSNotification *)notification
{
	DDTextureBuffer		**active;
	DDTextureBuffer		*buffer = nil;
	unsigned			count;
	int					row = [table selectedRow];
	
	if (-1 != row)
	{
		[DDTextureBuffer getActiveBuffers:&active count:&count];
		if ((unsigned)row < count) buffer = active[row];
	}
	
	[self setSelection:buffer];
}


- (void)setSelection:(DDTextureBuffer *)buffer
{
	if (nil != buffer)
	{
		[preview setObjectValue:[buffer image]];
		NSURL *url = [buffer file];
		if ([url isFileURL])
		{
			[fileField setStringValue:[[url absoluteURL] path]];
		}
		else
		{
			[fileField setStringValue:[[buffer file] absoluteString]];
		}
		[sizeField setStringValue:[buffer sizeString]];
		// Note: lie about the refcount, as there’s a reference in the cache.
		[refCountField setIntValue:[buffer retainCount] - 1];
		[keyField setStringValue:[NSString stringWithFormat:@"%@", [buffer key]]];
	}
	else
	{
		[preview setObjectValue:nil];
		[fileField setStringValue:@""];
		[sizeField setStringValue:@""];
		[refCountField setStringValue:@""];
		[keyField setStringValue:@""];
	}
}


- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	unsigned result;
	[DDTextureBuffer getActiveBuffers:NULL count:&result];
	return result;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	id					result;
	DDTextureBuffer		**active;
	DDTextureBuffer		*buffer;
	unsigned			count;
	
	[DDTextureBuffer getActiveBuffers:&active count:&count];
	if (count <= (unsigned)row) return nil;
	buffer = active[row];
	
	NSString *identifier = [tableColumn identifier];
	
	if ([identifier isEqual:@"image"])
	{
		result = [buffer image];
	}
	else if ([identifier isEqual:@"name"])
	{
		result = [[[buffer file] path] lastPathComponent];
	}
	else if ([identifier isEqual:@"size"])
	{
		result = [buffer sizeString];
	}
	else
	{
		LogMessage(@"Unknown column identifier \"%@\"", identifier);
		result = nil;
	}
	
	return result;
}

@end
