//
//  BufferQueue.m
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import "BufferQueue.h"

#define kBufferSize 1024

@implementation BufferQueue

short bufferq[kBufferSize];

@synthesize front, rear;

-(id) init{
    self = [super init];
    //buffer = alloca(514);
    front = rear = 0;
    return self;
}

-(Boolean) pushData:(Byte *)data datalength:(int)datalen{
    int totalDataLength = datalen;
//    NSLog(@"pushData stat rear %d - front %d", rear, front);
    if(rear+ totalDataLength < kBufferSize){
//        NSLog(@"rear+ totalDataLength , rear: %d, %d", rear+ totalDataLength, rear);
        memcpy(bufferq+rear, data, totalDataLength);
        rear += totalDataLength;
//        NSLog(@"coppied");
    }
    else{
        int availableLength = kBufferSize - rear;
//        NSLog(@"available length , rear: %d, %d", availableLength, rear);
        memcpy(bufferq+rear, data, availableLength);
        memcpy(bufferq, data+availableLength, totalDataLength-availableLength);
        rear = totalDataLength-availableLength;
        if (rear >= front) {
            front = rear + 1;
        }
        
//        NSLog(@"coppied");
    }
//    rear++;
    if(rear == kBufferSize)
        rear = 0;
//    NSLog(@"pushData end rear %d - front %d", rear, front);
    return true;
}

-(Boolean) popData:(Byte *)data datalength:(int)datalen{
    if(rear == front)
        return false;
//    NSLog(@"pop start rear %d - front %d", rear, front);
    
    int totalDataToPop = datalen;
    if(rear > front){
        if((rear - front) >= totalDataToPop){
            memcpy(data, bufferq+front, totalDataToPop);
            front += totalDataToPop;
        }
        else{
            return false;
        }
    }
    else{
        int availableDataSize = (kBufferSize - front) + rear;
        if(availableDataSize >= totalDataToPop){
            if((kBufferSize - front) >= totalDataToPop){
                memcpy(data, bufferq+front, totalDataToPop);
                front += totalDataToPop;
            }
            else{
                int len = kBufferSize - front;
//                NSLog(@"available: %d totalDataToPop: %d front: %d len: %d", availableDataSize, totalDataToPop, front, len);
                memcpy(data, bufferq+front, len);
                memcpy(data+len, bufferq, totalDataToPop - len);
                front = totalDataToPop - len;
//                NSLog(@"Complete pop. front: %d", front);
            }
        }
        else{
            return false;
        }
    }
    if (front == kBufferSize) {
        front = 0;
    }
//    NSLog(@"pop end rear %d - front %d", rear, front);
    return true;
}

-(int) getAvailableSize
{
    int size = 0;
    if(rear > front)
    {
        size = rear - front;
    }
    else if(rear < front)
    {
        size = (kBufferSize - front) + rear;
    }
    return size;
}


@end
