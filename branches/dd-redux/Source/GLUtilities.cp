/*
	GLUtilities.mm
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2004-2007 Jens Ayton

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#include "GLUtilities.h"
#include "Logging.h"


void DrawNormal(const Vector &inSurfacePoint, const Vector &inNormal)
{
	GLboolean oldLighting;
	glGetBooleanv(GL_LIGHTING, &oldLighting);
	if (oldLighting) glDisable(GL_LIGHTING);
	
	glColor3f(0.8, 0.2, 0.2);
	glBegin(GL_POINTS);
		inSurfacePoint.glDraw();
	glEnd();
	glBegin(GL_LINES);
		inSurfacePoint.glDraw();
		(inSurfacePoint + (inNormal.Direction() * 0.1)).glDraw();
	glEnd();
	
	if (oldLighting) glEnable(GL_LIGHTING);
}


void DrawAxes(bool inLabels)
{
	WFModeContext			wfmc;
	
	EnterWireframeMode(wfmc);
	GLboolean oldLighting;
	glGetBooleanv(GL_LIGHTING, &oldLighting);
	if (oldLighting) glDisable(GL_LIGHTING);
	
	/*glColor3f(1, 1, 1);
	glBegin(GL_POINTS);
		glVertex3f(0, 0, 0);
	glEnd();*/
	glBegin(GL_LINES);
		glColor3f(1, 0, 0);
		glVertex3f(0, 0, 0);
		glVertex3f(1, 0, 0);
		glVertex3f(1, 0, 0);
		glVertex3f(0.9, 0.05, 0);
		glVertex3f(1, 0, 0);
		glVertex3f(0.9, -0.05, 0);
		if (inLabels)
		{
			glVertex3f(1.1, 0.1, 0);
			glVertex3f(1.3, -0.1, 0);
			glVertex3f(1.1, -0.1, 0);
			glVertex3f(1.3, 0.1, 0);
		}
		
		glColor3f(0, 1, 0);
		glVertex3f(0, 0, 0);
		glVertex3f(0, 1, 0);
		glVertex3f(0, 1, 0);
		glVertex3f(0, 0.9, 0.05);
		glVertex3f(0, 1, 0);
		glVertex3f(0, 0.9, -0.05);
		if (inLabels)
		{
			glVertex3f(0, 1.1, 0.1);
			glVertex3f(0, 1.3, -0.1);
			glVertex3f(0, 1.2, -0.0);
			glVertex3f(0, 1.3, 0.1);
		}
		
		glColor3f(0, 0, 1);
		glVertex3f(0, 0, 0);
		glVertex3f(0, 0, 1);
		glVertex3f(0, 0, 1);
		glVertex3f(0.05, 0, 0.9);
		glVertex3f(0, 0, 1);
		glVertex3f(-0.05, 0, 0.9);
		if (inLabels)
		{
			glVertex3f(-0.1, 0, 1.1);
			glVertex3f(0.1, 0, 1.3);
			glVertex3f(0.1, 0, 1.1);
			glVertex3f(0.1, 0, 1.3);
			glVertex3f(-0.1, 0, 1.1);
			glVertex3f(-0.1, 0, 1.3);
		}
	glEnd();
	
	if (oldLighting) glEnable(GL_LIGHTING);
	ExitWireframeMode(wfmc);
}


void DrawTransformedAxes(const Matrix &inMatrix, bool inLabels)
{
	glPushMatrix();
	inMatrix.glMult();
	DrawAxes(inLabels);
	glPopMatrix();
}


void DrawSpring(const Vector &inA, const Vector &inB, Scalar inRestLength)
{
	Vector ds = inB - inA;
	Scalar lDs = ds.Magnitude();
	
	GLfloat bright[] = {0, 1, 1}, dim[] = {0, .4, .4};
	
	glBegin(GL_LINES);
		if (lDs > inRestLength)
		{
			ds.Normalize();
			Scalar fac = (lDs - inRestLength) / 2;
			Vector m0 = inA + fac * ds;
			Vector m1 = inA + (fac + inRestLength) * ds;
			
			glColor3fv(dim);
			inA.glDraw();
			m0.glDraw();
			m1.glDraw();
			inB.glDraw();
			glColor3fv(bright);
			m0.glDraw();
			m1.glDraw();
		}
		else
		{
			glColor3fv(bright);
			inA.glDraw();
			inB.glDraw();
		}
	glEnd();
}


void DrawStick(const Vector &inA, const Vector &inB, Scalar inLength)
{
	Vector ds = inB - inA;
	Scalar lDs = ds.Magnitude();
	
	GLfloat bright[] = {.5, 1, 0}, dim[] = {.2, .4, 0};
	
	glBegin(GL_LINES);
		if (lDs > inLength)
		{
			ds.Normalize();
			Scalar fac = (lDs - inLength) / 2;
			Vector m0 = inA + fac * ds;
			Vector m1 = inA + (fac + inLength) * ds;
			
			glColor3fv(dim);
			inA.glDraw();
			m0.glDraw();
			m1.glDraw();
			inB.glDraw();
			glColor3fv(bright);
			m0.glDraw();
			m1.glDraw();
		}
		else
		{
			glColor3fv(bright);
			inA.glDraw();
			inB.glDraw();
		}
	glEnd();
}


void DrawLight(const Vector &inPos, bool inDrawVectorToOrigin, Scalar inScale)
{
	GLboolean oldLighting;
	glGetBooleanv(GL_LIGHTING, &oldLighting);
	if (oldLighting) glDisable(GL_LIGHTING);
	
	glBegin(GL_POINTS);
	{
		inPos.glVertex();
	}
	glEnd();
	
	glBegin(GL_LINES);
	{
		Vector	x(inScale, 0, 0),
				y(0, inScale, 0),
				z(0, 0, inScale);
		
		(inPos - x).glVertex();
		(inPos + x).glVertex();
		
		(inPos - y).glVertex();
		(inPos + y).glVertex();
		
		(inPos - z).glVertex();
		(inPos + z).glVertex();
		
		if (inDrawVectorToOrigin)
		{
			glVertex3f(0, 0, 0);
			inPos.glVertex();
		}
	}
	glEnd();
	
	if (oldLighting) glEnable(GL_LIGHTING);
}


void DrawCylinder(uint32_t inSubDivisions, bool inDrawCaps)
{
	float					rotate, angle, s, c, x, z;
	uint32_t				count, iter;
	
	if (inSubDivisions < 6) inSubDivisions = 6;
	rotate = M_PI * 2.0f / (float)inSubDivisions;
	count = inSubDivisions + 1;
	
	angle = 0.0f;
	
	glBegin(GL_TRIANGLE_STRIP);
	iter = count;
	do
	{
		s = sinf(angle);
		c = cosf(angle);
		x = s * 0.5;
		z = c * 0.5;
		glNormal3f(c, 0.0f, s);
		glVertex3f(x, 0.5, z);
		glVertex3f(x, -0.5, z);
		angle += rotate;
	} while (--iter);
	glEnd();
	
	if (inDrawCaps)
	{
		glBegin(GL_TRIANGLE_FAN);
		iter = count;
		glNormal3f(0.0f, 1.0f, 0.0f);
		glVertex3f(0.0f, 0.5, 0.0f);
		do
		{
			s = sinf(angle);
			c = cosf(angle);
			x = s * 0.5;
			z = c * 0.5;
			glVertex3f(x, 0.5, z);
			angle += rotate;
		} while (--iter);
		glEnd();
		
		glBegin(GL_TRIANGLE_FAN);
		iter = count;
		glNormal3f(0.0f, -1.0f, 0.0f);
		glVertex3f(0.0f, -0.5, 0.0f);
		do
		{
			s = sinf(angle);
			c = cosf(angle);
			x = s * 0.5;
			z = c * 0.5;
			glVertex3f(x, -0.5, z);
			angle -= rotate;
		} while (--iter);
		glEnd();
	}
}


void DrawCylinder(uint32_t inSubDivisions, float inSStart, float inSEnd, float inTStart, float inTEnd)
{
	float					rotate, angle, s, c, x, z, S, dS;
	uint32_t				count, iter;
	
	if (inSubDivisions < 6) inSubDivisions = 6;
	rotate = M_PI * 2.0f / (float)inSubDivisions;
	count = inSubDivisions + 1;
	
	angle = 0.0f;
	
	S = inSStart;
	dS = (inSEnd - inSStart) / (float)inSubDivisions;
	
	glBegin(GL_TRIANGLE_STRIP);
	iter = count;
	do
	{
		s = sinf(angle);
		c = cosf(angle);
		x = s * 0.5;
		z = c * 0.5;
		glNormal3f(s, 0.0f, c);
		glTexCoord2f(S, inTEnd);
		glVertex3f(x, 0.5, z);
		glTexCoord2f(S, inTStart);
		glVertex3f(x, -0.5, z);
		
		angle += rotate;
		S += dS;
	} while (--iter);
	glEnd();
}


void DrawCircle(uint32_t inSubDivisions)
{
	float					rotate, angle, s, c, x, z;
	uint32_t				count, iter;
	
	if (inSubDivisions < 6) inSubDivisions = 6;
	rotate = M_PI * 2.0f / (float)inSubDivisions;
	count = inSubDivisions + 1;
	
	angle = 0.0f;
	
	glBegin(GL_TRIANGLE_FAN);
	iter = count;
	glNormal3f(0.0f, 1.0f, 0.0f);
	glTexCoord2f(0.5f, 0.5f);
	glVertex3f(0.0f, 0.0, 0.0f);
	do
	{
		s = sinf(angle);
		c = cosf(angle);
		x = s * 0.5;
		z = c * 0.5;
		glTexCoord2f(x + 0.5, z + 0.5);
		glVertex3f(x, 0.0, z);
		angle += rotate;
	} while (--iter);
	glEnd();
}


void DrawCube(void)
{
	glBegin(GL_QUADS);
	// Top
	glNormal3f(0.0f, 1.0f, 0.0f);
	glTexCoord2f(0.0f, 0.0f);
	glVertex3f(0.5f, 0.5f, 0.5f);
	glTexCoord2f(0.0f, 1.0f);
	glVertex3f(0.5f, 0.5f, -0.5f);
	glTexCoord2f(1.0f, 1.0f);
	glVertex3f(-0.5f, 0.5f, -0.5f);
	glTexCoord2f(1.0f, 0.0f);
	glVertex3f(-0.5f, 0.5f, 0.5f);
	
	// Bottom
	glNormal3f(0.0f, -1.0f, 0.0f);
	glTexCoord2f(0.0f, 0.0f);
	glVertex3f(0.5f, -0.5f, 0.5f);
	glTexCoord2f(0.0f, 1.0f);
	glVertex3f(-0.5f, -0.5f, 0.5f);
	glTexCoord2f(1.0f, 1.0f);
	glVertex3f(-0.5f, -0.5f, -0.5f);
	glTexCoord2f(1.0f, 0.0f);
	glVertex3f(0.5f, -0.5f, -0.5f);
	
	// Front
	glNormal3f(0.0f, 0.0f, -1.0f);
	glTexCoord2f(0.0f, 0.0f);
	glVertex3f(0.5f, 0.5f, -0.5f);
	glTexCoord2f(0.0f, 1.0f);
	glVertex3f(0.5f, -0.5f, -0.5f);
	glTexCoord2f(1.0f, 1.0f);
	glVertex3f(-0.5f, -0.5f, -0.5f);
	glTexCoord2f(1.0f, 0.0f);
	glVertex3f(-0.5f, 0.5f, -0.5f);
	
	// Back
	glNormal3f(0.0f, 0.0f, 1.0f);
	glTexCoord2f(0.0f, 0.0f);
	glVertex3f(0.5f, 0.5f, 0.5f);
	glTexCoord2f(0.0f, 1.0f);
	glVertex3f(-0.5f, 0.5f, 0.5f);
	glTexCoord2f(1.0f, 1.0f);
	glVertex3f(-0.5f, -0.5f, 0.5f);
	glTexCoord2f(1.0f, 0.0f);
	glVertex3f(0.5f, -0.5f, 0.5f);
	
	// Left
	glNormal3f(-1.0f, 0.0f, 0.0f);
	glTexCoord2f(0.0f, 0.0f);
	glVertex3f(-0.5f, 0.5f, 0.5f);
	glTexCoord2f(0.0f, 1.0f);
	glVertex3f(-0.5f, 0.5f, -0.5f);
	glTexCoord2f(1.0f, 1.0f);
	glVertex3f(-0.5f, -0.5f, -0.5f);
	glTexCoord2f(1.0f, 0.0f);
	glVertex3f(-0.5f, -0.5f, 0.5f);
	
	// Right
	glNormal3f(1.0f, 0.0f, 0.0f);
	glTexCoord2f(0.0f, 0.0f);
	glVertex3f(0.5f, 0.5f, 0.5f);
	glTexCoord2f(0.0f, 1.0f);
	glVertex3f(0.5f, -0.5f, 0.5f);
	glTexCoord2f(1.0f, 1.0f);
	glVertex3f(0.5f, -0.5f, -0.5f);
	glTexCoord2f(1.0f, 0.0f);
	glVertex3f(0.5f, 0.5f, -0.5f);
	glEnd();
}


void EnterWireframeMode(WFModeContext &outContext)
{
	outContext.program = glGetHandleARB(GL_PROGRAM_OBJECT_ARB);
	glGetBooleanv(GL_LIGHTING, &outContext.lighting);
	glGetBooleanv(GL_TEXTURE_2D, &outContext.texture2D);
	
	glDisable(GL_LIGHTING);
	glDisable(GL_TEXTURE_2D);
	glUseProgramObjectARB(0);
}


void ExitWireframeMode(const WFModeContext &inContext)
{
	if (inContext.texture2D) glEnable(GL_TEXTURE_2D);
	if (inContext.lighting) glEnable(GL_LIGHTING);
	if (0 != inContext.program) glUseProgramObjectARB(inContext.program);
}


void LogGLErrors(const char *context)
{
	GLenum					error;
	CFStringRef				desc;
	
	for (;;)
	{
		error = glGetError();
		if (GL_NO_ERROR == error) break;
		
		desc = CopyGLErrorDescription(error);
		LogWithFormat(CFSTR("Got OpenGL error %@ in context %s"), desc, context);
		CFRelease(desc);
	}
}


CFStringRef CopyGLErrorDescription(GLenum inError)
{
	CFStringRef				result;
	
	switch (inError)
	{
		case GL_NO_ERROR:
			result = CFSTR("GL_NO_ERROR");
			break;
		
		case GL_INVALID_ENUM:
			result = CFSTR("GL_INVALID_ENUM");
			break;
		
		case GL_INVALID_VALUE:
			result = CFSTR("GL_INVALID_VALUE");
			break;
		
		case GL_INVALID_OPERATION:
			result = CFSTR("GL_INVALID_OPERATION");
			break;
		
		case GL_STACK_OVERFLOW:
			result = CFSTR("GL_STACK_OVERFLOW");
			break;
		
		case GL_OUT_OF_MEMORY:
			result = CFSTR("GL_OUT_OF_MEMORY");
			break;
		
		case GL_TABLE_TOO_LARGE:
			result = CFSTR("GL_TABLE_TOO_LARGE");
			break;
		
		default:
			return CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("Unknown error 0x%.4X"), inError);
	}
	
	CFRetain(result);
	return result;
}
