#import "HelloViewController.h"
#import "HelloAppDelegate.h"

@implementation HelloViewController

@synthesize playButton, loginButton;

- (RDPlayer *)player {
    if (!_player) {
        _player = [HelloAppDelegate rdioInstance].player;
    }
    return _player;
}

#pragma mark - Lifecycle Methods

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"decibelLevels"];

    [_leftLevelMonitor release];
    [_rightLevelMonitor release];

    [_position release];
    [_duration release];

    [_positionSlider release];

    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.player addObserver:self forKeyPath:@"decibelLevels" options:NSKeyValueObservingOptionNew context:nil];
    [self.player addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionInitial context:nil];
    [self.player addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.player removeObserver:self forKeyPath:@"decibelLevels"];
}

#pragma mark -
#pragma mark UI event and state handling

- (IBAction) playClicked:(id) button {
    if (!playing) {
        NSArray* keys = [@"t1928163,t1992210,t7418766,t8816323" componentsSeparatedByString:@","];
        [self.player playSources:keys];
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

- (void) setLoggedIn:(BOOL)logged_in {
    loggedIn = logged_in;
    if (logged_in) {
        [loginButton setTitle:@"Log Out" forState: UIControlStateNormal];
    } else {
        [loginButton setTitle:@"Log In" forState: UIControlStateNormal];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"decibelLevels" isEqualToString:keyPath]) {
        NSArray *levels = [change objectForKey:NSKeyValueChangeNewKey];
        [self performSelectorOnMainThread:@selector(setMonitors:) withObject:levels waitUntilDone:NO];
    }
    else if ([@"position" isEqualToString:keyPath] || [@"duration" isEqualToString:keyPath]) {
        if (seeking) return;

        NSTimeInterval position = self.player.position;
        NSTimeInterval duration = self.player.duration;

        self.position.text = [self playerTimeForTime:position];
        self.duration.text = [self playerTimeForTime:duration];
        self.positionSlider.value = position / duration;
    }
}

- (void)setMonitors:(NSArray *)levels
{
    double leftLinear = pow(10, (0.05 * [levels[0] floatValue]));
    double rightLinear = pow(10, (0.05 * [levels[1] floatValue]));

    self.leftLevelMonitor.value = leftLinear;
    self.rightLevelMonitor.value = rightLinear;
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
