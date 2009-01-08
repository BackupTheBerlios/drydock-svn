//
//  SGLight.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "SGSceneGraphBase.h"
#import <Cocoa/Cocoa.h>	// For NSColor


@interface SGLight: NSObject <NSCopying>
{
@private
	NSString			*_name;
	GLfloat				_diffuse[4];
	GLfloat				_specular[4];
	GLfloat				_ambient[4];
	GLfloat				_position[4];
	GLfloat				_constantAttenuation;
	GLfloat				_linearAttenuation;
	GLfloat				_quadraticAttenuation;
	Vector				_spotDirection;
	GLfloat				_spotExponent;
	GLfloat				_spotCutoff;
	BOOL				_enabled;
}

@property (copy) NSString *name;

@property Vector position;					// Default: 0, 0, 1
@property (getter = isEnabled) BOOL enabled;// Default: YES
@property (getter = isPositional) BOOL positional;	// Default: NO (i.e. directional). This effectively sets position.w to either 0 or 1.

// Colours
@property (copy) NSColor *diffuse;			// Default: 0, 0, 0, 1
@property (copy) NSColor *specular;			// Default: 0, 0, 0, 1
@property (copy) NSColor *ambient;			// Default: 0, 0, 0, 1

// Attenuation
@property GLfloat constantAttenuation;		// Default: 1
@property GLfloat linearAttenuation;		// Default: 0
@property GLfloat quadraticAttenuation;		// Default: 0

// Spotlight properties
@property Vector spotDirection;				// Default: 0, 0, -1
@property GLfloat spotExponent;				// Default: 0
@property GLfloat spotCutoff;				// Default: 180 (i.e. disabled)

/*	Normally, this should only be called by SGLightManager.
	If using directly, note that ambient is set to zero; the caller is
	expected to accumulate ambients and use GL_LIGHT_MODEL_AMBIENT.
	If enabled == no, the light will be disabled and its colours set to black;
	other parameters will be ignored.
*/
- (void) applyToLight:(GLenum)light;

// Low-level access. These require all parameters to be non-null.
- (void) getDiffuseRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b alpha:(GLfloat *)a;
- (void) getSpecularRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b alpha:(GLfloat *)a;
- (void) getAmbientRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b alpha:(GLfloat *)a;
- (void) addAmbientRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b;

/*	Utility method to disable a light and set its colours to transparent black
	(so they're effectively disabled from the perspective of a shader).
*/
+ (void) disableAndClearLight:(GLenum)light;

@end
