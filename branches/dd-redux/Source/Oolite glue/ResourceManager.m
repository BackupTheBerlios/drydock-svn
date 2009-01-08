//
//  ResourceManager.m
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "ResourceManager.h"
#import "Logging.h"
#import "DDMockSingleton.h"
#import "DDDocument.h"


static NSString *ResolvePath(NSString *fileName, NSString *folder)
{
	DDDocument *owner = [[DDMockSingletonContext currentContext] owner];
	return [owner resolveResourcePathForFile:fileName nominalFolder:folder];
}


@implementation ResourceManager

+ (NSDictionary *) dictionaryFromFilesNamed:(NSString *)name
								   inFolder:(NSString *)folder
								   andMerge:(BOOL)merge
{
	NSString *path = ResolvePath(name, folder);
	return [NSDictionary dictionaryWithContentsOfFile:path];
}


+ (NSString *) stringFromFilesNamed:(NSString *)name
						   inFolder:(NSString *)folder
{
	NSString *path = ResolvePath(name, folder);
	return [NSString stringWithContentsOfFile:path];
}


+ (NSString *) pathForFileNamed:(NSString *)name
					   inFolder:(NSString *)folder
{
	return ResolvePath(name, folder);
}

@end
