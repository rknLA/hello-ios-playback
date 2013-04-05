/**
 *  @file RDPlayer.h
 *  Rdio Playback Interface
 *  Copyright 2011 Rdio Inc. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>

////////////////////////////////////////////////////////////////////////////////

/**
 * Playback status
 */
typedef enum {
  RDPlayerStateInitializing, /**< Player is not ready yet */
  RDPlayerStatePaused, /**< Playback is paused */
  RDPlayerStatePlaying, /**< Currently playing (or buffering) */
  RDPlayerStateStopped /**< Playback is stopped */
} RDPlayerState;

////////////////////////////////////////////////////////////////////////////////

/**
 * Player delegate
 */
@protocol RDPlayerDelegate <NSObject>

/**
 * Notification that the current user has started playing with Rdio from 
 * another location, and playback here must stop.
 * @return <code>YES</code> if you handle letting the user know, or <code>NO</code> to have the SDK display a dialog.
 */
-(BOOL)rdioIsPlayingElsewhere;

/**
 * Notification that the player has changed states. See <code>RDPlayerState</code>.
 */
-(void)rdioPlayerChangedFromState:(RDPlayerState)oldState toState:(RDPlayerState)newState;

@optional

/**
 * Notification that the play queue has been updated.
 *
 * For example, when new tracks are added using the queueSource and queueSources
 * methods.
 */
-(void)rdioPlayerQueueDidChange;

/**
 * Notification that the specified track did not successfully finish streaming.
 *
 * If this method is not implemented, we will automatically skip to the next track.
 *
 * @return <code>YES</code> if you want to override this behavior.
 */
- (BOOL)rdioPlayerCouldNotStreamTrack:(NSString *)trackKey;

@end

////////////////////////////////////////////////////////////////////////////////

@class AudioStreamer;
@class RDUserEventLog;
@class RDSession;

/**
 * Responsible for playback. Handles playing and enqueueing track sources, 
 * advancing to the next track, logging plays with the server, etc.
 *
 * To observe track changes, position changes, etc., use KVO. For example:
 * \code
 *  [player addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionNew context:nil];
 * \endcode
 */
@interface RDPlayer : NSObject {
@private
  RDPlayerState state_;
  double position_;
  
  RDSession *session_;
  
  int currentTrackIndex_;
  NSString *currentTrack_;
  AudioStreamer *audioStream_;
  
  NSString *nextTrack_;
  AudioStreamer *nextAudioStream_;
  
  RDUserEventLog *log_;
  
  BOOL sentPlayEvent_;
  BOOL sentTimedPlayEvent_;
  BOOL sendSkipEvent_;
  BOOL sentSkipEvent_;
  
  BOOL checkingPlayingElsewhere_;
  
  NSTimer *pauseTimer_;
  NSString *playerName_;
  
  NSArray *trackKeys_;
  
  id<RDPlayerDelegate> delegate_;
}

/**
 * Starts playing a source key, such as "t1232".
 *
 * Supported source keys include tracks, albums, playlists, and artist stations.
 *
 * Track keys can be found by calling web service API methods.
 * Objects such as Album contain a 'trackKeys' property.
 *
 * @param sourceKey a source key such as "t1232"
 */
-(void)playSource:(NSString *)sourceKey;

/**
 * Play through a list of track keys, pre-buffering and automatically advancing
 * between songs.
 *
 * Supported source keys include tracks, albums, playlists, and artist stations.
 *
 * @param sourceKeys list of source keys
 */
-(void)playSources:(NSArray *)sourceKeys;

/**
 * Play the next track in the \ref RDPlayer::trackKeys "trackKeys" array.
 */
-(void)next;

/**
 * Play the previous track in the \ref RDPlayer::trackKeys "trackKeys" array.
 */
-(void)previous;

/**
 * Play the track at a specific index in the \ref RDPlayer::trackKeys "trackKeys" array.
 *
 * @param index the index of the desired track
 * @return NO if the index is out of range
 */
-(BOOL)skipToIndex:(NSUInteger)index;

/**
 * Continues playing the current track
 *
 * This is the same as calling RDPlayer::playAndRestart:YES
 */
- (void)play;

/**
 * Continues playing the current track with an option to restart the track if
 * it's already playing
 *
 * If the player is already playing, setting shouldRestart to YES will restart
 * the track from the begining.
 *
 * @param shouldRestart if the player should restart the currently playing track
 */
- (void)playAndRestart:(BOOL)shouldRestart;

/**
 * Toggles paused state.
 */
- (void)togglePause;

/**
 * Stops playback and releases resources.
 */
- (void)stop;

/**
 * Seeks to the given position.
 * @param positionInSeconds position to seek to, in seconds
 */
- (void)seekToPosition:(double)positionInSeconds;

/**
 * Add a source key to the end of the existing play queue
 *
 * Supported source keys include tracks, albums, playlists, and artist stations.
 *
 * @param sourceKey A source key, such as "t1232"
 */
- (void)queueSource:(NSString*)sourceKey;

/**
 * Add the list of source keys to the end of the existing play queue
 *
 * Supported source keys include tracks, albums, playlists, and artist stations.
 *
 * @param sourceKeys List of source keys, such as "t1232"
 */
- (void)queueSources:(NSArray*)sourceKeys;

/**
 * Replace the play queue with a different list of track keys.
 *
 * This method replaces the entire play queue much like RDPlayer::playSources:.
 * Unlike RDPlayer::playSources:, this method does not stop playback of the
 * current track.
 *
 * If the index does not point at the currently playing track, the method will
 * not update the queue and will return NO.
 *
 * @param sourceKeys List of track keys, such as "t1232"
 * @param index Index of the currently playing track
 * @return NO if the queue was not updated
 */
- (BOOL)updateQueue:(NSArray*)sourceKeys withCurrentTrackIndex:(int)index;

/**
 * Stops playback, releases resources and resets the queue.
 */
- (void)resetQueue;

/**
 * Analagous to AVPlayer's method of the same name.
 * See https://developer.apple.com/library/mac/#documentation/AVFoundation/Reference/AVPlayer_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40009530-CH1-SW7 for details.
 *
 * @param interval The interval of invocation of the block during normal playback, according to progress of the current time of the player.
 * @param queue A serial queue onto which block should be enqueued.
 * @param block
 * The block to be invoked periodically.
 * The block takes a single parameter:
 *   time
 *     The time at which the block is invoked.
 */
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime time) )block;

/**
 * Analagous to AVPlayer's method of the same name.
 *
 * Remove a time observer added by addPeriodicTimeObserverForInterval.
 *
 * @param observer The opaque object returned by addPeriodicTimeObserverForInterval.
 */
- (void)removeTimeObserver:(id)observer;

/**
 * Similar to -addPeriodicTimeObserverForInterval:, this method calls back the passed in block with updated audio power levels.
 *
 * @param interval The interval of invocation of the block during normal playback, according to progress of the current time of the player.
 * @param queue A serial queue onto which block should be enqueued.
 * @param block
 * The block to be invoked periodically.
 * The block takes a single parameter:
 *   levelsArray
 *     An two item array of power levels.  The left channel's levels are in the first object, and the right channel's are in the second.
 */
- (id)addPeriodicLevelObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(NSArray *levelsArray))block;

/**
 * Remove a level observer added by addPeriodicLevelObserverForInterval.
 *
 * @param observer The opaque object returned by addPeriodicLevelObserverForInterval.
 */
- (void)removeLevelObserver:(id)observer;

/**
 * Current playback state.
 */
@property (nonatomic, readonly) RDPlayerState state;

/**
 * Current position in seconds.
 */
@property (nonatomic, readonly) double position;

/**
 * Duration of the current track, in seconds.
 */
@property (nonatomic, readonly) double duration;

/**
 * The key of the current track.
 */
@property (nonatomic, readonly) NSString *currentTrack;

/**
 * Index in the \ref RDPlayer::trackKeys "trackKeys" array that is currently playing.
 */
@property (nonatomic, readonly) int currentTrackIndex;

/**
 * List of track keys that represents the play queue
 */
@property (nonatomic, readonly) NSArray *trackKeys;

/**
 * Delegate used to receive player state changes.
 */
@property (nonatomic, assign) id<RDPlayerDelegate> delegate;

/**
 * Decibel metering information (iOS 6 only).
 * This will *not* fire on the main thread.
 *
 * This property contains an array of two float values that contain the current sound output level in decibels.
 * The values are range from -120.0dB (no sound) to 0.0dB (clipping).
 * The first item is the level for the left channel, and the second item is the level for the right channel.
 *
 * Note that these values are in dB units, which means they're inherently logarithmic in scale.
 * If you're using this information to drive a `UISlider` or similar linear object, you'll probably want
 * to convert these values to a linear scale.
 *
 * For example, this line will convert the left channel's power output from the decibel scale
 * to a value between 0.0 and 1.0:
 * `double linear = pow(10, (0.05 * [decibelLevels[0] floatValue]));`
 */
@property (nonatomic, retain, readonly) NSArray *decibelLevels;

@end

