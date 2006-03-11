/*
	phystypes.h
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2003-2006 Jens Ayton

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
	#if (defined(__ppc__) || defined(__ppc64__)) && (defined(__VEC__) || defined(VEC))
		#define PHYS_VECTORISE		!defined(PHYS_NO_VECTORISE_PPC)
	#elif defined(__i386__) && defined(__SSE__)
		#define PHYS_VECTORISE		1
	#else
		#define PHYS_VECTORISE		0
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


#ifdef __GNUC__
	#define GCC_ATTR	__attribute__
#else
	#define GCC_ATTR(foo)
#endif


#define kPhysComparisonMargin			1e-6f


#if PHYS_DOUBLE_PRECISION
	typedef GLdouble	Scalar;
#else
	typedef GLfloat		Scalar;
#endif

class					Vector;
class					Matrix;


#pragma cpp_extensions on

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
		#if PHYS_VECTORISE
			vFloat			vec;
		#endif
	};
	
	inline					Vector() GCC_ATTR((always_inline)) {}
	inline					Vector(const Scalar inVals[3]) GCC_ATTR((always_inline))
							{
								x = inVals[0];
								y = inVals[1];
								z = inVals[2];
							}
	inline					Vector(Scalar inX, Scalar inY, Scalar inZ) GCC_ATTR((always_inline))
							{
								x = inX;
								y = inY;
								z = inZ;
							}
						
	inline Scalar			&operator[](const unsigned long inIndex) GCC_ATTR((always_inline))
							{
								return v[inIndex];
							}
	
	inline const Scalar		&operator[](const unsigned long inIndex) const GCC_ATTR((always_inline))
							{
								return v[inIndex];
							}
	
	inline Vector			&Set(const Scalar inX, const Scalar inY = 0, const Scalar inZ = 0) GCC_ATTR((always_inline))
							{
								x = inX;
								y = inY;
								z = inZ;
								return *this;
							}
	
	#if PHYS_RANDOMIZE_URANDOMLIB
	inline Vector			&Randomize(void) GCC_ATTR((always_inline))
							{
								x = PRNG.DUniform_m1_1();
								y = PRNG.DUniform_m1_1();
								z = PRNG.DUniform_m1_1();
								
								Normalize();
								
								*this *= PRNG.DUniform_m1_1();
								return *this;
							}
	#else
	inline Vector			&Randomize(void) GCC_ATTR((always_inline))
							{
								x = random() / (float)RAND_MAX;
								y = random() / (float)RAND_MAX;
								z = random() / (float)RAND_MAX;
								
								Normalize();
								
								*this *= random() / (float)RAND_MAX;
								return *this;
							}
	#endif
	
	inline const Vector		operator-() const GCC_ATTR((always_inline))
							// Negation
							{
								return Vector(-x, -y, -z);
							}
	
	inline const Vector		&operator=(const Vector &inVector) GCC_ATTR((always_inline))
							{
								this->x = inVector.x;
								this->y = inVector.y;
								this->z = inVector.z;
								return *this;
							}
	
	inline const Vector		&operator+=(const Vector &inVector) GCC_ATTR((always_inline))
							{
								this->x += inVector.x;
								this->y += inVector.y;
								this->z += inVector.z;
								return *this;
							}
						
	inline const Vector		&operator-=(const Vector &inVector) GCC_ATTR((always_inline))
							{
								this->x -= inVector.x;
								this->y -= inVector.y;
								this->z -= inVector.z;
								return *this;
							}
	
	inline const Vector		&operator*=(const Scalar inScalar) GCC_ATTR((always_inline))
							{
								this->x *= inScalar;
								this->y *= inScalar;
								this->z *= inScalar;
								return *this;
							}
	
	inline const Vector		&operator/=(Scalar inScalar) GCC_ATTR((always_inline))
							{
								inScalar = 1.0 / inScalar;
								this->x *= inScalar;
								this->y *= inScalar;
								this->z *= inScalar;
								return *this;
							}
	
	inline const Vector		operator+(const Vector &inVector) const GCC_ATTR((always_inline))
							{
								return Vector(this->x + inVector.x, this->y + inVector.y, this->z + inVector.z);
							}
	
	inline const Vector		operator-(const Vector &inVector) const GCC_ATTR((always_inline))
							{
								return Vector(this->x - inVector.x, this->y - inVector.y, this->z - inVector.z);
							}
	
	inline const Vector		operator*(const Scalar inScalar) const GCC_ATTR((always_inline))
							// vector * scalar
							{
								return Vector(this->x * inScalar, this->y * inScalar, this->z * inScalar);
							}
	
	friend inline const Vector operator*(const Scalar inScalar, const Vector &inVector) GCC_ATTR((always_inline))
							// scalar * vector
							{
								return inVector * inScalar;
							}
	
	inline const Vector		operator/(Scalar inScalar) const GCC_ATTR((always_inline))
							{
								inScalar = 1.0 / inScalar;
								return Vector(this->x * inScalar, this->y * inScalar, this->z * inScalar);
							}
	
	inline const Scalar		operator*(Vector &inVector) const GCC_ATTR((always_inline))
							// scalar (dot) product
							{
								return this->x * inVector.x + this->y * inVector.y + this->z * inVector.z;
							}
	
	inline const Vector		operator%(const Vector &v) const GCC_ATTR((always_inline))
							// Cross product
							{
								return Vector(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
							}
	
	inline const Vector		&operator%=(Vector &v) GCC_ATTR((always_inline))
							// Cross product
							{
								this->Set(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
								return *this;
							}
	
	inline const bool		operator==(Vector &inVector) const GCC_ATTR((always_inline))
							{
								return	(fabs(this->x - inVector.x) < kPhysComparisonMargin) &&
										(fabs(this->y - inVector.y) < kPhysComparisonMargin) &&
										(fabs(this->z - inVector.z) < kPhysComparisonMargin);
							}
	
	inline const bool		operator!=(Vector &inVector) const GCC_ATTR((always_inline))
							{
								return	(fabs(this->x - inVector.x) >= kPhysComparisonMargin) ||
										(fabs(this->y - inVector.y) >= kPhysComparisonMargin) ||
										(fabs(this->z - inVector.z) >= kPhysComparisonMargin);
							}
	
	inline const Scalar		SquareMagnitude() const GCC_ATTR((always_inline))
							{
								return x * x + y * y + z * z;
							}
	
	inline const Scalar		Magnitude() const GCC_ATTR((always_inline))
							{
								return sqrt(this->SquareMagnitude());
							}
	
	inline const Scalar		ReciprocalMagnitude() const GCC_ATTR((always_inline))
							{
								return 1.0f/this->Magnitude();
							}
	
	inline const Scalar		ApproxReciprocalMagnitude() const GCC_ATTR((always_inline))
							{
								#if __ppc__
									return __frsqrte(this->SquareMagnitude());
								#else
									return sqrtf(this->SquareMagnitude());
								#endif
							}
	
	inline const Vector		Direction() const GCC_ATTR((always_inline))
							// Return a unit vector pointing in the same direction
							{
								return *this / this->Magnitude();
							}
	
	inline Vector			&Normalize() GCC_ATTR((always_inline))
							{
								*this /= this->Magnitude();
								return *this;
							}
	
	inline const Vector		ApproxUnit() const GCC_ATTR((always_inline))
							// Return an approximately unit vector pointing in the same direction
							{
								return *this * this->ApproxReciprocalMagnitude();
							}
	
	inline Vector			&ApproxNormalize() GCC_ATTR((always_inline))
							{
								*this *= this->ApproxReciprocalMagnitude();
								return *this;
							}
	
	inline void				glDraw(void) const GCC_ATTR((always_inline))
							{
								glVertex();
							}
	
	inline void				glVertex(void) const GCC_ATTR((always_inline))
							{
								#if PHYS_DOUBLE_PRECISION
									glVertex3d(x, y, z);
								#else
									glVertex3f(x, y, z);
								#endif
							}
	
	inline void				glLight(GLenum inLight) const GCC_ATTR((always_inline))
							{
								GLfloat val[4] = {x, y, z, 0.0f};
								glLightfv(inLight, GL_POSITION, val);
							}
	
	inline void				glQuickNormal(void) const GCC_ATTR((always_inline))
							{
								glNormal3f(x, y, z);
							}
	
	inline void				glNormal(void) const GCC_ATTR((always_inline))
							{
								ApproxUnit().glQuickNormal();
							}
	
	inline Vector			&CleanZeros() GCC_ATTR((always_inline))
							{
								if (-0.0 == x) x = 0.0;
								if (-0.0 == y) y = 0.0;
								if (-0.0 == z) z = 0.0;
								return *this;
							}
	
	CFStringRef				CopyDescription(void);
	
	#ifdef NSMaximumStringLength
	inline NSString			*Description(void) GCC_ATTR((always_inline))
							{
								NSString *result = (NSString *)CopyDescription();
								return [result autorelease];
							}
	#endif
};


inline Scalar operator<(Scalar a, Vector b) GCC_ATTR((always_inline));
inline Scalar operator<(Scalar a, Vector b)
{
	return a < b.Magnitude();
}


inline Scalar operator>(Scalar a, Vector b) GCC_ATTR((always_inline));
inline Scalar operator>(Scalar a, Vector b)
{
	return a > b.Magnitude();
}


inline Scalar operator<=(Scalar a, Vector b) GCC_ATTR((always_inline));
inline Scalar operator<=(Scalar a, Vector b)
{
	return a <= b.Magnitude();
}


inline Scalar operator>=(Scalar a, Vector b) GCC_ATTR((always_inline));
inline Scalar operator>=(Scalar a, Vector b)
{
	return a >= b.Magnitude();
}


inline Scalar operator<(Vector a, Scalar b) GCC_ATTR((always_inline));
inline Scalar operator<(Vector a, Scalar b)
{
	return a.Magnitude() < b;
}


inline Scalar operator>(Vector a, Scalar b) GCC_ATTR((always_inline));
inline Scalar operator>(Vector a, Scalar b)
{
	return a.Magnitude() > b;
}


inline Scalar operator<=(Vector a, Scalar b) GCC_ATTR((always_inline));
inline Scalar operator<=(Vector a, Scalar b)
{
	return a.Magnitude() <= b;
}


inline Scalar operator>=(Vector a, Scalar b) GCC_ATTR((always_inline));
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
	
	inline					Vector2() GCC_ATTR((always_inline)) {}
	inline					Vector2(const Scalar inVals[2]) GCC_ATTR((always_inline))
							{
								x = inVals[0];
								y = inVals[1];
							}
	inline					Vector2(Scalar inX, Scalar inY) GCC_ATTR((always_inline))
							{
								x = inX;
								y = inY;
							}
						
	inline Scalar			&operator[](const unsigned long inIndex) GCC_ATTR((always_inline))
							{
								return v[inIndex];
							}
	
	inline const Scalar		&operator[](const unsigned long inIndex) const GCC_ATTR((always_inline))
							{
								return v[inIndex];
							}
	
	inline Vector2			&Set(const Scalar inX, const Scalar inY = 0) GCC_ATTR((always_inline))
							{
								x = inX;
								y = inY;
								return *this;
							}
	
	#if PHYS_RANDOMIZE_URANDOMLIB
	inline Vector2			&Randomize(void) GCC_ATTR((always_inline))
							{
								x = PRNG.DUniform_m1_1();
								y = PRNG.DUniform_m1_1();
								
								Normalize();
								
								*this *= PRNG.DUniform_m1_1();
								return *this;
							}
	#else
	inline Vector2			&Randomize(void) GCC_ATTR((always_inline))
							{
								x = random() / (float)RAND_MAX;
								y = random() / (float)RAND_MAX;
								
								Normalize();
								
								*this *= random() / (float)RAND_MAX;
								return *this;
							}
	#endif
	
	inline const Vector2	operator-() const GCC_ATTR((always_inline))
							// Negation
							{
								return Vector2(-x, -y);
							}
	
	inline const Vector2	&operator=(const Vector2 &inVector) GCC_ATTR((always_inline))
							{
								this->x = inVector.x;
								this->y = inVector.y;
								return *this;
							}
	
	inline const Vector2	&operator+=(const Vector2 &inVector) GCC_ATTR((always_inline))
							{
								this->x += inVector.x;
								this->y += inVector.y;
								return *this;
							}
						
	inline const Vector2	&operator-=(const Vector2 &inVector) GCC_ATTR((always_inline))
							{
								this->x -= inVector.x;
								this->y -= inVector.y;
								return *this;
							}
	
	inline const Vector2	&operator*=(const Scalar inScalar) GCC_ATTR((always_inline))
							{
								this->x *= inScalar;
								this->y *= inScalar;
								return *this;
							}
	
	inline const Vector2	&operator/=(Scalar inScalar) GCC_ATTR((always_inline))
							{
								inScalar = 1.0 / inScalar;
								this->x *= inScalar;
								this->y *= inScalar;
								return *this;
							}
	
	inline const Vector2	operator+(const Vector2 &inVector) const GCC_ATTR((always_inline))
							{
								return Vector2(this->x + inVector.x, this->y + inVector.y);
							}
	
	inline const Vector2	operator-(const Vector2 &inVector) const GCC_ATTR((always_inline))
							{
								return Vector2(this->x - inVector.x, this->y - inVector.y);
							}
	
	inline const Vector2	operator*(const Scalar inScalar) const GCC_ATTR((always_inline))
							// vector * scalar
							{
								return Vector2(this->x * inScalar, this->y * inScalar);
							}
	
	friend inline const Vector2 operator*(const Scalar inScalar, const Vector2 &inVector) GCC_ATTR((always_inline))
							// scalar * vector
							{
								return inVector * inScalar;
							}
	
	inline const Vector2	operator/(Scalar inScalar) const GCC_ATTR((always_inline))
							{
								inScalar = 1.0 / inScalar;
								return Vector2(this->x * inScalar, this->y * inScalar);
							}
	
	inline const Scalar		operator*(Vector2 &inVector) const GCC_ATTR((always_inline))
							// scalar (dot) product
							{
								return this->x * inVector.x + this->y * inVector.y;
							}
	
	inline const bool		operator==(Vector2 &inVector) const GCC_ATTR((always_inline))
							{
								return	(fabs(this->x - inVector.x) < kPhysComparisonMargin) &&
										(fabs(this->y - inVector.y) < kPhysComparisonMargin);
							}
	
	inline const bool		operator!=(Vector2 &inVector) const GCC_ATTR((always_inline))
							{
								return	(fabs(this->x - inVector.x) >= kPhysComparisonMargin) ||
										(fabs(this->y - inVector.y) >= kPhysComparisonMargin);
							}
	
	inline const Scalar		SquareMagnitude() const GCC_ATTR((always_inline))
							{
								return x * x + y * y;
							}
	
	inline const Scalar		Magnitude() const GCC_ATTR((always_inline))
							{
								return sqrt(this->SquareMagnitude());
							}
	
	inline const Scalar		ReciprocalMagnitude() const GCC_ATTR((always_inline))
							{
								return 1.0f/this->Magnitude();
							}
	
	inline const Scalar		ApproxReciprocalMagnitude() const GCC_ATTR((always_inline))
							{
								#if __ppc__
									return __frsqrte(this->SquareMagnitude());
								#else
									return sqrtf(this->SquareMagnitude());
								#endif
							}
	
	inline const Vector2	Direction() const GCC_ATTR((always_inline))
							// Return a unit vector pointing in the same direction
							{
								return *this / this->Magnitude();
							}
	
	inline Vector2			&Normalize() GCC_ATTR((always_inline))
							{
								*this /= this->Magnitude();
								return *this;
							}
	
	inline const Vector2	ApproxUnit() const GCC_ATTR((always_inline))
							// Return an approximately unit vector pointing in the same direction
							{
								return *this * this->ApproxReciprocalMagnitude();
							}
	
	inline Vector2			&ApproxNormalize() GCC_ATTR((always_inline))
							{
								*this *= this->ApproxReciprocalMagnitude();
								return *this;
							}
	
	inline void				glDraw(void) const GCC_ATTR((always_inline))
							{
								glVertex();
							}
	
	inline void				glVertex(void) const GCC_ATTR((always_inline))
							{
								#if PHYS_DOUBLE_PRECISION
									glVertex2d(x, y);
								#else
									glVertex2f(x, y);
								#endif
							}
	
	inline void				glTexCoord(void) const GCC_ATTR((always_inline))
							{
								#if PHYS_DOUBLE_PRECISION
									glTexCoord2d(x, y);
								#else
									glTexCoord2f(x, y);
								#endif
							}
	
	inline Vector2			&CleanZeros() GCC_ATTR((always_inline))
							{
								if (-0.0 == x) x = 0.0;
								if (-0.0 == y) y = 0.0;
								return *this;
							}
	
	CFStringRef				CopyDescription(void);
	
	#ifdef NSMaximumStringLength
	inline NSString			*Description(void) GCC_ATTR((always_inline))
							{
								NSString *result = (NSString *)CopyDescription();
								return [result autorelease];
							}
	#endif
};


inline Scalar operator<(Scalar a, Vector2 b) GCC_ATTR((always_inline));
inline Scalar operator<(Scalar a, Vector2 b)
{
	return a < b.Magnitude();
}


inline Scalar operator>(Scalar a, Vector2 b) GCC_ATTR((always_inline));
inline Scalar operator>(Scalar a, Vector2 b)
{
	return a > b.Magnitude();
}


inline Scalar operator<=(Scalar a, Vector2 b) GCC_ATTR((always_inline));
inline Scalar operator<=(Scalar a, Vector2 b)
{
	return a <= b.Magnitude();
}


inline Scalar operator>=(Scalar a, Vector2 b) GCC_ATTR((always_inline));
inline Scalar operator>=(Scalar a, Vector2 b)
{
	return a >= b.Magnitude();
}


inline Scalar operator<(Vector2 a, Scalar b) GCC_ATTR((always_inline));
inline Scalar operator<(Vector2 a, Scalar b)
{
	return a.Magnitude() < b;
}


inline Scalar operator>(Vector2 a, Scalar b) GCC_ATTR((always_inline));
inline Scalar operator>(Vector2 a, Scalar b)
{
	return a.Magnitude() > b;
}


inline Scalar operator<=(Vector2 a, Scalar b) GCC_ATTR((always_inline));
inline Scalar operator<=(Vector2 a, Scalar b)
{
	return a.Magnitude() <= b;
}


inline Scalar operator>=(Vector2 a, Scalar b) GCC_ATTR((always_inline));
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
	
	inline					Matrix(void) GCC_ATTR((always_inline))
							{
								this->SetIdentity();
							};
	inline					Matrix(int) GCC_ATTR((always_inline))
							{ };		// Do-nothing constructor; parameter ignored.
	inline					Matrix( Scalar AA, Scalar AB, Scalar AC, Scalar AD,
									Scalar BA, Scalar BB, Scalar BC, Scalar BD,
									Scalar CA, Scalar CB, Scalar CC, Scalar CD,
									Scalar DA, Scalar DB, Scalar DC, Scalar DD) GCC_ATTR((always_inline))
							{
								m[0][0] = AA; m[0][1] = AB; m[0][2] = AC; m[0][3] = AD;
								m[1][0] = BA; m[1][1] = BB; m[1][2] = BC; m[1][3] = BD;
								m[2][0] = CA; m[2][1] = CB; m[2][2] = CC; m[2][3] = CD;
								m[3][0] = DA; m[3][1] = DB; m[3][2] = DC; m[3][3] = DD;
							}
	
	
	inline Scalar			&operator[](const unsigned long inIndex) GCC_ATTR((always_inline))
							{
								return vals[inIndex];
							}
	
	inline void				SetIdentity(void) GCC_ATTR((always_inline))
							{
								m[0][0] = 1; m[0][1] = 0; m[0][2] = 0; m[0][3] = 0;
								m[1][0] = 0; m[1][1] = 1; m[1][2] = 0; m[1][3] = 0;
								m[2][0] = 0; m[2][1] = 0; m[2][2] = 1; m[2][3] = 0;
								m[3][0] = 0; m[3][1] = 0; m[3][2] = 0; m[3][3] = 1;
							}
	
	inline void				Transpose(void) GCC_ATTR((always_inline))
							{
								Scalar temp;
								#define SWAPM(a, b) { temp = m[a][b]; m[a][b] = m[b][a]; m[b][a] = temp; }
								SWAPM(0, 1); SWAPM(0, 2); SWAPM(0, 3);
								SWAPM(1, 2); SWAPM(1, 3); SWAPM(2, 3);
								#undef SWAPM
							}
	inline Matrix			TransposeOf(void) const GCC_ATTR((always_inline))
							{
								Matrix result;
								result = *this;
								result.Transpose();
								return result;
							}
	
	inline const bool		operator==(const Matrix &inMatrix) const GCC_ATTR((always_inline))
							{
								for (unsigned i = 0; i != 16; ++i)
								{
									if (kPhysComparisonMargin <= fabs(m[i] - inMatrix.m[i])) return false;
								}
								
								return true;
							}
	
	inline const bool		operator!=(const Matrix &inMatrix) const GCC_ATTR((always_inline))
							{
								for (unsigned i = 0; i != 16; ++i)
								{
									if (fabs(m[i] - inMatrix.m[i]) < kPhysComparisonMargin) return false;
								}
								
								return true;
							}
	
	Matrix					operator*(const Matrix &inMatrix) const GCC_ATTR((pure));
	Matrix					&operator*=(const Matrix &inMatrix);
	
	static Matrix			RotationXMatrix(Scalar inAngle) GCC_ATTR((pure));
	static Matrix			RotationYMatrix(Scalar inAngle) GCC_ATTR((pure));
	static Matrix			RotationZMatrix(Scalar inAngle) GCC_ATTR((pure));
	
	Matrix					&RotateX(Scalar inAngle);
	Matrix					&RotateY(Scalar inAngle);
	Matrix					&RotateZ(Scalar inAngle);
	
	Matrix					&RotateAroundUnitAxis(Vector inAxis, Scalar inAngle);
	inline Matrix			&RotateAroundAxis(Vector inAxis, Scalar inAngle)
							{
								return RotateAroundUnitAxis(inAxis.Direction(), inAngle);
							}
	
	inline Matrix			&TranslateX(Scalar inDelta) GCC_ATTR((always_inline))
							{
								m[3][0] += inDelta;
								return *this;
							}
	inline Matrix			&TranslateY(Scalar inDelta) GCC_ATTR((always_inline))
							{
								m[3][1] += inDelta;
								return *this;
							}
	inline Matrix			&TranslateZ(Scalar inDelta) GCC_ATTR((always_inline))
							{
								m[3][2] += inDelta;
								return *this;
							}
	inline Matrix			&Translate(const Vector &inDelta) GCC_ATTR((always_inline))
							{
								m[3][0] += inDelta.x;
								m[3][1] += inDelta.y;
								m[3][2] += inDelta.z;
								return *this;
							}
	
	inline Matrix			&ScaleX(Scalar inFactor) GCC_ATTR((always_inline))
							{
								m[0][0] *= inFactor;
								m[1][0] *= inFactor;
								m[2][0] *= inFactor;
								return *this;
							}
	inline Matrix			&ScaleY(Scalar inFactor) GCC_ATTR((always_inline))
							{
								m[0][1] *= inFactor;
								m[1][1] *= inFactor;
								m[2][1] *= inFactor;
								return *this;
							}
	inline Matrix			&ScaleZ(Scalar inFactor) GCC_ATTR((always_inline))
							{
								m[0][2] *= inFactor;
								m[1][2] *= inFactor;
								m[2][2] *= inFactor;
								return *this;
							}
	inline Matrix			&Scale(Scalar inFactor) GCC_ATTR((always_inline))
							{
								ScaleX(inFactor);
								ScaleY(inFactor);
								ScaleZ(inFactor);
								return *this;
							}
	static inline Matrix	ScaleMatrix(Scalar inXFactor, Scalar inYFactor, Scalar inZFactor) GCC_ATTR((always_inline))
							{
								return Matrix(	inXFactor, 0, 0, 0,
												0, inYFactor, 0, 0,
												0, 0, inZFactor, 0,
												0, 0, 0, 1);
							}
	
	inline void				glLoad(void) const GCC_ATTR((always_inline))
							{
								#if PHYS_DOUBLE_PRECISION
									glLoadMatrixd(vals);
								#else
									glLoadMatrixf(vals);
								#endif
							}
	inline void				glLoadTranspose(void) const GCC_ATTR((always_inline))
							{
								#if PHYS_DOUBLE_PRECISION
									glLoadTransposeMatrixd(vals);
								#else
									glLoadTransposeMatrixf(vals);
								#endif
							}
	inline void				glMult(void) const GCC_ATTR((always_inline))
							{
								#if PHYS_DOUBLE_PRECISION
									glMultMatrixd(vals);
								#else
									glMultMatrixf(vals);
								#endif
							}
	inline void				glMultTranspose(void) const GCC_ATTR((always_inline))
							{
								#if PHYS_DOUBLE_PRECISION
									glMultTransposeMatrixd(vals);
								#else
									glMultTransposeMatrixf(vals);
								#endif
							}
	
	Matrix					&Orthogonalize(void);
};

#pragma cpp_extensions reset
#endif	/* INCLUDED_PHYSTYPES_h */
