//
//  OOMesh+PropertyList.h
//  Dry Dock Redux
//
//  Created by Jens Ayton on 2008-12-07.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOMesh.h"


@interface OOMesh (PropertyList)

- (id) propertyListRepresentation;

@end


id PropertyListFromOOMeshData(OOMeshData *data);
