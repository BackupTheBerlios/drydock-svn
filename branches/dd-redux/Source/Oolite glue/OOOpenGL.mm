#import "OOOpenGL.h"
#import "GLUtilities.h"
#import "OOMaterial.h"


BOOL CheckOpenGLErrors(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	LogGLErrors([string UTF8String]);
	return NO;
}


OODebugWFState OODebugBeginWireframe(BOOL ignoreZ)
{
	OO_ENTER_OPENGL();
	
	OODebugWFState state = { material: [OOMaterial current] };
	[OOMaterial applyNone];
	
	glPushAttrib(GL_ENABLE_BIT | GL_DEPTH_BUFFER_BIT | GL_LINE_BIT | GL_POINT_BIT | GL_CURRENT_BIT);
	
	glDisable(GL_LIGHTING);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_FOG);
	if (ignoreZ)
	{
		glDisable(GL_DEPTH_TEST);
		glDepthMask(GL_FALSE);
	}
	else
	{
		glEnable(GL_DEPTH_TEST);
		glDepthMask(GL_TRUE);
	}
	
	glLineWidth(1.0f);
	
	return state;
}


void OODebugEndWireframe(OODebugWFState state)
{
	OO_ENTER_OPENGL();
	glPopAttrib();
	[state.material apply];
}


GLuint GLAllocateTextureName(void)
{
	GLuint tex = 0;
	glGenTextures(1, &tex);
	return tex;
}


void GLRecycleTextureName(GLuint name, GLuint mipLevels)
{
	glDeleteTextures(1, &name);
}
