//
//  HomeView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "HomeView.h"
#import "AppDelegate.h"
#import "FriendsListView.h"
#import "SocialFriendsList.h"
#import "Constants.h"
#import <QuartzCore/QuartzCore.h>
#import "ProfileView.h"
#import "SyncFriendsView.h"
#import "WelcomeLandingView.h"
#import "NotificationsView.h"
#import "MessageThreadDetailView.h"
#import "TwitterPostViewController.h"

static NSDateFormatter *sUserVisibleDateFormatter;

static int kFriendViewTag = 5;
static int kFriendPicTag = 4;
static int kFriendGlowTag = 3;
static int kFriendNameLabelTag = 2;
static int kFriendButtonTag = 6;
static int kFBButtonTag = 8;
static int kTwitterButtonTag = 9;
static int kFriendDeleteTag = 123;

@implementation HomeView
{
	AVAudioRecorder *recorder_ ;
	BOOL isAudioSetUp_;
    NSInteger _selectedIndex;
    NSInteger _iNumberOfTimesWeCheckedForGroupsAndFriends;
}

@synthesize sendTo, sendType, sendPerson;
@synthesize fbHelper, twHelper, coreDataClass;
@synthesize friendsListView;
@synthesize socialFriendsList;
@synthesize disableMenu;
@synthesize theHUD;
@synthesize arrIcons;
@synthesize arrCellData;
@synthesize viewAction, pickedGlow, socialViewAction;
@synthesize imageBG;
@synthesize dictDownloadImages;
@synthesize inviteView;
@synthesize bttnRefresh;

@synthesize imageMicrophone;
@synthesize scrollIcons;
@synthesize viewMicBG;
@synthesize bttnCloseAction;

@synthesize bttnTxtCancel;
@synthesize bttnTxtSend;
@synthesize labelNewMsg;
@synthesize textMessage;
@synthesize viewTextMsg;

@synthesize bttnDelete;
@synthesize bttnPreview;
@synthesize bttnRecord;
@synthesize bttnSend;
@synthesize imageRecTab;
@synthesize viewRecord;

@synthesize imageTo;
@synthesize placeholderTo;
@synthesize labelTo;
@synthesize viewTo;

@synthesize searchView;
@synthesize homeTableView;
@synthesize dragScrollView;
@synthesize dragView;
@synthesize addFriendView;
@synthesize labelAddFriend;
@synthesize labelGroup;
@synthesize labelFacebook;
@synthesize labelTwitter;
@synthesize labelGroupGutter;
@synthesize labelNotification;
@synthesize searchBar;

@synthesize tutorialView;

@synthesize serverConnection;

@synthesize isRegister;
@synthesize shouldOpenSync;

@synthesize notificationHUD;

@synthesize menuImageView;

@synthesize useDataSourceIndexing;

@synthesize isCloseButtonOnTop;
@synthesize imgViewTutorial = _imgViewTutorial;
@synthesize tweetSheet = _tweetSheet;

BOOL _showDeleteTag;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Audio Setup

- (void)setupAudioForRecordingIfNeeded
{
	NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
	[recordSetting setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
	[recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
	[recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    newFileName = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    
    //>--------------------------------------------------------------------------------------------------------
    //>     Ben 09/18/2012: Based on Ticket #4
    //>
    //>     Store all song file in Library, instead of Documents folder. Anything that can be
    //>     redownloaded from server, must be saved in Library.
    //>
    //>     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //>--------------------------------------------------------------------------------------------------------
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kAudioDirectory];
    
    recorderFilePath = [documentsPath stringByAppendingPathComponent:newFileName];
    
	NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
    
	recorder_ = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:nil];
	audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    UInt32 allowBluetoothInput = 1;
    AudioSessionSetProperty(
                            kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                            sizeof (allowBluetoothInput),
                            &allowBluetoothInput);
    
	[audioSession setActive:YES error:nil];
	//prepare to record
	[recorder_ setDelegate:self];
	recorder_.meteringEnabled = YES;
	[recorder_ prepareToRecord];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    DLog(@"USER TOKEN: %@",[defaults objectForKey:@"UserToken"]);
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Home View"];
    
    if (_refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.homeTableView.bounds.size.height, self.view.frame.size.width, self.homeTableView.bounds.size.height)];
		view.delegate = self;
		[self.homeTableView addSubview:view];
		_refreshHeaderView = view;
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    
    _showDeleteTag = NO;
    _iNumberOfTimesWeCheckedForGroupsAndFriends = 0;
    
    homeTableView.delegate = self;
    // Set to YES if user needs to register
    isRegister = YES;
 
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTableView)
                                                 name:@"reloadMenu"
                                               object:nil];
 
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanMemory)
                                                 name:@"cleanMemory"
                                               object:nil];
  
    defaults = [NSUserDefaults standardUserDefaults];
    
    // TODO JMR review if need to uncomment this
    if ([defaults objectForKey:@"UserToken"]) {
        [self requestUserInfo];
    }
        

    arrIcons = [[NSMutableArray alloc] init];
    selectedIndex = -3;
    
#if TARGET_IPHONE_SIMULATOR
    // Do nothing
#else
    
#endif
    
    // Set the backbround image for this view
    currentThemeID = [defaults integerForKey:@"ThemeID"];
    currentMicID = [defaults integerForKey:@"MicID"];
    
    //imageBG = [[UIImageView alloc] initWithFrame:CGRectMake(0, -64, 320, 480)];
    CGRect deviceSize   = [[UIScreen mainScreen] bounds];
    imageBG = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, deviceSize.size.width, deviceSize.size.height)];
    
    if ([defaults integerForKey:@"ThemeID"] == 0)
    {
        imageBG.image = [UIImage imageNamed:k_UIImage_BackgroundImageName];
    }
    else
    {
        imageBG.image = [UIImage imageWithContentsOfFile:[defaults objectForKey:@"ThemeBG"]];
    }
    [self.view insertSubview:imageBG atIndex:0];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:@"TONGUE TANGO"];
    
    
    [self createProfileButton];
    
    // Set the action (popup menu) view
    [self createActionView];
    [self createSocialActionView];
    
    imageRecTab.image = [[UIImage imageNamed:@"tab_mic_bttn"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    imageRecTab.alpha = .8;
    
    if ([defaults integerForKey:@"MicID"] == 0) {
        // Set the microphone image
        imageMicrophone.image = [UIImage imageNamed:@"mic_default"];
    } else {
        imageMicrophone.image = [UIImage imageWithContentsOfFile:[defaults objectForKey:@"MicPath"]];
    }
    
    // Prepare to mask images
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    defaultGroup = [UIImage imageNamed:@"userpic_placeholder_group"];
    self.dictDownloadImages = [NSMutableDictionary dictionary];
    
    // Initiate the Facebook class
    fbHelper = [FacebookHelper sharedInstance];
    twHelper = [TwitterHelper sharedInstance];
    
    [bttnRecord setBackgroundImage:[UIImage imageNamed:@"bttn_record"] forState:UIControlStateNormal];
    [bttnRecord setBackgroundImage:[UIImage imageNamed:@"bttn_record_pressed"] forState:UIControlStateHighlighted];
    [self.bttnTxtCancel setTitle:NSLocalizedString(@"CANCEL", nil) forState:UIControlStateNormal];
    [self.bttnTxtSend setTitle:NSLocalizedString(@"SEND", nil) forState:UIControlStateNormal];
    labelNewMsg.text = NSLocalizedString(@"NEW MESSAGE", nil);
    
    isPlaying = NO;
    serverConnection = [ServerConnection sharedInstance];
    
    self.homeTableView.separatorColor = [UIColor clearColor];
    // Customize label group gutter
    [self.labelGroupGutter setText:NSLocalizedString(@"DRAG_PEOPLE_MESSAGE", nil)];
    [self.labelGroupGutter setFont:[UIFont fontWithName:@"BellGothic BT" size:14]];
    
    // Customize add friend label
    [self.labelAddFriend setText:NSLocalizedString(@"ADD FRIEND", nil)];
    [self.labelAddFriend setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    
    // Customize group label
    [self.labelGroup setText:NSLocalizedString(@"GROUP_LABEL", nil)];
    [self.labelGroup setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    
    // Customize FB label
    [self.labelFacebook setText:NSLocalizedString(@"FACEBOOK", nil)];
    [self.labelFacebook setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    
    // Customize Twitter label
    [self.labelTwitter setText:NSLocalizedString(@"TWITTER", nil)];
    [self.labelTwitter setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    
    //Customize search bar
    self.searchBar.placeholder = NSLocalizedString(@"SEARCH BAR PLACEHOLDER", nil);
    for (UIView *view in searchBar.subviews)
    {
        if ([view isKindOfClass:[UITextField class]])
        {
            [(UITextField*)view setFont:[UIFont fontWithName:@"Helvetica" size:14]];
        }
    }
    
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"UPLOADING", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
   
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    DLog(@"");
    
    if (!coreDataClass)
    {
        coreDataClass = [CoreDataClass sharedInstance];
    }
    
    if ([[defaults objectForKey:@"PushedUser"] intValue] == 0 && 
        [[defaults objectForKey:@"PushedGroup"] intValue] == 0)
    {
        if (![defaults objectForKey:@"UserToken"])
        {
            // show welcome view
            WelcomeLandingView *welcomeLanding = [[WelcomeLandingView alloc] initWithNibName:@"WelcomeLandingView" bundle:nil];
            UINavigationController *welcomeNav = [[UINavigationController alloc] initWithRootViewController:welcomeLanding];
            DLog(@"showing welcome landing");
            [self.navigationController presentModalViewController:welcomeNav animated:NO];
        }
        else
        {
            AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            if (!appDelegate.homeViewController.shouldOpenSync)
            {
                BOOL tutorialAlreadyDisplayed = [[NSUserDefaults standardUserDefaults] boolForKey:@"kTutorialAlreadyDisplayed"];
                if (!tutorialAlreadyDisplayed)
                {
                    if ([Utils isiPhone5])
                    {
                        [self.imgViewTutorial setImage:[UIImage imageNamed:@"tutorial_overlay_iPhone5.png"]];
                        
                        CGRect deviceFrame      = [[UIScreen mainScreen] bounds];
                        [self.tutorialView setFrame:CGRectMake(0, 0, deviceFrame.size.width, deviceFrame.size.height)];
                    }
                    
                    [UIView beginAnimations:nil context:NULL];
                    [UIView setAnimationDelegate:self];
                    [UIView setAnimationDuration:0.5];
                    
                    [[[UIApplication sharedApplication] keyWindow] addSubview:self.tutorialView];
                    
                    [UIView commitAnimations];
                    
                    [self.view setUserInteractionEnabled:NO];
                    [self.navigationController.navigationBar setUserInteractionEnabled:NO];
                    
                }
                
                //>---------------------------------------------------------------------------------------------------
                //>     Ben 10/02/2012
                //>
                //>     I added this here, because we don't need to check for unread count, until the view will
                //>     really appears. Previously, it was a redundant call.
                //>---------------------------------------------------------------------------------------------------
                [self getUnreadCount];
            }
            
            // TODO JMR review if works later 
            fbHelper.delegate = self;
            twHelper.delegate = self;
        }
    }
    
    isAlerted = NO;

    
	[self setupAudioForRecordingIfNeeded];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"queueFriends" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queueFriends) name:@"queueFriends" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadGroups" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryFriends) name:@"reloadGroups" object:nil];
    
    if ([defaults integerForKey:@"ThemeID"] != currentThemeID)
    {
        // Set the backbround image for this view
        currentThemeID = [defaults integerForKey:@"ThemeID"];
        if ([defaults integerForKey:@"ThemeID"] == 0)
        {
            NSString *imageFile = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], k_UIImage_BackgroundImageNamePNG];
            
            //>---------------------------------------------------------------------------------------------------
            //>     Set correct background image if iPhone 5
            //>---------------------------------------------------------------------------------------------------
            if ([Utils isiPhone5])
            {
                imageFile = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], k_UIImage_BackgroundImageNamePNG_iPhone5];
            }
            
            imageBG.image = [UIImage imageWithContentsOfFile:imageFile];
        }
        else
        {
            imageBG.image = [UIImage imageWithContentsOfFile:[defaults objectForKey:@"ThemeBG"]];
        }
    }
    
    if ([defaults integerForKey:@"MicID"] != currentMicID)
    {
        // Set the microphone for this view
        currentMicID = [defaults integerForKey:@"MicID"];
        if ([defaults integerForKey:@"MicID"] == 0)
        {
            imageMicrophone.image = [UIImage imageNamed:@"mic_default"];
        }
        else
        {
            imageMicrophone.image = [UIImage imageWithContentsOfFile:[defaults objectForKey:@"MicPath"]];
        }
    }

    if ([defaults integerForKey:@"ThemeID"] == 0)
    {
        self.menuImageView.backgroundColor = [UIColor darkGrayColor];
        self.searchBar.tintColor = [UIColor blackColor];
        self.navigationController.navigationBar.tintColor = DEFAULT_THEME_COLOR;
    }
    else
    {
        UIColor *themeColor;
        themeColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                     green:([defaults integerForKey:@"ThemeGreen"]/255.0) 
                                      blue:([defaults integerForKey:@"ThemeBlue"]/255.0) 
                                     alpha:1];
        
        self.menuImageView.backgroundColor = themeColor;
        self.searchBar.tintColor = themeColor;
        self.navigationController.navigationBar.tintColor = themeColor;
    }
    
    [self queryFriends];
    
    //>---------------------------------------------------------------------------------------------------
    //>     We don't need to reload Friends and Groups when coming from Messages screen, if user wants
    //>     to send a text message, or audio message. So skip queueFriend for these cases
    //>---------------------------------------------------------------------------------------------------
    BOOL shouldReloadFriendsAndGroups   = YES;
    
    if ([sendType isEqualToString:@"ToFriend"])
    {
        sendType = nil;
        NSInteger index = [self getObjectIndex:arrCellData byID:self.sendTo withKey:@"user_id"];
        [self selectFriend:index];
        
        //>     Don't reload groups and friends in this case
        shouldReloadFriendsAndGroups    = NO;
    }
    else
        if ([sendType isEqualToString:@"AudioInvite"])
        {
            toID = self.sendTo;
            [self showMicrophoneAnimated:NO];
            
            //>     Don't reload groups and friends in this case
            shouldReloadFriendsAndGroups    = NO;
        }
        else
            if ([sendType isEqualToString:@"AudioDirect"])
            {
                NSInteger index = [self getObjectIndex:arrCellData byID:self.sendTo withKey:@"user_id"];
                [self selectFriend:index];
                [self showMicrophoneAnimated:NO];
                
                //>     Don't reload groups and friends in this case
                shouldReloadFriendsAndGroups    = NO;
            }
            else
                if ([sendType isEqualToString:@"TextDirect"])
                {
                    NSInteger index = [self getObjectIndex:arrCellData byID:self.sendTo withKey:@"user_id"];
                    [self selectFriend:index];
                    [self showKeyboardAnimated:NO];
                    
                    //>     Don't reload groups and friends in this case
                    shouldReloadFriendsAndGroups    = NO;
                }
                else
                    if ([sendType isEqualToString:@"AudioDirect-Group"])
                    {
                        NSInteger index = [self getObjectIndex:arrCellData byID:self.sendTo withKey:@"group_id"];
                        [self selectFriend:index];
                        [self showMicrophoneAnimated:NO];
                        
                        //>     Don't reload groups and friends in this case
                        shouldReloadFriendsAndGroups    = NO;
                        
                        //>     Don't reload groups and friends in this case
                        shouldReloadFriendsAndGroups    = NO;
                    }
                    else
                        if ([sendType isEqualToString:@"TextDirect-Group"])
                        {
                            NSInteger index = [self getObjectIndex:arrCellData byID:self.sendTo withKey:@"group_id"];
                            [self selectFriend:index];
                            [self showKeyboardAnimated:NO];
                            
                            //>     Don't reload groups and friends in this case
                            shouldReloadFriendsAndGroups    = NO;
                        }
    
    //>---------------------------------------------------------------------------------------------------
    //>     Ben 09/29/2012
    //>
    //>     We don't need to call this method, if there is not server token yet. It means, user is not
    //>     yet registered/logged-in on server
    //>---------------------------------------------------------------------------------------------------
    NSString *strUserToken  = [defaults objectForKey:@"UserToken"];
    if (strUserToken)
    {
        //>---------------------------------------------------------------------------------------------------
        //>     Ben 10/03/2012
        //>
        //>     We have a redundant call for groups and friends, right in the beginning of the app, when
        //>     it's very important to display everything to user asap. So for second call, skip it. For sure
        //>     this is not the best method to do it, but it's working for now.
        //>---------------------------------------------------------------------------------------------------
        if (_iNumberOfTimesWeCheckedForGroupsAndFriends != 1)
        {
            //>     In some cases, skip this call
            if (shouldReloadFriendsAndGroups)
            {
                [self queueFriends];
            }
        }
    }
    
    if (self.disableMenu)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        [self createNotificationsButton];
    }
    
    /* Added By Aftab Baig */
    _showDeleteTag = NO;
    [self.homeTableView reloadData];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadGroups" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
}



-(void)viewDidAppear:(BOOL)animated
{
    /* Added By Aftab Baig */
    if (self.shouldOpenSync)
    {
        FirstSyncView *firstSyncView = [[FirstSyncView alloc] initWithNibName:@"FirstSyncView" bundle:nil];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:firstSyncView];
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeID"] == 0)
        {
            navController.navigationBar.tintColor = DEFAULT_THEME_COLOR;
        }
        else
        {
            navController.navigationBar.tintColor = [UIColor colorWithRed:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeRed"]/255.0) green:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeGreen"]/255.0) blue:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeBlue"]/255.0) alpha:1];
        }
        
        [self.navigationController presentModalViewController:navController animated:YES];
        self.shouldOpenSync = NO;
        return;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [self resetHomeView];
}

- (void)viewDidUnload
{
    arrIcons = nil;
    audioPlayer = nil;
    audioSession = nil;
    
    [self setBttnDelete:nil];
    [self setBttnPreview:nil];
    [self setBttnRecord:nil];
    [self setBttnRefresh:nil];
    [self setBttnSend:nil];
    [self setImageBG:nil];
    [self setImageMicrophone:nil];
    [self setImageRecTab:nil];
    [self setImageTo:nil];
    [self setLabelTo:nil];
    [self setPlaceholderTo:nil];
    [self setScrollIcons:nil];
    [self setTextMessage:nil];
    [self setViewRecord:nil];
    [self setViewTo:nil];
    [self setViewMicBG:nil];
    [self setViewTextMsg:nil];
    [self setTheHUD:nil];
    [self setBttnCloseAction:nil];
    [self setLabelNewMsg:nil];
    [self setBttnTxtCancel:nil];
    [self setBttnTxtSend:nil];
    [self setLoadingActivityIndicator:nil];
    [self setLblLoading:nil];
    [self setImgViewTutorial:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - Open Views

- (IBAction)openFriendsListView {
    
    isAlerted = NO;
    //AddFriendsView *friendsView = [[AddFriendsView alloc] initWithNibName:@"AddFriendsView" bundle:nil];
    //[self.navigationController pushViewController:friendsView animated:YES];
    
    /* Added by Aftab Baig */
    SyncFriendsView *syncFriendsView = [[SyncFriendsView alloc] initWithNibName:@"SyncFriendsView" bundle:nil];
    [self.navigationController pushViewController:syncFriendsView animated:YES];
    
    
}

- (IBAction)openGroupFriendsListView {    
    FriendsListView *groupsList = [[FriendsListView alloc] initWithNibName:@"FriendsListView" bundle:nil];
    [groupsList setGroupFriend:@"Groups"];
    [self.navigationController pushViewController:groupsList animated:YES];
}

#pragma mark - Navigation bar buttons

- (void)createMenuButton
{
    UIImage *image = [UIImage imageNamed:@"icon_menu"];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(toggleMove)];
    self.navigationItem.leftBarButtonItem = button;
}

- (void)createProfileButton
{
    // TODO: shows the menu for the moment
    UIImage *image = [UIImage imageNamed:@"icon_friend"];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(toggleProfile)];
    self.navigationItem.leftBarButtonItem = button;
}

- (void)createNotificationsButton
{
    if (self.disableMenu)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 30)];
        
        UIImage *image = [UIImage imageNamed:@"notifications.png"];
        self.labelNotification = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 31, 27)];
        [labelNotification setTextAlignment:UITextAlignmentCenter];
        [labelNotification setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
        [labelNotification setBackgroundColor:[UIColor clearColor]];
        [labelNotification setTextColor:[UIColor whiteColor]];
        labelNotification.lineBreakMode = UILineBreakModeMiddleTruncation;
        
        NSInteger badgeValue = [defaults integerForKey:@"UnreadMessages"] +  [defaults integerForKey:@"pendingInvitations"];
        if (badgeValue > 0)
        {
            labelNotification.text = [NSString stringWithFormat:@"%d", badgeValue];
        }
        else
        {
            labelNotification.text = @"";
        }
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 2, 33, 28)];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(notificationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [view addSubview:button];
        [view addSubview:labelNotification];
        
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:view];
        self.navigationItem.rightBarButtonItem = barButton;
    }
}

- (void)createCancelButton
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(handleCancelButton:)];
    self.navigationItem.leftBarButtonItem = button;
}

- (void)refreshTapped
{
    [self rotateRefresh];
    [self queueFriends];
}

- (void)rotateRefresh
{
    [refreshTimer invalidate];
    refreshTimer = nil;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:44];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 target: self selector:@selector(hadleTimer:) userInfo: nil repeats: YES];
    
    [UIView commitAnimations];
}

- (void)hadleTimer:(NSTimer *)timer
{
	angle += 0.1;
	if (angle > 6.283) { 
		angle = 0;
	}
	
	CGAffineTransform transform=CGAffineTransformMakeRotation(angle);
	bttnRefresh.transform = transform;
}

- (void)handleCancelButton:(id)sender
{
    if (sendType)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        imageMicrophone.hidden = YES;
        [self hideMicrophone:nil];
        [self hideKeyboard:nil];
    }
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    switch (section)
    {
        case 0:
            rows =  ceil((double)([arrCellData count]) / 4);
            rows++;
            break;
        default:
            break;
    }    
    return rows;
}

- (void)cleanCell:(UITableViewCell *)cell
{
    for (UIView *friendView in cell.contentView.subviews)
    {
        if (friendView.tag == kFriendViewTag)
        {
            for (id view in friendView.subviews)
            {
                if ([view isKindOfClass:[UIButton class]])
                {
                    UIButton *button = (UIButton*)view;
                    if (button.frame.size.height != 36.0f)
                    {
                        button.tag = kFriendButtonTag;
                    }
                }
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    // FRIEND ROWS
    if (indexPath.section == 0)
    {
        NSString *identifier;
        int friendIndex = 0;
        
        identifier = @"FriendRowCell";
        friendIndex += (indexPath.row * 4);
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell)
        {
            cell = [self reuseTableViewCellWithIdentifier:identifier];
        }
        else
        {
            [self cleanCell:cell];
        }
        
        for (UIView *friendView in cell.contentView.subviews)
        {
            if (friendView.tag == kFriendViewTag)
            {
                if (friendIndex < [arrCellData count])
                {
                    NSDictionary *dict = [arrCellData objectAtIndex:friendIndex];
                    
                    [friendView setHidden:NO];
                    UIImageView *friendPic = (UIImageView*)[friendView viewWithTag:kFriendPicTag];
                    UIImageView *friendGlow = (UIImageView*)[friendView viewWithTag:kFriendGlowTag];
                    UILabel *friendName = (UILabel*)[friendView viewWithTag:kFriendNameLabelTag];
                    UIButton *bttnFriend = (UIButton*)[friendView viewWithTag:kFriendButtonTag];
                    UIButton *btnClose = (UIButton*)[friendView viewWithTag:kFriendDeleteTag];
                    
                    // Customize cells
                    UIImage *profileImage;
                    if ([[dict objectForKey:@"user_id"] intValue] == 0)
                    {
                        profileImage = [self downloadCellImage:dict objectID:[dict objectForKey:@"group_id"] imageType:kGroupImage];
                    }
                    else
                    {
                        profileImage = [self downloadCellImage:dict objectID:[dict objectForKey:@"id"] imageType:kUserImage];
                    }
                    friendPic.image = profileImage;
                    
                    if ([[dict objectForKey:@"group_id"] intValue] == 0 && toID == [[dict objectForKey:@"user_id"] intValue])
                    {
                        friendGlow.alpha = 1;
                        pickedGlow = friendGlow;
                    }
                    else
                    {
                        friendGlow.alpha = 0;
                    }
                    
                    if ([[dict objectForKey:@"user_id"] intValue] == 0)
                    {
                        const char *utfChar = [[dict objectForKey:@"first_name"] UTF8String];
                        friendName.text = [NSString stringWithUTF8String:utfChar];
                    }
                    else
                    {
                        
                        NSString *lastName = [dict objectForKey:@"last_name"];
                        if([lastName length] > 0)
                        {
                            lastName = [lastName substringToIndex:1];
                            lastName = [NSString stringWithFormat:@"%@...",lastName];
                        }
                        friendName.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],lastName];
                    }
                    
                    btnClose.hidden = !_showDeleteTag;
                    bttnFriend.tag = friendIndex + 10;
                    
                    UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] init];
                    [gr addTarget:self action:@selector(friendLongPressed:)];
                    gr.minimumPressDuration = 1;
                    gr.numberOfTouchesRequired = 1;
                    [bttnFriend addGestureRecognizer:gr];
                    
                    friendIndex++;
                }
                else
                {
                    [friendView setHidden:YES];
                    friendIndex++;
                }
            }
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 40;
    if (indexPath.section == 0)
    {
        height = 90;
    }
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0 && !isSearchResults)
    {
        return self.dragView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    if (section == 0 && !isSearchResults)
    {
        height = 87;
    }
    return height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _showDeleteTag = NO;
    //[self removeActionBox];
    [self.homeTableView reloadData];
}

- (UITableViewCell *)reuseTableViewCellWithIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    cell.frame = CGRectMake(0, 0, 320, 88);
    
    if ([identifier isEqualToString:@"FirstFriendRowCell"])
    {
        addFriendView.center = CGPointMake(43, 53);
        [cell.contentView addSubview:self.addFriendView];
        for (int i = 1; i < 4; i++)
        {
            UIView *friendView = [self friendViewAtPosition:i];
            [cell.contentView addSubview:friendView];
        }
    }
    else if ([identifier isEqualToString:@"FriendRowCell"])
    {
        for (int i = 0; i < 4; i++) {
            UIView *friendView = [self friendViewAtPosition:i];
            [cell.contentView addSubview:friendView];
        }
    }
    
    return cell;
}

#pragma mark - Scroll view

-(void)checkIsLoading
{
	if(isLoading)
    {
		return;
	}
    else
    {
		//how far down did we pull?
		double down = homeTableView.contentOffset.y;
        DLog(@"Down : %f",down);
		//if(down <= -65)
        if(down <= -0)
        {
			
            isLoading = YES;
            [self refreshTapped];
		}
	}
}

#pragma mark - Friend icon layout

- (UIView*)friendViewAtPosition:(NSInteger)position
{
    NSInteger xaxis_start = 43;
    NSInteger yaxis_start = 53;
    NSInteger xaxis;
    NSInteger yaxis;
    xaxis = xaxis_start + (position * 78);
    yaxis = yaxis_start;
    UIImage *frameImage = [UIImage imageNamed:@"userpic_friend"];
    
    UIView *friendView = nil;
    UIImageView *friendGlow;
    UIImageView *friendPlaceholder;
    UIImageView *friendPic;
    UILabel *friendName;
    UIButton *bttnFriend;
    UIButton *btnClose;
    
    friendView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 78, 88)];
    friendView.center = CGPointMake(xaxis, yaxis);
    friendView.backgroundColor = [UIColor clearColor];
    friendView.tag = kFriendViewTag;
    
    friendPic = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, 52, 52)];
    friendPic.center = CGPointMake(39, 35);
    friendPic.tag = kFriendPicTag;
    
    friendPlaceholder = [[UIImageView alloc] initWithImage:frameImage];
    friendPlaceholder.frame = CGRectMake(0, 0, 60, 60);
    friendPlaceholder.center = CGPointMake(39, 35);
    //friendPlaceholder.tag = [[dict objectForKey:@"user_id"] intValue]+4;
    
    UIImage *glowImage = [UIImage imageNamed:@"userpic_friend_glow"];
    friendGlow = [[UIImageView alloc] initWithImage:glowImage];
    friendGlow.frame = CGRectMake(0, 0, 60, 60);
    friendGlow.center = CGPointMake(39, 35);
    friendGlow.alpha = 1;
    friendGlow.tag = kFriendGlowTag;
    
    friendName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 78, 16)];
    friendName.center = CGPointMake(39, 75);
    friendName.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    friendName.minimumFontSize = 10;
    friendName.textAlignment = UITextAlignmentCenter;
    friendName.textColor = [UIColor whiteColor];
    friendName.backgroundColor = [UIColor clearColor];
    friendName.text = @"Placeholder";
    friendName.tag = kFriendNameLabelTag;
    
    bttnFriend = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 78, 88)];
    [bttnFriend addTarget:self action:@selector(showActionBox:) forControlEvents:UIControlEventTouchUpInside];
    bttnFriend.tag = kFriendButtonTag;
    bttnFriend.showsTouchWhenHighlighted = YES;
    
    btnClose = [[UIButton alloc] initWithFrame:CGRectMake((bttnFriend.frame.origin.x+bttnFriend.frame.size.width + 10) - 40, bttnFriend.frame.origin.y,36,36)];
    btnClose.tag = kFriendDeleteTag;
    [btnClose setImage:[UIImage imageNamed:@"bttn_close_preview.png"] forState:UIControlStateNormal];
    [btnClose addTarget:self action:@selector(blockandDeleteFriend:) forControlEvents:UIControlEventTouchUpInside];
    [btnClose setHidden:YES];
    
    [friendView addSubview:friendPic];
    [friendView addSubview:friendPlaceholder];
    [friendView addSubview:friendGlow];
    [friendView addSubview:friendName];
    [friendView addSubview:bttnFriend];
    //[friendView addSubview:btnClose];
    [bttnFriend addSubview:btnClose];
    
    return friendView;
}

- (void)proximityChanged:(NSNotification *)notification
{
	UIDevice *device = [notification object];
    if (device.proximityState == 1)
    {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
    else
    {
        if ([defaults boolForKey:@"Speaker"])
        {
            [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        }
        else
        {
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        }
    }
}

#pragma mark - Image methods

- (void)downloadImages:(NSArray *)arrGroups
{
    if (arrGroups.count > 0)
    {
        for (NSInteger i = 0; i < arrGroups.count; i++)
        {
            //NSDictionary *dictInfo      = [arrGroups objectAtIndex:i];
            
            //UIImage *profileImage       = [self downloadCellImage:dictInfo objectID:[dictInfo objectForKey:@"group_id"] imageType:kGroupImage];
            //DLog(@"------------ Downloading image for %@ ---------------", [dictInfo objectForKey:@"first_name"]);
        }
    }
    
}

- (UIImage *)downloadCellImage:(NSDictionary *)dict objectID:(NSNumber *)theID imageType:(NSInteger)imageType
{
    //DLog(@"Dict : %@", dict);
    UIImage *imageDefault;
    NSString *imageID;
    if (imageType == kUserImage)
    {
        imageID = [NSString stringWithFormat:@"u%@", theID];
        imageDefault = defaultImage;
    }
    else
    {
        imageID = [NSString stringWithFormat:@"GroupImage%@", theID];
        imageDefault = defaultGroup;
    }
    
    if (![[dict objectForKey:@"photo"] isKindOfClass:[NSString class]] &&  imageType == kUserImage)
    {
        return imageDefault;
    }
    else if ([[dict objectForKey:@"photo"] isEqualToString:@""] && imageType == kUserImage)
        {
            return imageDefault;
        }
    
    UIImage *local = [SquareAndMask imageFromDevice:[dict objectForKey:@"photo"]];
    if (local)
    {
        return local;
    }
    else {
        
        local = [SquareAndMask imageFromDevice:imageID];
        if (local)
        {
            return local;
        }
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:imageID];
    if (objImage == nil)
    {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = [NSNumber numberWithInt:imageType];
        objImage.personId = theID;
        objImage.delegate = self;
        objImage.saveLocally = YES;
        [dictDownloadImages setObject:objImage forKey:imageID];
        [objImage imageFromURL:[dict objectForKey:@"photo"]];
    }
    
    return imageDefault;
}

- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image userInfo:(id)userInfo
{
    DLog(@"------------------ Image did finish downloading ------------------------");
    NSString *imageID = nil;
    NSInteger index;
    if ([userInfo intValue] == 0)
    {
        index = [self getObjectIndex:arrCellData byID:[personId intValue] withKey:@"group_id"];
        imageID = [NSString stringWithFormat:@"g%@", personId];
    }
    else
    {
        index = [self getObjectIndex:arrCellData byID:[personId intValue] withKey:@"id"];
        imageID = [NSString stringWithFormat:@"u%@", personId];
    }
    [dictDownloadImages removeObjectForKey:imageID];
    
    int row = index/4;
    UITableViewCell *cell = [homeTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    UIButton *button = (UIButton *)[cell.contentView viewWithTag:10+index];
    UIView *parentView = button.superview;
    UIImageView *friendImage = (UIImageView *)[parentView viewWithTag:kFriendPicTag];
    friendImage.image = image;
}

#pragma mark - Action Bubble
- (void)createActionView
{
    // initiate action bubble
    viewAction = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 196, 78)];
    viewAction.userInteractionEnabled = YES;
    viewAction.alpha = 0;
    
    // text button
    UIButton *bttnText = [UIButton buttonWithType:UIButtonTypeCustom];
    bttnText.frame = CGRectMake(10, 20, 56, 47);
    [bttnText setBackgroundImage:[UIImage imageNamed:@"bttn_msg_send_text.png"] forState:UIControlStateNormal];
    [bttnText addTarget:self action:@selector(showKeyboard:) forControlEvents:UIControlEventTouchUpInside];
    [viewAction addSubview:bttnText];
    
    // audio button
    UIButton *bttnAudio = [UIButton buttonWithType:UIButtonTypeCustom];
    bttnAudio.frame = CGRectMake(70, 20, 56, 47);
    [bttnAudio setBackgroundImage:[UIImage imageNamed:@"bttn_msg_send_audio.png"] forState:UIControlStateNormal];
    [bttnAudio addTarget:self action:@selector(showMicrophone:) forControlEvents:UIControlEventTouchUpInside];
    [viewAction addSubview:bttnAudio];
    
    // message thread button
    UIButton *bttnMessageThread = [UIButton buttonWithType:UIButtonTypeCustom];
    bttnMessageThread.frame = CGRectMake(130, 20, 56, 47);
    [bttnMessageThread setBackgroundImage:[UIImage imageNamed:@"ic-thread.png"] forState:UIControlStateNormal];
    [bttnMessageThread addTarget:self action:@selector(showMessageThread:) forControlEvents:UIControlEventTouchUpInside];
    [viewAction addSubview:bttnMessageThread];
    
    [self.view addSubview:viewAction];
}

- (void)createSocialActionView
{
    // initiate action bubble
    socialViewAction = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 136, 78)];
    socialViewAction.userInteractionEnabled = YES;
    socialViewAction.alpha = 0;
    
    // text button
    UIButton *bttnText = [UIButton buttonWithType:UIButtonTypeCustom];
    bttnText.frame = CGRectMake(10, 20, 56, 47);
    [bttnText setBackgroundImage:[UIImage imageNamed:@"bttn_msg_send_text.png"] forState:UIControlStateNormal];
    [bttnText addTarget:self action:@selector(showKeyboard:) forControlEvents:UIControlEventTouchUpInside];
    [socialViewAction addSubview:bttnText];
    
    // audio button
    UIButton *bttnAudio = [UIButton buttonWithType:UIButtonTypeCustom];
    bttnAudio.frame = CGRectMake(70, 20, 56, 47);
    [bttnAudio setBackgroundImage:[UIImage imageNamed:@"bttn_msg_send_audio.png"] forState:UIControlStateNormal];
    [bttnAudio addTarget:self action:@selector(showMicrophone:) forControlEvents:UIControlEventTouchUpInside];
    [socialViewAction addSubview:bttnAudio];
    
    [self.view addSubview:socialViewAction];
}

- (IBAction)removeActionBox
{
    [UIView animateWithDuration :.2
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          pickedGlow.alpha = 0;
                          [viewAction setAlpha:0];
                          [socialViewAction setAlpha:0];
                      }
                      completion:^(BOOL finished){
                      }];
    
    [self resetSocialValues];
}

- (void)hideActionBox
{
    [UIView animateWithDuration :.2
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          pickedGlow.alpha = 0;
                          [viewAction setAlpha:0];
                          [socialViewAction setAlpha:0];
                      }
                      completion:^(BOOL finished){
                      }];
}

- (void)resetSocialValues
{
    socialToID = @"";
    selectedIndex = -3;
    groupID = 0;
    toID = 0;
}

- (void)blockandDeleteFriend :(id) sender
{
    
    UIButton *btn = (UIButton *) sender;
    UIView *vParent = btn.superview;
    _selectedIndex = vParent.tag - 10;
    
//    UITableViewCell *cell = [homeTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
//    UIButton *frButton = (UIButton *)[cell.contentView viewWithTag:_selectedIndex+10];
    
    
    DLog(@"Here is friendButton tag : %d and social to id : %@ and toid : %d and sendto : %d",_selectedIndex,socialToID,toID,sendTo)
    
    UIAlertView *alert;
    NSDictionary *dict = [arrCellData objectAtIndex:_selectedIndex];
    nrUserId = [dict objectForKey:@"user_id"];
    
    DLog(@"Here is index %d and userid : %@",_selectedIndex,nrUserId);
    //return;
    
    
    
    if ([nrUserId intValue] > 0)
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Block Friend"
                                           message:@"Note: If you change your mind, go to profile \"Block List\" to edit?"
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Block", nil];
    }
    else
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Block Group"
                                           message:@"Note: If you change your mind, go to profile \"Block List\" to edit"
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Block",nil];
    }
    
    alert.tag = 1009;
    [alert show];

}

- (IBAction)showActionBox:(id)sender
{
    if (_showDeleteTag)
    {
        _showDeleteTag = NO;
        [self.homeTableView reloadData];
        return;
    }
   
    UIButton *button = (UIButton *)sender;
    socialButton = (button.tag == kFBButtonTag) || (button.tag == kTwitterButtonTag);
    NSInteger buttonTag = button.tag - 10;
    if (buttonTag == selectedIndex)
    {
        [self removeActionBox];
        return;
    }
    else
    {
        pickedGlow.alpha = 0;
        selectedIndex = buttonTag;
    }
    
    UIView *parentView = (UIView *)button.superview;
    UIImageView *friendGlow = (UIImageView *)[parentView viewWithTag:kFriendGlowTag];
    CGPoint viewCenter = parentView.center;
    CGPoint resultingPoint = [parentView convertPoint:viewCenter toView:(isSearchResults? self.searchDisplayController.searchResultsTableView:self.view)];
    UIImageView *friendPic = (UIImageView *)[parentView viewWithTag:kFriendPicTag];
    CGPoint centerPoint;
    
    imageTo.image = friendPic.image;
    pickedGlow = friendGlow;
    
    if (selectedIndex >= 0)
    {
        NSDictionary *dict = [arrCellData objectAtIndex:selectedIndex];
        if ([[dict objectForKey:@"user_id"] intValue] == 0)
        {
            toID = 0;
            groupID = [[dict objectForKey:@"group_id"] intValue];
        }
        else
        {
            toID = [[dict objectForKey:@"user_id"] intValue];
            groupID = 0;
        }
    }
    else
    {
        if (toID == 0 && groupID == 0)
        {
            toID = selectedIndex + 3;
            groupID = 0;
        }
    }
    
    bttnCloseAction.center = CGPointMake(160, 160);
    
    // Set the location of the action (popup menu) view
    int XCoord = (int) viewCenter.x;
    
    if (socialButton) {
        if (XCoord < 121) {
            socialViewAction.image = [[UIImage imageNamed:@"popup_bttn_edge"] stretchableImageWithLeftCapWidth:55 topCapHeight:0];
            centerPoint = CGPointMake(viewCenter.x + 26, resultingPoint.y + 50);
        } else if (XCoord > 199) {
            socialViewAction.image = [[UIImage imageNamed:@"popup_bttn_edge"] stretchableImageWithLeftCapWidth:28 topCapHeight:0];
            centerPoint = CGPointMake(viewCenter.x - 26, resultingPoint.y + 50);
        } else {
            socialViewAction.image = [UIImage imageNamed:@"popup_bttn"];
            centerPoint = CGPointMake(viewCenter.x, resultingPoint.y + 50);
        }
        if (socialViewAction.alpha == 0) {
            socialViewAction.center = centerPoint;
        }
        [UIView animateWithDuration :.2
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              socialViewAction.alpha = 1;
                              viewAction.alpha = 0;
                              socialViewAction.center = centerPoint;
                              friendGlow.alpha = 1;
                          }
                          completion:nil];
        
    }
    else {
        
        //Show Message Thread Ticket # 47
        [self showMessageThread:nil];

//        if (XCoord < 121) {
//            viewAction.image = [[UIImage imageNamed:@"popup_bttn_edge"] stretchableImageWithLeftCapWidth:55 topCapHeight:0];
//            centerPoint = CGPointMake(viewCenter.x + 56, resultingPoint.y + 50);
//        } else if (XCoord > 201) {
//            viewAction.image = [[UIImage imageNamed:@"popup_bttn_edge"] stretchableImageWithLeftCapWidth:28 topCapHeight:0];
//            centerPoint = CGPointMake(viewCenter.x - 56, resultingPoint.y + 50);
//        } else {
//            viewAction.image = [UIImage imageNamed:@"popup_bttn"];
//            centerPoint = CGPointMake(viewCenter.x, resultingPoint.y + 50);
//        }
//        if (viewAction.alpha == 0) {
//            viewAction.center = centerPoint;
//        }
//        
//        [UIView animateWithDuration :.2
//                               delay: 0
//                             options: UIViewAnimationOptionTransitionNone
//                          animations:^{
//                              viewAction.alpha = 1;
//                              socialViewAction.alpha = 0;
//                              viewAction.center = centerPoint;
//                              friendGlow.alpha = 1;
//                          }
//                          completion:nil];
    }
}

- (IBAction)openTwitterAction:(id)sender
{
    toID = 2;
    groupID = 0;

    if (![TWTweetComposeViewController canSendTweet])
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"SORRY", nil)
                                  message:NSLocalizedString(@"TWITTER_ALERT", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    //Old Code
//    if (![twHelper isLoggedIn]) {
//        [twHelper setUserInfo:[NSArray arrayWithObjects:sender, nil]];
//        [twHelper login];
//        return;
//    }
    
    [self showActionBox:sender];
}

-(void) refreshAfterDelete :(NSNotification *)notify
{
    if([arrCellData count] > _selectedIndex)
    {
        [arrCellData removeObjectAtIndex:_selectedIndex];
    }
    
    [self.homeTableView reloadData];
    
    [self refreshTapped];
}

#pragma mark - block friend
-(void) blockFriend
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshAfterBlock" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAfterDelete:) name:@"refreshAfterBlock" object:nil];
    
    
    NSDictionary *dict = [arrCellData objectAtIndex:_selectedIndex];
    nrUserId = [dict objectForKey:@"user_id"];
    
    NSString *url = [NSString stringWithFormat:@"%@contact/block?id=%@",kAPIURL,nrUserId];
    
    NSString *selector = @"refreshAfterBlock";
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 nil];
    
    
    [[serverConnection arrRequests] addObject:dictRequest];
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
    
    CoreDataClass *core = [[CoreDataClass alloc] init];
    
    NSString *where = [NSString stringWithFormat:@"user_id = %@", nrUserId];
    
    /* Added By Aftab Baig */
    /* The blocked people are now saved in it's own entity for quick fetching */
    NSArray *peoples = [core getData:@"People" Conditions:where Sort:@"first_name" Ascending:YES];
    [core addBlockedPeople:[core convertToDict:peoples]];
    [core deleteAll:@"People" Conditions:where];
    /* End Added By Aftab Baig */
    
    
    
    NSString *strWhere1 = [NSString stringWithFormat:@"friend_id = %@", nrUserId];
    [core deleteAll:@"Message_threads" Conditions:strWhere1];
    [core saveContext];

    
}

-(void) blockGroup
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshAfterBlock" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAfterDelete:) name:@"refreshAfterBlock" object:nil];
    
    
    NSDictionary *dict = [arrCellData objectAtIndex:_selectedIndex];
    nrUserId = [dict objectForKey:@"group_id"];
    
    NSString *url = [NSString stringWithFormat:@"%@group/block?id=%@",kAPIURL,nrUserId];
    
    NSString *selector = @"refreshAfterBlock";
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 nil];
    
    
    [[serverConnection arrRequests] addObject:dictRequest];
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
    
    
    
    CoreDataClass *core = [[CoreDataClass alloc] init];
    
    NSString *where = [NSString stringWithFormat:@"id = %@",nrUserId];
    NSArray *groups = [core getData:@"Groups" Conditions:where Sort:@"name" Ascending:YES];
    [core addBlockedGroups:[core convertToDict:groups]];
    NSString *strWhere1 = [NSString stringWithFormat:@"group_id = %@", nrUserId];
    [core deleteAll:@"Message_threads" Conditions:strWhere1];
    [core saveContext];
    
}

-(void) deleteFriend
{
    //============================================================================================
    //    Perform DELETE friend action
    //    For more details here: http://playground.brians.com/tango/api_help/#contactXdelete23
    //============================================================================================
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshAfterDelete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAfterDelete:) name:@"refreshAfterDelete" object:nil];
    
    //=>    get UserToken from user defaults
    defaults = [NSUserDefaults standardUserDefaults];
    NSString *userToken = [defaults objectForKey:@"UserToken"];
    
    //=>    create URL for deleting friend
    NSString *strURL = [NSString stringWithFormat:@"%@contact/delete?id=%@&token=%@" , kAPIURL, nrUserId, userToken];
    
    NSString *selector = @"refreshAfterDelete";
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 strURL, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 nil];
    
    
    [[serverConnection arrRequests] addObject:dictRequest];
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1009)
    {
        
        NSDictionary *dict1 = [arrCellData objectAtIndex:_selectedIndex];
        nrUserId = [dict1 objectForKey:@"user_id"];

        if (buttonIndex == 1)
        {
            DLog(@"Block Pressed");
            if ([nrUserId intValue] > 0)
            {
                [self blockFriend];
            }
            else{
                [self blockGroup];
            }

        }
        else
            if (buttonIndex == 2)
            {
                //         DLog(@"Delete Pressed");
                //            [self deleteFriend];
            }
    }
    _showDeleteTag = NO;
    [self.homeTableView reloadData];
    
}

- (IBAction)displaySocFriendList:(id)sender
{
    if ([socialToID length] > 0)
    {
        socialToID = @"";
        socialToName = @"";
        [self removeActionBox];
        return;
    }
    
    [self showActionBox:sender];
    viewAction.alpha = 0;
    socialViewAction.alpha = 0;
    bttnRefresh.alpha = 0;
    UIButton *button = (UIButton *)sender;
    NSInteger buttonTag = button.tag - 10;
    toID = buttonTag + 3;
    groupID = 0;
    if (toID == 1)
    {
        if (![fbHelper isLoggedIn])
        {
            [fbHelper setUserInfo:[NSArray arrayWithObjects:sender, nil]];
            [fbHelper login];
            return;
        }
    }
    if (self.socialFriendsList.view.alpha == 1)
    {
        [self removeSocFriendList];
    }
    self.socialFriendsList.toID = toID;
    [self.socialFriendsList populateTableCellData];
    
    [UIView animateWithDuration :.2
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          pickedGlow.alpha = 1;
                          [self.socialFriendsList.view setAlpha:1];
                      }
                      completion:nil];
}

- (void)removeSocFriendList
{
        socialToID = @"";
        selectedIndex = -3;
        [UIView animateWithDuration :.2
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              pickedGlow.alpha = 0;
                              bttnRefresh.alpha = .5;
                              [viewAction setAlpha:0];
                              [socialFriendsList.view setAlpha:0];
                          }
                          completion:^(BOOL finished){
                          }];
}

- (void)socFriendSelected:(NSString *)socialID withName:(NSString *)socialName
{
    DLog(@"ID: %@",socialID);
    DLog(@"NAME: %@",socialName);
    socialToID = socialID;
    socialToName = socialName;
    [UIView animateWithDuration :.2
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          socialViewAction.alpha = 1;
                          viewAction.alpha = 0;
                          pickedGlow.alpha = 1;
                          bttnRefresh.alpha = .5;
                      }
                      completion:nil];
}

- (void)changePhotoName
{
    if (groupID > 0)
    {
        NSDictionary *dict = [arrCellData objectAtIndex:selectedIndex];
        labelTo.text = [dict objectForKey:@"first_name"];
        placeholderTo.image = [UIImage imageNamed:@"userpic_friend"];
    }
    else
    {
        if (toID > 2)
        {
            NSDictionary *dict = [arrCellData objectAtIndex:selectedIndex];
            labelTo.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
            placeholderTo.image = [UIImage imageNamed:@"userpic_friend"];
        }
        else
        {
            imageTo.image = nil;
            if (toID == 1)
            {
                placeholderTo.image = [UIImage imageNamed:@"userpic_friend_fb"];
                NSString *name = [socialToName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                labelTo.text = [NSString stringWithFormat:@"Facebook (%@)", name];
            }
            else
            if (toID == 2)
            {
                placeholderTo.image = [UIImage imageNamed:@"userpic_friend_tw"];
                labelTo.text = [NSString stringWithFormat:@"Twitter (%@)", NSLocalizedString(@"MY FEED", nil)];
            }
            else
            {
                placeholderTo.image = [UIImage imageNamed:@"icon_contacts"];
                labelTo.text = [NSString stringWithFormat:@"%@ %@", [self.sendPerson objectForKey:@"first_name"], [self.sendPerson objectForKey:@"last_name"]];
            }
        }
    }
    [self.viewTo bringSubviewToFront:placeholderTo];
}

#pragma mark - API server methods
- (void)connectionAlert:(NSString *)message
{
    if (!message) {
        message = NSLocalizedString(@"REQUEST ERROR MESSAGE", nil);
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REQUEST ERROR" , nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"Connection failed: %@", [error description]);
    [theHUD hide];
    [refreshTimer invalidate];
    refreshTimer = nil;
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
//    NSLog(@"connectionDidFinishLoading");
    [theHUD hide];
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
//    NSLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"])
    {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"sendAudioInviteToFacebook"])
    {
        if ([dictJSON objectForKey:@"public_url"])
        {
            [fbHelper postVideoToFriend:[self.sendPerson objectForKey:@"facebook_id"]
                               videoURL:[dictJSON objectForKey:@"public_url"] message:NSLocalizedString(@"FB VIDEO POST DESC", nil)];
            if ([inviteView respondsToSelector:@selector(didSendAudioToFacebook)])
            {
                [inviteView didSendAudioToFacebook];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else
    if ([ref isEqualToString:@"sendAudioInviteByEmail"])
    {
        if ([dictJSON objectForKey:@"public_url"])
        {
            if ([inviteView respondsToSelector:@selector(sendEmailWithURL:)])
            {
                [inviteView sendEmailWithURL:[dictJSON objectForKey:@"public_url"]];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }
    else
    if ([ref isEqualToString:@"sendAudioToFacebook"])
    {
        NSLog(@"Total Time : %f", [[NSDate date] timeIntervalSinceDate:callStartDate]);
        if ([dictJSON objectForKey:@"public_url"])
        {
            //>     Hide Loading indicator
            [theHUD hide];
            
            socialPublicURL = [dictJSON objectForKey:@"public_url"];
            postVideoToFriend = YES;
            [self showKeyboard:nil];
        }
    }
    else
    if ([ref isEqualToString:@"sendAudioToTwitter"])
    {
        if ([dictJSON objectForKey:@"public_url"])
        {
            [theHUD hide];
            NSString *message = NSLocalizedString(@"TW AUDIO POST DESC", nil);
            [self openTwitterPostWithMessage:message withLink:[dictJSON objectForKey:@"public_url"]];
            [self hideMicrophone:nil];
        }
    }
    else
    if ([ref isEqualToString:@"saveFacebook"])
    {
        [self queueFriends];
    }
    else
    if ([ref isEqualToString:@"reloadMenu"])
    {
        if ([dictJSON objectForKey:@"threads"])
        {
            NSInteger unread = 0;
            NSArray *arrTmpThreads = [dictJSON objectForKey:@"threads"];
            for (NSDictionary *thread in arrTmpThreads)
            {
                unread += [[thread objectForKey:@"unread"] intValue];
            }
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate updateUnreadMessages:unread];
            
            //>---------------------------------------------------------------------------------------------------
            //>     I added this in order to save in CoreData last info about threads. Otherwise, it won't be
            //>     saved until user reaches notification view
            //>---------------------------------------------------------------------------------------------------
            CoreDataClass *core = [[CoreDataClass alloc] init];
            BOOL changed = NO;
                        
            NSArray *allThreads = [core getData:@"Message_threads" Conditions:@"" Sort:@"" Ascending:YES];
            NSMutableDictionary *dictThreads = [[NSMutableDictionary alloc] init];
            for (NSManagedObject *thread in allThreads)
            {
                [dictThreads setObject:thread forKey:[thread valueForKey:@"id"]];
            }
            
            // Loop through to add threads
            for (NSDictionary *thread in arrTmpThreads)
            {
                NSNumber *key = [thread objectForKey:@"thread_id"];
                NSManagedObject *object = [dictThreads objectForKey:key];
                if (object)
                {
                    [core setMessageThread:thread forObject:object];
                    [dictThreads removeObjectForKey:key];
                }
                else
                {
                    [core addMessageThread:thread];
                }
                changed = YES;
            }
            
            for (NSNumber *key in dictThreads)
            {
                [core deleteAll:@"Message_threads" Conditions:[NSString stringWithFormat:@"id = %@", key]];
                changed = YES;
            }
            
            if (changed)
            {
                [core saveContext];
            }
        }
        
        if ([dictJSON objectForKey:@"pending_friends"])
        {
            NSInteger pending = 0;
            NSArray *arrPendingFriends = [dictJSON objectForKey:@"pending_friends"];
            
            for (NSDictionary *newFriend in arrPendingFriends)
            {
                NSInteger initiator = [[newFriend objectForKey:@"initiator_id"] intValue];
                if (initiator > 0) {
                    if ([defaults integerForKey:@"UserID"] != initiator)
                    {
                        pending += 1;
                    }
                }
            }
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate updatePendingFriends:pending];
        }
        
        [self createNotificationsButton];
        
      
        
    }
    else
    if ([ref isEqualToString:@"login"])
    {
        [defaults setObject:[dictJSON objectForKey:@"first_name"] forKey:@"UserFirstName"];
        [defaults setObject:[dictJSON objectForKey:@"last_name"] forKey:@"UserLastName"];
        [defaults setObject:[dictJSON objectForKey:@"email_address"] forKey:@"UserEmail"];
        [defaults setObject:[dictJSON objectForKey:@"phone_number"] forKey:@"UserPhone"];
        [defaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu" object:nil];
 
        /* TODO fix update image
        // Hotfix until we analize what is going on with the serevr response
        BOOL isPhotoNil = [[dictJSON objectForKey:@"photo"] isKindOfClass:[NSNull class]];
        

        if ( !isPhotoNil && [[dictJSON objectForKey:@"photo"] length] > 7) {
            [squareAndMask setDelegate:self];
            [squareAndMask imageFromURL:[dictJSON objectForKey:@"photo"]];
        }*/
    }
    if ([ref isEqualToString:@"reloadGroups"])
    {
        [self queryFriends];
    }
    
    [refreshTimer invalidate];
    refreshTimer = nil;
}

- (void)queueFriends
{
    //>     Increase this number. We use it to skip some redundant calls
    _iNumberOfTimesWeCheckedForGroupsAndFriends++;
    
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@group/list", kAPIURL];
    NSString *selector = @"reloadGroups";
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                   url, @"url",
                   selector, @"selector",
                   @"GET", @"method",
                   @"", @"json_string",
                   @"", @"file_name",
                   @"", @"file_path",
                   nil];
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    // Make the API request
    url = [NSString stringWithFormat:@"%@contact", kAPIURL];
    selector = @"reloadFriends";
    dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 nil];
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
}

// Sort an array of people by their first name
- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people
{
    NSSortDescriptor *firstDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"first_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSSortDescriptor *lastDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"last_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSArray *descriptors = [NSArray arrayWithObjects:firstDescriptor, lastDescriptor, nil];
    NSArray *arrSorted = [people sortedArrayUsingDescriptors:descriptors];
    
    return [NSMutableArray arrayWithArray:arrSorted];
}

- (void)queryFriends
{
    NSArray *results;
    NSMutableArray *arrFriends = [[NSMutableArray alloc] init];
    
    // Get friends from core data
    NSString *whereString = @"is_friend = 1";
    CoreDataClass *core = [CoreDataClass sharedInstance];
    results = [core getData:@"People" Conditions:whereString Sort:@"first_name" Ascending:YES];
    
    for (NSManagedObject *friend in results)
    {
        NSDictionary *dictFriend = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [friend valueForKey:@"id"], @"id",
                                    [friend valueForKey:@"user_id"], @"user_id",
                                    [NSNumber numberWithInt:0], @"group_id",
                                    [friend valueForKey:@"first_name"], @"first_name",
                                    [friend valueForKey:@"last_name"], @"last_name",
                                    [friend valueForKey:@"photo"], @"photo",
                                    nil];
        [arrFriends addObject:dictFriend];
    }
    
    // Get groups from core data
    results = [core getData:@"Groups" Conditions:@"delete_date = nil" Sort:@"name" Ascending:YES];
    
    for (NSManagedObject *group in results)
    {
        NSDictionary *dictGroup = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"", @"id",
                                   @"", @"user_id",
                                   [group valueForKey:@"id"], @"group_id",
                                   [group valueForKey:@"name"], @"first_name",
                                   @"", @"last_name",
                                   [group valueForKey:@"photo"], @"photo",
                                   nil];
        [arrFriends addObject:dictGroup];
    }
    
    if (arrFriends)
    {
        NSMutableArray *arrSortedFriends = [self sortPeopleByFirstName:arrFriends];
        [arrIcons removeAllObjects];
        [arrIcons addObjectsFromArray:arrSortedFriends];
        [arrCellData removeAllObjects];
        arrCellData = [NSMutableArray arrayWithArray:arrIcons];
        
        if ([self.searchBar.text length] == 0)
        {
            [self.homeTableView reloadData];
        }
        else
        {
            [self handleSearchForTerm:self.searchBar.text];
        }
    }
    
    [self.homeTableView reloadData];
    isLoading = NO;
}

- (NSInteger)getObjectIndex:(NSArray *)array byID:(NSInteger)theID withKey:(NSString *)theKey
{
    NSInteger idx = 0;
    for (NSDictionary* dict in array)
    {
        if ([[dict objectForKey:theKey] intValue] == theID)
        {
            return idx;
        }
        ++idx;
    }
    return NSNotFound;
}

-(void) friendLongPressed:(UILongPressGestureRecognizer *)gesture
{
    
    
    UIButton *button = (UIButton *)gesture.view;
    _selectedIndex = button.tag - 10;
    
    _showDeleteTag = YES;
    [self.homeTableView reloadData];
       
}

#pragma mark - Loading From Other View

- (void)selectFriend:(NSInteger)index
{
    int row = index / 4;
    
    if (self.useDataSourceIndexing)
    {
        NSDictionary *dict = [arrCellData objectAtIndex:index];
        selectedIndex = index;
        if ([[dict objectForKey:@"user_id"] intValue] == 0)
        {
            toID = 0;
            groupID = [[dict objectForKey:@"group_id"] intValue];
        }
        else
        {
            toID = [[dict objectForKey:@"user_id"] intValue];
            groupID = 0;
        }
        
        UIImage *profileImage;
        if ([[dict objectForKey:@"user_id"] intValue] == 0)
        {
            profileImage = [self downloadCellImage:dict objectID:[dict objectForKey:@"group_id"] imageType:kGroupImage];
        }
        else
        {
            profileImage = [self downloadCellImage:dict objectID:[dict objectForKey:@"id"] imageType:kUserImage];
        }
        imageTo.image = profileImage;
    }
    else
    {
        UITableViewCell *cell = [homeTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        UIButton *frButton = (UIButton *)[cell.contentView viewWithTag:index+10];
        UIView *frParent = (UIView *)[frButton superview];
        UIImageView *frGlow = (UIImageView *)[frParent viewWithTag:kFriendGlowTag];
        frGlow.alpha = 1;
        [self showActionBox:(id)frButton];
    }
    
}

#pragma mark - Reset View

- (SocialFriendsList *)socialFriendsList
{
    if (socialFriendsList != nil) {
        return socialFriendsList;
    }
    
    self.socialFriendsList = [[SocialFriendsList alloc] initWithNibName:@"SocialFriendsList" bundle:nil];
    socialFriendsList.homeView = self;
    [self.view addSubview:socialFriendsList.view];
    
    return socialFriendsList;
}

- (void)resetHomeView
{
    toID = 0;
    self.sendTo = 0;
    self.sendType = nil;
    self.sendPerson = nil;
    
    if ([Utils isiPhone5])
    {
        viewTextMsg.center = CGPointMake(160, -224);
    }
    else
    {
        viewTextMsg.center = CGPointMake(160, -124);
    }
    
    [textMessage setText:@""];
    disableMenu = NO;
    imageMicrophone.center = CGPointMake(160, 497.5);
    viewRecord.center = CGPointMake(160, 658);
    viewTo.center = CGPointMake(160, -18);
    viewMicBG.alpha = 0;
    bttnRefresh.alpha = .5;
    viewRecord.alpha = 0;
    viewAction.alpha = 0;
    socialViewAction.alpha = 0;
    scrollIcons.alpha = 1;
    bttnRecord.alpha = 1;
    bttnPreview.alpha = 0;
    bttnSend.alpha = 0;
    bttnDelete.alpha = 0;
    [self createNotificationsButton];
    [self removeActionBox];
    [textMessage resignFirstResponder];
    [self.socialFriendsList.view setAlpha:0];
}

#pragma mark - Create message
- (IBAction)showMicrophone:(id)sender
{
    [self showMicrophoneAnimated:YES];
    if (isSearchResults) {
        [self searchBarCancelButtonClicked:self.searchDisplayController.searchBar];
        [self.searchDisplayController setActive:NO];
    }
}

- (void)showMicrophoneAnimated:(BOOL)animated
{
    disableMenu = YES;
    
    imageMicrophone.hidden = NO;
    
    //>---------------------------------------------------------------------------------------------------
    //>     Ben 28/09/2012 - Ticket #114
    //>
    //>     We need to hide activity indicator and "Loading" label while recording
    //>---------------------------------------------------------------------------------------------------
    self.loadingActivityIndicator.hidden        = YES;
    self.lblLoading.hidden                      = YES;
    
    // Hide the notification if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:nil];
    viewRecord.alpha = 1;
    [self changePhotoName];
    
    CGRect deviceFrame      = [[UIScreen mainScreen] bounds];
    if (animated)
    {
        [UIView animateWithDuration :.5
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              //>---------------------------------------------------------------------------------------------------
                              //>       Those are hardcoded values, which is not good. Previous values were 220 and 362.
                              //>       480 - 220 => 260
                              //>       480 - 362 => 118
                              //>       So we will use now deviceFrame.size.height, and substract those hardcoded values
                              //>
                              //>       imageMicrophone.center = CGPointMake(160, 220);
                              //>       viewRecord.center = CGPointMake(160, 362);
                              //>---------------------------------------------------------------------------------------------------
                              if ([Utils isiPhone5])
                              {
                                  imageMicrophone.center = CGPointMake(160, deviceFrame.size.height - 340);
                              }
                              else
                              {
                                  imageMicrophone.center = CGPointMake(160, deviceFrame.size.height - 260);
                              }
                              
                              viewRecord.center = CGPointMake(160, deviceFrame.size.height - 118);
                              viewAction.alpha = 0;
                              socialViewAction.alpha = 0;
                              viewMicBG.alpha = 1;
                              scrollIcons.alpha = 0;
                              homeTableView.alpha = 0;
                              bttnRefresh.alpha = 0;
                              viewTo.center = CGPointMake(160, 18);
                          }
                          completion:^(BOOL finished){
                              [self createCancelButton];
                              [self.navigationItem setRightBarButtonItem:nil];
                          }];
    }
    else
    {
        imageMicrophone.center = CGPointMake(160, deviceFrame.size.height - 260);
        viewRecord.center = CGPointMake(160, deviceFrame.size.height - 118);
        //imageMicrophone.center = CGPointMake(160, 220);
        //viewRecord.center = CGPointMake(160, 362);
        viewAction.alpha = 0;
        socialViewAction.alpha = 0;
        viewMicBG.alpha = 1;
        bttnRefresh.alpha = 0;
        scrollIcons.alpha = 0;
        homeTableView.alpha = 0;
        viewTo.center = CGPointMake(160, 18);
        [self createCancelButton];
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (IBAction)hideMicrophone:(id)sender
{
    [self hideActionBox];
    disableMenu = NO;
    if (sendType)
    {
        imageMicrophone.center = CGPointMake(160, 497.5);
        viewRecord.center = CGPointMake(160, 658);
        viewTo.center = CGPointMake(160, -18);
        if (!sendType) {
            if (socialButton) {
                socialViewAction.alpha = 1;
            }
            else {
                viewAction.alpha = 1;                                      
            }
        }
        viewMicBG.alpha = 0;
        scrollIcons.alpha = 1;
        homeTableView.alpha = 1;
        bttnRecord.alpha = 1;
        bttnPreview.alpha = 0;
        bttnSend.alpha = 0;
        bttnDelete.alpha = 0;
    }
    else
    {
        [UIView animateWithDuration :.5
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              imageMicrophone.center = CGPointMake(160, 497.5);
                              viewRecord.center = CGPointMake(160, 658);
                              viewTo.center = CGPointMake(160, -18);
                              if (!sendType && (selectedIndex > -1))
                              {
                                  if (socialButton)
                                  {
                                      socialViewAction.alpha = 1;
                                  }
                                  else
                                  {
                                      viewAction.alpha = 1;                                      
                                  }
                              }
                              viewMicBG.alpha = 0;
                              scrollIcons.alpha = 1;
                              homeTableView.alpha = 1;
                              bttnRecord.alpha = 1;
                              bttnPreview.alpha = 0;
                              bttnSend.alpha = 0;
                              bttnDelete.alpha = 0;
                              bttnRefresh.alpha = .5;
                          }
                          completion:^(BOOL finished){
                              
                              imageMicrophone.hidden = YES;
                              viewRecord.alpha = 0;
                              [self createProfileButton];
                              [self createNotificationsButton];
                              
                              //>---------------------------------------------------------------------------------------------------
                              //>     Ben 28/09/2012 - Ticket #114
                              //>
                              //>     Show activity indicator and "Loading" label, when finished recording
                              //>---------------------------------------------------------------------------------------------------
                              self.loadingActivityIndicator.hidden        = NO;
                              self.lblLoading.hidden                      = NO;
                          }];
    }
}

- (IBAction)showKeyboard:(id)sender
{    
    if (isSearchResults)
    {
        // Inactivating the displayController results on a call to resetSearch, 
        // which causes incosistent behaviour when displaying the keyboard
        resetFromKeyboardAction = YES;
        [self.searchDisplayController setActive:NO];
        [self showKeyboardAnimated:YES];
        [self searchBarCancelButtonClicked:self.searchDisplayController.searchBar];
    }
    else
    {
        [self showKeyboardAnimated:YES];
    }

}

- (void)showKeyboardAnimated:(BOOL)animated
{
    //>---------------------------------------------------------------------------------------------------
    //>     Changes because of iOS 5 Twitter SDK. If toID == 2, user wants to tweet a message
    //>---------------------------------------------------------------------------------------------------
    if (toID == 2)
    {
        //>     Hide action box
        [self removeActionBox];
        
        NSString *message = [NSString stringWithFormat:@"\n@TongueTango"];
        
        if ([TWTweetComposeViewController canSendTweet])
        {
            if (!self.tweetSheet)
            {
                self.tweetSheet = [[TWTweetComposeViewController alloc] init];
            }

            [self.tweetSheet setInitialText:message];
            [self presentModalViewController:self.tweetSheet animated:YES];
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedString(@"SORRY", nil)
                                      message:NSLocalizedString(@"TWITTER_ALERT", nil)
                                      delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                      otherButtonTitles:nil];
            [alertView show];
        }
        
        return;
    }
    
    disableMenu = YES;
    
    [self.lblLoading setHidden:YES];
    [self.loadingActivityIndicator setHidden:YES];
    
    // Hide the notification if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:nil];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [textMessage becomeFirstResponder];
    [self changePhotoName];
    
    if (animated)
    {
        [UIView animateWithDuration :.5
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              
                              
                              if ([Utils isiPhone5])
                              {
                                  viewTo.center = CGPointMake(160, 18);
                                  //viewTextMsg.center = CGPointMake(160, 174);
                                  //[viewTextMsg setFrame:CGRectMake(0, viewTo.frame.size.height, 320, 300)];
                                  [viewTextMsg setFrame:CGRectMake(0, 0, 320, 320)];
                              }
                              else
                              {
                                  viewTo.center = CGPointMake(160, 18);
                                  viewTextMsg.center = CGPointMake(160, 124);
                              }
                              viewAction.alpha = 0;
                              socialViewAction.alpha = 0;
                              scrollIcons.alpha = 0;
                              homeTableView.alpha = 0;
                              bttnRefresh.alpha = 0;
                              
                          }
                          completion:nil];
    }
    else
    {
        if ([Utils isiPhone5])
        {
            viewTo.center = CGPointMake(160, 18);
            [viewTextMsg setFrame:CGRectMake(0, 0, 320, 320)];
        }
        else
        {
            viewTo.center = CGPointMake(160, 18);
            viewTextMsg.center = CGPointMake(160, 124);
        }
        
        viewAction.alpha = 0;
        socialViewAction.alpha = 0;
        scrollIcons.alpha = 0;
        homeTableView.alpha = 0;
        bttnRefresh.alpha = .5;
    }
}

- (IBAction)hideKeyboard:(id)sender
{
    [self removeActionBox];
    
    [self.lblLoading setHidden:NO];
    [self.loadingActivityIndicator setHidden:NO];
    
    // Message origin wasn't from home, pop
    disableMenu = NO;
    if (sendType)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [textMessage resignFirstResponder];
        if (self.sendTo != 0)
        {
            if (self.sendTo > -1)
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        [UIView animateWithDuration :.5
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              if ([Utils isiPhone5])
                              {
                                  viewTextMsg.center = CGPointMake(160, -224);
                              }
                              else
                              {
                                  viewTextMsg.center = CGPointMake(160, -124);
                              }
                              
                              if (toID >= 1 || groupID > 0)
                              {
                                  if (socialButton)
                                  {
                                      socialViewAction.alpha = 1;
                                  }
                                  else
                                  {
                                      viewAction.alpha = 1;                                      
                                  }
                              }
                              scrollIcons.alpha = 1;
                              homeTableView.alpha = 1;
                              bttnRefresh.alpha = .5;
                              viewTo.center = CGPointMake(160, -18);
                          }
                          completion:^(BOOL finished){
                              [textMessage setText:@""];
                          }];
    }
}

- (IBAction)showMessageThread:(id)sender
{
    MessageThreadDetailView *messageThread = [[MessageThreadDetailView alloc] initWithNibName:@"MessageThreadDetailView" bundle:nil];
    NSDictionary *dict = [self.arrCellData objectAtIndex:selectedIndex];
    messageThread.dictPerson = dict;
    messageThread.toID = toID; //New added
    messageThread.socialToID = socialToID; //New added
    [self.navigationController pushViewController:messageThread animated:YES];
}

#pragma mark - Audio
- (IBAction)startRecording
{
    [bttnRecord setShowsTouchWhenHighlighted:YES];
    
	// start recording
	[recorder_ record];
}

- (IBAction)stopRecording
{
	[recorder_ stop];
    if ([defaults boolForKey:@"ReviewRecording"]) {
        [UIView animateWithDuration :.3
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              bttnRecord.alpha = 0;
                              bttnPreview.alpha = 1;
                              bttnSend.alpha = 1;
                              bttnDelete.alpha = 1;
                          }
                          completion:^(BOOL finished){
                          }];
    } else {
        [self sendAudio:nil];
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)aRecorder successfully:(BOOL)flag
{
	DLog(@"Finished recording audio: %d", flag) ;
}

- (IBAction)playRecording
{
    if (isPlaying) {
        [self stopPlaying];
    } else {
        // Proximity Sensor
        UIDevice *device = [UIDevice currentDevice];
        device.proximityMonitoringEnabled = YES;
        if (device.proximityMonitoringEnabled == YES)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityChanged:) name:@"UIDeviceProximityStateDidChangeNotification" object:device];
        
        isPlaying = YES;
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        if ([defaults boolForKey:@"Speaker"]) {
            UInt32 doChangeDefaultRoute = 1;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
        }
        
        UInt32 allowBluetoothInput = 1;
        AudioSessionSetProperty(
                                kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                sizeof (allowBluetoothInput),
                                &allowBluetoothInput);
        
        [audioSession setActive:YES error:nil];
        
		NSError *audioError = nil ;
		NSURL *url = [NSURL fileURLWithPath:recorderFilePath] ;
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&audioError];
		if( !audioError ) {
			[audioPlayer setDelegate:self];
			[audioPlayer play];
		}
		else {
			DLog(@"Error initializing audio player: %@" , audioError) ;
		}
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    isPlaying = NO;
}

- (void)stopPlaying
{
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    isPlaying = NO;
    [audioPlayer stop];
}

- (IBAction)deletePreview:(id)sender {
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    [audioPlayer stop];
    isPlaying = NO;
    [recorder_ deleteRecording];
    
    // Remove the file from the device
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *theFileName = [[recorderFilePath lastPathComponent] stringByDeletingPathExtension];
    if ([theFileName length] > 0) {
        TFLog(@"Deleting discarded audio file: %@", recorderFilePath);
        BOOL isDir;
        if ([fileManager fileExistsAtPath:recorderFilePath isDirectory:&isDir] && !isDir) {
            [fileManager removeItemAtPath:recorderFilePath error:nil];
        }
    }
    
    [UIView animateWithDuration :.3
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          bttnRecord.alpha = 1;
                          bttnPreview.alpha = 0;
                          bttnSend.alpha = 0;
                          bttnDelete.alpha = 0;
                      }
                      completion:^(BOOL finished){
                      }];
}

#pragma mark - Send Message

- (BOOL)isValidFileSize:(NSString *)filePath
{
    NSError *attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attributesError];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    double fileSize = [fileSizeNumber doubleValue];
    
    DLog(@"File size: %f", fileSize);
    
    if (fileSize < 4200) {
        TFLog(@"Attempted to upload an empty file.");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UPLOAD ERROR" , nil)
                                                        message:NSLocalizedString(@"UPLOAD ERROR MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}

- (IBAction)sendAudio:(id)sender
{
    if (sUserVisibleDateFormatter == nil)
    {
        sUserVisibleDateFormatter = [[NSDateFormatter alloc] init];
        [sUserVisibleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    [audioPlayer stop];
    isPlaying = NO;
    
    if ([sendType isEqualToString:@"AudioInvite"])
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        if (toID == 0)
        {
            // Email an audio invitation
            NSString *url = [NSString stringWithFormat:@"%@message/twitter", kAPIURL];
            ServerConnection *APIrequest = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setReference:@"sendAudioInviteByEmail"];
            [APIrequest sendFile:recorderFilePath URL:url JSON:nil];
        }
        else if (toID == 1)
        {
            // Post an audio invitation on Facebook
            NSString *url = [NSString stringWithFormat:@"%@message/facebook", kAPIURL];
            ServerConnection *APIrequest = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setReference:@"sendAudioInviteToFacebook"];
            [APIrequest sendFile:recorderFilePath URL:url JSON:nil];
        }
        return;
    }
    
    //>---------------------------------------------------------------------------------------------------
    //>     I am sending GMT date to server, as create_date
    //>---------------------------------------------------------------------------------------------------
    NSDate *currentDate         = [NSDate date];
    NSDateFormatter *dfGMT      = [[NSDateFormatter alloc] init];
    [dfGMT setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dfGMT setTimeZone:gmt];
    
    NSString *strCreateDateGMT  = [dfGMT stringFromDate:currentDate];
    
    if (groupID > 0)
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        NSNumber *numGroupID = [NSNumber numberWithInt:groupID];
        //NSString *strFullDate = [sUserVisibleDateFormatter stringFromDate:[NSDate date]];
        
        // Send an audio message to a group
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                                 strCreateDateGMT, @"create_date",
                                 [NSNumber numberWithInt:2], @"message_type_id",
                                 @"Audio Message", @"message_header",
                                 newFileName, @"message_body",
                                 [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:numGroupID forKey:@"group_id"]], @"recipients",
                                 nil];
        
        // Save to core data
        NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [defaults objectForKey:@"UserID"], @"user_id",
                                 @"Audio Message", @"message_header",
                                 newFileName, @"message_body",
                                 strCreateDateGMT, @"create_date",
                                 [NSNumber numberWithInt:0], @"favorite",
                                 nil];
        
        CoreDataClass *core = [CoreDataClass sharedInstance];
        [core setMessageForGroup:numGroupID withDictionary:message forObject:nil];
        
        // Send API request
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];

        NSString *url = [NSString stringWithFormat:@"%@message/create", kAPIURL];
        
        NSString *selector = @"sendAudio";
        
        NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                     url, @"url",
                                     selector, @"selector",
                                     @"POST", @"method",
                                     jsonString, @"json_string",
                                     @"recording.mp4", @"file_name",
                                     recorderFilePath, @"file_path",
                                     nil];
        
        [[serverConnection arrRequests] addObject:dictRequest];
        
        [serverConnection startQueue];
        
        bttnRecord.hidden = NO;
        if (sendType)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self hideMicrophone:nil];
        }
        
        return;
    }
    
    if (toID == 1 )
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        
        //>     Show Loading indicator to user
        [theHUD show];
        
        // Send an audio message to Facebook
        callStartDate  = [NSDate date];
        
        NSString *url = [NSString stringWithFormat:@"%@message/create/facebook", kAPIURL];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setUserInfo:socialToID];
        [APIrequest setReference:@"sendAudioToFacebook"];
        [APIrequest sendFile:recorderFilePath URL:url JSON:nil];

        if (sendType)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self hideMicrophone:nil];
        }
    }
    else if (toID == 2)
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        
       
        [theHUD show];
        // Send an audio message to Twitter
        NSLog(@"Start : %@", [NSDate date]);
        NSString *url = [NSString stringWithFormat:@"%@message/create/twitter", kAPIURL];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"sendAudioToTwitter"];
        [APIrequest sendFile:recorderFilePath URL:url JSON:nil];
        
        if (sendType)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self hideMicrophone:nil];
        }
    }
    else
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        
        NSNumber *recipientID = [NSNumber numberWithInt:toID];
        
        // Send an audio message to a friend
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                                 strCreateDateGMT, @"create_date",
                                 [NSNumber numberWithInt:2], @"message_type_id",
                                 @"Audio Message", @"message_header",
                                 newFileName, @"message_body",
                                 [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:toID] forKey:@"user_id"]], @"recipients",
                                 nil];
        
        // Save to core data
        NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [defaults objectForKey:@"UserID"], @"sender_id",
                                 recipientID, @"recipient_id",
                                 @"Audio Message", @"message_header",
                                 newFileName, @"message_body",
                                 strCreateDateGMT, @"create_date",
                                 [NSNumber numberWithInt:0], @"favorite",
                                 nil];
        
        CoreDataClass *core = [CoreDataClass sharedInstance];
        [core setMessage:message forObject:nil];
        
        // Send API request
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        
        NSString *url = [NSString stringWithFormat:@"%@message/create", kAPIURL];
        
        NSString *selector = @"sendAudio";
        
        NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                     url, @"url",
                                     selector, @"selector",
                                     @"POST", @"method",
                                     jsonString, @"json_string",
                                     @"recording.mp4", @"file_name",
                                     recorderFilePath, @"file_path",
                                     nil];
        
        [[serverConnection arrRequests] addObject:dictRequest];
        
        [serverConnection startQueue];
        
        bttnRecord.hidden = NO;
        
        if (sendType)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self hideMicrophone:nil];
        }

    }
}

- (IBAction)sendText:(id)sender
{
    if (sUserVisibleDateFormatter == nil)
    {
        sUserVisibleDateFormatter = [[NSDateFormatter alloc] init];
        [sUserVisibleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    //>---------------------------------------------------------------------------------------------------
    //>     I am sending GMT date to server, as create_date
    //>---------------------------------------------------------------------------------------------------
    NSDate *currentDate         = [NSDate date];
    NSDateFormatter *dfGMT      = [[NSDateFormatter alloc] init];
    [dfGMT setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dfGMT setTimeZone:gmt];
    
    NSString *strCreateDateGMT  = [dfGMT stringFromDate:currentDate];
    
    // Post video message can be empty
    if ([textMessage.text length] > 0 || postVideoToFriend)
    {
        if (groupID > 0)
        {
            NSNumber *numGroupID = [NSNumber numberWithInt:groupID];
            
            // Save to core data
            NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [defaults objectForKey:@"UserID"], @"user_id",
                                     @"Text Message", @"message_header",
                                     [NSNumber numberWithInt:1], @"message_type_id",
                                     textMessage.text, @"message_body",
                                     strCreateDateGMT, @"create_date",
                                     nil];
            
            CoreDataClass *core = [CoreDataClass sharedInstance];
            [core setMessageForGroup:numGroupID withDictionary:message forObject:nil];
            
            // Send an text message to a friend
            NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                                     strCreateDateGMT, @"create_date",
                                     [NSNumber numberWithInt:1], @"message_type_id",
                                     @"Text Message", @"message_header",
                                     textMessage.text, @"message_body",
                                     [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:groupID] forKey:@"group_id"]], @"recipients",
                                     nil];
            
            UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
            NSString *jsonString = [writer stringWithObject:dictAPI];
            
            // Make the API request
            NSString *url = [NSString stringWithFormat:@"%@message/create", kAPIURL];
            
            NSString *selector = @"sendText";
            
            NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                         url, @"url",
                                         selector, @"selector",
                                         @"POST", @"method",
                                         jsonString, @"json_string",
                                         @"", @"file_name",
                                         @"", @"file_path",
                                         nil];
            
            [[serverConnection arrRequests] addObject:dictRequest];
            
            [serverConnection startQueue];
            
            if (sendType) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self hideKeyboard:nil];
            }
        }
        else
        {
            if (toID == 1)
            {
                if (postVideoToFriend)
                {
                    //[fbHelper postVideoToFriend:socialToID videoURL:socialPublicURL message:textMessage.text];
                    [fbHelper postLinkToFriend:socialToID linkURL:socialPublicURL message:textMessage.text];
                    postVideoToFriend = NO;
                } 
                else
                {
                    [fbHelper postTextToFriend:socialToID message:textMessage.text];                    
                }
                
                [self hideKeyboard:nil];
                [self resetSocialValues];
            }
            else if (toID == 2)
            {
                
                NSString *message = [NSString stringWithFormat:@"%@ @TongueTango", textMessage.text];
                
                if ([TWTweetComposeViewController canSendTweet])
                {
                    if (!self.tweetSheet)
                    {
                        self.tweetSheet = [[TWTweetComposeViewController alloc] init];
                    }
                    
                    [self.tweetSheet setInitialText:message];
                    [self presentModalViewController:self.tweetSheet animated:YES];
                }
                else
                {
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:NSLocalizedString(@"SORRY", nil)
                                              message:NSLocalizedString(@"TWITTER_ALERT", nil)
                                              delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
                    [alertView show];
                }
                //[twHelper postTextMessage:message]; //Old code
                
                [self hideKeyboard:nil];
                [self resetSocialValues];
            }
            else
            {
                NSNumber *recipientID = [NSNumber numberWithInt:toID];
                
                // Save to core data
                NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [defaults objectForKey:@"UserID"], @"sender_id",
                                         recipientID, @"recipient_id",
                                         @"Text Message", @"message_header",
                                         textMessage.text, @"message_body",
                                         strCreateDateGMT, @"create_date",
                                         nil];
                
                CoreDataClass *core = [CoreDataClass sharedInstance];
                [core setMessage:message forObject:nil];
                
                NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                                         strCreateDateGMT, @"create_date",
                                         [NSNumber numberWithInt:1], @"message_type_id",
                                         @"Text Message", @"message_header",
                                         textMessage.text, @"message_body",
                                         [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:toID] forKey:@"user_id"]], @"recipients",
                                         nil];
                
                UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
                NSString *jsonString = [writer stringWithObject:dictAPI];
                
                // Make the API request
                NSString *url = [NSString stringWithFormat:@"%@message/create", kAPIURL];
                
                NSString *selector = @"sendText";
                
                NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                             url, @"url",
                                             selector, @"selector",
                                             @"POST", @"method",
                                             jsonString, @"json_string",
                                             @"", @"file_name",
                                             @"", @"file_path",
                                             nil];
                
                [[serverConnection arrRequests] addObject:dictRequest];
                
                [serverConnection startQueue];
                
                [self handleCancelButton:nil];
            }
        }
    } 
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TYPE MESSAGE" , nil)
                                                        message:NSLocalizedString(@"TYPE MESSAGE MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Social networks

- (void)twDidReturnLogin:(BOOL)success
{
    if (success)
    {
        toID = 2;
        UIButton *sender = (UIButton *)[[twHelper userInfo] objectAtIndex:0];
        [self showActionBox:sender];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                                        message:NSLocalizedString(@"TW ERROR", nil) 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)twDidReturnRequest:(BOOL)success
{
    if (success)
    {
        if (twHelper.currentAPICall == kTWTextMessage)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your text message has been posted to Twitter" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
        }
        else
            if (twHelper.currentAPICall == kTWAudioMessage)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your voice message has been posted to Twitter" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
            }
    }
    else
    {
        if (twHelper.currentAPICall == kTWTextMessage)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to tweet a text message. \nPlease try again" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
        }
        else
            if (twHelper.currentAPICall == kTWAudioMessage)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to tweet an audio message. \nPlease try again" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
            }
    }
    
    [theHUD hide];
}

- (void)fbDidReturnLogin:(BOOL)success
{
    if (success) {
        [fbHelper getMyInfo];
        toID = 1;
        self.socialFriendsList.toID = toID;
        [self.socialFriendsList populateTableCellData];
        
        [UIView animateWithDuration :.2
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              pickedGlow.alpha = 1;
                              [self.socialFriendsList.view setAlpha:1];
                          }
                          completion:nil];
    } 
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                                        message:NSLocalizedString(@"FB ERROR", nil) 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)fbDidReturnRequest:(BOOL)success:(NSMutableArray *)result
{
    if (success)
    {
        if ([result count] > 0)
        {
            NSDictionary *dict = [result objectAtIndex:0];
            NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [defaults objectForKey:@"FBAccessTokenKey"], @"facebook_access_token",
                                     [dict objectForKey:@"facebook_id"], @"facebook_id",
                                     nil];
            
            // Convert object to data
            UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
            NSString *jsonString = [writer stringWithObject:dictAPI];
            NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSString *url = [NSString stringWithFormat:@"%@user",kAPIURL];
            ServerConnection *APIrequest = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setReference:@"saveFacebook"];
            [APIrequest apiCall:jsonData Method:@"POST" URL:url];
        }
        else
        {
            [self hideKeyboard:nil];
            [self hideMicrophone:nil];
            
            if (fbHelper.currentAPICall == kPostText ||
                fbHelper.currentAPICall == kPostStatus)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your text message has been posted to Facebook" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
            }
            else
                if (fbHelper.currentAPICall == kPostLink ||
                    fbHelper.currentAPICall == kPostVideos)
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your voice message has been posted to Facebook" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alertView show];
                }
        }
    }
    else
    {
        if (fbHelper.currentAPICall == kPostText ||
            fbHelper.currentAPICall == kPostStatus)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send text message to Facebook. \nPlease try again" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
        }
        else
            if (fbHelper.currentAPICall == kPostLink ||
                fbHelper.currentAPICall == kPostVideos)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send voice message to Facebook. \nPlease try again" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
            }
    }
    
    [theHUD hide];
}

#pragma mark - Notification

- (IBAction)notificationButtonPressed:(id)sender {
    NotificationsView *notif = [[NotificationsView alloc] initWithNibName:@"NotificationsView" bundle:nil showPendingFriends:NO];
    [self.navigationController pushViewController:notif animated:YES];
}

#pragma mark - Social Post

- (void)openTwitterPostWithMessage:(NSString*)message withLink:(NSString*)link
{
    if ([TWTweetComposeViewController canSendTweet])
    {
        TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
        [tweetSheet setInitialText:message];
        [tweetSheet addURL:[NSURL URLWithString:link]];
        [self presentModalViewController:tweetSheet animated:YES];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"SORRY", nil)
                                  message:NSLocalizedString(@"TWITTER_ALERT", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                  otherButtonTitles:nil];
        [alertView show];
    }
//    TwitterPostViewController *postController = [[TwitterPostViewController alloc] initWithNibName:@"TwitterPostViewController" bundle:nil];
//    postController.message = message;
//    postController.link = link;
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:postController];
//    [self presentModalViewController:navController animated:YES];
}

#pragma mark - Tutorial

- (IBAction)hideTutorial:(id)sender
{
    [self.tutorialView removeFromSuperview];
    [self.view setUserInteractionEnabled:YES];
    [self.navigationController.navigationBar setUserInteractionEnabled:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kTutorialAlreadyDisplayed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)toggleProfile
{
    DLog(@"");
    
//    NotificationsView *notif = [[NotificationsView alloc] initWithNibName:@"NotificationsView" bundle:nil showPendingFriends:NO];
//    notif.isGroupInvitationArrived = YES;
//    notif.notifyMessage = @"Your address book friend Ashwin joined on TT.";
//    notif.isExternalPush = YES;
//    [self.navigationController pushViewController:notif animated:YES];
//    return;
    ProfileView *profile = [[ProfileView alloc] initWithNibName:@"ProfileView" bundle:nil];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)getUnreadCount
{
    DLog(@"");
    NSString *url = [NSString stringWithFormat:@"%@message/conversations",kAPIURL];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"reloadMenu"];
    [APIrequest apiCall:nil Method:@"GET" URL:url];
}

#pragma mark - Search table methods

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    UIImageView *anImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, -64, 320, 480)];
    if ([defaults integerForKey:@"ThemeID"] == 0)
    {
        anImage.image = [UIImage imageNamed:k_UIImage_BackgroundImageName];
    }
    else
    {
        anImage.image = [UIImage imageWithContentsOfFile:[defaults objectForKey:@"ThemeBG"]];
    }
    
    controller.searchResultsTableView.backgroundView = anImage;
    controller.searchResultsTableView.separatorColor = [UIColor clearColor];
    
    // Remove action box if present
    [self removeActionBox];
    
    // Add the action box to search screen
    [self.viewAction removeFromSuperview];
    [controller.searchResultsTableView addSubview:viewAction];
}

- (void)resetSearch
{
    [self.arrCellData removeAllObjects];
    [self.arrCellData addObjectsFromArray:arrIcons];
    isSearchResults = NO;
    resetFromKeyboardAction = NO;
}

- (void)handleSearchForTerm:(NSString *)searchText
{
    NSMutableArray *arrSearch;
    arrSearch = [arrIcons mutableDeepCopy];
    
    int sectionCount = [arrSearch count];
    NSMutableIndexSet *rowsToRemove = [[NSMutableIndexSet alloc] init];
    for (int i = 0; i < sectionCount; i++) {        
        NSDictionary *dict = [arrSearch objectAtIndex:i];
        NSString *name;
        name = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
        if ([name rangeOfString:searchText options:NSCaseInsensitiveSearch].location == NSNotFound) {
            [rowsToRemove addIndex:i];
        }
    }
    if (rowsToRemove.count > 0) {
        [arrSearch removeObjectsAtIndexes:rowsToRemove];
    }
    
    [self.arrCellData removeAllObjects];
    [self.arrCellData addObjectsFromArray:arrSearch];
    isSearchResults = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        if (resetFromKeyboardAction) {
            [self performSelector:@selector(resetSearch) withObject:nil afterDelay:1.0];            
        }
        else {
            [self resetSearch];
        }
        [self.homeTableView reloadData];
        return;
    }
    [self handleSearchForTerm:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)mSearchBar {
    self.searchDisplayController.searchBar.text = @"";
    [self resetSearch];
    [self.homeTableView reloadData];
    [mSearchBar resignFirstResponder];
    
    // Set back the action box
    [self.viewAction removeFromSuperview];
    [self removeActionBox];
    [self.view addSubview:viewAction];
}

- (void)cleanMemory {
    // JMR TODO review which data from this view we need to clean
}

- (void)reloadTableView {
    defaults = [NSUserDefaults standardUserDefaults];
    // TODO something to refresh the view but also review the notification is not being send until the profile information is saved (fix)
}

- (void)requestUserInfo {
    NSString *url = [NSString stringWithFormat:@"%@user/%@",kAPIURL,[defaults objectForKey:@"UserID"]];
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"login"];
    [APIrequest apiCall:nil Method:@"GET" URL:url];
}

#pragma mark - Handle Notification Popup

- (BOOL)acceptingNotificationsForDictionary:(NSDictionary *)extras {
    NSInteger intCurrentView;
    switch (intCurrentView) {
        case kViewGroups:
        {
            if ([[extras objectForKey:@"action"] isEqualToString:@"group"]) {
                return NO;
            }
            break;
        }
        case kViewFriends:
        {
            if ([[extras objectForKey:@"action"] isEqualToString:@"request"]) {
                return NO;
            }
            break;
        }
        case kViewHome:
        {
            /*
            if (self.homeView.disableMenu) {
                return NO;
            }*/
            break;
        }
        case kViewMessages:
        {
            /*
            if ([[extras objectForKey:@"action"] isEqualToString:@"message"]) {
                if (self.messageThreadView.strCurrentID == nil) {
                    return NO;
                }
                NSString *strCurrentID = nil;
                if ([[extras objectForKey:@"group_id"] intValue] > 0) {
                    strCurrentID = [NSString stringWithFormat:@"g%@", [extras objectForKey:@"group_id"]];
                } else {
                    strCurrentID = [NSString stringWithFormat:@"u%@", [extras objectForKey:@"user_id"]];
                }
                if ([strCurrentID isEqualToString:self.messageThreadView.strCurrentID]) {
                    return NO;
                }
            }
             */
            break;
        }
        case kThreadDetail:
        {
            /*
            NSInteger notifyID = 0;
            NSInteger currentID = 0;
            if ([[extras objectForKey:@"group_id"] intValue] > 0) {
                notifyID = [[extras objectForKey:@"group_id"] intValue];
                currentID = [[self.threadDetail.dictPerson objectForKey:@"group_id"] intValue];
            } else {
                notifyID = [[extras objectForKey:@"user_id"] intValue];
                currentID = [[self.threadDetail.dictPerson objectForKey:@"friend_id"] intValue];
            }
            if (notifyID == currentID) {
                return NO;
            }
             */
            break;
        }
        default:
            break;
    }
    
    return YES;
}

- (void)openMessageView {
    //[self replaceWithView:kThreadDetail];
    [self hideNotificationHUD:nil];
}

- (void)openGroupsView {
    //[self replaceWithView:kViewGroups];
    [self hideNotificationHUD:nil];
}

- (void)openFriendsView {
    //[self replaceWithView:kViewFriends];
    [self hideNotificationHUD:nil];
}

- (void)pushNotificationReceivedExternal:(NSDictionary *)userInfo
{
    
    NSDictionary *extras = [userInfo objectForKey:@"extra"];
    NSString *action = [extras objectForKey:@"action"];
    
    if ([action isEqualToString:NEW_MESSAGE_NOTIFICATION] ||
        [action isEqualToString:FRIEND_REQUEST_NOTIFICATION]) {
        [self getUnreadCount];
        
        
        MessageThreadDetailView *messageThread = [[MessageThreadDetailView alloc] initWithNibName:@"MessageThreadDetailView" bundle:nil];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSString *pushUserId = [extras objectForKey:@"user_id"];
        NSString *pushGroupId = [extras objectForKey:@"group_id"];
        
       // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setObject:pushUserId forKey:@"PushedUser"];
        [defaults setObject:pushGroupId forKey:@"PushedGroup"];
        
        
        if([pushUserId intValue] > 0){
            toID = [pushUserId intValue];
        }
        else{
            toID = [pushGroupId intValue];
        }
        [dict setObject:pushUserId forKey:kFriendKey];
        [dict setObject:pushGroupId forKey:@"group_id"];
        
        messageThread.openFromRoot = YES;
        messageThread.dictPerson = dict;
        messageThread.toID = toID; //New added
        messageThread.socialToID = socialToID; //New added
        [self.navigationController pushViewController:messageThread animated:YES];
    }
    else if([action isEqualToString:ADDED_TO_GROUP_NOTIFICATION])
    {
        //Redirect user to notification view if we found any group invitation
        //[self notificationButtonPressed:nil];
        
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        
        NSString *message = [aps objectForKey:@"alert"];
        
        NotificationsView *notif = [[NotificationsView alloc] initWithNibName:@"NotificationsView" bundle:nil showPendingFriends:NO];
        notif.isGroupInvitationArrived = YES;
        notif.notifyMessage = message;
        notif.isExternalPush = YES;
        [self.navigationController pushViewController:notif animated:YES];
    }
    else if([action isEqualToString:FRIEND_ADDED])
    {
        //Redirect user to notification view if we found any group invitation
        //[self notificationButtonPressed:nil];
         [self refreshTapped];
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        
        NSString *message = [aps objectForKey:@"alert"];
        
        NotificationsView *notif = [[NotificationsView alloc] initWithNibName:@"NotificationsView" bundle:nil showPendingFriends:NO];
        notif.isFriendPushNotify = YES;
        notif.notifyMessage = message;
        notif.isExternalPushFrnd = YES;
        [self.navigationController pushViewController:notif animated:YES];
    }
    else {
        // user added to group or friend request accepted
        [self refreshTapped];
    }
}
- (void)pushNotificationReceived:(NSDictionary *)userInfo {
    
    NSDictionary *extras = [userInfo objectForKey:@"extra"];
    NSString *action = [extras objectForKey:@"action"];
    
    
    //Play sound
    SystemSoundID pushSound;
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty (kAudioSessionProperty_AudioCategory,
                             sizeof (sessionCategory),
                             &sessionCategory);
    
    CFURLRef soundFileURLRef = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("sound"), CFSTR("caf"), NULL);
    AudioServicesCreateSystemSoundID(soundFileURLRef, &pushSound);
    CFRelease(soundFileURLRef);
    AudioServicesPlaySystemSound(pushSound);
    
    if ([action isEqualToString:NEW_MESSAGE_NOTIFICATION] ||
        [action isEqualToString:FRIEND_REQUEST_NOTIFICATION]) {
        
       
   
        
        [self getUnreadCount];
    }
    else if([action isEqualToString:ADDED_TO_GROUP_NOTIFICATION])
    {
        //Redirect user to notification view if we found any group invitation
        //[self notificationButtonPressed:nil];
        
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        
        NSString *message = [aps objectForKey:@"alert"];
        
        NotificationsView *notif = [[NotificationsView alloc] initWithNibName:@"NotificationsView" bundle:nil showPendingFriends:NO];
        notif.isGroupInvitationArrived = YES;
        notif.notifyMessage = message;
        [self.navigationController pushViewController:notif animated:YES];
    }
    else if([action isEqualToString:FRIEND_ADDED])
    {
        //Redirect user to notification view if we found any group invitation
        //[self notificationButtonPressed:nil];
         [self refreshTapped];
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        
        NSString *message = [aps objectForKey:@"alert"];
        
        NotificationsView *notif = [[NotificationsView alloc] initWithNibName:@"NotificationsView" bundle:nil showPendingFriends:NO];
        notif.isFriendPushNotify = YES;
        notif.notifyMessage = message;
        [self.navigationController pushViewController:notif animated:YES];
    }
    else {
        // user added to group or friend request accepted
        [self refreshTapped];
    } 
    
    // TODO JMR
    /*
    if (!notificationHUD) {
        notificationHUD = [[NotificationHUD alloc] initWithTarget:self];
    }
    
    [notificationHUD setWithUserInfo:userInfo];
    NSDictionary *extras = [userInfo objectForKey:@"extra"];
    
    if ([self acceptingNotificationsForDictionary:extras]) {
        if ([[extras objectForKey:@"action"] isEqualToString:@"message"]) {
            [notificationHUD addAction:@selector(openMessageView)];
        } else if ([[extras objectForKey:@"action"] isEqualToString:@"group"]) {
            [notificationHUD addAction:@selector(openGroupsView)];
        } else {
            [notificationHUD addAction:@selector(openFriendsView)];
        }
        [notificationHUD setHidden:NO animate:YES];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification" object:nil userInfo:userInfo];
    }
     */
}

- (void)hideNotificationHUD:(NSNotification *)notification {
    BOOL animate = YES;
    if (notification) {
        NSDictionary *userInfo = (NSDictionary *)[notification userInfo];
        animate = [[userInfo objectForKey:@"animate"] boolValue];
    }
    if (notificationHUD) {
        [notificationHUD setHidden:YES animate:animate];
    }
}

#pragma mark - Process external notifications

- (void)openPendingFriends
{
    NotificationsView *notif = [[NotificationsView alloc] initWithNibName:@"NotificationsView" bundle:nil showPendingFriends:YES];
    
    // TODO set invitations
    
    
    [self.navigationController pushViewController:notif animated:NO];
}

- (void)openMessageThreadDetail
{
    MessageThreadDetailView *messageThread = [[MessageThreadDetailView alloc] initWithNibName:@"MessageThreadDetailView" bundle:nil];
    //NSDictionary *dict = [self.arrCellData objectAtIndex:selectedIndex];
    //messageThread.dictPerson = dict;
    messageThread.openFromRoot = YES;
    [self.navigationController pushViewController:messageThread animated:NO];
}

- (void)openGroups
{
    FriendsListView *groupsList = [[FriendsListView alloc] initWithNibName:@"FriendsListView" bundle:nil];
    [groupsList setGroupFriend:@"Groups"];
    [self.navigationController pushViewController:groupsList animated:NO];
}

- (void)createRefreshButton
{
    bttnRefresh = [UIButton buttonWithType:UIButtonTypeCustom];
    //[bttnRefresh setFrame:CGRectMake(10, 370, 44, 44)];
    [bttnRefresh setFrame:CGRectMake(10, 120, 44, 44)];
    [bttnRefresh setImage:[UIImage imageNamed:@"bttn_refresh"] forState:UIControlStateNormal];
    [bttnRefresh setBackgroundColor:[UIColor clearColor]];
    [bttnRefresh addTarget:self action:@selector(refreshTapped) forControlEvents:UIControlEventTouchUpInside];
    bttnRefresh.alpha = .5;
    bttnRefresh.adjustsImageWhenHighlighted = NO;
    //[self.view addSubview:bttnRefresh];
    [self.view addSubview:bttnRefresh];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    _showDeleteTag = NO;
    [self.homeTableView reloadData];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark - Twitter Trick

- (UIView *)findFirstResponderInView:(UIView*) view
{
    if (view.isFirstResponder)
    {
        return view;
    }
    
    for (UIView *subview in view.subviews)
    {
        UIView *result = [self findFirstResponderInView:subview];
        if (result)
        {
            return result;
        }
    }
    return nil;
}

- (void) handleKeyboardWillShow:(NSNotification *) notification;
{
    UIView *fr = [self findFirstResponderInView:self.tweetSheet.view];
    if ([fr isKindOfClass:[UITextView class]])
    {
        UITextView *tv = (UITextView *) fr;
        [tv setSelectedRange:NSMakeRange(0,0)];
    }
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource
{
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	isLoading = YES;
    [self refreshTapped];
}

- (void)doneLoadingTableViewData
{
	//  model should call this when its done loading
	isLoading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.homeTableView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return isLoading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [NSDate date]; // should return date data source was last changed
}


@end

@interface HomeView (PrivateMethods)

- (void)loadScrollViewWithPage:(int)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;

@end