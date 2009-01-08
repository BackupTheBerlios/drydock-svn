/*
	Geometry++.h
	$Id$
	
	C++ convenience operators for CGGeometry and NSGeometry types.
	
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

#ifndef INCLUDED_GEOMETRYPLUSPLUS_h
#define INCLUDED_GEOMETRYPLUSPLUS_h

#ifndef GCC_ATTR
	#ifdef __GNUC__
		#define GCC_ATTR(attr)		__attribute__(attr)
	#else
		#define GCC_ATTR()
	#endif
#endif

#ifdef __cplusplus

static inline bool operator == (const CGPoint &a, const CGPoint &b) GCC_ATTR((const, always_inline));
static inline bool operator != (const CGPoint &a, const CGPoint &b) GCC_ATTR((const, always_inline));
static inline CGPoint operator + (const CGPoint &a, const CGPoint &b) GCC_ATTR((const, always_inline));
static inline CGPoint &operator += (CGPoint &a, const CGPoint &b) GCC_ATTR((always_inline));
static inline CGPoint operator - (const CGPoint &a, const CGPoint &b) GCC_ATTR((const, always_inline));
static inline CGPoint &operator -= (CGPoint &a, const CGPoint &b) GCC_ATTR((always_inline));
static inline CGPoint operator * (const CGPoint &a, float b) GCC_ATTR((const, always_inline));
static inline CGPoint operator * (float a, const CGPoint &b) GCC_ATTR((const, always_inline));
static inline CGPoint &operator *= (CGPoint &a, float b) GCC_ATTR((always_inline));
static inline CGPoint operator / (const CGPoint &a, float b) GCC_ATTR((const, always_inline));
static inline CGPoint &operator /= (CGPoint &a, float b) GCC_ATTR((always_inline));

static inline bool operator == (const CGSize &a, const CGSize &b) GCC_ATTR((const, always_inline));
static inline bool operator != (const CGSize &a, const CGSize &b) GCC_ATTR((const, always_inline));
static inline CGSize operator + (const CGSize &a, const CGSize &b) GCC_ATTR((const, always_inline));
static inline CGSize &operator += (CGSize &a, const CGSize &b) GCC_ATTR((always_inline));
static inline CGSize operator - (const CGSize &a, const CGSize &b) GCC_ATTR((const, always_inline));
static inline CGSize &operator -= (CGSize &a, const CGSize &b) GCC_ATTR((always_inline));
static inline CGSize operator * (const CGSize &a, float b) GCC_ATTR((const, always_inline));
static inline CGSize operator * (float a, const CGSize &b) GCC_ATTR((const, always_inline));
static inline CGSize &operator *= (CGSize &a, float b) GCC_ATTR((always_inline));
static inline CGSize operator / (const CGSize &a, float b) GCC_ATTR((const, always_inline));
static inline CGSize &operator /= (CGSize &a, float b) GCC_ATTR((always_inline));

static inline bool operator == (const CGRect &a, const CGRect &b) GCC_ATTR((const, always_inline));
static inline bool operator != (const CGRect &a, const CGRect &b) GCC_ATTR((const, always_inline));
static inline CGRect operator * (const CGRect &a, float b) GCC_ATTR((const, always_inline));
static inline CGRect operator * (float a, const CGRect &b) GCC_ATTR((const, always_inline));
static inline CGRect &operator *= (CGRect &a, float b) GCC_ATTR((always_inline));
static inline CGRect operator / (const CGRect &a, float b) GCC_ATTR((const, always_inline));
static inline CGRect &operator /= (CGRect &a, float b) GCC_ATTR((always_inline));


static inline bool operator == (const CGPoint &a, const CGPoint &b)
{
	return a.x == b.x && a.y == b.y;
}


static inline bool operator != (const CGPoint &a, const CGPoint &b)
{
	return !(a == b);
}


static inline CGPoint operator + (const CGPoint &a, const CGPoint &b)
{
	CGPoint result = a;
	result += b;
	return result;
}


static inline CGPoint &operator += (CGPoint &a, const CGPoint &b)
{
	a.x += b.x;
	a.y += b.y;
	return a;
}


static inline CGPoint operator - (const CGPoint &a, const CGPoint &b)
{
	CGPoint result = a;
	result -= b;
	return result;
}


static inline CGPoint &operator -= (CGPoint &a, const CGPoint &b)
{
	a.x -= b.x;
	a.y -= b.y;
	return a;
}


static inline CGPoint operator * (const CGPoint &a, float b)
{
	CGPoint result = a;
	result *= b;
	return result;
}


static inline CGPoint operator * (float a, const CGPoint &b)
{
	return b * a;
}


static inline CGPoint &operator *= (CGPoint &a, float b)
{
	a.x *= b;
	a.y *= b;
	return a;
}


static inline CGPoint operator / (const CGPoint &a, float b)
{
	CGPoint result = a;
	result /= b;
	return result;
}


static inline CGPoint &operator /= (CGPoint &a, float b)
{
	a.x /= b;
	a.y /= b;
	return a;
}


static inline bool operator == (const CGSize &a, const CGSize &b)
{
	return a.width == b.width && a.height == b.height;
}


static inline bool operator != (const CGSize &a, const CGSize &b)
{
	return !(a == b);
}


static inline CGSize operator + (const CGSize &a, const CGSize &b)
{
	CGSize result = a;
	result += b;
	return result;
}


static inline CGSize &operator += (CGSize &a, const CGSize &b)
{
	a.width += b.width;
	a.height += b.height;
	return a;
}


static inline CGSize operator - (const CGSize &a, const CGSize &b)
{
	CGSize result = a;
	result -= b;
	return result;
}


static inline CGSize &operator -= (CGSize &a, const CGSize &b)
{
	a.width -= b.width;
	a.height -= b.height;
	return a;
}


static inline CGSize operator * (const CGSize &a, float b)
{
	CGSize result = a;
	result *= b;
	return result;
}


static inline CGSize operator * (float a, const CGSize &b)
{
	return b * a;
}


static inline CGSize &operator *= (CGSize &a, float b)
{
	a.width *= b;
	a.height *= b;
	return a;
}


static inline CGSize operator / (const CGSize &a, float b)
{
	CGSize result = a;
	result /= b;
	return result;
}


static inline CGSize &operator /= (CGSize &a, float b)
{
	a.width /= b;
	a.height /= b;
	return a;
}


static inline bool operator == (const CGRect &a, const CGRect &b)
{
	return a.origin == b.origin && a.size == b.size;
}


static inline bool operator != (const CGRect &a, const CGRect &b)
{
	return !(a == b);
}


static inline CGRect operator * (const CGRect &a, float b)
{
	CGRect result = a;
	result *= b;
	return result;
}


static inline CGRect operator * (float a, const CGRect &b)
{
	return b * a;
}


static inline CGRect &operator *= (CGRect &a, float b)
{
	a.origin *= b;
	a.size *= b;
	return a;
}


static inline CGRect operator / (const CGRect &a, float b)
{
	CGRect result = a;
	result /= b;
	return result;
}


static inline CGRect &operator /= (CGRect &a, float b)
{
	a.origin /= b;
	a.size /= b;
	return a;
}


#ifdef __OBJC__

static inline bool operator == (const NSPoint &a, const NSPoint &b) GCC_ATTR((const, always_inline));
static inline bool operator != (const NSPoint &a, const NSPoint &b) GCC_ATTR((const, always_inline));
static inline NSPoint operator + (const NSPoint &a, const NSPoint &b) GCC_ATTR((const, always_inline));
static inline NSPoint &operator += (NSPoint &a, const NSPoint &b) GCC_ATTR((always_inline));
static inline NSPoint operator - (const NSPoint &a, const NSPoint &b) GCC_ATTR((const, always_inline));
static inline NSPoint &operator -= (NSPoint &a, const NSPoint &b) GCC_ATTR((always_inline));
static inline NSPoint operator * (const NSPoint &a, float b) GCC_ATTR((const, always_inline));
static inline NSPoint operator * (float a, const NSPoint &b) GCC_ATTR((const, always_inline));
static inline NSPoint &operator *= (NSPoint &a, float b) GCC_ATTR((always_inline));
static inline NSPoint operator / (const NSPoint &a, float b) GCC_ATTR((const, always_inline));
static inline NSPoint &operator /= (NSPoint &a, float b) GCC_ATTR((always_inline));

static inline bool operator == (const NSSize &a, const NSSize &b) GCC_ATTR((const, always_inline));
static inline bool operator != (const NSSize &a, const NSSize &b) GCC_ATTR((const, always_inline));
static inline NSSize operator + (const NSSize &a, const NSSize &b) GCC_ATTR((const, always_inline));
static inline NSSize &operator += (NSSize &a, const NSSize &b) GCC_ATTR((always_inline));
static inline NSSize operator - (const NSSize &a, const NSSize &b) GCC_ATTR((const, always_inline));
static inline NSSize &operator -= (NSSize &a, const NSSize &b) GCC_ATTR((always_inline));
static inline NSSize operator * (const NSSize &a, float b) GCC_ATTR((const, always_inline));
static inline NSSize operator * (float a, const NSSize &b) GCC_ATTR((const, always_inline));
static inline NSSize &operator *= (NSSize &a, float b) GCC_ATTR((always_inline));
static inline NSSize operator / (const NSSize &a, float b) GCC_ATTR((const, always_inline));
static inline NSSize &operator /= (NSSize &a, float b) GCC_ATTR((always_inline));

static inline bool operator == (const NSRect &a, const NSRect &b) GCC_ATTR((const, always_inline));
static inline bool operator != (const NSRect &a, const NSRect &b) GCC_ATTR((const, always_inline));
static inline NSRect operator * (const NSRect &a, float b) GCC_ATTR((const, always_inline));
static inline NSRect operator * (float a, const NSRect &b) GCC_ATTR((const, always_inline));
static inline NSRect &operator *= (NSRect &a, float b) GCC_ATTR((always_inline));
static inline NSRect operator / (const NSRect &a, float b) GCC_ATTR((const, always_inline));
static inline NSRect &operator /= (NSRect &a, float b) GCC_ATTR((always_inline));


static inline bool operator == (const NSPoint &a, const NSPoint &b)
{
	return a.x == b.x && a.y == b.y;
}


static inline bool operator != (const NSPoint &a, const NSPoint &b)
{
	return !(a == b);
}


static inline NSPoint operator + (const NSPoint &a, const NSPoint &b)
{
	NSPoint result = a;
	result += b;
	return result;
}


static inline NSPoint &operator += (NSPoint &a, const NSPoint &b)
{
	a.x += b.x;
	a.y += b.y;
	return a;
}


static inline NSPoint operator - (const NSPoint &a, const NSPoint &b)
{
	NSPoint result = a;
	result -= b;
	return result;
}


static inline NSPoint &operator -= (NSPoint &a, const NSPoint &b)
{
	a.x -= b.x;
	a.y -= b.y;
	return a;
}


static inline NSPoint operator * (const NSPoint &a, float b)
{
	NSPoint result = a;
	result *= b;
	return result;
}


static inline NSPoint operator * (float a, const NSPoint &b)
{
	return b * a;
}


static inline NSPoint &operator *= (NSPoint &a, float b)
{
	a.x *= b;
	a.y *= b;
	return a;
}


static inline NSPoint operator / (const NSPoint &a, float b)
{
	NSPoint result = a;
	result /= b;
	return result;
}


static inline NSPoint &operator /= (NSPoint &a, float b)
{
	a.x /= b;
	a.y /= b;
	return a;
}


static inline bool operator == (const NSSize &a, const NSSize &b)
{
	return a.width == b.width && a.height == b.height;
}


static inline bool operator != (const NSSize &a, const NSSize &b)
{
	return !(a == b);
}


static inline NSSize operator + (const NSSize &a, const NSSize &b)
{
	NSSize result = a;
	result += b;
	return result;
}


static inline NSSize &operator += (NSSize &a, const NSSize &b)
{
	a.width += b.width;
	a.height += b.height;
	return a;
}


static inline NSSize operator - (const NSSize &a, const NSSize &b)
{
	NSSize result = a;
	result -= b;
	return result;
}


static inline NSSize &operator -= (NSSize &a, const NSSize &b)
{
	a.width -= b.width;
	a.height -= b.height;
	return a;
}


static inline NSSize operator * (const NSSize &a, float b)
{
	NSSize result = a;
	result *= b;
	return result;
}


static inline NSSize operator * (float a, const NSSize &b)
{
	return b * a;
}


static inline NSSize &operator *= (NSSize &a, float b)
{
	a.width *= b;
	a.height *= b;
	return a;
}


static inline NSSize operator / (const NSSize &a, float b)
{
	NSSize result = a;
	result /= b;
	return result;
}


static inline NSSize &operator /= (NSSize &a, float b)
{
	a.width /= b;
	a.height /= b;
	return a;
}


static inline bool operator == (const NSRect &a, const NSRect &b)
{
	return a.origin == b.origin && a.size == b.size;
}


static inline bool operator != (const NSRect &a, const NSRect &b)
{
	return !(a == b);
}


static inline NSRect operator * (const NSRect &a, float b)
{
	NSRect result = a;
	result *= b;
	return result;
}


static inline NSRect operator * (float a, const NSRect &b)
{
	return b * a;
}


static inline NSRect &operator *= (NSRect &a, float b)
{
	a.origin *= b;
	a.size *= b;
	return a;
}


static inline NSRect operator / (const NSRect &a, float b)
{
	NSRect result = a;
	result /= b;
	return result;
}


static inline NSRect &operator /= (NSRect &a, float b)
{
	a.origin /= b;
	a.size /= b;
	return a;
}

#endif	/* __OBJC */
#endif	/* __cplusplus */
#endif	/* INCLUDED_GEOMETRYPLUSPLUS_h */
