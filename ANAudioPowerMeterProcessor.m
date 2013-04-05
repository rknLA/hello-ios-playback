//
//  ANAudioPowerMeterProcessor.m
//  Avernus
//
//  Created by kevin on 9/23/11.
//  Copyright (c) 2011 Hz Systems. All rights reserved.
//

#import "ANAudioPowerMeterProcessor.h"

#pragma mark - Constants

const double kMinLinearPower = 1e-6;
const double kMinDecibelsPower = -120.0;
const double kMaxDecibelsPower = 20.0;

const double kPeakDecay = 0.006;
const double kDecay = 0.016;

const double kPeakResetTime = 0.90702947845805;		// in seconds

#define kUnknownSampleRate 0.0
#define kUnknownBlockSize (-1)

#pragma mark - Private Methods

void zapgremlins(double x)
{
	// zap gremlins - eliminate denormals, not-a-numbers, and infinities.
	// denormals will fail the first test (absx > 1e-15), infinities will fail the second test (absx < 1e15), and
	// NaNs will fail both tests. Zero will also fail both tests, but since it will get set to zero that is OK.
	
	double absx = fabs(x);
	x = (absx > 1e-15 && absx < 1e15) ? x : 0.;
}

const double kLog001 = -6.907755278982137; // natural log of 0.001 (0.001 is -60 dB)
double CalcDecayConstant(double in60dBDecayTimeInSeconds, double inSampleRate)
{
	return exp(kLog001 / (in60dBDecayTimeInSeconds * inSampleRate));
}

double AmpToDb(double inDb)
{
	return 20. * log10(inDb);
}

double LinearToDB(double p)
{
	return (p <= kMinLinearPower) ? kMinDecibelsPower : AmpToDb(p);
}

#pragma mark - Obj-C Body

@interface ANAudioPowerMeterProcessor() {
  AudioUnitMeterClipping mClipping;
  
  double mSampleRate;
  
  double mPeakDecay;
  double mPeakDecay1;

  double mDecay;
  double mDecay1;
  
  double mPeak;
  double mMaxPeak;
  
  double mAveragePower;
  double mAveragePowerPeak;
  
  int mPeakHoldCount;
  
  NSInteger mPrevBlockSize;
}

-(void)clearClipping;

@end

@implementation ANAudioPowerMeterProcessor

- (id)init
{
	self = [super init];
	if (self)
	{
		mSampleRate = kUnknownSampleRate;
		mPeakDecay = kPeakDecay;
		mDecay = kDecay;
		mPrevBlockSize = kUnknownBlockSize;
		[self reset];
	}
	return self;
}

-(void)clearClipping
{
	mClipping.sawInfinity = false;
	mClipping.sawNotANumber = false;
	mClipping.peakValueSinceLastCall = 0.0;
}

-(void)setSampleRate:(double)inSampleRate
{
	mSampleRate = inSampleRate;
	
	// 3.33 was determined by reverse engineering kPeakDecay:  
	// x = 1 - pow(1 - kPeakDecay, 1/128);  ..this backs out the per sample value from the per block value.
	// 3.33 = log(0.001)/(44100. * log(1. - x))  ..this calculates the 60dB time constant
	// 3.33 seems too slow. use 2.5
	mPeakDecay1 = CalcDecayConstant(2.5, inSampleRate);
	
	// 1.24 was determined by reverse engineering kDecay: 
	// x = 1 - pow(1 - kDecay, 1/128);  ..this backs out the per sample value from the per block value.
	// 1.24 = log(0.001)/(44100. * log(1. - x));  ..this calculates the 60dB time constant
	mDecay1 = CalcDecayConstant(1.24, inSampleRate);
}

-(double)averagePowerLinear { return mAveragePowerPeak; }
-(double)peakPowerLinear { return mMaxPeak; }
-(double)averagePowerDB { return LinearToDB([self averagePowerLinear]); }
-(double)peakPowerDB { return LinearToDB([self peakPowerLinear]); }

#pragma mark -

- (OSStatus)processAudio:(AudioBufferList*)ioData
		  numberOfFrames:(uint32_t)numberOfFrames
{
	uint32_t stride = 1;
	uint32_t inFramesToProcess = numberOfFrames;
    uint32_t i;
    for (i = 0; i < ioData->mNumberBuffers; i++)
    {
		// scale decay constants based on nframes
		if (inFramesToProcess != mPrevBlockSize)
		{
			if (mSampleRate == kUnknownSampleRate)
				[self setSampleRate:44100.];
			mPeakDecay = 1. - pow(mPeakDecay1, inFramesToProcess);
			mDecay = 1. - pow(mDecay1, inFramesToProcess);
			mPrevBlockSize = inFramesToProcess;
		}
        
		// update peak and average power
		int nframes = inFramesToProcess;
		
		const Float32 *src = (const Float32 *)ioData->mBuffers[i].mData;
		double averagePower = mAveragePower;
		float maxSample = 0;
        
		// TODO: vectorize!
		
		while (--nframes >= 0)
		{
			float sample = *src;
			src += stride;
			if (sample < 0) sample = -sample;
			
			if (sample > maxSample) maxSample = sample;
			averagePower += (sample * sample - averagePower) * .03;
		}
		
		if (maxSample > mClipping.peakValueSinceLastCall)
			mClipping.peakValueSinceLastCall = maxSample;
        
		int fptype = fpclassify(averagePower);
		if (fptype != FP_NORMAL)
		{
			switch (fptype)
			{
				case FP_NAN : 
					mClipping.sawNotANumber = true; 
					// encountered bad values. 
					maxSample = 1.0;
					averagePower = 0.0;
					break;
				case FP_INFINITE : 
					mClipping.sawInfinity = true; 
					// encountered bad values. 
					maxSample = 1.0;
					averagePower = 0.0;
					break;
			}
		}
		
		
		
		
		double fAveragePower = averagePower;
		float peakValue = maxSample;
		
		mAveragePower = averagePower;
		
		// scale power value correctly
		double powerValue = sqrt(fAveragePower) * M_SQRT2;			// formula is to divide by 1/sqrt(2)
		
		if (mPeak > peakValue)
			// exponential decay
			mPeak += (peakValue - mPeak) * mDecay;
		else
			// hit peaks instantly
			mPeak = peakValue;
		
		mPeakHoldCount += inFramesToProcess;
        
		
		int peakResetFrames = (int)(kPeakResetTime * mSampleRate);
		
		if (mPeakHoldCount >= peakResetFrames)
			// reset current peak
			mMaxPeak -=  mMaxPeak * mPeakDecay;
		if (mMaxPeak < mPeak) {
			mMaxPeak = mPeak;
			mPeakHoldCount = 0;
		}
		
		if(mAveragePowerPeak > powerValue)
			// exponential decay
			mAveragePowerPeak += (powerValue - mAveragePowerPeak) * mDecay;
		else
			// hit power peaks instantly
			mAveragePowerPeak = powerValue;
		
		if (mAveragePowerPeak > mMaxPeak)
			mAveragePowerPeak = mMaxPeak;	// ?
		
		zapgremlins(mAveragePower);
		zapgremlins(mAveragePowerPeak);
		zapgremlins(mPeak);
		zapgremlins(mMaxPeak);
    }
	return noErr;
}

- (void)reset
{
	mPeak = 0;
	mMaxPeak = 0;
	mAveragePower = 0;
	mAveragePowerPeak = 0;
	
//!	memset(&m_vAvePower, 0, sizeof(m_vAvePower));
	[self clearClipping];
	
	mPrevBlockSize = kUnknownBlockSize;
	mPeakHoldCount = 0;	
}

@end
