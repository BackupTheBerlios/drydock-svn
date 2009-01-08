//
//  OOOpenGLExtensionManager.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "DDMockSingleton.h"


#define OOOpenGLExtensionManager DDMockOpenGLExtensionManager

@interface OOOpenGLExtensionManager: DDMockSingleton
{
@private
	NSOpenGLContext			*_glContext;
	NSSet					*_extensions;
}

+ (id) sharedManager;

@property (readonly, nonatomic) BOOL shadersSupported;

@property (readonly, nonatomic) unsigned majorVersionNumber;
@property (readonly, nonatomic) unsigned minorVersionNumber;
@property (readonly, nonatomic) unsigned releaseVersionNumber;

- (BOOL)haveExtension:(NSString *)extension;
- (void)getVersionMajor:(unsigned *)outMajor minor:(unsigned *)outMinor release:(unsigned *)outRelease;

@end
