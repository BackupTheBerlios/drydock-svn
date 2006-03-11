//
//  DDHeaderGradientView.m
//  Dry Dock
//
//  Created by Jens Ayton on 2006-03-10.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DDHeaderGradientView.h"
#import "Logging.h"


static uint32_t			sGlobalsRefCount = 0;
static CGColorSpaceRef	sColorSpace = NULL;
static CGFunctionRef	sGradientFunction = NULL;


typedef struct
{
	float				r, g, b;
} ColorComponents;
typedef struct
{
	ColorComponents		highlight,
						shadow,
						gradientTop,
						gradientBottom;
} GradientViewPalette;


// Colours lifted from screen shots of Spotlight and Spotlight Comments info field
static const GradientViewPalette	kAquaPalette =
									{
										{ 0.259, 0.569, 0.925 },
										{ 0.000, 0.220, 0.851 },
										{ 0.157, 0.510, 0.918 },
										{ 0.000, 0.369, 0.894 }
									};
static const GradientViewPalette	kGraphitePalette =
									{
										{ 0.518, 0.584, 0.659 },
										{ 0.275, 0.361, 0.455 },
										{ 0.455, 0.525, 0.612 },
										{ 0.310, 0.400, 0.510 }
									};


static void SetColorComponents(const ColorComponents *inComponents);
static void GradientEvaluate(void *info, const float *inValue, float *outColor);
static CGFunctionRef CreateGradientFunction(const GradientViewPalette *inPalette);


@implementation DDHeaderGradientView

- (id)initWithFrame:(NSRect)inFrame
{
	NSNotificationCenter		*nctr;
	
	self = [super initWithFrame:(NSRect)inFrame];
	if (nil != self)
	{
		++sGlobalsRefCount;
		nctr = [NSNotificationCenter defaultCenter];
		[nctr addObserver:self
				 selector:@selector(aquaColorVariantChanged:)
					 name:NSControlTintDidChangeNotification
				   object:nil];
	}
	return self;
}


- (void)dealloc
{
	NSDistributedNotificationCenter	*dnctr;
	NSNotificationCenter		*nctr;
	
	nctr = [NSNotificationCenter defaultCenter];
	[nctr removeObserver:self];
	
	if (!--sGlobalsRefCount)
	{
		if (NULL != sColorSpace)
		{
			CFRelease(sColorSpace);
			sColorSpace = NULL;
		}
		if (NULL != sGradientFunction)
		{
			CFRelease(sGradientFunction);
			sGradientFunction = NULL;
		}
	}
	
	[super dealloc];
}


- (void)aquaColorVariantChanged:notification
{
	// Need to change function so its “info” pointer can be different.
	if (NULL != sGradientFunction)
	{
		CFRelease(sGradientFunction);
		sGradientFunction = NULL;
	}
	
	[self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)rect
{
	NSColor						*tintColor;
	NSControlTint				tint;
	const GradientViewPalette	*palette;
	CGContextRef				cgContext;
	CGShadingRef				shading = NULL;
	
	NSSize						size = {0};
	
	tint = [NSColor currentControlTint];
	tintColor = [NSColor colorForControlTint:tint];
	tintColor = [tintColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	LogMessage(@"Control tint = %u. Colour = {%g, %g, %g, %g}.", tint, [tintColor redComponent] * 255, [tintColor greenComponent] * 255, [tintColor blueComponent] * 255, [tintColor alphaComponent]);
	
	size = [self frame].size;
	
	if (NSGraphiteControlTint == tint) palette = &kGraphitePalette;
	else palette = &kAquaPalette;
	
	if (NULL == sColorSpace) sColorSpace = CGColorSpaceCreateDeviceRGB();
	if (NULL == sGradientFunction) sGradientFunction = CreateGradientFunction(palette);
	if (NULL != sGradientFunction) shading = CGShadingCreateAxial(sColorSpace, CGPointMake(0, 0), CGPointMake(0, size.height), sGradientFunction, NO, NO);
	cgContext = [[NSGraphicsContext currentContext] graphicsPort];
	
	if (NULL != shading)
	{
		CGContextDrawShading(cgContext, shading);
		CFRelease(shading);	
	}
	
	SetColorComponents(&palette->highlight);
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0, size.height - 0.5) toPoint:NSMakePoint(size.width, size.height - 0.5)];
	SetColorComponents(&palette->shadow);
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0.5) toPoint:NSMakePoint(size.width, 0.5)];
}

@end


static void SetColorComponents(const ColorComponents *inComponents)
{
	NSColor						*temp;
	float						r, g, b;
	
	r = inComponents->r;
	g = inComponents->g;
	b = inComponents->b;
	
	temp = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0f];
	[temp set];
}


static void GradientEvaluate(void *info, const float *inValue, float *outColor)
{
	const GradientViewPalette	*palette;
	float						blend;
	const ColorComponents		*top, *bottom;
	
	palette = (const GradientViewPalette *)info;
	
	assert (NULL != inValue && NULL != outColor);
	blend = *inValue;
	
	top = &palette->gradientTop;
	bottom = &palette->gradientBottom;
	
	outColor[0] = ((float)top->r * blend + (float)bottom->r * (1.0f - blend));
	outColor[1] = ((float)top->g * blend + (float)bottom->g * (1.0f - blend));
	outColor[2] = ((float)top->b * blend + (float)bottom->b * (1.0f - blend));
	outColor[3] = 1.0f;	// Alpha
}


static CGFunctionRef CreateGradientFunction(const GradientViewPalette *inPalette)
{
	float						range[] = { 0, 1, 0, 1, 0, 1, 0, 1 };
	CGFunctionCallbacks			cb =
								{
									0,
									GradientEvaluate,
									NULL
								};
	
	return CGFunctionCreate((void *)inPalette, 1, range, 4, range, &cb);
}
