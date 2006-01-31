//
//  PointCloudNode.m
//  Dry Dock
//
//  Created by Jens Ayton on 2005-12-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "PointCloudNode.h"
#import "GLUtilities.h"
#import "Logging.h"


@implementation PointCloudNode

+ (SceneNode *)node
{
	return [[[self alloc] init] autorelease];
}


+ (PointCloudNode *)nodeWithSize:(float)inSize divisions:(unsigned)inDivisions
{
	return [[[self alloc] initWithSize:inSize divisions:inDivisions] autorelease];
}


- (id)init
{
	return [self initWithSize:10.0 divisions:11];
}


- (id)initWithSize:(float)inSize divisions:(unsigned)inDivisions
{
	self = [super init];
	if (nil != self)
	{
		_size = inSize;
		_divisions = inDivisions;
	}
	
	return self;
}


- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty
{
	int				xc, yc, zc;
	float			offset, step;
	float			x, y, z;
	WFModeContext	fwmc;
	float			oldPointSize;
	
	if (_divisions < 2) return;
	
	#if OBJECTIVESCENE_TRACE_RENDER
		LogMessage(@"Drawing point cloud, size=%g, divisions=%u", _size, _divisions);
	#endif
	
	offset = -0.5 * _size;
	step = _size / (float)(_divisions - 1);
	
	EnterWireframeMode(fwmc);
	glGetFloatv(GL_POINT_SIZE, &oldPointSize);
	glPointSize(1.0f);
	
	glColor3f(0.8, 0.8, 0.8);
	glBegin(GL_POINTS);
	
	x = offset;
	xc = _divisions;
	do
	{
		y = offset;
		yc = _divisions;
		do
		{
			z = offset;
			zc = _divisions;
			do
			{
				glVertex3f(x, y, z);
				z += step;
			} while (--zc);
			y += step;
		} while (--yc);
		x += step;
	} while (--xc);
	
	glEnd();
	glPointSize(oldPointSize);
	ExitWireframeMode(fwmc);
}

@end
