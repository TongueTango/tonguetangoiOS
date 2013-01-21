//
//  HomeView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreData/CoreData.h>
#import <Twitter/Twitter.h>
#import "FacebookHelper.h"
#import "TwitterHelper.h"
#import "SquareAndMask.h"
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "ProgressHUD.h"
#import "NotificationHUD.h"
#import "EGORefreshTableHeaderView.h"

@class FriendsListView;
@class SocialFriendsList;

@interface HomeView : UIViewController <UIScrollViewDelegate,UIAlertViewDelegate, UIPageViewControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, AVAudioSessionDelegate, UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate,UIGestureRecognizerDelegate, EGORefreshTableHeaderDelegate>
{
    BOOL isPlaying;
    BOOL disableMenu;
    BOOL isAlerted;
    NSInteger pages, toID, groupID, selectedIndex, currentThemeID, currentMicID;
    NSUserDefaults *defaults;
    UIImage *defaultImage;
    UIImage *defaultGroup;
    NSTimer *callTimer;
    NSTimer *refreshTimer;
    NSDate *callStartDate;
    
	NSMutableDictionary *editedObject;
    NSMutableDictionary *dictDownloadImages;
    NSString *newFileName;
	NSString *recorderFilePath;
    AVAudioPlayer *audioPlayer;
    AVAudioSession *audioSession;
    
    float angle;
    
    NSString *socialToID;
    NSString *socialToName;
    NSString *socialPublicURL;
    BOOL isSearchResults;
    BOOL resetFromKeyboardAction;
    BOOL socialButton;
    BOOL postVideoToFriend;
    BOOL isLoading;
    int blockOrDeleteFriendId;
    
    NSNumber *nrUserId;
    EGORefreshTableHeaderView *_refreshHeaderView;
}

@property (nonatomic) NSInteger sendTo;
@property (nonatomic) BOOL disableMenu;
@property (strong, nonatomic) NSString *sendType;
@property (strong, nonatomic) NSDictionary *sendPerson;
@property (strong, nonatomic) id inviteView;

@property (strong, nonatomic) FacebookHelper *fbHelper;
@property (strong, nonatomic) TwitterHelper *twHelper;
@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong, nonatomic) ServerConnection *serverConnection;
@property (strong, nonatomic) FriendsListView *friendsListView;
@property (strong, nonatomic) SocialFriendsList *socialFriendsList;
@property (strong, nonatomic) ProgressHUD *theHUD;

@property (strong, nonatomic) NSMutableArray *arrIcons;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong, nonatomic) UIImageView *viewAction, *pickedGlow, *imageBG, *socialViewAction;

@property (strong, nonatomic) IBOutlet UIImageView *imageMicrophone;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollIcons;
@property (strong, nonatomic) IBOutlet UIView *viewMicBG;
@property (strong, nonatomic) IBOutlet UIButton *bttnCloseAction;

#pragma mark - Text Msg View
@property (strong, nonatomic) IBOutlet UIButton *bttnTxtCancel;
@property (strong, nonatomic) IBOutlet UIButton *bttnTxtSend;
@property (strong, nonatomic) IBOutlet UILabel *labelNewMsg;
@property (strong, nonatomic) IBOutlet UITextView *textMessage;
@property (strong, nonatomic) IBOutlet UIView *viewTextMsg;

#pragma mark - Record View
@property (strong, nonatomic) IBOutlet UIButton *bttnDelete;
@property (strong, nonatomic) IBOutlet UIButton *bttnPreview;
@property (strong, nonatomic) IBOutlet UIButton *bttnRecord;
@property (strong, nonatomic) IBOutlet UIButton *bttnSend;
@property (strong, nonatomic) IBOutlet UIImageView *imageRecTab;
@property (strong, nonatomic) IBOutlet UIView *viewRecord;
@property (strong, nonatomic) IBOutlet UIButton *bttnRefresh;

#pragma mark - To View
@property (strong, nonatomic) IBOutlet UIImageView *imageTo;
@property (strong, nonatomic) IBOutlet UIImageView *placeholderTo;
@property (strong, nonatomic) IBOutlet UILabel *labelTo;
@property (strong, nonatomic) IBOutlet UIView *viewTo;

#pragma mark - New design outlets
@property (strong, nonatomic) IBOutlet UIView *searchView;
@property (strong, nonatomic) IBOutlet UITableView *homeTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *dragScrollView;
@property (strong, nonatomic) IBOutlet UIView *dragView;
@property (strong, nonatomic) IBOutlet UIView *addFriendView;
@property (strong, nonatomic) IBOutlet UILabel *labelAddFriend;
@property (strong, nonatomic) IBOutlet UILabel *labelGroup;
@property (strong, nonatomic) IBOutlet UILabel *labelFacebook;
@property (strong, nonatomic) IBOutlet UILabel *labelTwitter;
@property (strong, nonatomic) IBOutlet UILabel *labelGroupGutter;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) UILabel *labelNotification;
@property (nonatomic, assign) BOOL *isCloseButtonOnTop;

@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblLoading;
@property (unsafe_unretained, nonatomic) IBOutlet UIImageView *imgViewTutorial;
@property (nonatomic, strong) TWTweetComposeViewController *tweetSheet;

@property (strong, nonatomic) NotificationHUD *notificationHUD;


#pragma mark - Tuturial view
@property (strong, nonatomic) IBOutlet UIView *tutorialView;


@property (nonatomic) BOOL isRegister;
@property (nonatomic) BOOL shouldOpenSync;

@property (nonatomic) BOOL useDataSourceIndexing;

@property (strong, nonatomic) IBOutlet UIImageView *menuImageView;

- (void)handleCancelButton:(id)sender;
- (IBAction)openFriendsListView;
- (void)createMenuButton;
- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image userInfo:(NSString *)userInfo;

- (void)createActionView;
- (IBAction)removeActionBox;
- (IBAction)showActionBox:(id)sender;
- (IBAction)displaySocFriendList:(id)sender;
- (void)socFriendSelected:(NSString *)socialID withName:(NSString *)socialName;
- (void)removeSocFriendList;

- (void)changePhotoName;
- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people;
- (void)queryFriends;

- (NSInteger)getObjectIndex:(NSArray *)array byID:(NSInteger)theID withKey:(NSString *)theKey;
- (void)selectFriend:(NSInteger)index;
- (void)resetHomeView;
- (IBAction)showMicrophone:(id)sender;
- (void)showMicrophoneAnimated:(BOOL)animated;
- (IBAction)hideMicrophone:(id)sender;
- (IBAction)showKeyboard:(id)sender;
- (void)showKeyboardAnimated:(BOOL)animated;
- (IBAction)hideKeyboard:(id)sender;
- (IBAction)startRecording;
- (IBAction)stopRecording;
- (IBAction)playRecording;
- (void)stopPlaying;
- (IBAction)deletePreview:(id)sender;
- (IBAction)sendAudio:(id)sender;
- (void)refreshTapped;
- (void)rotateRefresh;
- (void)hadleTimer:(NSTimer *)timer;

- (void)getUnreadCount;

- (void)pushNotificationReceived:(NSDictionary *)userInfo;
-(void)pushNotificationReceivedExternal:(NSDictionary *)userInfo;

- (void)openPendingFriends;
- (void)openMessageThreadDetail;
- (void)openGroups;
- (void)downloadImages:(NSArray *)arrGroups;

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@end

@protocol InviteEmail <NSObject>
@optional
- (void)sendEmailWithURL:(NSString *)_audioURL;
- (void)didSendAudioToFacebook;
@end

