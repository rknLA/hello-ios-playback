//
//  ANAudioPowerMeterProcessor.h
//  Diad
//
//  Created by Philipe Megavölt on 10/1/13.
//  Copyright (c) 2013 Diad. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface ANAudioPowerMeterProcessor : NSObject

- (OSStatus)processAudio:(AudioBufferList*)ioData numberOfFrames:(uint32_t)numberOfFrames;

- (void)reset;

@property (readonly) double averagePowerLinear;
@property (readonly) double peakPowerLinear;
@property (readonly) double averagePowerDB;
@property (readonly) double peakPowerDB;

@end
