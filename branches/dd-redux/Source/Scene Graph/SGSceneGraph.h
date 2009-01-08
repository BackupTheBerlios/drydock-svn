#import "SGSceneNode.h"

#import "SGSceneTag.h"
#import "SGSimpleTag.h"
#import "SGConditionalTag.h"
#import "SGPointSizeTag.h"
#import "SGLineWidthTag.h"

#import "SGLight.h"
#import "SGLightManager.h"


@interface SGSceneGraph: NSObject
{
@private
	NSOpenGLContext				*_context;
	SGSceneNode					*_root;
	SGLightManager				*_lightManager;
}

- (id) initWithContext:(NSOpenGLContext *)context;
- (id) initWithCurrentContext;

@property (readonly) NSOpenGLContext *context;
@property (retain) SGSceneNode *rootNode;
@property (readonly) SGLightManager *lightManager;

- (void) render;

@end


// Key representing SGSceneGraph object in render state passed to nodes
extern NSString * const kSceneGraphStateKey;
