/*
	DDDDLightController.mm
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

#import "DDLightController.h"
#import "GLUtilities.h"
#import "Logging.h"

@interface DDLightController(Private)

- (void)updatePosition;

@end


@implementation DDLightController

- (id)init
{
	return [self initWithView:nil];
}


- (id)initWithView:(NSView *)inView
{
	self = [super init];
	if (nil != self)
	{
		_elevation = -60;
		_azimuth = -80;
		_distance = 1;
		_view = inView;
		[self updatePosition];
	}
	return self;
}


- (void)updateLightState
{
	float				l0[4] = { 0.8, 0.8, 0.8, 1.0 },
						l1[4] = { 0.1, 0.1, 0.1, 1.0 };
	
	glEnable(GL_LIGHT0);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, l0);
	glLightfv(GL_LIGHT0, GL_SPECULAR, l0);
	
	glEnable(GL_LIGHT1);
	glLightfv(GL_LIGHT1, GL_DIFFUSE, l1);
	glLightfv(GL_LIGHT1, GL_SPECULAR, l1);
	
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, l1);
	
	_pos.glLight(GL_LIGHT0);
	(-_pos).glLight(GL_LIGHT1);
}


- (void)drawLightPos
{
	float				bright[4]	= { 0.6, 0.6, 0.6, 1.0 },
						dark[4]		= { 0.2, 0.2, 0.2, 1.0 };
	Vector				zero(0, 0, 0);
	WFModeContext		wfmc;
	
	EnterWireframeMode(wfmc);
	
	glColor3fv(bright);
	DrawLight(0.5 * _pos, YES, 0.01f * _distance);
	
	glColor3fv(dark);
	DrawLight(-0.5 * _pos, YES, 0.01f * _distance);
	
	ExitWireframeMode(wfmc);
}


- (void)handleDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY
{
	float				azimuth, elevation;
	
	azimuth = _azimuth - inDeltaX * 0.6;
	elevation = _elevation - inDeltaY * 0.6;
	
	if (elevation < -180.0f) elevation = -180.0f;
	if (0.0f < elevation) elevation = 0.0f;
	
	while (azimuth < -270.0f) azimuth += 360.0f;
	while (90.0f < azimuth) azimuth -= 360.0f;
	
	if (azimuth != _azimuth || elevation != _elevation)
	{
		_azimuth = azimuth;
		_elevation = elevation;
		[self updatePosition];
		[_view setNeedsDisplay:YES];
	}
}


- (void)updatePosition
{
	float				phi, sphi, theta;
	
	phi = _elevation * 3.1415f / 180.0f;
	theta = _azimuth * 3.1415f / 180.0f;
	sphi = sinf(phi);
	_pos[0] = sphi * cosf(theta) * _distance;
	_pos[2] = sphi * sinf(theta) * _distance;
	_pos[1] = cosf(phi) * _distance;
}


- (void)setLightDistance:(float)inDistance
{
	_distance = inDistance;
	[self updatePosition];
}

@end
