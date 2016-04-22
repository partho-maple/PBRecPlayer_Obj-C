//
//  AudioHandler.m
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

#import "AudioHandler.h"
#import <AudioToolbox/AudioToolbox.h>

#define kOutputBus 0
#define kInputBus 1

G729Wrapper* g729EncoderDecoder;
static AudioHandler *sharedInstance = nil;

void checkStatus(int status){
	if (status) {
		printf("Status not 0! %d\n", status);
	}
}




@implementation AudioHandler

@synthesize audioUnit, tempBuffer, audioDelegate, pcmRcordedData, isRecordDataPullingThreadRunning, isAudioUnitRunning, isBufferClean;

short shortArray[1024];
short receivedShort[1024];
NSThread* recorderThread;



+(AudioHandler *)sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[AudioHandler alloc] init];
    }
    return sharedInstance;
}


/**
 Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested.
 */
- (id) init {
	self = [super init];
	OSStatus status;
    pcmRcordedData = [[BufferQueue alloc] init];
    g729EncoderDecoder = [[G729Wrapper alloc]init];
    
    TPCircularBufferInit(&recordedPCMBuffer, 100000);
    TPCircularBufferInit(&receivedPCMBuffer, 100000);
    
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	// Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
	checkStatus(status);
    
	
	// Enable IO for recording
	UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit,
								  kAudioOutputUnitProperty_EnableIO,
								  kAudioUnitScope_Input,
								  kInputBus,
								  &flag,
								  sizeof(flag));
	checkStatus(status);
	
	// Enable IO for playback
	status = AudioUnitSetProperty(audioUnit,
								  kAudioOutputUnitProperty_EnableIO,
								  kAudioUnitScope_Output,
								  kOutputBus,
								  &flag,
								  sizeof(flag));
	checkStatus(status);
	
	// Describe format
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= 8000;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagsCanonical | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
	
	// Apply format
	status = AudioUnitSetProperty(audioUnit,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Output,
								  kInputBus,
								  &audioFormat,
								  sizeof(audioFormat));
    checkStatus(status);
    
    
    
    /* Make sure that your application can receive remote control
     * events by adding the code:
     *     [[UIApplication sharedApplication]
     *      beginReceivingRemoteControlEvents];
     * Otherwise audio unit will fail to restart while your
     * application is in the background mode.
     */
    
    
    /* Make sure we set the correct audio category before restarting */
    UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
    status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                      sizeof(audioCategory),
                                      &audioCategory);

	checkStatus(status);
    
    
    
    
	status = AudioUnitSetProperty(audioUnit,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Input,
								  kOutputBus,
								  &audioFormat,
								  sizeof(audioFormat));
	checkStatus(status);
	
	
	// Set input callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = recordingCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	status = AudioUnitSetProperty(audioUnit,
								  kAudioOutputUnitProperty_SetInputCallback,
								  kAudioUnitScope_Global,
								  kInputBus,
								  &callbackStruct,
								  sizeof(callbackStruct));
	checkStatus(status);
	
	// Set output callback
	callbackStruct.inputProc = playbackCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	status = AudioUnitSetProperty(audioUnit,
								  kAudioUnitProperty_SetRenderCallback,
								  kAudioUnitScope_Global,
								  kOutputBus,
								  &callbackStruct,
								  sizeof(callbackStruct));
	checkStatus(status);
	
	// Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
	flag = 0;
	status = AudioUnitSetProperty(audioUnit,
								  kAudioUnitProperty_ShouldAllocateBuffer,
								  kAudioUnitScope_Output,
								  kInputBus,
								  &flag,
								  sizeof(flag));
	
	// Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
	// Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
	tempBuffer.mNumberChannels = 1;
    
    tempBuffer.mDataByteSize = 1024 * 2;
	tempBuffer.mData = malloc( 1024 * 2 );
    
    isAudioUnitRunning = false;
    isBufferClean = false;
    
	return self;
}




/**
 Start the audioUnit. This means data will be provided from
 the microphone, and requested for feeding to the speakers, by
 use of the provided callbacks.
 */
- (void) start {
    if (isAudioUnitRunning) {
        return;
    }
//    This will enable the proximity monitoring.
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
    
    [g729EncoderDecoder open];
    
	OSStatus status;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    
    
    
//    Activates the audio session
    status = AudioSessionSetActive(true);
    checkStatus(status);
    
//    Initialise the audio unit
	status = AudioUnitInitialize(audioUnit);
    checkStatus(status);

//    Starts the Audio Unit
    status = AudioOutputUnitStart(audioUnit);
	checkStatus(status);
    
    
    if(![self isRecordDataPullingThreadRunning])
    {
        recorderThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(recordDataPullingMethod)
                                                   object:NULL];
        [self setIsRecordDataPullingThreadRunning:true];
        [recorderThread start];
//        [recorderThread setThreadPriority:1.0];
    }
    
    isAudioUnitRunning = true;
}

/**
 Stop the audioUnit
 */
- (void) stop {
    
    if (!isAudioUnitRunning) {
        return;
    }
    
//    This will disable the proximity monitoring.
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    
    
    OSStatus status;
    
//    Stops the Audio Unit
	status = AudioOutputUnitStop(audioUnit);
	checkStatus(status);
    
//    Deactivates the audio session
    status = AudioSessionSetActive(false);
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    checkStatus(status);
    
//    Uninitialise the Audio Unit
	status = AudioUnitUninitialize(audioUnit);
    checkStatus(status);
    
    isRecordDataPullingThreadRunning = false;
    isAudioUnitRunning = false;
    [g729EncoderDecoder close];
}


- (void) recordDataPullingMethod
{
        int availableBytes;
        while([self isRecordDataPullingThreadRunning])
        {
            SInt16 *buffer = TPCircularBufferTail(&recordedPCMBuffer, &availableBytes);
            if (availableBytes > 159)
            {
                memcpy(shortArray, buffer, 160);
                TPCircularBufferConsume(&recordedPCMBuffer, 160);
                Byte g729EncodedBytes[10];
                int encodedLength = [g729EncoderDecoder encodeWithPCM:shortArray andSize:80 andEncodedG729:g729EncodedBytes];
                
                // Here encodedLength will be 10 if g729EncodedBytes size is 80.
                if (encodedLength > 0)
                {
                    if ([audioDelegate respondsToSelector:@selector(recordedRTP:andLenght:)])
                    {
                        [audioDelegate recordedRTP:g729EncodedBytes andLenght:encodedLength];
                    }
                }
            }
        }
    
    [recorderThread cancel];
    recorderThread = nil;
    [NSThread exit];
    
}



/**
 Change this funtion to decide what is done with incoming
 audio data from the microphone.
 Right now we copy it to our own temporary buffer.
 */
- (void) processAudio: (AudioBufferList*) bufferList{
    
    bool isRecordedBufferProduceBytes = false;
    isRecordedBufferProduceBytes = TPCircularBufferProduceBytes(&recordedPCMBuffer, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);
    
    
    if (!isRecordedBufferProduceBytes) {
        NSLog(@"---------------------- Recorded RTP push faild ----------------------");
    }
}

- (void) receiverAudio:(Byte *)audio WithLen:(int)len
{
    bool isBufferProduceBytes = false;
    memset(receivedShort, 0, 1024);
    
    @try {
        int numberOfDecodedShorts = [g729EncoderDecoder decodeWithG729:audio andSize:len andEncodedPCM:receivedShort];
        isBufferProduceBytes = TPCircularBufferProduceBytes(&receivedPCMBuffer, receivedShort, (numberOfDecodedShorts*2));
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
    if (!isBufferProduceBytes) {
        NSLog(@"---------------------- Incoming RTP push faild ----------------------");
    }
    
}













/**
 This callback is called when new audio data from the microphone is
 available.
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
	
	// Because of the way our audio format (setup below) is chosen:
	// we only need 1 buffer, since it is mono
	// Samples are 16 bits = 2 bytes.
	// 1 frame includes only 1 sample
    
	AudioBuffer buffer;
	buffer.mNumberChannels = 1;
	buffer.mDataByteSize = inNumberFrames * 2;
	buffer.mData = malloc( inNumberFrames * 2 );
	
	// Put buffer in a AudioBufferList
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
	
	
    OSStatus status;
    status = AudioUnitRender([sharedInstance audioUnit],
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
	checkStatus(status);
	
    // Now, we have the samples we just read sitting in buffers in bufferList
	// Process the new data
	[sharedInstance processAudio:&bufferList];
    
	
	// release the malloc'ed data in the buffer we created earlier
	free(bufferList.mBuffers[0].mData);
	
    return noErr;
}

/**
 This callback is called when the audioUnit needs new data to play through the
 speakers. If you don't have any, just don't write anything in the buffers
 */
static OSStatus playbackCallback(void *inRefCon,
								 AudioUnitRenderActionFlags *ioActionFlags,
								 const AudioTimeStamp *inTimeStamp,
								 UInt32 inBusNumber,
								 UInt32 inNumberFrames,
								 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    AudioHandler *THIS = sharedInstance;
	
	for (int i=0; i < ioData->mNumberBuffers; i++) { // in practice we will only ever have 1 buffer, since audio format is mono
		AudioBuffer buffer = ioData->mBuffers[i];

        
        int availabeBytes;
        UInt32 size;
        SInt16 *temp = NULL;
        
        availabeBytes = THIS->receivedPCMBuffer.fillCount;
        size = min(buffer.mDataByteSize, availabeBytes);
        if (size == 0) {
            return 1;
        }
        
        temp = TPCircularBufferTail(&THIS->receivedPCMBuffer, &availabeBytes);
        if (temp == NULL) {
            return 1;
        }
        memcpy(buffer.mData, temp, size);
        buffer.mDataByteSize = size;
        TPCircularBufferConsume(&THIS->receivedPCMBuffer, size);
	}
    return noErr;
}


- (void) resetRTPQueue
{
    TPCircularBufferClear(&receivedPCMBuffer);
    TPCircularBufferClear(&recordedPCMBuffer);
}

- (void) closeG729Codec {
    [g729EncoderDecoder close];
}


/**
 Clean up.
 */
- (void) dealloc {
	AudioUnitUninitialize(audioUnit);
	free(tempBuffer.mData);
}

@end
