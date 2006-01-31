/*
	phystypes.cp
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

#include "phystypes.h"
#include "Logging.h"


CFStringRef Vector::CopyDescription(void)
{
	return CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("{%g, %g, %g}"), x, y, z);
}


Matrix Matrix::operator*(const Matrix &inMatrix) const
{
	Matrix				result(0);
	
	#if defined(__ppc__) && PHYS_VECTORISE
		// Adaptation of MultiplyMatrix4x4 from http://developer.apple.com/hardware/ve/algorithms.html
		const vector float	*A = vec,
							*B = inMatrix.vec;
		vector float		*C = result.vec;
		
		//Load the matrix rows
		vector float A1 = vec_ld(0, A);
		vector float A2 = vec_ld(1 * sizeof (vector float), A);
		vector float A3 = vec_ld(2 * sizeof (vector float), A);
		vector float A4 = vec_ld(3 * sizeof (vector float), A);

		vector float B1 = vec_ld(0, B);
		vector float B2 = vec_ld(1 * sizeof (vector float), B);
		vector float B3 = vec_ld(2 * sizeof (vector float), B);
		vector float B4 = vec_ld(3 * sizeof (vector float), B);

		vector float zero = (vector float) vec_splat_u32(0);
		vector float C1, C2, C3, C4;

		//Do the first scalar x vector multiply for each row
		C1 = vec_madd(vec_splat(A1, 0), B1, zero);
		C2 = vec_madd(vec_splat(A2, 0), B1, zero);
		C3 = vec_madd(vec_splat(A3, 0), B1, zero);
		C4 = vec_madd(vec_splat(A4, 0), B1, zero);

		//Accumulate in the second scalar x vector multiply for each row
		C1 = vec_madd(vec_splat(A1, 1), B2, C1);
		C2 = vec_madd(vec_splat(A2, 1), B2, C2);
		C3 = vec_madd(vec_splat(A3, 1), B2, C3);
		C4 = vec_madd(vec_splat(A4, 1), B2, C4);

		//Accumulate in the third scalar x vector multiply for each row
		C1 = vec_madd(vec_splat(A1, 2), B3, C1);
		C2 = vec_madd(vec_splat(A2, 2), B3, C2);
		C3 = vec_madd(vec_splat(A3, 2), B3, C3);
		C4 = vec_madd(vec_splat(A4, 2), B3, C4);

		//Accumulate in the fourth scalar x vector multiply for each row
		C1 = vec_madd(vec_splat(A1, 3), B4, C1);
		C2 = vec_madd(vec_splat(A2, 3), B4, C2);
		C3 = vec_madd(vec_splat(A3, 3), B4, C3);
		C4 = vec_madd(vec_splat(A4, 3), B4, C4);

		//Store out the result
		vec_st(C1, 0 * sizeof (vector float), C);
		vec_st(C2, 1 * sizeof (vector float), C);
		vec_st(C3, 2 * sizeof (vector float), C);
		vec_st(C4, 3 * sizeof (vector float), C);
	#elif PHYS_VECTORISE
		vMultMatMat_4x4(((Matrix *)this)->blasVec,
						((Matrix *)&inMatrix)->blasVec,
						result.blasVec);
	#else
		unsigned			i = 0;
		
		for (i = 0; i != 4; ++i)
		{
			result.m[i][0] = m[i][0] * inMatrix.m[0][0] + m[i][1] * inMatrix.m[1][0] + m[i][2] * inMatrix.m[2][0] + m[i][3] * inMatrix.m[3][0];
			result.m[i][1] = m[i][0] * inMatrix.m[0][1] + m[i][1] * inMatrix.m[1][1] + m[i][2] * inMatrix.m[2][1] + m[i][3] * inMatrix.m[3][1];
			result.m[i][2] = m[i][0] * inMatrix.m[0][2] + m[i][1] * inMatrix.m[1][2] + m[i][2] * inMatrix.m[2][2] + m[i][3] * inMatrix.m[3][2];
			result.m[i][3] = m[i][0] * inMatrix.m[0][3] + m[i][1] * inMatrix.m[1][3] + m[i][2] * inMatrix.m[2][3] + m[i][3] * inMatrix.m[3][3];
		}
	#endif
	
	return result;
}


Matrix &Matrix::operator*=(const Matrix &inMatrix)
{
	*this = *this * inMatrix;
	return *this;
}


#if PHYS_DOUBLE_PRECISION
	#define		SINCOS(a, s, c) { s = sin(a); c = cos(a); }
#else
	#define		SINCOS(a, s, c) { s = sinf(a); c = cosf(a); }
#endif


Matrix Matrix::RotationXMatrix(Scalar inAngle)
{
	Scalar				s, c;
	SINCOS(inAngle, s, c);
	
	Matrix result(	1,	0,	0,	0,
					0,	c,	s,	0,
					0, -s,	c,	0,
					0,	0,	0,	1);
	return result;
}


Matrix Matrix::RotationYMatrix(Scalar inAngle)
{
	Scalar				s, c;
	SINCOS(inAngle, s, c);
	
	Matrix result(	c,	0, -s,	0,
					0,	1,	0,	0,
					s,	0,	c,	0,
					0,	0,	0,	1);
	return result;
}


Matrix Matrix::RotationZMatrix(Scalar inAngle)
{
	Scalar				s, c;
	SINCOS(inAngle, s, c);
	
	Matrix result(	c,	s,	0,	0,
				   -s,	c,	0,	0,
					0,	0,	1,	0,
					0,	0,	0,	1);
	return result;
}


Matrix &Matrix::RotateX(Scalar inAngle)
{
	*this *= RotationXMatrix(inAngle);
	return *this;
}


Matrix &Matrix::RotateY(Scalar inAngle)
{
	*this *= RotationYMatrix(inAngle);
	return *this;
}


Matrix &Matrix::RotateZ(Scalar inAngle)
{
	*this *= RotationZMatrix(inAngle);
	return *this;
}


Matrix &Matrix::RotateAroundUnitAxis(Vector inAxis, Scalar inAngle)
{
	float				x, y, z, s, c, t;
	
	x = inAxis.x;
	y = inAxis.y;
	z = inAxis.z;
	
	SINCOS(inAngle, s, c);
	t = 1.0f - c;
	
	#if 1
	Matrix xform(	t * x * x + c,		t * x * y + s * z,	t * x * z - s * y,	0,
					t * x * y - s * z,	t * y * y + c,		t * y * z + s * x,	0,
					t * x * y + s * y,	t * y * z - s * x,	t * z * z + c,		0,
					0,					0,					0,					1);
	#else
	Matrix xform(	t * x * x + c,		t * x * y - s * z,	t * x * z + s * y,	0,
					t * x * y + s * z,	t * y * y + c,		t * y * z - s * x,	0,
					t * x * z - s * y,	t * y * z + s * x,	t * z * z + c,		0,
					0,					0,					0,					1);
	#endif
	
	*this *= xform;
	this->Orthogonalize();
	
	return *this;
}


Matrix &Matrix::Orthogonalize(void)
{
	// Mathematically unsatisfactory but simple orthogonalization, i.e. conversion to a "proper"
	// transformation matrix. The approach is basically to make everything the cross product of
	// everything else.
	Vector				i(m[0][0], m[1][0], m[2][0]),
						j(m[0][1], m[1][1], m[2][1]),
						k(m[0][2], m[1][2], m[2][2]);
	
	k.Normalize();
	i = (j % k).Direction();
	j = k % i;
	
	m[0][0] = i[0]; m[1][0] = i[1]; m[2][0] = i[2];
	m[0][1] = j[0]; m[1][1] = j[1]; m[2][1] = j[2];
	m[0][2] = k[0]; m[1][2] = k[1]; m[2][2] = k[2];
}
