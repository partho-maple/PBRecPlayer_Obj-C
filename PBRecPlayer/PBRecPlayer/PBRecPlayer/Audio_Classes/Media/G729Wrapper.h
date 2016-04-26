//
//  G729Wrapper.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import <Foundation/Foundation.h>
#include "G729CodecNative.h"

@interface G729Wrapper : NSObject

-(id) init;

-(Boolean) open;
-(Boolean) close;
-(int) encodeWithPCM: (short*) shortArray andSize: (int) size andEncodedG729: (Byte*) byteArray;
-(int) decodeWithG729: (Byte*) byteArray andSize: (int) size andEncodedPCM: (short*) shortArray;

@end

