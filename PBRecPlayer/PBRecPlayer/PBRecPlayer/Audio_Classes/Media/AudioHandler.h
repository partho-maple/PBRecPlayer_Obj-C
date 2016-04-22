//
//  AudioHandler.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

@protocol AudioControllerDelegate;

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "BufferQueue.h"
#import "G729Wrapper.h"
#import "TPCircularBuffer.h"
#import "AudioRouter.h"

#import <AVFoundation/AVFoundation.h>


#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

@class AudioHandler;

@protocol AudioControllerDelegate <NSObject>

@optional
- (void) recordedRTP:(Byte *)rtpData andLenght:(int)len;

@end



@interface AudioHandler : NSObject {
	AudioComponentInstance audioUnit;
	AudioBuffer tempBuffer; // this will hold the latest data from the microphone
    TPCircularBuffer recordedPCMBuffer;
    TPCircularBuffer receivedPCMBuffer;
    
    id <AudioControllerDelegate> audioDelegate;
}

@property (readonly) AudioComponentInstance audioUnit;
@property (readonly) AudioBuffer tempBuffer;
@property (readwrite) BufferQueue* pcmRcordedData;

@property (nonatomic, retain) id<AudioControllerDelegate> audioDelegate;

@property(nonatomic, readwrite) bool isRecordDataPullingThreadRunning, isAudioUnitRunning;
@property(nonatomic, readwrite) bool isLocalRingBackToneEnabled;
@property(nonatomic, readwrite) bool isLocalRingToneEnabled;
@property(nonatomic, readwrite) bool isBufferClean;

+ (AudioHandler *) sharedInstance;
- (void) start;
- (void) stop;
- (void) processAudio: (AudioBufferList*) bufferList;
- (void) receiverAudio:(Byte *) audio WithLen:(int)len;

- (void) recordDataPullingMethod;
- (void) resetRTPQueue;
- (void) closeG729Codec;

@end





