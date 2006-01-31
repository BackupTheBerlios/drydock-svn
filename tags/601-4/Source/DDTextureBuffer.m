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
#import "Logging.h"
#import "MathsUtils.h"
#import <Accelerate/Accelerate.h>


#if __BIG_ENDIAN__
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8_REV
#else
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8
#endif


/*	If 1, use high-quality NSImage scaling for mip-maps. If 0, use bilinear scaling.
	Should always be 1; bi-linear is here for testing purposes.
*/
#define USE_NSIMAGE_TO_SCALE	1
#define USE_ALTIVEC_SCALING		0


static NSMutableDictionary		*sCache = nil;

static void Swizzle_RGBA_ARGB(char *inBuffer, unsigned inPixelCount);

#if !USE_NSIMAGE_TO_SCALE
static void ScaleDown(restrict char *inSrc, restrict char *inDst, unsigned inWidth, unsigned inHeight);
#endif


@interface DDTextureBuffer(Private)

+ (id)textureWithImage:(NSImage *)inImage key:(id)inKey;
- (id)initWithImage:(NSImage *)inImage key:(id)inKey;

#if USE_TEXTURE_VERIFICATION_WINDOW
- (void)makeTextureVerificationWindowWithImage:(NSImage *)inImage;
#endif

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
			result->_file = [inFile retain];
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
	char					*data, *nextData;
	unsigned				w, h;
	NSImage					*dstImage;
	NSBitmapImageRep		*dstRep;
	NSDictionary			*attrs;
	
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
			srcRect.size = [inImage size];
		}
		_width = w = RoundUpToPowerOf2((uint16_t)srcRect.size.width);
		_height = h = RoundUpToPowerOf2((uint16_t)srcRect.size.height);
		
		data = (char *)malloc(w * h * 4 * 4 / 3); // 4 / 3 ratio provides space for mipmaps
		if (NULL == data) OK = NO;
		_data = data;
		
		[inImage setSize:srcRect.size];
		srcRect.origin = NSMakePoint(0, 0);
	
		#if USE_TEXTURE_VERIFICATION_WINDOW
			[self makeTextureVerificationWindowWithImage:inImage];
		#endif
		
		#if USE_NSIMAGE_TO_SCALE
			savedContext = [[NSGraphicsContext currentContext] retain];
			while (1 < w && 1 < h && OK)
			{
				dstRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(unsigned char **)&data pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:w * 4 bitsPerPixel:0];
				if (nil == dstRep) OK = NO;
				
				if (OK)
				{
					attrs = [NSDictionary dictionaryWithObject:dstRep forKey:NSGraphicsContextDestinationAttributeName];
					nsContext = [NSGraphicsContext graphicsContextWithAttributes:attrs];
					if (nil == nsContext) OK = NO;
				}
				
				if (OK)
				{
					[nsContext setImageInterpolation:NSImageInterpolationHigh];
					[NSGraphicsContext setCurrentContext:nsContext];
					
					dstRect = NSMakeRect(0, 0, w, h);
					[inImage drawInRect:dstRect fromRect:srcRect operation:NSCompositeCopy fraction:1.0];
				}
				
				data += w * h * 4;
				
				w /= 2;
				h /= 2;
			}
			
			Swizzle_RGBA_ARGB(_data, _width * _height * 4 / 3);
			[NSGraphicsContext setCurrentContext:[savedContext autorelease]];
		#else
			// Draw largest mip level with NSImage
			savedContext = [[NSGraphicsContext currentContext] retain];
			dstRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(unsigned char **)&data pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:w * 4 bitsPerPixel:0];
			if (nil == dstRep) OK = NO;
			
			if (OK)
			{
				attrs = [NSDictionary dictionaryWithObject:dstRep forKey:NSGraphicsContextDestinationAttributeName];
				nsContext = [NSGraphicsContext graphicsContextWithAttributes:attrs];
				if (nil == nsContext) OK = NO;
			}
			
			if (OK)
			{
				[nsContext setImageInterpolation:NSImageInterpolationHigh];
				[NSGraphicsContext setCurrentContext:nsContext];
				
				dstRect = NSMakeRect(0, 0, w, h);
				[inImage drawInRect:dstRect fromRect:srcRect operation:NSCompositeCopy fraction:1.0];
			}
			[NSGraphicsContext setCurrentContext:[savedContext autorelease]];
			Swizzle_RGBA_ARGB(_data, _width * _height);
			
			// Generate mip-maps using linear interpolator
			while (1 < w && 1 < h)
			{
				nextData = data + w * h * 4;
				ScaleDown(data, nextData, w, h);
				data = nextData;
				w /= 2;
				h /= 2;
			}
		#endif
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


- (NSURL *)file
{
	return _file;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{%dx%d pixels, %@}", [self className], self, _width, _height, _key];
}


#if USE_TEXTURE_VERIFICATION_WINDOW
- (void)makeTextureVerificationWindowWithImage:(NSImage *)inImage
{
	NSSize				size;
	
	TraceMessage(@"Called.");
	
	[NSBundle loadNibNamed:@"DDTextureBufferVerificationWindow" owner:self];
	
	size = [inImage size];
	size.height += 28;
	[window setContentSize:size];
	[view setImage:inImage];
	[imageDesc setObjectValue:[inImage description]];
	[window orderFront:self];
}
#endif

@end


#if __ppc__
// PPC systems love explicit paralellism and use of lots of registers.
static void Swizzle_RGBA_ARGB_AltiVec(char *inBuffer, unsigned inPixelCount);


static inline BOOL HaveAltivec(void)
{
	OSErr				err;
	long				response;
	static uint8_t		answer;
	
	if (0 == answer)
	{
		err = Gestalt(gestaltPowerPCProcessorFeatures, &response);
		answer = (!err && (response & (1 << gestaltPowerPCHasVectorInstructions))) ? 2 : 1;
	}
	return answer - 1;
}


static void Swizzle_RGBA_ARGB(char *inBuffer, unsigned inPixelCount)
{
	__builtin_prefetch(inBuffer, 1, 0);
	
	uint32_t			*pix;
	uint32_t			curr0, curr1, curr2, curr3, curr4, curr5, curr6, curr7,
						rgb0, rgb1, rgb2, rgb3, rgb4, rgb5, rgb6, rgb7,
						a0, a1, a2, a3, a4, a5, a6, a7;
	unsigned			loopCount;
	
	/*if (HaveAltivec())
	{
		Swizzle_RGBA_ARGB_AltiVec(inBuffer, inPixelCount);
		return;
	}*/
	
	loopCount = inPixelCount / 8;
	pix = (uint32_t *)inBuffer;
	do
	{
		curr0 = pix[0];
		curr1 = pix[1];
		curr2 = pix[2];
		curr3 = pix[3];
		curr4 = pix[4];
		curr5 = pix[5];
		curr6 = pix[6];
		curr7 = pix[7];
		
		a0 = (curr0 & 0xFF) << 24;
		a1 = (curr1 & 0xFF) << 24;
		a2 = (curr2 & 0xFF) << 24;
		a3 = (curr3 & 0xFF) << 24;
		a4 = (curr4 & 0xFF) << 24;
		a5 = (curr5 & 0xFF) << 24;
		a6 = (curr6 & 0xFF) << 24;
		a7 = (curr7 & 0xFF) << 24;
		rgb0 = curr0 >> 8;
		rgb1 = curr1 >> 8;
		rgb2 = curr2 >> 8;
		rgb3 = curr3 >> 8;
		rgb4 = curr4 >> 8;
		rgb5 = curr5 >> 8;
		rgb6 = curr6 >> 8;
		rgb7 = curr7 >> 8;
		
		pix[0] = a0 | rgb0;
		pix[1] = a1 | rgb1;
		pix[2] = a2 | rgb2;
		pix[3] = a3 | rgb3;
		pix[4] = a4 | rgb4;
		pix[5] = a5 | rgb5;
		pix[6] = a6 | rgb6;
		pix[7] = a7 | rgb7;
		pix += 8;
	} while (--loopCount);
	
	// Handle odd pixels at end
	loopCount = inPixelCount % 8;
	while (loopCount--)
	{
		curr0 = *pix;
		
		a0 = (curr0 & 0xFF) << 24;
		rgb0 = curr0 >> 8;
		
		*pix++ = a0 | rgb0;
	}
}


typedef union
{
	uint8_t				bytes[16];
	vUInt8				vec;
} VecBytesU8;


static void Swizzle_RGBA_ARGB_AltiVec(char *inBuffer, unsigned inPixelCount)
{
	vec_dststt(inBuffer, 256, 0);
	
	vUInt32				*pix;
	vUInt32				curr0, curr1, curr2, curr3;
	VecBytesU8			permBytes =
						{
							3, 0, 1, 2,
							7, 4, 5, 6,
							11, 8, 9, 10,
							15, 12, 13, 14
						};
	vUInt8				permMask = permBytes.vec;
	unsigned			loopCount;
	uint32_t			*pixS;
	uint32_t			currS, rgb, a;
	
	pix = (vUInt32 *)inBuffer;
	loopCount = inPixelCount / 16;
	do
	{
		curr0 = pix[0];
		curr1 = pix[1];
		curr2 = pix[2];
		curr3 = pix[3];
		
		// Note: second parameter is unused
		pix[0] = vec_perm(curr0, curr0, permMask);
		pix[1] = vec_perm(curr1, curr1, permMask);
		pix[2] = vec_perm(curr2, curr2, permMask);
		pix[3] = vec_perm(curr3, curr3, permMask);
		
		pix += 4;
		
	} while (--loopCount);
	
	pixS = (uint32_t *)pix;
	loopCount = inPixelCount % 16;
	while (loopCount--)
	{
		currS = *pixS;
		
		a = (currS & 0xFF) << 24;
		rgb = currS >> 8;
		
		*pixS++ = a | rgb;
	}
}

#else
// x86 systems, however, don’t do too well with explicit loop unrolling.

static void Swizzle_RGBA_ARGB(char *inBuffer, unsigned inPixelCount)
{
	__builtin_prefetch(inBuffer, 1, 0);
	
	uint32_t			*pix;
	uint32_t			curr, rgb, a;
	
	assert(0 != inPixelCount);
	
	pix = (uint32_t *)inBuffer;
	do
	{
		curr = *pix;
		
		a = (curr & 0xFF) << 24;
		rgb = curr >> 8;
		
		*pix++ = a | rgb;
	} while (--inPixelCount);
}

#endif


#if !USE_NSIMAGE_TO_SCALE
#if USE_ALTIVEC_SCALING
static void ScaleDown_Altivec(restrict char *inSrc, restrict char *inDst, unsigned inWidth, unsigned inHeight);
#endif


static void ScaleDown(restrict char *inSrc, restrict char *inDst, unsigned inWidth, unsigned inHeight)
{
	__builtin_prefetch(inSrc, 1, 0);
	__builtin_prefetch(inDst, 0, 1);
	
	#if USE_ALTIVEC_SCALING
	if (HaveAltivec() && 8 <= inWidth)
	{
		ScaleDown_Altivec(inSrc, inDst, inWidth, inHeight);
		return;
	}
	#endif
	
	assert(NULL != inSrc && NULL != inDst && 0 != inWidth && 0 != inHeight);
	assert(!(inWidth & 1) && !(inHeight & 1));	// Source dimensions must be even
	
	uint32_t				*oddSrc, *evenSrc,
							*dst;
	uint32_t				px0, px1, px2, px3;
	uint32_t				rb,	// Red and blue channels
							ga;	// Green and alpha chans
	unsigned				w, h;
	
	oddSrc = (uint32_t *)inSrc;
	evenSrc = oddSrc + inWidth;
	dst = (uint32_t *)inDst;
	
	h = inHeight / 2;
	do
	{
		w = inWidth / 2;
		do
		{
			px0 = *oddSrc++;
			px1 = *oddSrc++;
			px2 = *evenSrc++;
			px3 = *evenSrc++;
			
			rb = (px0 & 0xFF00FF00) >> 2;
			ga = px0 & 0x00FF00FF;
			rb += (px1 & 0xFF00FF00) >> 2;
			ga += px1 & 0x00FF00FF;
			rb += (px2 & 0xFF00FF00) >> 2;
			ga += px2 & 0x00FF00FF;
			rb += (px3 & 0xFF00FF00) >> 2;
			ga += px3 & 0x00FF00FF;
			
			*dst++ = (rb & 0xFF00FF00) | ((ga >> 2) & 0x00FF00FF);
		} while (--w);
		oddSrc += inWidth;
		evenSrc += inWidth;
	} while (--h);
}


#if USE_ALTIVEC_SCALING
/*
	Strategy: read four vectors, write one. In order to be able to add them together and not lose
	bits, use an intermediate two vectors of 16-bits per channel.
	
	Original data layout:
	Odd row:	[r0 g0 b0 a0 r1 g1 b1 a1 r2 g2 b2 a2 r3 g3 b3 a3] [r4 g4 b4 a4 r5 g5 b5 a5 r6 g6 b6 a6 r7 g7 b7 a7]
	Even row:	[r8 g8 b8 a8 r9 g9 b9 a9 rA gA bA aA rB gB bB aB] [rC gC bC aC rD gD bD aD rE gE bE aE rF gF bF aF]
	
	Calculation layout:
				[ 0 r0  0 g0  0 b0  0 a0  0 r2  0 g2  0 b2  0 a2]
				[ 0 r1  0 g1  0 b1  0 a1  0 r3  0 g3  0 b3  0 a3]
				[ 0 r8  0 g8  0 b8  0 a8  0 rA  0 gA  0 bA  0 aA]
				[ 0 r9  0 g9  0 b9  0 a9  0 rB  0 gB  0 bB  0 aB]
	
	To create the calculation layout, we use vec_perm. We use the permutation vector to provide the
	zero byte. The permutation vector to select the first and third pixels of a source vector is:
				[ 0 16  0 17  0 18  0 19  0 24  0 25  0 26  0 27]
	and for the second and fourth pixels:
				[ 0 20  0 21  0 22  0 23  0 28  0 29  0 30  0 31]
	
	Output pixel 0 is the average of pixels 0, 1, 8 and 9. Output pixel 1 is input pixels 2, 3, A and B.
	Thus the interleaved peromutations above let us sum the vectors to produced two mixed 10-bit-per
	channel pixels padded to two bytes per channel. Two such vectors can then be shifted and permuted
	into the final output, with the following permutation vector:
				[ 1  3  5  7  9 11 13 15 17 19 21 23 25 27 29 31]
	
	Currently slightly broken. Not fixed since the NSImage route is better on Macs anyway.
*/
static void ScaleDown_Altivec(restrict char *inSrc, restrict char *inDst, unsigned inWidth, unsigned inHeight)
{
	vec_dstt(inSrc, 256, 0);
	vec_dststt(inDst, 256, 1);
	
	assert(!((uintptr_t)inSrc % 16) && !((uintptr_t)inDst % 16) && !(inWidth % 8));
	
	vUInt16					*oddSrc, *evenSrc,
							*dst;
	vUInt16					src0, src1;
	vUInt16					calc0, calc1, calc2, calc3,
							sum0, sum1, sumTemp;
	unsigned				w, h;
	const VecBytesU8		permOddPixels = { 0, 16, 0, 17, 0, 18, 0, 19, 0, 24, 0, 25, 0, 26, 0, 27 };
	const VecBytesU8		permEvenPixels = { 0, 20, 0, 21, 0, 22, 0, 23, 0, 28, 0, 29, 0, 30, 31 };
	const VecBytesU8		permCombinePix = { 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31 };
	const vUInt8			two = vec_splat_u8(2);
	
	oddSrc = (vUInt16 *)inSrc;
	evenSrc = oddSrc + inWidth / 4;
	dst = (vUInt16 *)inDst;
	
	h = inHeight / 2;
	do
	{
		w = inWidth / 8;
		do
		{
			// Load pixels 0..3 and 8..B (see description comment above)
			src0 = *oddSrc++;
			src1 = *evenSrc++;
			
			calc0 = vec_perm(permOddPixels.vec, src0, permOddPixels.vec);
			calc1 = vec_perm(permEvenPixels.vec, src0, permEvenPixels.vec);
			calc2 = vec_perm(permOddPixels.vec, src1, permOddPixels.vec);
			calc3 = vec_perm(permEvenPixels.vec, src1, permEvenPixels.vec);
			
			sum0 = vec_add(calc0, calc1);
			sumTemp = vec_add(calc2, calc3);
			sum0 = vec_add(sum0, sumTemp);
			
			// Load pixels 4..7 and C..F
			src0 = *oddSrc++;
			src1 = *evenSrc++;
			
			calc0 = vec_perm(permOddPixels.vec, src0, permOddPixels.vec);
			calc1 = vec_perm(permEvenPixels.vec, src0, permEvenPixels.vec);
			calc2 = vec_perm(permOddPixels.vec, src1, permOddPixels.vec);
			calc3 = vec_perm(permEvenPixels.vec, src1, permEvenPixels.vec);
			
			sum1 = vec_add(calc0, calc1);
			sumTemp = vec_add(calc2, calc3);
			sum1 = vec_add(sum1, sumTemp);
			
			sum0 = vec_srl(sum0, two);
			sum1 = vec_srl(sum1, two);
			sumTemp = vec_perm(sum0, sum1, permCombinePix.vec);
			*dst++ = sumTemp;
		} while (--w);
		oddSrc += inWidth / 4;
		evenSrc += inWidth / 4;
	} while (--h);
}

#endif
#endif
