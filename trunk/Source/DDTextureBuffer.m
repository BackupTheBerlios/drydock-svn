/*
	DDTextureBuffer.m
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

#define ENABLE_TRACE 0

#import "DDTextureBuffer.h"
#import "DDUtilities.h"
#import "Logging.h"
#import "MathsUtils.h"
#import <Accelerate/Accelerate.h>
#import <QuickTime/QuickTime.h>
#import "DDErrorDescription.h"
#import "DDProblemReportManager.h"


#if __BIG_ENDIAN__
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8_REV
#else
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8
#endif


static NSMutableDictionary		*sCache = nil;

static unsigned GetMaxTextureSize(void);


@interface DDTextureBuffer(Private)

- (id)initWithURL:(NSURL *)inURL key:(id)inKey issues:(DDProblemReportManager *)ioIssues;
- (BOOL)loadNSImage:(NSImage *)inImage issues:(DDProblemReportManager *)ioIssues;
- (BOOL)loadFSRef:(FSRef *)inFile issues:(DDProblemReportManager *)ioIssues;

#if USE_TEXTURE_VERIFICATION_WINDOW
- (void)makeTextureVerificationWindowWithImage:(NSImage *)inImage;
#endif

@end


@implementation DDTextureBuffer


+ (id)textureWithFile:(NSURL *)inFile issues:(DDProblemReportManager *)ioIssues
{
	DDTextureBuffer				*result;
	
	TraceEnterMsg(@"Called for %@. {", [inFile absoluteURL]);
	
	result = [sCache objectForKey:inFile];
	if (nil == result)
	{
		result = [[self alloc] initWithURL:inFile key:[inFile absoluteURL] issues:ioIssues];
	}
	else
	{
		TraceMessage(@"Using cached texture %@.", result);
	}
	
	return result;
	TraceExit();
}


+ (id)placeholderTextureWithIssues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	DDTextureBuffer				*result;
	NSURL						*url;
	
	result = [sCache objectForKey:@"placeholder"];
	if (nil == result)
	{
		url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Placeholder Texture" ofType:@"png"]];
		result = [[self alloc] initWithURL:url key:@"placeholder" issues:ioIssues];
	}
	else
	{
		TraceMessage(@"Using cached texture %@.", result);
	}
	
	return result;
	TraceExit();
}


- (id)initWithURL:(NSURL *)inURL key:(id)inKey issues:(DDProblemReportManager *)ioIssues
{
	TraceEnterMsg(@"Called with key=%@ {", inKey);
	
	BOOL					OK = YES;
	FSRef					fsRef;
	
	assert(nil != inURL);
	assert(nil == [sCache objectForKey:inURL]);
	
	self = [super init];
	if (nil == self) OK = NO;
	
	if (OK)
	{
		_key = [inKey retain];
		
		OK = CFURLGetFSRef((CFURLRef)inURL, &fsRef);
		if (OK) OK = [self loadFSRef:&fsRef issues:ioIssues];
	}
	
	if (!OK)
	{
		TraceMessage(@"Failed to load texture %@.", inKey);
		[self release];
		self = nil;
	}
	
	return self;
	
	TraceExit();
}


- (BOOL)loadFSRef:(FSRef *)inFile issues:(DDProblemReportManager *)ioIssues
{
	TraceEnter();
	
	OSStatus				err;
	FSSpec					spec;
	ComponentInstance		importer = NULL;
	Rect					bounds;
	unsigned				w, h;
	BOOL					errDescribed = NO;
	CGImageRef				image = NULL;
	char					*data;
	size_t					dataSize;
	CGContextRef			context = NULL;
	CGColorSpaceRef			colorSpace = NULL;
	
	// Open an importer component for the file
	err = FSGetCatalogInfo(inFile, kFSCatInfoNone, NULL, NULL, &spec, NULL);
	if (!err) err = GetGraphicsImporterForFile(&spec, &importer);
	
	// Find the output dimensions
	if (!err) err = GraphicsImportGetNaturalBounds(importer, &bounds);
	if (!err)
	{
		if (bounds.left < bounds.right) _width = bounds.right - bounds.left;
		else _width = bounds.left - bounds.right;
		if (bounds.top < bounds.bottom) _height = bounds.bottom - bounds.top;
		else _height = bounds.top - bounds.bottom;
		
		w = RoundUpToPowerOf2(_width);
		h = RoundUpToPowerOf2(_height);
		
		if (w != _width || h != _height)
		{
			[ioIssues addWarningIssueWithKey:@"textureNotPowerOfTwo" localizedFormat:@"The texture %@ does not have power-of-two dimensions. It has been rescaled from %u x %u pixels to %u x %u pixels.", _key, _width, _height, w, h];
			_width = w;
			_height = h;
		}
	}
	
	// Import image
	if (!err) err = GraphicsImportCreateCGImage(importer, &image, kGraphicsImportCreateCGImageUsingCurrentSettings);
	if (NULL != importer) CloseComponent(importer);
	
	// Set up buffer
	if (!err)
	{
		dataSize = w * h * 4 * 4 / 3;
		data = malloc(dataSize); // 4 / 3 ratio provides space for mipmaps
		if (NULL == data)
		{
			err = memFullErr;
			errDescribed = YES;
			TraceMessage(@"Failed to allocate %u-byte buffer.", dataSize);
			[ioIssues addWarningIssueWithKey:@"textureFileNotLoadedMemory" localizedFormat:@"The texture %@ could not be loaded, because there is not enough memory.", _key];
		}
		_data = data;
	}
	
	// Draw image at each mip level
	if (!err)
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
		while (1 < w && 1 < h && !err)
		{
			context = CGBitmapContextCreate(data, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
			if (NULL == context)
			{
				LogMessage(@"No CG context.");
				err = coreFoundationUnknownErr;
			}
			
			CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
			CGContextDrawImage(context, CGRectMake(0, 0, w, h), image);
			
			CFRelease(context);
			
			data += w * h * 4;
			
			w /= 2;
			h /= 2;
		}
		if (NULL != colorSpace) CFRelease(colorSpace);
	}
	
	if (NULL != image) CGImageRelease(image);
	
	if (err && !errDescribed)
	{
		[ioIssues addWarningIssueWithKey:@"textureFileNotLoadedOSErr" localizedFormat:@"The texture %@ could not be loaded, because an error of type %@ occured.", _key, OSStatusErrorNSString(err)];
		errDescribed = YES;
	}
	
	return !err;
	TraceExit();
}


- (void)dealloc
{
	free(_data);
	[_key release];
	[_file autorelease];
	
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
	unsigned			w, h, max;
	char				*data;
	size_t				dataSize;
	BOOL				scaledDown = NO;
	
	
	// Set up mip-map levels
	w = _width;
	h = _height;
	data = (char *)_data;
	level = 0;
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
	dataSize = w * h * 4 * 4 / 3;
	glTextureRangeAPPLE(GL_TEXTURE_2D, dataSize, data);
	
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
	
	max = GetMaxTextureSize();
	
	while (w && h)
	{
		if (w <= max && h <= max)
		{
			glTexImage2D(GL_TEXTURE_2D, level, GL_RGBA, w, h, 0, GL_BGRA, ARGB_IMAGE_TYPE, data);
			++level;
		}
		else scaledDown = YES;
		
		data += w * h * 4;
		w /= 2;
		h /= 2;
	}
	
	if (scaledDown)
	{
		LogMessage(@"Texture %@ scaled down.", self);
	}
}


- (NSURL *)file
{
	return _file;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{%dx%d pixels, %@}", [self className], self, _width, _height, _key];
}

@end


static unsigned GetMaxTextureSize(void)
{
	GLint				result;
	NSNumber			*override;
	GLint				value;
	
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &result);
	
	override = [[NSUserDefaults standardUserDefaults] objectForKey:@"texture maximum size"];
	if (nil != override)
	{
		value = [override intValue];
		if (value < result) result = value;
	}
	
	return result;
}
