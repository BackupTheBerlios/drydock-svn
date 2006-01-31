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
#import <CoreFoundation/CoreFoundation.h>


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
	
	inline					Vector() {}
	inline					Vector(const Scalar inVals[3]) { x = inVals[0]; y = inVals[1]; z = inVals[2]; }
	inline					Vector(Scalar inX, Scalar inY, Scalar inZ)
							{
								x = inX;
								y = inY;
								z = inZ;
							}
						
	inline Scalar			&operator[](const unsigned long inIndex)
							{
								return v[inIndex];
							}
	
	inline const Scalar		&operator[](const unsigned long inIndex) const
							{
								return v[inIndex];
							}
	
	inline void				Set(const Scalar inX, const Scalar inY = 0, const Scalar inZ = 0)
							{
								x = inX;
								y = inY;
								z = inZ;
							}
	
	#if PHYS_RANDOMIZE_URANDOMLIB
	inline void				Randomize(void)
							{
								x = PRNG.DUniform_m1_1();
								y = PRNG.DUniform_m1_1();
								z = PRNG.DUniform_m1_1();
								
								Normalize();
								
								*this *= PRNG.DUniform_m1_1();
							}
	#else
	inline void				Randomize(void)
							{
								x = random() / (float)RAND_MAX;
								y = random() / (float)RAND_MAX;
								z = random() / (float)RAND_MAX;
								
								Normalize();
								
								*this *= random() / (float)RAND_MAX;;
							}
	#endif
	
	inline const Vector		operator-() const
							// Negation
							{
								return Vector(-x, -y, -z);
							}
	
	inline const Vector		&operator=(const Vector &inVector)
							{
								this->x = inVector.x;
								this->y = inVector.y;
								this->z = inVector.z;
								return *this;
							}
	
	inline const Vector		&operator+=(const Vector &inVector)
							{
								this->x += inVector.x;
								this->y += inVector.y;
								this->z += inVector.z;
								return *this;
							}
						
	inline const Vector		&operator-=(const Vector &inVector)
							{
								this->x -= inVector.x;
								this->y -= inVector.y;
								this->z -= inVector.z;
								return *this;
							}
	
	inline const Vector		&operator*=(const Scalar inScalar)
							{
								this->x *= inScalar;
								this->y *= inScalar;
								this->z *= inScalar;
								return *this;
							}
	
	inline const Vector		&operator/=(Scalar inScalar)
							{
								inScalar = 1.0 / inScalar;
								this->x *= inScalar;
								this->y *= inScalar;
								this->z *= inScalar;
								return *this;
							}
	
	inline const Vector		operator+(const Vector &inVector) const
							{
								return Vector(this->x + inVector.x, this->y + inVector.y, this->z + inVector.z);
							}
	
	inline const Vector		operator-(const Vector &inVector) const
							{
								return Vector(this->x - inVector.x, this->y - inVector.y, this->z - inVector.z);
							}
	
	inline const Vector		operator*(const Scalar inScalar) const
							// vector * scalar
							{
								return Vector(this->x * inScalar, this->y * inScalar, this->z * inScalar);
							}
	
	friend inline const Vector operator*(const Scalar inScalar, const Vector &inVector)
							// scalar * vector
							{
								return inVector * inScalar;
							}
	
	inline const Vector		operator/(Scalar inScalar) const
							{
								inScalar = 1.0 / inScalar;
								return Vector(this->x * inScalar, this->y * inScalar, this->z * inScalar);
							}
	
	inline const Scalar		operator*(Vector &inVector) const
							// scalar (dot) product
							{
								return this->x * inVector.x + this->y * inVector.y + this->z * inVector.z;
							}
	
	inline const Vector		operator%(const Vector &v) const
							// Cross product
							{
								return Vector(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
							}
	
	inline const Vector		&operator%=(Vector &v)
							// Cross product
							{
								this->Set(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
								return *this;
							}
	
	inline const bool		operator==(Vector &inVector) const
							{
								return	(fabs(this->x - inVector.x) < kPhysComparisonMargin) &&
										(fabs(this->y - inVector.y) < kPhysComparisonMargin) &&
										(fabs(this->z - inVector.z) < kPhysComparisonMargin);
							}
	
	inline const bool		operator!=(Vector &inVector) const
							{
								return	(fabs(this->x - inVector.x) >= kPhysComparisonMargin) ||
										(fabs(this->y - inVector.y) >= kPhysComparisonMargin) ||
										(fabs(this->z - inVector.z) >= kPhysComparisonMargin);
							}
	
	inline const Scalar		SquareMagnitude() const
							{
								return x * x + y * y + z * z;
							}
	
	inline const Scalar		Magnitude() const
							{
								return sqrt(this->SquareMagnitude());
							}
	
	inline const Scalar		ReciprocalMagnitude() const
							{
								return 1.0f/this->Magnitude();
							}
	
	inline const Scalar		ApproxReciprocalMagnitude() const
							{
								#if __ppc__
									return __frsqrte(this->SquareMagnitude());
								#else
									return sqrtf(this->SquareMagnitude());
								#endif
							}
	
	inline const Vector		Direction() const
							// Return a unit vector pointing in the same direction
							{
								return *this / this->Magnitude();
							}
	
	inline const Vector		&Normalize()
							{
								*this /= this->Magnitude();
								return *this;
							}
	
	inline const Vector		ApproxUnit() const
							// Return an approximately unit vector pointing in the same direction
							{
								return *this * this->ApproxReciprocalMagnitude();
							}
	
	inline const Vector		&ApproxNormalize()
							{
								*this *= this->ApproxReciprocalMagnitude();
								return *this;
							}
	
	inline void				glDraw(void) const
							{
								glVertex();
							}
	
	inline void				glVertex(void) const
							{
								glVertex3f(x, y, z);
							}
	
	inline void				glLight(GLenum inLight) const
							{
								GLfloat val[4] = {x, y, z, 0.0f};
								glLightfv(inLight, GL_POSITION, val);
							}
	
	inline void				glQuickNormal(void) const
							{
								glNormal3f(x, y, z);
							}
	
	inline void				glNormal(void) const
							{
								ApproxUnit().glQuickNormal();
							}
	
	CFStringRef				CopyDescription(void);
	
	#ifdef NSMaximumStringLength
	inline NSString			*Description(void)
							{
								NSString *result = (NSString *)CopyDescription();
								return [result autorelease];
							}
	#endif
};


inline Scalar operator<(Scalar a, Vector b)
{
	return a < b.Magnitude();
}


inline Scalar operator>(Scalar a, Vector b)
{
	return a > b.Magnitude();
}


inline Scalar operator<=(Scalar a, Vector b)
{
	return a <= b.Magnitude();
}


inline Scalar operator>=(Scalar a, Vector b)
{
	return a >= b.Magnitude();
}


inline Scalar operator<(Vector a, Scalar b)
{
	return a.Magnitude() < b;
}


inline Scalar operator>(Vector a, Scalar b)
{
	return a.Magnitude() > b;
}


inline Scalar operator<=(Vector a, Scalar b)
{
	return a.Magnitude() <= b;
}


inline Scalar operator>=(Vector a, Scalar b)
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
	
	inline					Matrix(void) { this->SetIdentity(); };
	inline					Matrix(int) { };		// Do-nothing constructor; parameter ignored.
	inline					Matrix( Scalar AA, Scalar AB, Scalar AC, Scalar AD,
									Scalar BA, Scalar BB, Scalar BC, Scalar BD,
									Scalar CA, Scalar CB, Scalar CC, Scalar CD,
									Scalar DA, Scalar DB, Scalar DC, Scalar DD)
							{
								m[0][0] = AA; m[0][1] = AB; m[0][2] = AC; m[0][3] = AD;
								m[1][0] = BA; m[1][1] = BB; m[1][2] = BC; m[1][3] = BD;
								m[2][0] = CA; m[2][1] = CB; m[2][2] = CC; m[2][3] = CD;
								m[3][0] = DA; m[3][1] = DB; m[3][2] = DC; m[3][3] = DD;
							}
	
	
	inline Scalar			&operator[](const unsigned long inIndex)
							{
								return vals[inIndex];
							}
	
	inline void				SetIdentity(void)
							{
								m[0][0] = 1; m[0][1] = 0; m[0][2] = 0; m[0][3] = 0;
								m[1][0] = 0; m[1][1] = 1; m[1][2] = 0; m[1][3] = 0;
								m[2][0] = 0; m[2][1] = 0; m[2][2] = 1; m[2][3] = 0;
								m[3][0] = 0; m[3][1] = 0; m[3][2] = 0; m[3][3] = 1;
							}
	
	inline void				Transpose(void)
							{
								Scalar temp;
								#define SWAPM(a, b) { temp = m[a][b]; m[a][b] = m[b][a]; m[b][a] = temp; }
								SWAPM(0, 1); SWAPM(0, 2); SWAPM(0, 3);
								SWAPM(1, 2); SWAPM(1, 3); SWAPM(2, 3);
								#undef SWAPM
							}
	inline Matrix			TransposeOf(void) const
							{
								Matrix result;
								result = *this;
								result.Transpose();
								return result;
							}
	
	inline const bool		operator==(const Matrix &inMatrix) const
							{
								for (unsigned i = 0; i != 16; ++i)
								{
									if (kPhysComparisonMargin <= fabs(m[i] - inMatrix.m[i])) return false;
								}
								
								return true;
							}
	
	inline const bool		operator!=(const Matrix &inMatrix) const
							{
								for (unsigned i = 0; i != 16; ++i)
								{
									if (fabs(m[i] - inMatrix.m[i]) < kPhysComparisonMargin) return false;
								}
								
								return true;
							}
	
	Matrix					operator*(const Matrix &inMatrix) const;
	Matrix					&operator*=(const Matrix &inMatrix);
	
	static Matrix			RotationXMatrix(Scalar inAngle);
	static Matrix			RotationYMatrix(Scalar inAngle);
	static Matrix			RotationZMatrix(Scalar inAngle);
	
	Matrix					&RotateX(Scalar inAngle);
	Matrix					&RotateY(Scalar inAngle);
	Matrix					&RotateZ(Scalar inAngle);
	
	Matrix					&RotateAroundUnitAxis(Vector inAxis, Scalar inAngle);
	inline Matrix			&RotateAroundAxis(Vector inAxis, Scalar inAngle)
							{
								return RotateAroundUnitAxis(inAxis.Direction(), inAngle);
							}
	
	inline Matrix			&TranslateX(Scalar inDelta)
							{
								m[3][0] += inDelta;
								return *this;
							}
	inline Matrix			&TranslateY(Scalar inDelta)
							{
								m[3][1] += inDelta;
								return *this;
							}
	inline Matrix			&TranslateZ(Scalar inDelta)
							{
								m[3][2] += inDelta;
								return *this;
							}
	inline Matrix			&Translate(const Vector &inDelta)
							{
								m[3][0] += inDelta.x;
								m[3][1] += inDelta.y;
								m[3][2] += inDelta.z;
								return *this;
							}
	
	inline Matrix			&ScaleX(Scalar inFactor)
							{
								m[0][0] *= inFactor;
								m[1][0] *= inFactor;
								m[2][0] *= inFactor;
								return *this;
							}
	inline Matrix			&ScaleY(Scalar inFactor)
							{
								m[0][1] *= inFactor;
								m[1][1] *= inFactor;
								m[2][1] *= inFactor;
								return *this;
							}
	inline Matrix			&ScaleZ(Scalar inFactor)
							{
								m[0][2] *= inFactor;
								m[1][2] *= inFactor;
								m[2][2] *= inFactor;
								return *this;
							}
	inline Matrix			&Scale(Scalar inFactor)
							{
								ScaleX(inFactor);
								ScaleY(inFactor);
								ScaleZ(inFactor);
								return *this;
							}
	static inline Matrix	ScaleMatrix(Scalar inXFactor, Scalar inYFactor, Scalar inZFactor)
							{
								return Matrix(	inXFactor, 0, 0, 0,
												0, inYFactor, 0, 0,
												0, 0, inZFactor, 0,
												0, 0, 0, 1);
							}
	
	inline void				glLoad(void) const
							{
								#if PHYS_DOUBLE_PRECISION
									glLoadMatrixd(vals);
								#else
									glLoadMatrixf(vals);
								#endif
							}
	inline void				glLoadTranspose(void) const
							{
								#if PHYS_DOUBLE_PRECISION
									glLoadTransposeMatrixd(vals);
								#else
									glLoadTransposeMatrixf(vals);
								#endif
							}
	inline void				glMult(void) const
							{
								#if PHYS_DOUBLE_PRECISION
									glMultMatrixd(vals);
								#else
									glMultMatrixf(vals);
								#endif
							}
	inline void				glMultTranspose(void) const
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
