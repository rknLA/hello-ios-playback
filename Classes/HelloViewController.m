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

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.player addObserver:self forKeyPath:@"decibelLevels" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];

    [self.player removeObserver:self forKeyPath:@"decibelLevels"];
}

#pragma mark -
#pragma mark UI event and state handling

- (IBAction) playClicked:(id) button {
    if (!playing) {
        NSArray* keys = [@"t2742133,t1992210,t7418766,t8816323" componentsSeparatedByString:@","];
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

        self.leftLevelMonitor.value = [[levels objectAtIndex:0] floatValue];
        self.rightLevelMonitor.value = [[levels objectAtIndex:1] floatValue];
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
}

@end
