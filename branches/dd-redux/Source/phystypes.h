/*
	phystypes.h
	
	Copyright © 2003-2008 Jens Ayton

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

#ifndef INCLUDED_PHYSTYPES_h
#define	INCLUDED_PHYSTYPES_h

#define PHYS_RANDOMIZE_URANDOMLIB	0
#define PHYS_DOUBLE_PRECISION		0

#ifndef PHYS_VECTORISE
	#define PHYS_VECTORISE			0
#endif

#ifndef PHYS_COCOA
	#ifdef NSFoundationVersionNumber10_0	// Just a macro that's declared in NSObjCRuntime.h
		#define PHYS_COCOA			1
	#else
		#define PHYS_COCOA			0
	#endif
#endif


#ifndef PHYS_OPENGL
	#if TARGET_OS_IPHONE
		#define PHYS_OPENGL			0
	#endif
#endif


#include <math.h>
#include <stdlib.h>
#if PHYS_RANDOMIZE_URANDOMLIB
#include "URandomLib.h"
#endif
#include <gcc/darwin/default/ppc_intrinsics.h>
#include <Accelerate/Accelerate.h>
#include <CoreFoundation/CoreFoundation.h>

#if PHYS_OPENGL
#include <OpenGL/gl.h>
#endif


#ifndef GCC_ATTR
	#ifdef __GNUC__
		#define GCC_ATTR	__attribute__
	#else
		#define GCC_ATTR(foo)
	#endif
#endif


#ifndef PHYS_NO_FORCE_INLINE
	#define PHYS_ALWAYS_INLINE GCC_ATTR((always_inline))
#else
	#define PHYS_ALWAYS_INLINE
#endif

#define PHYS_PURE GCC_ATTR((pure))


#define kPhysComparisonMargin			1e-6f


#if PHYS_DOUBLE_PRECISION
	typedef GLdouble		Scalar;
	#define GL_SCALAR		GL_DOUBLE
#else
	#if PHYS_OPENGL
		typedef GLfloat		Scalar;
		#define GL_SCALAR	GL_FLOAT
	#else
		typedef float		Scalar;
	#endif
#endif


#ifdef __cplusplus


class						Vector;
class						Matrix;


#ifdef __MWERKS__
#pragma cpp_extensions on
#endif

class Vector
// 3D, hetrogenous-co-ordinate vector
{
public:
	union
	{
		Scalar					v[3];
		struct
		{
			Scalar					x, y, z;
		};
	};
	
	static const Vector zero;
	
	inline					Vector() PHYS_ALWAYS_INLINE {}
	inline					Vector(const Scalar inVals[3]) PHYS_ALWAYS_INLINE
							{
								if (NULL == inVals)
								{
									// Support Vector(0)
									x = y = z = 0.0f;
								}
								else
								{
									x = inVals[0];
									y = inVals[1];
									z = inVals[2];
								}
							}
	inline					Vector(Scalar inX, Scalar inY, Scalar inZ) PHYS_ALWAYS_INLINE
							{
								x = inX;
								y = inY;
								z = inZ;
							}
						
	inline Scalar			&operator[](const unsigned long inIndex) PHYS_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline const Scalar		&operator[](const unsigned long inIndex) const PHYS_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline Vector			&Set(const Scalar inX, const Scalar inY = 0, const Scalar inZ = 0) PHYS_ALWAYS_INLINE
							{
								x = inX;
								y = inY;
								z = inZ;
								return *this;
							}
	
	#if PHYS_RANDOMIZE_URANDOMLIB
	inline Vector			&Randomize(void) PHYS_ALWAYS_INLINE
							{
								x = PRNG.DUniform_m1_1();
								y = PRNG.DUniform_m1_1();
								z = PRNG.DUniform_m1_1();
								
								Normalize();
								
								*this *= PRNG.DUniform_m1_1();
								return *this;
							}
	#else
	inline Vector			&Randomize(void) PHYS_ALWAYS_INLINE
							{
								x = random() / (float)RAND_MAX;
								y = random() / (float)RAND_MAX;
								z = random() / (float)RAND_MAX;
								
								Normalize();
								
								*this *= random() / (float)RAND_MAX;
								return *this;
							}
	#endif
	
	inline const Vector		operator-() const PHYS_ALWAYS_INLINE
							// Negation
							{
								return Vector(-x, -y, -z);
							}
	
	inline const Vector		&operator=(const Vector &inVector) PHYS_ALWAYS_INLINE
							{
								this->x = inVector.x;
								this->y = inVector.y;
								this->z = inVector.z;
								return *this;
							}
	
	inline const Vector		&operator+=(const Vector &inVector) PHYS_ALWAYS_INLINE
							{
								this->x += inVector.x;
								this->y += inVector.y;
								this->z += inVector.z;
								return *this;
							}
						
	inline const Vector		&operator-=(const Vector &inVector) PHYS_ALWAYS_INLINE
							{
								this->x -= inVector.x;
								this->y -= inVector.y;
								this->z -= inVector.z;
								return *this;
							}
	
	inline const Vector		&operator*=(const Scalar inScalar) PHYS_ALWAYS_INLINE
							{
								this->x *= inScalar;
								this->y *= inScalar;
								this->z *= inScalar;
								return *this;
							}
	
	inline const Vector		&operator/=(Scalar inScalar) PHYS_ALWAYS_INLINE
							{
								inScalar = 1.0 / inScalar;
								this->x *= inScalar;
								this->y *= inScalar;
								this->z *= inScalar;
								return *this;
							}
	
	inline const Vector		operator+(const Vector &inVector) const PHYS_ALWAYS_INLINE
							{
								return Vector(this->x + inVector.x, this->y + inVector.y, this->z + inVector.z);
							}
	
	inline const Vector		operator-(const Vector &inVector) const PHYS_ALWAYS_INLINE
							{
								return Vector(this->x - inVector.x, this->y - inVector.y, this->z - inVector.z);
							}
	
	inline const Vector		operator*(const Scalar inScalar) const PHYS_ALWAYS_INLINE
							// vector * scalar
							{
								return Vector(this->x * inScalar, this->y * inScalar, this->z * inScalar);
							}
	
	friend inline const Vector operator*(const Scalar inScalar, const Vector &inVector) PHYS_ALWAYS_INLINE
							// scalar * vector
							{
								return inVector * inScalar;
							}
	
	inline const Vector		operator/(Scalar inScalar) const PHYS_ALWAYS_INLINE
							{
								inScalar = 1.0 / inScalar;
								return Vector(this->x * inScalar, this->y * inScalar, this->z * inScalar);
							}
	
	inline const Scalar		operator*(const Vector &inVector) const PHYS_ALWAYS_INLINE
							// scalar (dot) product
							{
								return this->x * inVector.x + this->y * inVector.y + this->z * inVector.z;
							}
	
	inline const Vector		operator%(const Vector &other) const PHYS_ALWAYS_INLINE
							// Cross product
							{
								return Vector(y * other.z - z * other.y, z * other.x - x * other.z, x * other.y - y * other.x);
							}
	
	inline const Vector		&operator%=(const Vector &other) PHYS_ALWAYS_INLINE
							// Cross product
							{
								this->Set(y * other.z - z * other.y, z * other.x - x * other.z, x * other.y - y * other.x);
								return *this;
							}
	
	inline const bool		operator==(const Vector &inVector) const PHYS_ALWAYS_INLINE
							{
								return	(fabs(this->x - inVector.x) < kPhysComparisonMargin) &&
										(fabs(this->y - inVector.y) < kPhysComparisonMargin) &&
										(fabs(this->z - inVector.z) < kPhysComparisonMargin);
							}
	
	inline const bool		operator!=(const Vector &inVector) const PHYS_ALWAYS_INLINE
							{
								return	(fabs(this->x - inVector.x) >= kPhysComparisonMargin) ||
										(fabs(this->y - inVector.y) >= kPhysComparisonMargin) ||
										(fabs(this->z - inVector.z) >= kPhysComparisonMargin);
							}
	
	inline const Scalar		SquareMagnitude() const PHYS_ALWAYS_INLINE
							{
								return x * x + y * y + z * z;
							}
	
	inline const Scalar		Magnitude() const PHYS_ALWAYS_INLINE
							{
								return sqrt(this->SquareMagnitude());
							}
	
	inline const Scalar		ReciprocalMagnitude() const PHYS_ALWAYS_INLINE
							{
								return 1.0f/this->Magnitude();
							}
	
	inline const Scalar		ApproxReciprocalMagnitude() const PHYS_ALWAYS_INLINE
							{
								#if __ppc__
									return __frsqrte(this->SquareMagnitude());
								#else
									return sqrtf(this->SquareMagnitude());
								#endif
							}
	
	inline const Vector		Direction() const PHYS_ALWAYS_INLINE
							// Return a unit vector pointing in the same direction
							{
								return *this / this->Magnitude();
							}
	
	inline Vector			&Normalize() PHYS_ALWAYS_INLINE
							{
								*this /= this->Magnitude();
								return *this;
							}
	
	inline const Vector		ApproxUnit() const PHYS_ALWAYS_INLINE
							// Return an approximately unit vector pointing in the same direction
							{
								return *this * this->ApproxReciprocalMagnitude();
							}
	
	inline Vector			&ApproxNormalize() PHYS_ALWAYS_INLINE
							{
								*this *= this->ApproxReciprocalMagnitude();
								return *this;
							}
	
	inline const Vector		operator!(void) const PHYS_ALWAYS_INLINE
							// Normal
							{
								return this->Direction();
							}
	
	inline const Scalar		operator~(void) const PHYS_ALWAYS_INLINE
							// Magnitude
							{
								return this->Magnitude();
							}
	
#if PHYS_OPENGL
	inline void				glDraw(void) const PHYS_ALWAYS_INLINE
							{
								glVertex();
							}
	
	inline void				glVertex(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glVertex3d(x, y, z);
								#else
									glVertex3f(x, y, z);
								#endif
							}
	
	inline void				glLight(GLenum inLight) const PHYS_ALWAYS_INLINE
							{
								GLfloat val[4] = {x, y, z, 0.0f};
								glLightfv(inLight, GL_POSITION, val);
							}
	
	inline void				glQuickNormal(void) const PHYS_ALWAYS_INLINE
							{
								glNormal3f(x, y, z);
							}
	
	inline void				glNormal(void) const PHYS_ALWAYS_INLINE
							{
								ApproxUnit().glQuickNormal();
							}
	
	inline void				glTranslate(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glTranslated(x, y, z);
								#else
									glTranslatef(x, y, z);
								#endif
							}
#endif
	
	inline Vector			&CleanZeros() PHYS_ALWAYS_INLINE
							{
								if (-0.0 == x) x = 0.0;
								if (-0.0 == y) y = 0.0;
								if (-0.0 == z) z = 0.0;
								return *this;
							}
	
	CFStringRef				CopyDescription(void);
	
	#if PHYS_COCOA
	inline NSString			*Description(void) PHYS_ALWAYS_INLINE
							{
								NSString *result = (NSString *)CopyDescription();
								return [result autorelease];
							}
	#endif
};


inline Scalar operator<(Scalar a, Vector b) PHYS_ALWAYS_INLINE;
inline Scalar operator<(Scalar a, Vector b)
{
	return a < b.Magnitude();
}


inline Scalar operator>(Scalar a, Vector b) PHYS_ALWAYS_INLINE;
inline Scalar operator>(Scalar a, Vector b)
{
	return a > b.Magnitude();
}


inline Scalar operator<=(Scalar a, Vector b) PHYS_ALWAYS_INLINE;
inline Scalar operator<=(Scalar a, Vector b)
{
	return a <= b.Magnitude();
}


inline Scalar operator>=(Scalar a, Vector b) PHYS_ALWAYS_INLINE;
inline Scalar operator>=(Scalar a, Vector b)
{
	return a >= b.Magnitude();
}


inline Scalar operator<(Vector a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator<(Vector a, Scalar b)
{
	return a.Magnitude() < b;
}


inline Scalar operator>(Vector a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator>(Vector a, Scalar b)
{
	return a.Magnitude() > b;
}


inline Scalar operator<=(Vector a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator<=(Vector a, Scalar b)
{
	return a.Magnitude() <= b;
}


inline Scalar operator>=(Vector a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator>=(Vector a, Scalar b)
{
	return a.Magnitude() >= b;
}


class Vector2
// 2D, hetrogenous-co-ordinate vector
{
public:
	union
	{
		Scalar					v[2];
		struct
		{
			Scalar					x, y;
		};
	};
	
	static const Vector2 zero;
	
	inline					Vector2() PHYS_ALWAYS_INLINE {}
	inline					Vector2(const Scalar inVals[2]) PHYS_ALWAYS_INLINE
							{
								if (NULL == inVals)
								{
									// Support Vector(0)
									x = y = 0.0f;
								}
								else
								{
									x = inVals[0];
									y = inVals[1];
								}
							}
	inline					Vector2(Scalar inX, Scalar inY) PHYS_ALWAYS_INLINE
							{
								x = inX;
								y = inY;
							}
						
	inline Scalar			&operator[](const unsigned long inIndex) PHYS_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline const Scalar		&operator[](const unsigned long inIndex) const PHYS_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline Vector2			&Set(const Scalar inX, const Scalar inY = 0) PHYS_ALWAYS_INLINE
							{
								x = inX;
								y = inY;
								return *this;
							}
	
	#if PHYS_RANDOMIZE_URANDOMLIB
	inline Vector2			&Randomize(void) PHYS_ALWAYS_INLINE
							{
								x = PRNG.DUniform_m1_1();
								y = PRNG.DUniform_m1_1();
								
								Normalize();
								
								*this *= PRNG.DUniform_m1_1();
								return *this;
							}
	#else
	inline Vector2			&Randomize(void) PHYS_ALWAYS_INLINE
							{
								x = random() / (float)RAND_MAX;
								y = random() / (float)RAND_MAX;
								
								Normalize();
								
								*this *= random() / (float)RAND_MAX;
								return *this;
							}
	#endif
	
	inline const Vector2	operator-() const PHYS_ALWAYS_INLINE
							// Negation
							{
								return Vector2(-x, -y);
							}
	
	inline const Vector2	&operator=(const Vector2 &inVector) PHYS_ALWAYS_INLINE
							{
								this->x = inVector.x;
								this->y = inVector.y;
								return *this;
							}
	
	inline const Vector2	&operator+=(const Vector2 &inVector) PHYS_ALWAYS_INLINE
							{
								this->x += inVector.x;
								this->y += inVector.y;
								return *this;
							}
						
	inline const Vector2	&operator-=(const Vector2 &inVector) PHYS_ALWAYS_INLINE
							{
								this->x -= inVector.x;
								this->y -= inVector.y;
								return *this;
							}
	
	inline const Vector2	&operator*=(const Scalar inScalar) PHYS_ALWAYS_INLINE
							{
								this->x *= inScalar;
								this->y *= inScalar;
								return *this;
							}
	
	inline const Vector2	&operator/=(Scalar inScalar) PHYS_ALWAYS_INLINE
							{
								inScalar = 1.0 / inScalar;
								this->x *= inScalar;
								this->y *= inScalar;
								return *this;
							}
	
	inline const Vector2	operator+(const Vector2 &inVector) const PHYS_ALWAYS_INLINE
							{
								return Vector2(this->x + inVector.x, this->y + inVector.y);
							}
	
	inline const Vector2	operator-(const Vector2 &inVector) const PHYS_ALWAYS_INLINE
							{
								return Vector2(this->x - inVector.x, this->y - inVector.y);
							}
	
	inline const Vector2	operator*(const Scalar inScalar) const PHYS_ALWAYS_INLINE
							// vector * scalar
							{
								return Vector2(this->x * inScalar, this->y * inScalar);
							}
	
	friend inline const Vector2 operator*(const Scalar inScalar, const Vector2 &inVector) PHYS_ALWAYS_INLINE
							// scalar * vector
							{
								return inVector * inScalar;
							}
	
	inline const Vector2	operator/(const Scalar inScalar) const PHYS_ALWAYS_INLINE
							{
								Scalar recip = 1.0 / inScalar;
								return Vector2(this->x * recip, this->y * recip);
							}
	
	inline const Scalar		operator*(const Vector2 &inVector) const PHYS_ALWAYS_INLINE
							// scalar (dot) product
							{
								return this->x * inVector.x + this->y * inVector.y;
							}
	
	inline const bool		operator==(const Vector2 &inVector) const PHYS_ALWAYS_INLINE
							{
								return	(fabs(this->x - inVector.x) < kPhysComparisonMargin) &&
										(fabs(this->y - inVector.y) < kPhysComparisonMargin);
							}
	
	inline const bool		operator!=(const Vector2 &inVector) const PHYS_ALWAYS_INLINE
							{
								return	(fabs(this->x - inVector.x) >= kPhysComparisonMargin) ||
										(fabs(this->y - inVector.y) >= kPhysComparisonMargin);
							}
	
	inline const Scalar		SquareMagnitude() const PHYS_ALWAYS_INLINE
							{
								return x * x + y * y;
							}
	
	inline const Scalar		Magnitude() const PHYS_ALWAYS_INLINE
							{
								return sqrt(this->SquareMagnitude());
							}
	
	inline const Scalar		ReciprocalMagnitude() const PHYS_ALWAYS_INLINE
							{
								return 1.0f/this->Magnitude();
							}
	
	inline const Scalar		ApproxReciprocalMagnitude() const PHYS_ALWAYS_INLINE
							{
								#if __ppc__
									return __frsqrte(this->SquareMagnitude());
								#else
									return sqrtf(this->SquareMagnitude());
								#endif
							}
	
	inline const Vector2	Direction() const PHYS_ALWAYS_INLINE
							// Return a unit vector pointing in the same direction
							{
								return *this / this->Magnitude();
							}
	
	inline Vector2			&Normalize() PHYS_ALWAYS_INLINE
							{
								*this /= this->Magnitude();
								return *this;
							}
	
	inline const Vector2	ApproxUnit() const PHYS_ALWAYS_INLINE
							// Return an approximately unit vector pointing in the same direction
							{
								return *this * this->ApproxReciprocalMagnitude();
							}
	
	inline Vector2			&ApproxNormalize() PHYS_ALWAYS_INLINE
							{
								*this *= this->ApproxReciprocalMagnitude();
								return *this;
							}
	
	inline const Vector2	operator!(void) const PHYS_ALWAYS_INLINE
							// Normal
							{
								return this->Direction();
							}
	
	inline const Scalar		operator~(void) const PHYS_ALWAYS_INLINE
							// Magnitude
							{
								return this->Magnitude();
							}
	
#if PHYS_OPENGL
	inline void				glDraw(void) const PHYS_ALWAYS_INLINE
							{
								glVertex();
							}
	
	inline void				glVertex(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glVertex2d(x, y);
								#else
									glVertex2f(x, y);
								#endif
							}
	
	inline void				glTexCoord(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glTexCoord2d(x, y);
								#else
									glTexCoord2f(x, y);
								#endif
							}
#endif
	
	inline Vector2			&CleanZeros() PHYS_ALWAYS_INLINE
							{
								if (-0.0 == x) x = 0.0;
								if (-0.0 == y) y = 0.0;
								return *this;
							}
	
	inline					operator Vector(void) const PHYS_ALWAYS_INLINE
							{
								return Vector(x, y, 0);
							}
	
	CFStringRef				CopyDescription(void);
	
	#if PHYS_COCOA
	inline NSString			*Description(void) PHYS_ALWAYS_INLINE
							{
								NSString *result = (NSString *)CopyDescription();
								return [result autorelease];
							}
	#endif
};


inline Scalar operator<(Scalar a, Vector2 b) PHYS_ALWAYS_INLINE;
inline Scalar operator<(Scalar a, Vector2 b)
{
	return a < b.Magnitude();
}


inline Scalar operator>(Scalar a, Vector2 b) PHYS_ALWAYS_INLINE;
inline Scalar operator>(Scalar a, Vector2 b)
{
	return a > b.Magnitude();
}


inline Scalar operator<=(Scalar a, Vector2 b) PHYS_ALWAYS_INLINE;
inline Scalar operator<=(Scalar a, Vector2 b)
{
	return a <= b.Magnitude();
}


inline Scalar operator>=(Scalar a, Vector2 b) PHYS_ALWAYS_INLINE;
inline Scalar operator>=(Scalar a, Vector2 b)
{
	return a >= b.Magnitude();
}


inline Scalar operator<(Vector2 a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator<(Vector2 a, Scalar b)
{
	return a.Magnitude() < b;
}


inline Scalar operator>(Vector2 a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator>(Vector2 a, Scalar b)
{
	return a.Magnitude() > b;
}


inline Scalar operator<=(Vector2 a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator<=(Vector2 a, Scalar b)
{
	return a.Magnitude() <= b;
}


inline Scalar operator>=(Vector2 a, Scalar b) PHYS_ALWAYS_INLINE;
inline Scalar operator>=(Vector2 a, Scalar b)
{
	return a.Magnitude() >= b;
}


class Matrix
{
public:
	union
	{
		Scalar				m[4][4];
		Scalar				vals[16];
		#if PHYS_VECTORISE
			vFloat			vec[4];
			VectorFloat		blasVec[4][1];
		#endif
	};
	
private:
	class Uninited {};
	
public:
	static Uninited uninited;
	static const Matrix identity;
	static const Matrix zero;
	
	inline					Matrix(void) PHYS_ALWAYS_INLINE
							{
								this->SetIdentity();
							};
	inline					Matrix(Uninited) PHYS_ALWAYS_INLINE
							{ };		// Do-nothing constructor; parameter ignored.
	inline					Matrix( Scalar AA, Scalar AB, Scalar AC, Scalar AD,
									Scalar BA, Scalar BB, Scalar BC, Scalar BD,
									Scalar CA, Scalar CB, Scalar CC, Scalar CD,
									Scalar DA, Scalar DB, Scalar DC, Scalar DD) PHYS_ALWAYS_INLINE
							{
								Set(AA, AB, AC, AD,
									BA, BB, BC, BD,
									CA, CB, CC, CD,
									DA, DB, DC, DD);
							}
	inline					Matrix(Vector X, Vector Y, Vector Z, Vector O = Vector(0))
							{
								Set(X, Y, Z, O);
							}
	
	inline Scalar			&operator[](const unsigned long inIndex) PHYS_ALWAYS_INLINE
							{
								return vals[inIndex];
							}
	
	inline void				Set(Scalar AA, Scalar AB, Scalar AC, Scalar AD,
								Scalar BA, Scalar BB, Scalar BC, Scalar BD,
								Scalar CA, Scalar CB, Scalar CC, Scalar CD,
								Scalar DA, Scalar DB, Scalar DC, Scalar DD) PHYS_ALWAYS_INLINE
							{
								m[0][0] = AA; m[0][1] = AB; m[0][2] = AC; m[0][3] = AD;
								m[1][0] = BA; m[1][1] = BB; m[1][2] = BC; m[1][3] = BD;
								m[2][0] = CA; m[2][1] = CB; m[2][2] = CC; m[2][3] = CD;
								m[3][0] = DA; m[3][1] = DB; m[3][2] = DC; m[3][3] = DD;
							}
							
	inline void				Set(Vector X, Vector Y, Vector Z, Vector O = Vector(0))
							{
								Set(X.x, X.y, X.z, 0,
									Y.x, Y.y, Y.z, 0,
									Z.x, Z.y, Z.z, 0,
									O.x, O.y, O.z, 1);
							}
	
	inline void				SetIdentity(void) PHYS_ALWAYS_INLINE
							{
								Set(1, 0, 0, 0,
									0, 1, 0, 0,
									0, 0, 1, 0,
									0, 0, 0, 1);
							}
	
	inline void				Transpose(void) PHYS_ALWAYS_INLINE
							{
								Scalar temp;
								#define SWAPM(a, b) { temp = m[a][b]; m[a][b] = m[b][a]; m[b][a] = temp; }
								SWAPM(0, 1); SWAPM(0, 2); SWAPM(0, 3);
								SWAPM(1, 2); SWAPM(1, 3); SWAPM(2, 3);
								#undef SWAPM
							}
	inline Matrix			TransposeOf(void) const PHYS_ALWAYS_INLINE
							{
								Matrix result;
								result = *this;
								result.Transpose();
								return result;
							}
	
	inline const bool		operator==(const Matrix &inMatrix) const PHYS_ALWAYS_INLINE
							{
								for (unsigned i = 0; i != 16; ++i)
								{
									if (kPhysComparisonMargin <= fabs(m[i] - inMatrix.m[i])) return false;
								}
								
								return true;
							}
	
	inline const bool		operator!=(const Matrix &inMatrix) const PHYS_ALWAYS_INLINE
							{
								for (unsigned i = 0; i != 16; ++i)
								{
									if (fabs(m[i] - inMatrix.m[i]) < kPhysComparisonMargin) return false;
								}
								
								return true;
							}
	
	Matrix					operator*(const Matrix &inMatrix) const PHYS_PURE;
	Matrix					&operator*=(const Matrix &inMatrix);
	
	static Matrix			RotationXMatrix(Scalar inAngle) PHYS_PURE;
	static Matrix			RotationYMatrix(Scalar inAngle) PHYS_PURE;
	static Matrix			RotationZMatrix(Scalar inAngle) PHYS_PURE;
	
	Matrix					&RotateX(Scalar inAngle);
	Matrix					&RotateY(Scalar inAngle);
	Matrix					&RotateZ(Scalar inAngle);
	
	Matrix					&RotateAroundUnitAxis(Vector inAxis, Scalar inAngle);
	inline Matrix			&RotateAroundAxis(Vector inAxis, Scalar inAngle)
							{
								return RotateAroundUnitAxis(inAxis.Direction(), inAngle);
							}
	
	inline Matrix			&TranslateX(Scalar inDelta) PHYS_ALWAYS_INLINE
							{
								m[3][0] += inDelta;
								return *this;
							}
	inline Matrix			&TranslateY(Scalar inDelta) PHYS_ALWAYS_INLINE
							{
								m[3][1] += inDelta;
								return *this;
							}
	inline Matrix			&TranslateZ(Scalar inDelta) PHYS_ALWAYS_INLINE
							{
								m[3][2] += inDelta;
								return *this;
							}
	inline Matrix			&Translate(Scalar inXDelta, Scalar inYDelta, Scalar inZDelta) PHYS_ALWAYS_INLINE
							{
								TranslateX(inXDelta);
								TranslateY(inYDelta);
								TranslateZ(inZDelta);
								return *this;
							}
	inline Matrix			&Translate(const Vector &inDelta) PHYS_ALWAYS_INLINE
							{
								return Translate(inDelta.x, inDelta.y, inDelta.z);
							}
	
	inline Matrix			&ScaleX(Scalar inFactor) PHYS_ALWAYS_INLINE
							{
								m[0][0] *= inFactor;
								m[1][0] *= inFactor;
								m[2][0] *= inFactor;
								return *this;
							}
	inline Matrix			&ScaleY(Scalar inFactor) PHYS_ALWAYS_INLINE
							{
								m[0][1] *= inFactor;
								m[1][1] *= inFactor;
								m[2][1] *= inFactor;
								return *this;
							}
	inline Matrix			&ScaleZ(Scalar inFactor) PHYS_ALWAYS_INLINE
							{
								m[0][2] *= inFactor;
								m[1][2] *= inFactor;
								m[2][2] *= inFactor;
								return *this;
							}
	inline Matrix			&Scale(Scalar inXFactor, Scalar inYFactor, Scalar inZFactor) PHYS_ALWAYS_INLINE
							{
								ScaleX(inXFactor);
								ScaleY(inYFactor);
								ScaleZ(inZFactor);
								return *this;
							}
	inline Matrix			&Scale(Scalar inFactor) PHYS_ALWAYS_INLINE
							{
								return Scale(inFactor, inFactor, inFactor);
								return *this;
							}
	static inline Matrix	ScaleMatrix(Scalar inXFactor, Scalar inYFactor, Scalar inZFactor) PHYS_ALWAYS_INLINE
							{
								return Matrix(	inXFactor, 0, 0, 0,
												0, inYFactor, 0, 0,
												0, 0, inZFactor, 0,
												0, 0, 0, 1);
							}
	
#if PHYS_OPENGL
	inline void				glLoad(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glLoadMatrixd(vals);
								#else
									glLoadMatrixf(vals);
								#endif
							}
	inline void				glLoadTranspose(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glLoadTransposeMatrixd(vals);
								#else
									glLoadTransposeMatrixf(vals);
								#endif
							}
	inline void				glMult(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glMultMatrixd(vals);
								#else
									glMultMatrixf(vals);
								#endif
							}
	inline void				glMultTranspose(void) const PHYS_ALWAYS_INLINE
							{
								#if PHYS_DOUBLE_PRECISION
									glMultTransposeMatrixd(vals);
								#else
									glMultTransposeMatrixf(vals);
								#endif
							}
#endif
	
	Matrix					&Orthogonalize(void);
	
	CFStringRef				CopyDescription(void);
	
	#if PHYS_COCOA
	inline NSString			*Description(void) PHYS_ALWAYS_INLINE
							{
								NSString *result = (NSString *)CopyDescription();
								return [result autorelease];
							}
	#endif
};


static inline const Vector operator*(const Matrix &m, const Vector &v)
{
	return Vector(m.m[0][0] * v.x + m.m[0][1] * v.y + m.m[0][2] * v.z + m.m[0][3],
				  m.m[1][0] * v.x + m.m[1][1] * v.y + m.m[1][2] * v.z + m.m[1][3],
				  m.m[2][0] * v.x + m.m[2][1] * v.y + m.m[2][2] * v.z + m.m[2][3]);
}


static inline const Vector operator*(const Vector &v, const Matrix &m)
{
	return Vector(m.m[0][0] * v.x + m.m[1][0] * v.y + m.m[2][0] * v.z + m.m[3][0],
				  m.m[0][1] * v.x + m.m[1][1] * v.y + m.m[2][1] * v.z + m.m[3][1],
				  m.m[0][2] * v.x + m.m[1][2] * v.y + m.m[2][2] * v.z + m.m[3][2]);
}


static inline const Vector &operator*=(Vector &v, const Matrix &m)
{
	Vector temp = v;
	v = temp * m;
	return v;
}

#ifdef __MWERKS__
#pragma cpp_extensions reset
#endif


#else	/* Not C++ */


typedef struct
{
	union
	{
		Scalar					v[3];
		struct
		{
			Scalar					x, y, z;
		};
	};
} Vector;


typedef struct
{
	union
	{
		Scalar					v[2];
		struct
		{
			Scalar					x, y;
		};
	};
} Vector2;


typedef struct
{
	union
	{
		Scalar				m[4][4];
		Scalar				vals[16];
		#if PHYS_VECTORISE
			vFloat			vec[4];
			VectorFloat		blasVec[4][1];
		#endif
	};
} Matrix;


#endif
#endif	/* INCLUDED_PHYSTYPES_h */
