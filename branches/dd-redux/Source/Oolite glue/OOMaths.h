#import "phystypes.h"
#import "OOFunctionAttributes.h"

BEGIN_EXTERN_C


#define INCLUDED_OOMATHS_h 1

#import "OOFastArithmetic.h"

typedef Matrix OOMatrix;


extern const Vector		kZeroVector,		/* 0, 0, 0 */
						kBasisXVector,		/* 1, 0, 0 */
						kBasisYVector,		/* 0, 1, 0 */
						kBasisZVector;		/* 0, 0, 1 */

extern const Matrix		kZeroMatrix,
						kIdentityMatrix;


Vector make_vector(Scalar x, Scalar y, Scalar z);
BOOL vector_equal(Vector a, Vector b);
Vector vector_add(Vector a, Vector b);
Vector vector_subtract(Vector a, Vector b);
#define vector_between(a, b) vector_subtract(b, a)
Vector cross_product(Vector first, Vector second);
Vector true_cross_product(Vector first, Vector second);
Scalar dot_product(Vector first, Vector second);
Vector normal_to_surface(Vector v1, Vector v2, Vector v3);
Vector vector_multiply_scalar(Vector v, Scalar s);
Scalar distance(Vector v1, Vector v2);
Scalar distance2(Vector v1, Vector v2);
Scalar magnitude(Vector v);
Scalar magnitude2(Vector v);
Vector vector_normal(Vector v);
void scale_vector(Vector *vec, GLfloat factor) NONNULL_FUNC;


OOINLINE Vector vector_normal_or_fallback(Vector vec, Vector fallback)
{
	GLfloat mag2 = magnitude2(vec);
	if (EXPECT_NOT(mag2 == 0))  return fallback;
	return vector_multiply_scalar(vec, OOInvSqrtf(mag2));
}

Vector OOVectorMultiplyMatrix(Vector v, OOMatrix m);

Vector OORandomUnitVector(void);
Vector OOVectorRandomSpatial(GLfloat maxLength);
Vector OOVectorRandomRadial(GLfloat maxLength);

	
#import "OOQuaternion.h"
#import "OOTriangle.h"
#import "OOBoundingBox.h"
#import "OOVoxel.h"

OOMatrix OOMatrixConstruct(GLfloat aa, GLfloat ab, GLfloat ac, GLfloat ad,
						   GLfloat ba, GLfloat bb, GLfloat bc, GLfloat bd,
						   GLfloat ca, GLfloat cb, GLfloat cc, GLfloat cd,
						   GLfloat da, GLfloat db, GLfloat dc, GLfloat dd);

OOMatrix OOMatrixForQuaternionRotation(Quaternion orientation);

NSString *VectorDescription(Vector v);
NSString *OOMatrixDescription(Matrix m);

void GLUniformMatrix(int location, Matrix m);


float randf(void);
unsigned Ranrot(void);	// Not actually Ranrot - it's easier to use a real PRNG

END_EXTERN_C
