#import "HelloViewController.h"
#import "HelloAppDelegate.h"

@interface HelloViewController() {
    UIButton *_playButton;
    UIButton *_loginButton;
    BOOL _loggedIn;
    BOOL _playing;
    BOOL _paused;
    RDPlayer* _player;
    BOOL _supposedToBePaused;
    UIBackgroundTaskIdentifier songBgTaskId;
}

@end

@implementation HelloViewController

@synthesize player;

#pragma mark - View Lifecycle
- (void)loadView
{
    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
    UIView *view = [[UIView alloc] initWithFrame:appFrame];
    [view setBackgroundColor:[UIColor whiteColor]];

    // Play Button
    _playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_playButton setTitle:@"Play" forState:UIControlStateNormal];
    CGRect playFrame = CGRectMake(20, 20, appFrame.size.width - 40, 40);
    [_playButton setFrame:playFrame];
    [_playButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [_playButton addTarget:self action:@selector(playClicked) forControlEvents:UIControlEventTouchUpInside];

    _loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_loginButton setTitle:@"Log In" forState:UIControlStateNormal];
    CGRect loginFrame = CGRectMake(20, 70, appFrame.size.width - 40, 40);
    [_loginButton setFrame:loginFrame];
    [_loginButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [_loginButton addTarget:self action:@selector(loginClicked) forControlEvents:UIControlEventTouchUpInside];

    CGRect labelFrame = CGRectMake(20, 120, appFrame.size.width - 40, 40);
    UILabel *rdioLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [rdioLabel setText:@"Powered by Rdio®"];
    [rdioLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [rdioLabel setTextAlignment:NSTextAlignmentCenter];

    CGRect instructionsFrame = CGRectMake(20, 180, appFrame.size.width - 40, 200);
    UILabel *instructionsLabel = [[UILabel alloc] initWithFrame:instructionsFrame];
    [instructionsLabel setText:@"Pressing play should play the first track, pause just before the second track, wait 5 seconds, then continue. Try this first with the app in the foreground. Works, right? Restart the app, and try again, this time sending the app to the background using the home button after pressing play. Watch the console for an AudioQueueStart error.\n\nThis test case does not require that you log in."];
    [instructionsLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    instructionsLabel.numberOfLines = 0;
    instructionsLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];

    [view addSubview:_playButton];
    [view addSubview:_loginButton];
    [view addSubview:rdioLabel];
    [view addSubview:instructionsLabel];

    [rdioLabel release];
    [instructionsLabel release];

    self.view = view;
    [view release];
}

- (void)dealloc
{
    [_playButton release];
    [_loginButton release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    Rdio *sharedRdio = [HelloAppDelegate rdioInstance];
    sharedRdio.delegate = self;
    sharedRdio.player.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Watch for track changes so that we can pause between track one and two
    [self addObserver:self forKeyPath:@"player.currentTrack" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Remove observers
    [self removeObserver:self forKeyPath:@"player.currentTrack" context:nil];

    [super viewDidDisappear:animated];
}

# pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"player.currentTrack"]) {
        int trackIndex = [[self getPlayer] currentTrackIndex];

        UIBackgroundTaskIdentifier newSongBgTaskId = UIBackgroundTaskInvalid;
        if (trackIndex < 4) {
            // Let's request a new background task for the song that just started to play
            newSongBgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        // Let's kill the background task for the song that just finished playing
        if (songBgTaskId != UIBackgroundTaskInvalid) [[UIApplication sharedApplication] endBackgroundTask:songBgTaskId];
        songBgTaskId = newSongBgTaskId;

        if (trackIndex == 1) { // We've hit track two
            NSLog(@"We've hit track two!");

            // Let's start a background task while we're about to muck around, not playing audio
            UIBackgroundTaskIdentifier bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];

            // Log how much background time we have left every second, just to prove that this bug doesn't have to do with running out of background execution time
            NSTimer *backgroundTimeLogTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(logBackroundTimeRemaining) userInfo:nil repeats:YES];

            // Let's pause
            NSLog(@"Let's pause here.");
            _supposedToBePaused = YES;
            [[self getPlayer] togglePause]; // On an unrelated note – why does this throw: AudioQueuePause err \316\377\377\377 -50

            // Wait for 5 seconds
            NSLog(@"…and wait for 5 seconds");
            NSTimeInterval delayInSeconds = 5.0;
            NSNumber *taskIDObject = [NSNumber numberWithLong:bgTaskId];
            [self performSelector:@selector(attemptToResumePlaying:) withObject:taskIDObject afterDelay:delayInSeconds];

            // Stop logging background time remaining separately,
            // unless you want to write performSelector:withObject:withObject:afterDelay:
            [backgroundTimeLogTimer performSelector:@selector(invalidate) withObject:nil afterDelay:delayInSeconds];
        }
    }
}

- (void)attemptToResumePlaying:(NSNumber *)taskToStop
{
  NSLog(@"...then keep on playing");
  _supposedToBePaused = NO;
  [[self getPlayer] togglePause];

  // End the background task; we should be playing audio again!
  [[UIApplication sharedApplication] endBackgroundTask:[taskToStop longValue]];
}


- (void)logBackroundTimeRemaining
{
    // How much background execution time do we have left?
    NSLog(@"%f seconds left to execute in the background", [[UIApplication sharedApplication] backgroundTimeRemaining]);
}

#pragma mark - Screen Rotation
- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAll;
}

#pragma mark - Rdio Helper

- (RDPlayer*)getPlayer
{
  if (_player == nil) {
    _player = [HelloAppDelegate rdioInstance].player;
  }
  return _player;
}

#pragma mark - UI event and state handling

- (void)playClicked
{
    if (!_playing) {
        NSArray* keys = [@"t2742133,t1992210,t7418766,t8816323" componentsSeparatedByString:@","];
        [[self getPlayer] playSources:keys];
    } else {
        [[self getPlayer] togglePause];
    }
}

- (void)loginClicked
{
    if (_loggedIn) {
        [[HelloAppDelegate rdioInstance] logout];
    } else {
        [[HelloAppDelegate rdioInstance] authorizeFromController:self];
    }
}

- (void)setLoggedIn:(BOOL)logged_in
{
    _loggedIn = logged_in;
    if (logged_in) {
        [_loginButton setTitle:@"Log Out" forState: UIControlStateNormal];
    } else {
        [_loginButton setTitle:@"Log In" forState: UIControlStateNormal];
    }
}


#pragma mark - RdioDelegate

- (void)rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken
{
    [self setLoggedIn:YES];
}

- (void)rdioAuthorizationFailed:(NSString *)error
{
    [self setLoggedIn:NO];
}

- (void)rdioAuthorizationCancelled
{
    [self setLoggedIn:NO];
}

- (void)rdioDidLogout
{
    [self setLoggedIn:NO];
}


#pragma mark - RDPlayerDelegate

- (BOOL)rdioIsPlayingElsewhere
{
    // let the Rdio framework tell the user.
    return NO;
}

- (void)rdioPlayerChangedFromState:(RDPlayerState)fromState toState:(RDPlayerState)state
{
    _playing = (state != RDPlayerStateInitializing && state != RDPlayerStateStopped);
    _paused = (state == RDPlayerStatePaused);
    if (_paused || !_playing) {
        [_playButton setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        [_playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
    // We asked the player to pause, but it's not listening.
    // Possibly related to https://github.com/rdio/api/issues/64
    // Pause!
    if (_supposedToBePaused && !_paused) [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!_supposedToBePaused) return;

        NSLog(@"Forcing a pause, since the player didn't listen the first time, throwing \"AudioQueuePause err \\316\\377\\377\\377 -50\" instead");
        [[self getPlayer] togglePause];
    }];
}

- (BOOL)rdioPlayerCouldNotStreamTrack:(NSString *)trackKey
{
    NSLog(@"Trying to recussitate playback…");
    [[self getPlayer] playAndRestart:YES];
    
    return YES;
}

@end