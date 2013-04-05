#import <UIKit/UIKit.h>
#import "Rdio/Rdio.h"

@interface HelloViewController : UIViewController<RdioDelegate,RDPlayerDelegate> {
    UIButton *playButton;
    UIButton *loginButton;
    UIButton *nextButton;
    UIButton *previousButton;
    UIButton *searchButton;
    BOOL loggedIn;
    BOOL playing;
    BOOL seeking;
    BOOL paused;
    RDPlayer *_player;

    id timeObserver;
    id levelObserver;
}

@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIButton *loginButton;
@property (nonatomic, retain) IBOutlet UIButton *nextButton;
@property (nonatomic, retain) IBOutlet UIButton *previousButton;
@property (nonatomic, retain) IBOutlet UIButton *searchButton;

@property (retain, nonatomic) IBOutlet UISlider *leftLevelMonitor;
@property (retain, nonatomic) IBOutlet UISlider *rightLevelMonitor;

@property (retain, nonatomic) IBOutlet UISlider *positionSlider;
@property (retain, nonatomic) IBOutlet UILabel *position;
@property (retain, nonatomic) IBOutlet UILabel *duration;

- (IBAction)playClicked:(id) button;
- (IBAction)loginClicked:(id) button;
- (IBAction)nextClicked:(id)sender;
- (IBAction)previousClicked:(id)sender;
- (IBAction)searchClicked:(id)sender;

- (IBAction)seekStarted:(id)sender;
- (IBAction)seekFinished:(id)sender;

@end
