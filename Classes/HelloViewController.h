#import <UIKit/UIKit.h>
#import "Rdio/Rdio.h"

@interface HelloViewController : UIViewController<RdioDelegate,RDPlayerDelegate> {
    UIButton *playButton;
    UIButton *loginButton;
    BOOL loggedIn;
    BOOL playing;
    BOOL paused;
    RDPlayer *_player;
}

@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIButton *loginButton;

@property (retain, nonatomic) IBOutlet UISlider *leftLevelMonitor;
@property (retain, nonatomic) IBOutlet UISlider *rightLevelMonitor;

- (IBAction) playClicked:(id) button;
- (IBAction) loginClicked:(id) button;

@end
