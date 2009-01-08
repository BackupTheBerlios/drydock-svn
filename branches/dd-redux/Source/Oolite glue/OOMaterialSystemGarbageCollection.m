//
//  OOMaterialSystemGarbageCollection.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-30.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOPNGTextureLoader.h"
#import "OOShaderMaterial.h"
#import "png.h"


@implementation OOTextureLoader (GarbageCollection)

- (void) finalize
{
	free(data);
	data = NULL;
	
	[super finalize];
}

@end


@implementation OOPNGTextureLoader (GarbageCollection)

+ (void) asyncDestroyPNGReadStruct:(NSDictionary *)pieces
{
	struct png_struct_def		*png = [[pieces objectForKey:@"png"] pointerValue];
	struct png_info_struct		*pngInfo = [[pieces objectForKey:@"pngInfo"] pointerValue];
	struct png_info_struct		*pngEndInfo = [[pieces objectForKey:@"pngEndInfo"] pointerValue];
	
	png_destroy_read_struct(&png, &pngInfo, &pngEndInfo);
}


- (void) finalize
{
	if (png != NULL)
	{
		[OOPNGTextureLoader asyncDestroyPNGReadStruct:$dict($object(png), @"png", $object(pngInfo), @"pngInfo", $object(pngEndInfo))];
		png = NULL;
	}
	
	[super finalize];
}

@end


@implementation OOShaderMaterial (GarbageCollection)

- (void) finalize
{
	free(textures);
	textures = NULL;
	
	[super finalize];
}

@end


// FIXME: glDeleteObject for OOShaderProgram


@implementation OOTexture (GarbageCollection)

- (void) finalize
{
	// FIXME: GLRecycleTextureName(_textureName, _mipLevels)
	// FIXME: sInUseTextures will keep all textures alive!
	free(_bytes);
	_bytes = NULL;
	
	[super finalize];
}

@end

