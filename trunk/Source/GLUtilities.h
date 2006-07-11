/*
	GLUtilities.h
	Dry Dock for Oolite
	$Id$
	
	Miscellaneous OpenGL tools.
	
	Copyright © 2004-2006 Jens Ayton

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

#ifndef INCLUDED_GLUTILITIES_h
#define INCLUDED_GLUTILITIES_h


#include "phystypes.h"


inline const Vector avg(const Vector &inA, const Vector &inB)
{
	return (inA + inB) / 2;
}


inline const Vector avg(const Vector &inA, const Vector &inB, const Vector &inC)
{
	return (inA + inB + inC) / 3;
}


inline const Vector avg(Vector &inA, const Vector &inB, const Vector &inC, const Vector &inD)
{
	return (inA + inB + inC + inD) / 4;
}


inline Scalar min(Scalar a, Scalar b)
{
	return (a < b) ? a : b;
}


inline Scalar max(Scalar a, Scalar b)
{
	return (a < b) ? b : a;
}

// Componentwise min and max
inline const Vector cmin(const Vector &a, const Vector &b)
{
	return Vector(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z));
}


inline const Vector cmax(const Vector &a, const Vector &b)
{
	return Vector(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z));
}

#ifdef __MWERKS__
#pragma cpp_extensions on
#endif

typedef struct Colour
{
	union
	{
		GLfloat					v[3];
		struct
		{
			GLfloat					r, g, b;
		};
	};
	
							Colour(GLfloat inR, GLfloat inG, GLfloat inB)
							{
								Set(inR, inG, inB);
							}
							Colour(void) {}
	
	void					Set(GLfloat inR, GLfloat inG, GLfloat inB)
							{
								r = inR;
								g = inG;
								b = inB;
							}
	GLfloat					&operator[](const unsigned long inIndex)
							{
								return v[inIndex];
							}
							
	void					glColor(void) const
							{
								glColor3f(r, g, b);
							}
	void					glMaterial(GLenum inFace, GLenum inParam) const
							{
								glMaterialfv(inFace, inParam, v);
							}
	void					glLight(GLenum inLight, GLenum inParam) const
							{
								glLightfv(inLight, inParam, v);
							}
} Colour;

#ifdef __MWERKS__
#pragma cpp_extensions reset
#endif


// Drawing routines for common primitives
void DrawNormal(const Vector &inSurfacePoint, const Vector &inNormal);

void DrawAxes(bool inLabels = false);

void DrawSpring(const Vector &inA, const Vector &inB, Scalar inRestLength);
inline void DrawSpring(const Vector &inA, const Vector &inB, Scalar inRestLength, Scalar inSpringConstant, Scalar inDamping) { (void) inSpringConstant; (void) inDamping; DrawSpring(inA, inB, inRestLength); }

void DrawStick(const Vector &inA, const Vector &inB, Scalar inLength);

void DrawLight(const Vector &inPos, bool inDrawVectorToOrigin = false, Scalar inScale = 0.1);

// Draws a cylinder (extruded regular polygon) of height 1 and radius 0.5 aligned with the Y axis.
void DrawCylinder(uint32_t inSubDivisions, bool inDrawCaps);
// Draw textured cylinder, without caps. Texture S co-ordinate wraps cylidner, T is vertical.
void DrawCylinder(uint32_t inSubDivisions, float inSStart, float inSEnd, float inTStart, float inTEnd);

// Draws a circle (regular polygon) of radius 0.5 in the XZ plane (normal along +Y).
//void DrawCircle(uint32_t inSubDivisions);

// Drawsa  cube[oid] of side 1 around the origin. For your inconvenience the current texture is applied to all sides.
void DrawCube(void);


typedef struct
{
	GLhandleARB		program;
	GLboolean		lighting;
	GLboolean		texture2D;
} WFModeContext;

void EnterWireframeMode(WFModeContext &outContext);
void ExitWireframeMode(const WFModeContext &inContext);


void LogGLErrors(void);
CFStringRef CopyGLErrorDescription(GLenum inError);

#endif	/* INCLUDED_GLUTILITIES_h */
