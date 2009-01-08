//
//  ResourceManager.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-11-29.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ResourceManager: NSObject

+ (NSDictionary *) dictionaryFromFilesNamed:(NSString *)name
								   inFolder:(NSString *)folder
								   andMerge:(BOOL)merge;

+ (NSString *) stringFromFilesNamed:(NSString *)name
						   inFolder:(NSString *)folder;

+ (NSString *) pathForFileNamed:(NSString *)name
					   inFolder:(NSString *)folder;

@end
