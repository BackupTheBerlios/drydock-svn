#import "OOColor.h"


@implementation NSColor (OOColorExtensions)

+ (id) colorWithDescription:(id)description
{
	NSDictionary			*dict = nil;
	
	if (description == nil) return nil;
	
	if ([description isKindOfClass:[OOColor class]])
	{
		return [[description copy] autorelease];
	}
	else if ([description isKindOfClass:[NSString class]])
	{
		if ([description hasSuffix:@"Color"])
		{
			// +fooColor selector
			SEL selector = NSSelectorFromString(description);
			if ([self respondsToSelector:selector])  return [self performSelector:selector];
		}
		else
		{
			// Some other string
			return [self colorFromString:description];
		}
	}
	else if ([description isKindOfClass:[NSArray class]])
	{
		return [self colorFromString:[description componentsJoinedByString:@" "]];
	}
	else if ([description isKindOfClass:[NSDictionary class]])
	{
		dict = description;	// Workaround for gnu-gcc's more agressive "multiple methods named..." warnings.
		
		if ([dict objectForKey:@"hue"] != nil)
		{
			// Treat as HSB(A) dictionary
			float h = [dict floatForKey:@"hue"];
			float s = [dict floatForKey:@"saturation" defaultValue:1.0f];
			float b = [dict floatForKey:@"brightness" defaultValue:-1.0f];
			if (b < 0.0f)  b = [dict floatForKey:@"value" defaultValue:1.0f];
			float a = [dict floatForKey:@"alpha" defaultValue:-1.0f];
			if (a < 0.0f)  a = [dict floatForKey:@"opacity" defaultValue:1.0f];
			
			return [OOColor colorWithCalibratedHue:h / 360.0f saturation:s brightness:b alpha:a];
		}
		else
		{
			// Treat as RGB(A) dictionary
			float r = [dict floatForKey:@"red"];
			float g = [dict floatForKey:@"green"];
			float b = [dict floatForKey:@"blue"];
			float a = [dict floatForKey:@"alpha" defaultValue:-1.0f];
			if (a < 0.0f)  a = [dict floatForKey:@"opacity" defaultValue:1.0f];
			
			return [OOColor colorWithCalibratedRed:r green:g blue:b alpha:a];
		}
	}
	
	return nil;
}


+ (OOColor *)colorFromString:(NSString*) colorFloatString
{
	float			rgbaValue[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
	NSScanner		*scanner = [NSScanner scannerWithString:colorFloatString];
	float			factor = 1.0f;
	int				i;
	
	for (i = 0; i != 4; ++i)
	{
		if (![scanner scanFloat:&rgbaValue[i]])
		{
			// Less than three floats or non-float, can't parse -> quit
			if (i < 3) return nil;
			
			// If we get here, we only got three components. Make sure alpha is at correct scale:
			rgbaValue[3] /= factor;
		}
		if (1.0f < rgbaValue[i]) factor = 1.0f / 255.0f;
	}
	
	return [OOColor colorWithCalibratedRed:rgbaValue[0] * factor green:rgbaValue[1] * factor blue:rgbaValue[2] * factor alpha:rgbaValue[3] * factor];
}


- (BOOL)isBlack
{
	NSColor *rgb = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	return	rgb.redComponent == 0.0 &&
			rgb.greenComponent == 0.0 &&
			rgb.blueComponent == 0.0;
}


- (NSArray *)normalizedArray
{
	NSColor *rgb = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	CGFloat r, g, b, a;
	[rgb getRed:&r green:&g blue:&b alpha:&a];
	return [NSArray arrayWithObjects:
			[NSNumber numberWithDouble:r],
			[NSNumber numberWithDouble:g],
			[NSNumber numberWithDouble:b],
			[NSNumber numberWithDouble:a],
			nil];
}

@end
