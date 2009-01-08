#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <OpenGL/glext.h>

BEGIN_EXTERN_C


#define OO_ENTER_OPENGL()  do {} while (0)


BOOL CheckOpenGLErrors(NSString *format, ...);



@class OOMaterial;

typedef struct
{
	OOMaterial			*material;
} OODebugWFState;


OODebugWFState OODebugBeginWireframe(BOOL ignoreZ);
void OODebugEndWireframe(OODebugWFState state);


GLuint GLAllocateTextureName(void);
void GLRecycleTextureName(GLuint name, GLuint mipLevels);


#define NULL_SHADER ((GLhandleARB)0)

END_EXTERN_C
