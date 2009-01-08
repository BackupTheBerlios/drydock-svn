//
//  DDSceneView.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDSceneView.h"


@implementation DDSceneView

- (id) initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code here.
    }
    return self;
}

- (void) drawRect:(NSRect)rect
{
	NSLog(@"Drawing!");
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}


- (BOOL) isOpaque
{
	return YES;
}

@end
