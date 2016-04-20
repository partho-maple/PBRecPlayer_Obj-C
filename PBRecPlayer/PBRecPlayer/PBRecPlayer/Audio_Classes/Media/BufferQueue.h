//
//  BufferQueue.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BufferQueue : NSObject{
//    short  *buffer;
}

//@property (readwrite) short *buffer;
@property int front;
@property int rear;

-(id) init;
-(Boolean) pushData: (Byte*) data datalength: (int) datalen;
-(Boolean) popData: (Byte*) data datalength: (int) datalen;
-(int) getAvailableSize;
@end
