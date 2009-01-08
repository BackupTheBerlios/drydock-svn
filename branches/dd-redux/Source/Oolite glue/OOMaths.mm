//
//  OOMaths.mm
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOMaths.h"
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>


const Vector		kZeroVector = Vector(0, 0, 0);
const Vector		kBasisXVector = Vector(1, 0, 0);
const Vector		kBasisYVector = Vector(0, 1, 0);
const Vector		kBasisZVector = Vector(0, 0, 1);

const Matrix		kZeroMatrix = Matrix::zero;
const Matrix		kIdentityMatrix = Matrix::identity;
const BoundingBox	kZeroBoundingBox = {kZeroVector, kZeroVector};


Vector make_vector(Scalar x, Scalar y, Scalar z)
{
	return Vector(x, y, z);
}


BOOL vector_equal(Vector a, Vector b)
{
	return a == b;
}


Vector vector_add(Vector a, Vector b)
{
	return a + b;
}


Vector vector_subtract(Vector a, Vector b)
{
	return a - b;
}


Vector cross_product(Vector first, Vector second)
{
	return (first % second).Direction();
}


Vector true_cross_product(Vector first, Vector second)
{
	return first % second;
}


Scalar dot_product(Vector first, Vector second)
{
	return first * second;
}


Vector normal_to_surface(Vector v1, Vector v2, Vector v3)
{
	Vector d0, d1;
	d0 = vector_subtract(v2, v1);
	d1 = vector_subtract(v3, v2);
	return cross_product(d0, d1);
}


Vector vector_multiply_scalar(Vector v, Scalar s)
{
	return v * s;
}


Scalar distance(Vector v1, Vector v2)
{
	return (v2 - v1).Magnitude();
}


Scalar distance2(Vector v1, Vector v2)
{
	return (v2 - v1).SquareMagnitude();
}


Scalar magnitude(Vector v)
{
	return v.Magnitude();
}


Scalar magnitude2(Vector v)
{
	return v.SquareMagnitude();
}


Vector vector_normal(Vector v)
{
	return v.Direction();
}


void scale_vector(Vector *vec, GLfloat factor)
{
	assert(vec != NULL);
	*vec *= factor;
}


Vector OOVectorMultiplyMatrix(Vector v, OOMatrix m)
{
	return v * m;
}


float randf(void)
{
	return (float)random() / (float)RAND_MAX;
}


unsigned Ranrot(void)
{
	return random();
}

/*	This generates random vectors distrubuted evenly over the surface of the
	unit sphere. It does this the simple way, by generating vectors in the
	half-unit cube and rejecting those outside the half-unit sphere (and the
	zero vector), then normalizing the result. (Half-unit measures are used
	to avoid unnecessary multiplications of randf() values.)
	
	In principle, using three normally-distributed co-ordinates (and again
	normalizing the result) would provide the right result without looping, but
	I don't trust bellf() so I'll go with the simple approach for now.
*/
Vector OORandomUnitVector(void)
{
	Vector				v;
	float				m;
	
	do
	{
		v = make_vector(randf() - 0.5f, randf() - 0.5f, randf() - 0.5f);
		m = magnitude2(v);
	}
	while (m > 0.25f || m == 0.0f);	// We're confining to a sphere of radius 0.5 using the sqared magnitude; 0.5 squared is 0.25.
	
	return vector_normal(v);
}


Vector OOVectorRandomSpatial(GLfloat maxLength)
{
	Vector				v;
	float				m;
	
	do
	{
		v = make_vector(randf() - 0.5f, randf() - 0.5f, randf() - 0.5f);
		m = magnitude2(v);
	}
	while (m > 0.25f);	// We're confining to a sphere of radius 0.5 using the sqared magnitude; 0.5 squared is 0.25.
	
	return vector_multiply_scalar(v, maxLength * 2.0f);	// 2.0 is to compensate for the 0.5-radius sphere.
}


Vector OOVectorRandomRadial(GLfloat maxLength)
{
	return vector_multiply_scalar(OORandomUnitVector(), randf() * maxLength);
}


OOMatrix OOMatrixConstruct(GLfloat aa, GLfloat ab, GLfloat ac, GLfloat ad,
						   GLfloat ba, GLfloat bb, GLfloat bc, GLfloat bd,
						   GLfloat ca, GLfloat cb, GLfloat cc, GLfloat cd,
						   GLfloat da, GLfloat db, GLfloat dc, GLfloat dd)
{
	return Matrix(aa, ab, ac, ad, ba, bb, bc, bd, ca, cb, cc, cd, da, db, dc, dd);
}


OOMatrix OOMatrixForQuaternionRotation(Quaternion orientation)
{
	GLfloat	w, wz, wy, wx;
	GLfloat	x, xz, xy, xx;
	GLfloat	y, yz, yy;
	GLfloat	z, zz;
	
	Quaternion q = orientation;
	quaternion_normalize(&q);
	
	w = q.w;
	z = q.z;
	y = q.y;
	x = q.x;
	
	xx = 2.0f * x; yy = 2.0f * y; zz = 2.0f * z;
	wx = w * xx; wy = w * yy; wz = w * zz;
	xx = x * xx; xy = x * yy; xz = x * zz;
	yy = y * yy; yz = y * zz;
	zz = z * zz;
	
	return OOMatrixConstruct
	(
		1.0f - yy - zz,	xy - wz,		xz + wy,		0.0f,
		xy + wz,		1.0f - xx - zz,	yz - wx,		0.0f,
		xz - wy,		yz + wx,		1.0f - xx - yy,	0.0f,
		0.0f,			0.0f,			0.0f,			1.0f
	);
}


NSString *VectorDescription(Vector v)
{
	return v.Description();
}


NSString *OOMatrixDescription(Matrix m)
{
	return m.Description();
}


void GLUniformMatrix(int location, Matrix m)
{
	glUniformMatrix4fvARB(location, 1, NO, &m.m[0][0]);
}
