#import <UIKit/UIKit.h>
#import "Rdio/Rdio.h"

@interface HelloViewController : UIViewController<RdioDelegate,RDPlayerDelegate> {
    UIButton *playButton;
    UIButton *loginButton;
    BOOL loggedIn;
    BOOL playing;
    BOOL seeking;
    BOOL paused;
    RDPlayer *_player;
}

@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIButton *loginButton;

@property (retain, nonatomic) IBOutlet UISlider *leftLevelMonitor;
@property (retain, nonatomic) IBOutlet UISlider *rightLevelMonitor;

@property (retain, nonatomic) IBOutlet UISlider *positionSlider;
@property (retain, nonatomic) IBOutlet UILabel *position;
@property (retain, nonatomic) IBOutlet UILabel *duration;

- (IBAction)playClicked:(id) button;
- (IBAction)loginClicked:(id) button;

- (IBAction)seekStarted:(id)sender;
- (IBAction)seekFinished:(id)sender;

@end
