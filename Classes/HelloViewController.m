#import <CoreMedia/CoreMedia.h>
#import "HelloViewController.h"
#import "HelloAppDelegate.h"
#import "RdioSearchViewController.h"

#import "ANAudioPowerMeterProcessor.h"

@implementation HelloViewController

@synthesize playButton, loginButton, nextButton, previousButton, searchButton;

- (RDPlayer *)player {
    if (!_player) {
        _player = [HelloAppDelegate rdioInstance].player;
    }
    return _player;
}

#pragma mark - Lifecycle Methods

- (void)dealloc {
    [_leftLevelMonitor release];
    [_rightLevelMonitor release];

    [_position release];
    [_duration release];

    [_positionSlider release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Zero out our position
    [self positionUpdated:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    levelObserver = [self.player addPeriodicLevelObserverForInterval:CMTimeMake(50, 100) queue:NULL usingBlock:^(NSArray *levelsArray) {
      NSNumber *left = [NSNumber numberWithDouble:((ANAudioPowerMeterProcessor *)levelsArray[0]).averagePowerDB];
      NSNumber *right = [NSNumber numberWithDouble:((ANAudioPowerMeterProcessor *)levelsArray[1]).averagePowerDB];
      NSArray *levels = @[left, right];

      [self performSelectorOnMainThread:@selector(setMonitors:) withObject:levels waitUntilDone:NO];
    }];

    timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(40, 100) queue:NULL usingBlock:^(CMTime time) {
      NSNumber *position = [NSNumber numberWithDouble:CMTimeGetSeconds(time)];
      [self performSelectorOnMainThread:@selector(positionUpdated:) withObject:position waitUntilDone:NO];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.player removeLevelObserver:levelObserver];
    [self.player removeTimeObserver:timeObserver];
}

#pragma mark -
#pragma mark UI event and state handling

- (IBAction) playClicked:(id) button {
    if (!playing) {
      if ([[self.player trackKeys] count] > 0) {
        [self.player play];
      } else {
        NSArray* keys = [@"t1928163,t1992210,t7418766,t8816323" componentsSeparatedByString:@","];
        [self.player playSources:keys];
      }
    } else {
        [self.player togglePause];
    }
}

- (IBAction) loginClicked:(id) button {
    if (loggedIn) {
        [[HelloAppDelegate rdioInstance] logout];
    } else {
        [[HelloAppDelegate rdioInstance] authorizeFromController:self];
    }
}

- (IBAction)nextClicked:(id)sender
{
  [self.player next];
}

- (IBAction)previousClicked:(id)sender
{
  [self.player previous];
}

- (IBAction)searchClicked:(id)sender
{
  RdioSearchViewController *searchView = [[RdioSearchViewController alloc] initWithNibName:@"RdioSearchView" bundle:[NSBundle mainBundle]];
  [self presentViewController:searchView animated:YES completion:nil];
}

- (IBAction)seekStarted:(id)sender {
    if (!playing) return;

    seeking = YES;
}

- (IBAction)seekFinished:(id)sender {
    if (!playing) return;

    seeking = NO;
    
    NSTimeInterval position = self.positionSlider.value * self.player.duration;
    [self.player seekToPosition:position];
}

- (void)setLoggedIn:(BOOL)logged_in {
    loggedIn = logged_in;
    if (logged_in) {
        [loginButton setTitle:@"Log Out" forState: UIControlStateNormal];
    } else {
        [loginButton setTitle:@"Log In" forState: UIControlStateNormal];
    }
}

- (void)setMonitors:(NSArray *)levels
{
    double leftLinear = pow(10, (0.05 * [levels[0] floatValue]));
    double rightLinear = pow(10, (0.05 * [levels[1] floatValue]));

    self.leftLevelMonitor.value = leftLinear;
    self.rightLevelMonitor.value = rightLinear;
}


- (void)positionUpdated:(NSNumber *)newPosition
{
  NSTimeInterval duration = self.player.duration;

  NSTimeInterval position = [newPosition doubleValue];

  // snafu for nan and other wonky cases.
  if (position < 0.1) {
    position = 0;
  }

  self.position.text = [self playerTimeForTime:position];
  self.duration.text = [self playerTimeForTime:duration];
  self.positionSlider.value = position / duration;
}

- (NSString *)playerTimeForTime:(NSTimeInterval)interval
{
    NSInteger min = (NSInteger) interval / 60;
    NSInteger sec = (NSInteger) interval % 60;

    return [NSString stringWithFormat:@"%d:%02d", min, sec];
}

#pragma mark -
#pragma mark RdioDelegate

- (void) rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken {
    [self setLoggedIn:YES];
}

- (void) rdioAuthorizationFailed:(NSString *)error {
    [self setLoggedIn:NO];
}

- (void) rdioAuthorizationCancelled {
    [self setLoggedIn:NO];
}

- (void) rdioDidLogout {
    [self setLoggedIn:NO];
}


#pragma mark -
#pragma mark RDPlayerDelegate

- (BOOL) rdioIsPlayingElsewhere {
    // let the Rdio framework tell the user.
    return NO;
}

- (void) rdioPlayerChangedFromState:(RDPlayerState)fromState toState:(RDPlayerState)state {
    playing = (state != RDPlayerStateInitializing && state != RDPlayerStateStopped);
    paused = (state == RDPlayerStatePaused);
    if (paused || !playing) {
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        [playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

@end
