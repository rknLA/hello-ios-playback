#import "HelloViewController.h"
#import "HelloAppDelegate.h"

@interface HelloViewController() {
    NSArray *readyToPlay;
    NSString *trackOne, *trackTwo, *trackThree;
}
@end

@implementation HelloViewController

@synthesize playButton, loginButton, player;

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    trackOne = @"t2742133";
    trackTwo = @"t1992210";
    trackThree = @"t7418766";
    
    // No songs are ready to play. I expect the player to pause before playing the first one.
    readyToPlay = [[NSArray alloc] init];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[self getPlayer] addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [[self getPlayer] addObserver:self forKeyPath:@"currentTrackIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [[self getPlayer] addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id oldValue = change[NSKeyValueChangeOldKey];
    id newValue = change[NSKeyValueChangeNewKey];
    
    NSLog(@"%@ changed from %@ to %@", keyPath, oldValue, newValue);
}

-(RDPlayer*)getPlayer
{
    if (player == nil) {
        player = [HelloAppDelegate rdioInstance].player;
    }
    return player;
}

#pragma mark -
#pragma mark UI event and state handling

- (IBAction) playClicked:(id) button {
    if (!playing) {
        [[self getPlayer] playSources:@[trackOne, trackTwo, trackThree]];
    } else {
        [[self getPlayer] togglePause];
    }
}

- (IBAction) loginClicked:(id) button {
    if (loggedIn) {
        [[HelloAppDelegate rdioInstance] logout];
    } else {
        [[HelloAppDelegate rdioInstance] authorizeFromController:self];
    }
}

- (void) setLoggedIn:(BOOL)logged_in {
    loggedIn = logged_in;
    if (logged_in) {
        [loginButton setTitle:@"Log Out" forState: UIControlStateNormal];
    } else {
        [loginButton setTitle:@"Log In" forState: UIControlStateNormal];
    }
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
    
    NSLog(@"Tracks we are ready to play include %@", readyToPlay);
    
    NSString *currentTrack = [[self getPlayer] currentTrack];
    NSLog(@"currentTrack is %@", currentTrack);
    
    if (![currentTrack isEqual:[NSNull null]] && ![readyToPlay containsObject:currentTrack]) {
        if (playing && !paused) {
            NSLog(@"We're not ready to play track %@, so I'm pausing the player.", currentTrack);
            [[self getPlayer] togglePause];
        } else {
            NSLog(@"We're not ready to play track %@, but the player is already paused, so it's all good.", currentTrack);
        }
    } else {
        NSLog(@"We're ready to play track %@, so I won't pause the player.", currentTrack);
    }
}

- (void)rdioPlayerQueueDidChange
{
    
}

@end
