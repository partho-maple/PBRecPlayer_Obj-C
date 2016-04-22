//
//  ViewController.m
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/12/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, readwrite) int iRTPDataLen;
@property(nonatomic, readwrite) BOOL isRunning;

@property (weak, nonatomic) IBOutlet UIButton *startStopButton;


- (IBAction)StartButtonTapped:(id)sender;

@end




@implementation ViewController

unsigned char byteRTPDataToSend[500];


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isRunning = NO;
    self.iRTPDataLen = 0;
    [[AudioHandler sharedInstance] setAudioDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Class member methodes

-(void) StartAudio
{
    [[AudioHandler sharedInstance] start];
    [[AudioHandler sharedInstance] resetRTPQueue];
    
}
-(void) StopAudio
{
    [[AudioHandler sharedInstance] stop];
    [[AudioHandler sharedInstance] resetRTPQueue];
}


// Basically, it will a callback method which will be called after getting each trp packet.
-(void) receivedRtpWithData:(unsigned char*)pChRtp andLength:(int)len
{
    Byte receivedRTPData [1024];
    int receivedRTPDataLength = 0;
    
    memcpy(receivedRTPData, pChRtp, len);
    receivedRTPDataLength = len;
    [[AudioHandler sharedInstance] receiverAudio:receivedRTPData WithLen:receivedRTPDataLength];
}



#pragma mark - AudioControllerDelegate delegate methodes

// This method will be called after pulling each recorded data block
-(void) recordedRTP:(Byte *)rtpData andLenght:(int)len
{
    NSLog(@"rtplen %d", len);
    /* Here we will send rtpData(recorded and encoded data to send) to the other end. We have encoder, recorded data into rtpData variable and it's length is into len variable */
    memcpy(byteRTPDataToSend+self.iRTPDataLen, rtpData, len);
    self.iRTPDataLen += len;
    
    
    [self receivedRtpWithData:byteRTPDataToSend andLength:self.iRTPDataLen];
    
    memset(byteRTPDataToSend, 0, 500);
    self.iRTPDataLen = 0;
}

#pragma mark - Button action methodes

- (IBAction)StartButtonTapped:(id)sender {
    if (self.isRunning) {
        self.isRunning = NO;
        [self StopAudio];
        [self.startStopButton setTitle:@"START" forState:UIControlStateNormal];
    } else {
        self.isRunning = YES;
        [self StartAudio];
        [self.startStopButton setTitle:@"STOP" forState:UIControlStateNormal];
    }
}

@end
