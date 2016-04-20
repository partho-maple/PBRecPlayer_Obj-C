//
//  AudioRouter.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface AudioRouter : NSObject <CBCentralManagerDelegate> {
    
}


// this class is a singleton class.
+ (AudioRouter *) getiOS_AudioRouterInstance;

+ (void) initAudioSessionRouting;
+ (void) switchToDefaultHardware;
+ (void) forceOutputToBuiltInSpeakers;

+ (void) muteAudio;
+ (void) unMuteAudio;

+ (void) startBTAudio;
+ (void) stopBTAudio;

+ (NSString*) getAudioSessionInput;
+ (NSString*) getAudioSessionOutput;
+ (NSString*) getAudioSessionRoute ;

@end
