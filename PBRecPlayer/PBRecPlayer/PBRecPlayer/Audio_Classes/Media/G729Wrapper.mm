//
//  G729Wrapper.m
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import "G729Wrapper.h"

@implementation G729Wrapper

bool m_bCodecOpened;

G729CodecNative* g729;

-(id) init
{
    self = [super init];
    g729 = new G729CodecNative();
    m_bCodecOpened = false;
    return self;
}

-(Boolean) open
{
    if (!m_bCodecOpened) {
        m_bCodecOpened = g729->Open();
    }
    return m_bCodecOpened;
}

-(Boolean) close
{
    if (m_bCodecOpened) {
        g729->Close();
        m_bCodecOpened = false;
    }
    return true;
}

-(int) encodeWithPCM: (short*) shortArray andSize: (int) size andEncodedG729: (Byte*) byteArray
{
    if (m_bCodecOpened) {
        return g729->Encode(shortArray, size, byteArray);
    }
    else
        return 0;
}

-(int) decodeWithG729: (Byte*) byteArray andSize: (int) size andEncodedPCM: (short*) shortArray
{
    if (m_bCodecOpened) {
        return g729->Decode(byteArray, size, shortArray);
    }
    else
        return 0;
}

-(void) dealloc
{
//    delete g729;
//    g729 = NULL;
}

@end
