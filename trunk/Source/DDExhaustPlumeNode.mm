/*
	DDExhaustPlumeNode.mm
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

#import "DDExhaustPlumeNode.h"
#import "GLUtilities.h"
#import "Logging.h"
#import "DDMesh.h"
#import "DDProblemReportManager.h"

#define CGL_MACRO_CACHE_RENDERER
#import <OpenGL/CGLMacro.h>


static DDMesh	*sPlumeMesh = nil;
static BOOL		sLoadedPlumeMesh = NO;
static void LoadPlumeMesh(void);


@implementation DDExhaustPlumeNode

- (id)init
{
	self = [super init];
	if (nil != self)
	{
		[self setLocalizedName:@"Exhaust Plume"];
	}
	return self;
}


- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty
{
	TraceEnter();
	
	BOOL					shading = YES;
	id						val;
	WFModeContext			wfmc;
	
	val = [inState objectForKey:@"shading"];
	if (val && [val respondsToSelector:@selector(boolValue)])
	{
		shading = [val boolValue];
	}
	
	EnterWireframeMode(wfmc);
	
	CGL_MACRO_DECLARE_VARIABLES();
	
	if (shading)
	{
		if (!sLoadedPlumeMesh) LoadPlumeMesh();
		if (nil != sPlumeMesh)
		{
			glColor3f(0.2, 0.2, 1);
			[sPlumeMesh glRenderShaded];
		}
	}
	
	glColor3f(0.5, 0.5, 1);
	glBegin(GL_POINTS);
		glVertex3f(0, 0, 0);
	glEnd();
	
	glColor3f(0, 0, 1);
	glBegin(GL_LINE_LOOP);
		glVertex3f(0, 0, 0);
		glVertex3f(0, -0.5, -0.05);
		glVertex3f(0, -0.5, -0.3);
		glVertex3f(0, -0.357, -0.65);
		glVertex3f(0, 0, -1);
		glVertex3f(0, 0.357, -0.65);
		glVertex3f(0, 0.5, -0.3);
		glVertex3f(0, 0.5, -0.05);
		glVertex3f(0, 0, 0);
		glVertex3f(-0.5, 0, -0.05);
		glVertex3f(-0.5, 0, -0.3);
		glVertex3f(-0.357, 0, -0.65);
		glVertex3f(0, 0, -1);
		glVertex3f(0.357, 0, -0.65);
		glVertex3f(0.5, 0, -0.3);
		glVertex3f(0.5, 0, -0.05);
	glEnd();
	glBegin(GL_LINE_LOOP);
		glVertex3f(0, -0.5, -0.3);
		glVertex3f(0.357, -0.357, -0.3);
		glVertex3f(0.5, 0, -0.3);
		glVertex3f(0.357, 0.357, -0.3);
		glVertex3f(0, 0.5, -0.3);
		glVertex3f(-0.357, 0.357, -0.3);
		glVertex3f(-0.5, 0, -0.3);
		glVertex3f(-0.357, -0.357, -0.3);
	glEnd();
	
	ExitWireframeMode(wfmc);
	
	TraceExit();
}

@end


static void LoadPlumeMesh(void)
{
	TraceEnter();
	
	NSString				*path;
	NSURL					*url;
	DDProblemReportManager	*issues;
	
	path = [[NSBundle mainBundle] pathForResource:@"Exhaust Plume" ofType:@"dat"];
	url = [NSURL fileURLWithPath:path];
	issues = [[[DDProblemReportManager alloc] init] autorelease];
	sPlumeMesh = [[DDMesh alloc] initWithOoliteDAT:url issues:issues];
	
	if (nil == sPlumeMesh)
	{
		#if ENABLE_LOGGING
			LogMessage(@"Problems arose loading exhaust plume data, will draw wireframe instead. %@", issues);
		#else
			NSLog(@"Problems arose loading exhaust plume data, will draw wireframe instead. %@", issues);
		#endif
	}
	
	TraceExit();
}
