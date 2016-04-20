//
//  ViewController.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/12/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#include <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AudioHandler.h"
#import "AudioRouter.h"



@interface ViewController : UIViewController <AudioControllerDelegate>

-(void) StartAudio;
-(void) StopAudio;

@end

