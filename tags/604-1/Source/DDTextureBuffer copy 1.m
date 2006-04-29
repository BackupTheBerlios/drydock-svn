//
//  DDTextureBuffer.m
//  Dry Dock
//
//  Created by Jens Ayton on 2005-12-22.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

IDENT("$Id$");

#define ENABLE_TRACE 0

#import "DDTextureBuffer.h"
#import "Logging.h"
#import "MathsUtils.h"


#if __BIG_ENDIAN__
	// #warning Big-endian
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8_REV
#else
	// #warning Little-endian
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8
#endif


static NSMutableDictionary		*sCache = nil;


@interface DDTextureBuffer(Private)

+ (id)textureWithImage:(NSImage *)inImage key:(id)inKey;
- (id)initWithImage:(NSImage *)inImage key:(id)inKey;

@end


@implementation DDTextureBuffer

+ (id)textureWithImage:(NSImage *)inImage key:(id)inKey
{
	DDTextureBuffer				*result;
	
	TraceMessage(@"Called.");
	TraceIndent();
	
	assert(nil == [sCache objectForKey:inKey]);
	
	result = [[[self alloc] initWithImage:inImage key:inKey] autorelease];
	if (nil == sCache) sCache = [[NSMutableDictionary alloc] init];
	[sCache setObject:result forKey:inKey];
	
	TraceOutdent();
	return result;
}

+ (id)textureWithFile:(NSURL *)inFile
{
	DDTextureBuffer				*result;
	NSImage						*image;
	
	TraceMessage(@"Called for %@.", [inFile absoluteURL]);
	TraceIndent();
	
	result = [sCache objectForKey:inFile];
	if (nil == result)
	{
		image = [[NSImage alloc] initByReferencingURL:inFile];
		if ([image isValid])
		{
			result = [self textureWithImage:image key:inFile];
		}
	}
	else
	{
	//	LogMessage(@"Using cached texture %@.", result);
	}
	
	TraceOutdent();
	return result;
}


+ (id)placeholderTexture
{
	DDTextureBuffer				*result;
	NSImage						*image;
	
	TraceMessage(@"Called.");
	TraceIndent();
	
	result = [sCache objectForKey:@"placeholder"];
	if (nil == result)
	{
		image = [NSImage imageNamed:@"Placeholder Texture"];
		if ([image isValid])
		{
			result = [self textureWithImage:image key:@"placeholder"];
		}
	}
	else
	{
	//	LogMessage(@"Using cached texture %@.", result);
	}
	
	TraceOutdent();
	return result;
}


- (id)initWithImage:(NSImage *)inImage key:(id)inKey
{
	BOOL					OK = YES;
	NSArray					*reps;
	NSEnumerator			*repEnum;
	id						rep;
	NSGraphicsContext		*nsContext, *savedContext;
	CGContextRef			cgContext = NULL;
	CGColorSpaceRef			colorSpace = NULL;
	NSRect					srcRect = {{0, 0}, {0, 0}}, dstRect;
	char					*data;
	unsigned				w, h;
	
	TraceMessage(@"Called.");
	TraceIndent();
	
	assert(nil != inImage);
	
	self = [super init];
	if (nil != self)
	{
		_key = [inKey retain];
	
		for (repEnum = [[inImage representations] objectEnumerator]; rep = [repEnum nextObject]; )
		{
			if ([rep isKindOfClass:[NSBitmapImageRep class]]) break;
		}
		
		if (nil != rep)
		{
			srcRect.size.width = [rep pixelsWide];
			srcRect.size.height = [rep pixelsHigh];
		}
		else
		{
			srcRect.size = [rep size];
		}
		_width = w = RoundUpToPowerOf2((uint16_t)srcRect.size.width);
		_height = h = RoundUpToPowerOf2((uint16_t)srcRect.size.height);
		
		data = (char *)malloc(w * h * 4 * 4 / 3); // 4 / 3 ratio provides space for mipmaps
		if (NULL == data) OK = NO;
		_data = data;
		
		srcRect.origin = NSMakePoint(0, 0);
		srcRect.size = [inImage size];
		
		savedContext = [[NSGraphicsContext currentContext] retain];
		colorSpace = CGColorSpaceCreateDeviceRGB();
		if (NULL == colorSpace) OK = NO;
		while (w && h && OK)
		{
			cgContext = CGBitmapContextCreate(data, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
			if (NULL == cgContext)
			{
				LogMessage(@"No CG context.");
				OK = NO;
			}
			
			if (OK)
			{
				nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:YES];
				[nsContext setImageInterpolation:NSImageInterpolationHigh];
				if (nil == nsContext) OK = NO;
			}
			
			if (OK)
			{
				[NSGraphicsContext setCurrentContext:nsContext];
				
				dstRect = NSMakeRect(0, 0, w, h);
				[inImage drawInRect:dstRect fromRect:srcRect operation:NSCompositeCopy fraction:1.0];
			}
			
			if (NULL != cgContext) CFRelease(cgContext);
			
			data += w * h * 4;
			
			w /= 2;
			h /= 2;
		}
		[NSGraphicsContext setCurrentContext:savedContext];
		[savedContext release];
	}
	if (colorSpace) CFRelease(colorSpace);
	
	if (!OK)
	{
		[self release];
		self = nil;
	}
	
	TraceOutdent();
	return self;
}


- (void)dealloc
{
	free(_data);
	[_key release];
	
	[super dealloc];
}


- (void)release
{
	BOOL					uncache;
	
	uncache = (2 == [self retainCount]);
	[super release];
	
	if (uncache) [sCache removeObjectForKey:_key];
}


- (void)setUpCurrentTexture
{
	GLint				wrapMode;
	GLint				magFilter;
	GLint				level;
	unsigned			w, h;
	char				*data;
	
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	
	// Set up mip-map levels
	w = _width;
	h = _height;
	data = (char *)_data;
	level = 0;
	
	while (w && h)
	{
		glTexImage2D(GL_TEXTURE_2D, level, GL_RGBA, w, h, 0, GL_BGRA, ARGB_IMAGE_TYPE, data);
		
		data += w * h * 4;
		++level;
		w /= 2;
		h /= 2;
	}
	
	if ([@"placeholder" isEqual:_key])
	{
		wrapMode = GL_REPEAT;
		magFilter = GL_NEAREST;
	}
	else
	{
		wrapMode = GL_CLAMP_TO_EDGE;
		magFilter = GL_LINEAR;
	}
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4.0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{%dx%d pixels, %@}", [self className], self, _width, _height, _key];
}

@end
