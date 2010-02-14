/*
	DDWizardBackdropView.m
	Dry Dock for Oolite
	$Id$
	
	A view which draws a translucent white background, similar to that used in installers.
	
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

#import "DDWizardBackdropView.h"
#import "Logging.h"


#define	kBorderWidth			0.25f		// Effective border width in points
#define kInverseBorderWidth		(1.0f / (kBorderWidth))
#define kBackAlpha				0.60f


@implementation DDWizardBackdropView

- (void)drawRect:(NSRect)rect
{
	float					scale, alpha, width;
	NSWindow				*window;
	NSRect					frame;
	
	window = [self window];
	scale = [window userSpaceScaleFactor];
	
	if (scale < kInverseBorderWidth)
	{
		// Draw border as 1.0 px line with alpha corresponding to thickness
		alpha = scale * kBorderWidth;
		width = 1.0f;
	}
	else
	{
		// Draw border as black line of relevant width
		alpha = 1.0f;
		width = scale * kBorderWidth;
	}
	
//	LogMessage(@"Scale = %g, width = %g, alpha = %g.", scale, width, alpha);
	
	frame.size = [self frame].size;
	frame.origin.x = width / 2.0f;
	frame.origin.y = width / 2.0f;
	frame.size.width -= width;
	frame.size.height -= width;
	
	[[NSColor colorWithCalibratedWhite:0.0f alpha:alpha] set];
	[NSBezierPath strokeRect:frame];
	
	frame.origin.x += width / 2.0f;
	frame.origin.y += width / 2.0f;
	frame.size.width -= width;
	frame.size.height -= width;
	[[NSColor colorWithCalibratedWhite:1.0f alpha:kBackAlpha] set];
	[NSBezierPath fillRect:frame];
}


- (BOOL)isOpaque
{
	return NO;
}

@end
