 //
//  MessageThreadDetailView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "MessageThreadDetailView.h"
#import "ManagedObjectValues.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "UAPush.h"

#define INVALID_DATA_TAG                        1000

#define kLoadMore                               @"Load More"
#define kNumberOfMessagesToFetchPerTurn         10

static NSDateFormatter *sUserVisibleDateFormatter;

@implementation MessageThreadDetailView

@synthesize dictPerson;
@synthesize arrCellData;
@synthesize dictDownloadImages;
@synthesize currentMessage;
@synthesize labelSubtitle;
@synthesize msgButtonBar;
@synthesize buttonRecord;
@synthesize buttonText;
@synthesize buttonCamera;
@synthesize tableThread;
@synthesize imageBG;
@synthesize bttnRefresh;
@synthesize coreDataClass;
@synthesize openFromRoot;
@synthesize serverConnection;

@synthesize imageMicrophone;
@synthesize viewMicBG;

@synthesize bttnDelete;
@synthesize bttnPreview;
@synthesize bttnRecord;
@synthesize bttnSend;
@synthesize imageRecTab;
@synthesize viewRecord;

@synthesize socialToID;
@synthesize toID;
@synthesize iMaxNumberOfMessages = _iMaxNumberOfMessages;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)createRefreshButton
{
    bttnRefresh = [UIButton buttonWithType:UIButtonTypeCustom];
    [bttnRefresh setFrame:CGRectMake(280, 0, 36, 36)];
    [bttnRefresh setImage:[UIImage imageNamed:@"bttn_refresh"] forState:UIControlStateNormal];
    [bttnRefresh setBackgroundColor:[UIColor clearColor]];
    [bttnRefresh addTarget:self action:@selector(refreshTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bttnRefresh];
}

- (void)createEditButton
{
    //>     Add Edit button on top bar
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(btnEdit_Pressed)];

    self.navigationItem.rightBarButtonItem = button;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    DLog(@"View did load");
    [FlurryAnalytics logEvent:@"Visited Message Details View."];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    serverConnection = [ServerConnection sharedInstance];
    
    currentThemeID = [defaults integerForKey:@"ThemeID"];
    
    // Set the backbround image for this view
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
    
    [self createRefreshButton];
    
    //>     Create Edit button on top bar
    [self createEditButton];
    
    // Disable the selection of rows
    self.tableThread.allowsSelection = NO;
    
    // Set a default user image
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
    
    NSString *theFilePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:theFilePath])
    {
        myUserImage = [UIImage imageWithContentsOfFile:theFilePath];
    }
    else
    {
        myUserImage = defaultImage;
    }
    
    dictDownloadAudio = [[NSMutableDictionary alloc] init];
    dictFavorites = [[NSMutableDictionary alloc] init];
    coreDataClass = [CoreDataClass sharedInstance];
    
    // Set the audio player
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendText" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:@"sendText" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendAudio" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAfterNewMessage) name:@"sendAudio" object:nil];
    
    [bttnRecord setBackgroundImage:[UIImage imageNamed:@"bttn_record"] forState:UIControlStateNormal];
    [bttnRecord setBackgroundImage:[UIImage imageNamed:@"bttn_record_pressed"] forState:UIControlStateHighlighted];

    DLog(@"View did load finish");
}

- (void)viewDidUnload
{
    [self setLabelSubtitle:nil];
    [self setMsgButtonBar:nil];
    [self setButtonRecord:nil];
    [self setButtonText:nil];
    [self setTableThread:nil];
    [self setButtonCamera:nil];
    
    
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    
    DLog(@"viewDidAppear");
    if (([[dictPerson valueForKey:kFriendKey] intValue] == 0) && 
        ([[dictPerson valueForKey:@"group_id"] intValue] == 0)) {
        
        
        DLog(@"kFriendKey %d", [[dictPerson valueForKey:kFriendKey] intValue]);
        DLog(@"group_id %d", [[dictPerson valueForKey:@"group_id"] intValue]);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"INVALID THREAD DETAIL DATA", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        alert.tag = INVALID_DATA_TAG;
        [alert show];
    }
    
    // Scroll to the bottom of the table;
    [self scrollToBottom:YES];
    
    if ([defaults integerForKey:@"ThemeID"] != currentThemeID) {
        // Set the backbround image for this view
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DLog(@"viewWillAppear");
    //    if ([[defaults objectForKey:@"PushedUser"] intValue] > 0 || [[defaults objectForKey:@"PushedGroup"] intValue] > 0) {
    if (openFromRoot)
    {
        openFromRoot = NO;
        [self createMenuButton];
        
        NSMutableDictionary *newDict;
        
        if ([[defaults objectForKey:@"PushedUser"] intValue] > 0)
        {
            NSString *where = [NSString stringWithFormat:@"user_id = %i",[[defaults objectForKey:@"PushedUser"] intValue]];
            NSArray *arrTemp = [coreDataClass searchEntity:@"People" Conditions:where Sort:@"" Ascending:YES andLimit:1];
            if ([arrTemp count] > 0)
            {
                NSMutableDictionary *tempDict = [[coreDataClass convertToDict:arrTemp] objectAtIndex:0];
                newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [tempDict objectForKey:@"first_name"], @"first_name",
                           [tempDict objectForKey:@"last_name"], @"last_name",
                           [tempDict objectForKey:@"user_id"], @"user_id",
                           @"0", @"group_id",
                           nil];
            }
        }
        else
        {
            NSString *where = [NSString stringWithFormat:@"id = %i",[[defaults objectForKey:@"PushedGroup"] intValue]];
            NSArray *arrTemp = [coreDataClass searchEntity:@"Groups" Conditions:where Sort:@"" Ascending:YES andLimit:1];
            NSMutableDictionary *tempDict = [[coreDataClass convertToDict:arrTemp] objectAtIndex:0];
            newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                       [tempDict objectForKey:@"name"], @"first_name",
                       @"", @"last_name",
                       @"0", @"friend_id",
                       [tempDict objectForKey:@"id"], @"group_id",
                       nil];
        }
        
        [defaults setInteger:0 forKey:@"PushedGroup"];
        [defaults setInteger:0 forKey:@"PushedUser"];
        dictPerson = [NSDictionary dictionaryWithDictionary:newDict];
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
    
    if (([[dictPerson valueForKey:kFriendKey] intValue] == 0) && 
        ([[dictPerson valueForKey:@"group_id"] intValue] == 0))
    {
        DLog(@"invalid data, logged with diff user");
        self.labelSubtitle.text = @"";
    }
    else
    {
        // Get the name for the person or group
        self.labelSubtitle.text = [NSString stringWithFormat:@"%@ %@",[dictPerson valueForKey:@"first_name"],[dictPerson valueForKey:@"last_name"]];
        
        [self populateTableCellData];
        [self.tableThread reloadData];
        
        if (self.arrCellData.count > 0)
        {
             DLog(@"self.arrCellData.count > 0");
            //>---------------------------------------------------------------------------------------------------
            //>     We already downloaded some messages, so just hit a reload/refresh
            //>---------------------------------------------------------------------------------------------------
            [self refreshTapped];
            
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
        }
        else
        {
            DLog(@"self.arrCellData.count > 0 - ELSE");
            //>---------------------------------------------------------------------------------------------------
            //>     No messages downloaded, so go and download first kNumberOfMessagesToFetchPerTurn messages
            //>---------------------------------------------------------------------------------------------------
            [self downloadMoreMessages];
            
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
        }
    }
    
    // Scroll to the bottom of the table;
    [self scrollToBottom:NO];
    
    [self setupAudioForRecordingIfNeeded];
    
    [self markThreadAsRead];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendText" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendAudio" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadGroupMessages" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadFriendMessages" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadMoreGroupMessages" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadMoreFriendMessages" object:nil];
    //loadMoreFriendMessages
    
    avPlayer = nil;
    currentMessage = nil;
}

- (void)createMenuButton
{
    UIImage *image = [UIImage imageNamed:@"icon_menu"];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(toggleMove)];
    self.navigationItem.leftBarButtonItem = button;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)scrollToBottom:(BOOL)animated
{
    NSInteger cellCount = [self.arrCellData count];
    if (cellCount > 0) {
        NSIndexPath* ipath = [NSIndexPath indexPathForRow:cellCount - 1 inSection: 0];
        [self.tableThread scrollToRowAtIndexPath:ipath atScrollPosition: UITableViewScrollPositionTop animated:animated];
    }
}

- (void)proximityChanged:(NSNotification *)notification
{
    DLog(@"Proximity Change in Message");
    
	UIDevice *device = [notification object];
    if (device.proximityState == 1)
    {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        DLog(@"Ear speaker enabled");
    }
    else
    {
        DLog(@"Ear speaker disabled");
        
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


#pragma mark - Show Hide Micro Phone Animation


-(void)handleBackButton :(id) sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createBackButton
{
    self.navigationItem.leftBarButtonItem = nil;
}


- (void)handleCancelButton:(id)sender
{
    imageMicrophone.hidden = YES;
        [self hideMicrophone:nil];
    //    [self hideKeyboard:nil];
    
}

- (void)createCancelButton
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(handleCancelButton:)];
    self.navigationItem.leftBarButtonItem = button;
}

- (void)showMicrophoneAnimated:(BOOL)animated
{
    imageMicrophone.hidden = NO;
    
    // Hide the notification if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:nil];
    viewRecord.alpha = 1;

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
                              tableThread.alpha = 0;
                              msgButtonBar.alpha = 0;
                              viewMicBG.alpha = 1;
                              bttnRefresh.alpha = 0;
                              
                              [self.navigationItem setRightBarButtonItem:nil];
                          }
                          completion:^(BOOL finished){
                              
                              [self createCancelButton];
                          }];
    }
    else
    {
        imageMicrophone.center = CGPointMake(160, deviceFrame.size.height - 260);
        viewRecord.center = CGPointMake(160, deviceFrame.size.height - 118);
        //imageMicrophone.center = CGPointMake(160, 220);
        //viewRecord.center = CGPointMake(160, 362);
        viewMicBG.alpha = 1;
        bttnRefresh.alpha = 0;
        tableThread.alpha = 0;
        msgButtonBar.alpha = 0;

        [self createCancelButton];
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (IBAction)hideMicrophone:(id)sender
{

        [UIView animateWithDuration :.5
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              imageMicrophone.center = CGPointMake(160, 497.5);
                              viewRecord.center = CGPointMake(160, 658);
                              tableThread.alpha = 1;
                              msgButtonBar.alpha = 1;
                              viewMicBG.alpha = 0;
                          
                              bttnRecord.alpha = 1;
                              bttnPreview.alpha = 0;
                              bttnSend.alpha = 0;
                              bttnDelete.alpha = 0;
                              bttnRefresh.alpha = .5;
                              imageMicrophone.hidden = YES;
                          }
                          completion:^(BOOL finished){
                              viewRecord.alpha = 0;
                          
                          }];
    [self createBackButton];
    
    //>     Create Edit button on top bar
    [self createEditButton];
}

#pragma mark - Audio

#pragma mark - Audio Setup

- (void)setupAudioForRecordingIfNeeded
{
	NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
	//[recordSetting setValue :[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
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
    if (isPlaying)
    {
        [self stopPlaying];
    }
    else
    {
        
    
        // Proximity Sensor
        
        UIDevice *device = [UIDevice currentDevice];
        
        device.proximityMonitoringEnabled = YES;
        if (device.proximityMonitoringEnabled == YES)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityChanged:) name:@"UIDeviceProximityStateDidChangeNotification" object:device];
        
        isPlaying = YES;
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        if ([defaults boolForKey:@"Speaker"])
        {
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
        avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&audioError];
		if( !audioError )
        {
			[avPlayer setDelegate:self];
			[avPlayer play];
		}
		else
        {
			DLog(@"Error initializing audio player: %@" , audioError) ;
		}
    }
}


- (void)stopPlaying
{
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    isPlaying = NO;
    [avPlayer stop];
}

- (IBAction)deletePreview:(id)sender {
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    [avPlayer stop];
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
    
   // if (fileSize < 4200) {
     if (fileSize < 14200) {
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
    else
    {
        [sUserVisibleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    [avPlayer stop];
    isPlaying = NO;
    
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
        [self hideMicrophone:nil];
        
        //>     Increase number of kCoreData_Thread_TotalNumber
        self.iMaxNumberOfMessages++;
       
        [self reloadTable];
        
        return;
    }
    
    if (toID == 1 )
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        // Send an audio message to Facebook
        NSString *url = [NSString stringWithFormat:@"%@message/facebook", kAPIURL];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setUserInfo:socialToID];
        [APIrequest setReference:@"sendAudioToFacebook"];
        [APIrequest sendFile:recorderFilePath URL:url JSON:nil];
        [self hideMicrophone:nil];
    }
    else if (toID == 2)
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        // Send an audio message to Twitter
        NSString *url = [NSString stringWithFormat:@"%@message/twitter", kAPIURL];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"sendAudioToTwitter"];
        [APIrequest sendFile:recorderFilePath URL:url JSON:nil];
        [self hideMicrophone:nil];
    }
    else
    {
        if (![self isValidFileSize:recorderFilePath])
        {
            return;
        }
        NSNumber *recipientID       = [NSNumber numberWithInt:toID];
        //NSTimeInterval secondsInMinute = 60*3;
        //NSDate *dateAhead = [[NSDate date] dateByAddingTimeInterval:secondsInMinute];
        //NSString *strFullDate       = [sUserVisibleDateFormatter stringFromDate:currentDate];
        
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
        
        //>     Increase number of kCoreData_Thread_TotalNumber
        self.iMaxNumberOfMessages++;
        
        [self reloadTable];
        
        bttnRecord.hidden = NO;
        [self hideMicrophone:nil];
    }
}


#pragma mark - Delete files from the device

- (void)deleteAudioFile:(NSNumber *)messageID
{
    // Find the audio file on the device
    
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
    
    NSString *fileName = [NSString stringWithFormat:@"Audio%@", messageID];
    
    if ([fileName length] > 0) {
        // Build the full path
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Audio%@", messageID]];
        TFLog(@"Deleting audio: %@", filePath);
        
        // Delete the audio file from the device.
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        BOOL isDir;
        if ([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
            [fileManager removeItemAtPath:filePath error:&error];
            if (error) {
                DLog(@"Unable to delete audio file: %@", [error localizedDescription]);
            }
        }
    }
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
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
//    NSLog(@"Connection failed: %@", [error description]);
    
    if ([ref isEqualToString:@"setMessageAsFavorite"]) {
        UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[userInfo objectAtIndex:0];
        [activity stopAnimating];
        
        UIButton *button = (UIButton *)[userInfo objectAtIndex:1];
        button.hidden = NO;
    }
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    // NSLog(@"connectionDidFinishLoading");
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    
    responseString = [[responseString stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"] mutableCopy];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    // NSLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"]) {
        
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"deleteMessage"]) {
        
        if ([[dictJSON objectForKey:@"deleted"] intValue] == 1) {
            NSIndexPath *indexPath = (NSIndexPath *)[userInfo objectAtIndex:0];
            
            // Remove the table data and row
            [self.arrCellData removeObjectAtIndex:indexPath.row];
            
            NSArray *deleteIndexPaths = [NSArray arrayWithObject:indexPath];
            
            [self.tableThread beginUpdates];
            [self.tableThread deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
            [self.tableThread endUpdates];
            
            // Delete from core data
            NSString *conditions = [NSString stringWithFormat:@"id = %i", [[userInfo objectAtIndex:1] intValue]];
            [coreDataClass deleteAll:@"Messages" Conditions:conditions];
            
            [self deleteAudioFile:[userInfo objectAtIndex:1]];
        }
    }
}

/**
 **     Call this after response is coming from server that new message was created
 **/
- (void)reloadAfterNewMessage
{
    //>     First reload all messages
    [self refreshTapped];
}

- (void)reloadTable
{
    [self populateTableCellData];

    [self.tableThread reloadData];
    
    // Scroll to the bottom of the table;
    [self scrollToBottom:NO];
    
    [refreshTimer invalidate];
    refreshTimer = nil;
}

- (void)reloadTableWithoutScrolling
{
    [self populateTableCellData];
    [self.tableThread reloadData];
    
    if (self.arrCellData.count > 0 && self.arrCellData.count <= kNumberOfMessagesToFetchPerTurn+1)
    {
        // Scroll to the bottom of the table;
        [self scrollToBottom:NO];
    }
    
    [refreshTimer invalidate];
    refreshTimer = nil;
}

/**
 **     This method will download kNumberOfMessagesToFetchPerTurn messages for current group
 **/
- (void)requestSomeMessagesForGroup
{
    [self rotateRefresh];

    NSString *url = [NSString stringWithFormat:@"%@message/group/%@/%d/%d", kAPIURL, [self getGroupId], self.arrCellData.count, kNumberOfMessagesToFetchPerTurn];
    
    if (self.arrCellData.count > 0)
    {
        url = [NSString stringWithFormat:@"%@message/group/%@/%d/%d", kAPIURL, [self getGroupId], self.arrCellData.count-1, kNumberOfMessagesToFetchPerTurn];
    }
    
    NSString *selector = @"loadMoreGroupMessages";
    
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 [self getGroupId], @"id",
                                 nil];
    
    NSLog(@"Dict Request SomeMessagesForGroup: %@", dictRequest);
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:selector object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableWithoutScrolling) name:selector object:nil];
    
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
}

/**
 **     This method will download kNumberOfMessagesToFetchPerTurn messages for current user
 **/
- (void)requestSomeMessagesForUser
{
    [self rotateRefresh];
    NSString *url = [NSString stringWithFormat:@"%@message/user/%@/%d/%d", kAPIURL, [self getUserId], self.arrCellData.count, kNumberOfMessagesToFetchPerTurn];
    
    if (self.arrCellData.count > 0)
    {
        url = [NSString stringWithFormat:@"%@message/user/%@/%d/%d", kAPIURL, [self getUserId], self.arrCellData.count-1, kNumberOfMessagesToFetchPerTurn];
    }
    
    NSString *selector = @"loadMoreFriendMessages";
    
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 [self getUserId], @"id",
                                 nil];
    
    NSLog(@"Dict Request SomeMessagesForUser: %@", dictRequest);
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:selector object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableWithoutScrolling) name:selector object:nil];
    
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
}

/**
 **     This method will reload all message already downloaded for a group
 **/
- (void)reloadAllMessagesForGroup
{
    [self rotateRefresh];
    
    NSString *url = [NSString stringWithFormat:@"%@message/group/%@/%d/%d", kAPIURL, [self getGroupId], 0, self.arrCellData.count];
    
    if (self.arrCellData.count <= 10)
    {
        url = [NSString stringWithFormat:@"%@message/group/%@/%d/%d", kAPIURL, [self getGroupId], 0, kNumberOfMessagesToFetchPerTurn];
    }
    
    NSString *selector = @"reloadGroupMessages";
    
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 [self getGroupId], @"id",
                                 nil];
    
    NSLog(@"Dict Request AllMessagesForGroup: %@", dictRequest);
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:selector object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:selector object:nil];
    
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
}

/**
 **     This method will reload all message already downloaded for a user
 **/
- (void)reloadAllMessagesForUser
{
    [self rotateRefresh];
    NSString *url = [NSString stringWithFormat:@"%@message/user/%@/%d/%d", kAPIURL, [self getUserId], 0, self.arrCellData.count];
    
    if (self.arrCellData.count <= 10)
    {
        url = [NSString stringWithFormat:@"%@message/user/%@/%d/%d", kAPIURL, [self getUserId], 0, kNumberOfMessagesToFetchPerTurn];
    }

    NSString *selector = @"reloadFriendMessages";
    
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 [self getUserId], @"id",
                                 nil];
    
    NSLog(@"Dict Request AllMessagesForUser: %@", dictRequest);
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:selector object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:selector object:nil];
    
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
}

- (IBAction)refreshTapped
{
    [dictDownloadAudio removeAllObjects];
    if ([[dictPerson valueForKey:kFriendKey] intValue] > 0)
    {
        [self reloadAllMessagesForUser];
    }
    else
    {
        [self reloadAllMessagesForGroup];
    }
}

- (void)downloadMoreMessages
{
    [dictDownloadAudio removeAllObjects];
    if ([[dictPerson valueForKey:kFriendKey] intValue] > 0)
    {
        [self requestSomeMessagesForUser];
    }
    else
    {
        [self requestSomeMessagesForGroup];
    }
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
	if (angle > 6.283)
    {
		angle = 0;
	}
	
	CGAffineTransform transform=CGAffineTransformMakeRotation(angle);
	bttnRefresh.transform = transform;
}

- (void)loadMore_Pressed
{
    [self downloadMoreMessages];
}

#pragma mark - Audio Message Controls

- (IBAction)openHomeView:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSInteger intSendType = button.tag;
    
    NSString *strSendType;
    switch (intSendType)
    {
        case kSendText:
            strSendType = @"TextDirect";
            
            //>     Increase number of kCoreData_Thread_TotalNumber
            self.iMaxNumberOfMessages++;
            break;
        case kSendAudio:
            strSendType = @"AudioDirect";
            break;
        default:
            break;
    }
    
    NSInteger talkingWith = [[self getUserId] intValue];
    if (talkingWith == 0) {
        talkingWith = [[self getGroupId] intValue];
        groupID = talkingWith;
        strSendType = [NSString stringWithFormat:@"%@-%@", strSendType, @"Group"];
    }
    
    if(intSendType == kSendAudio)
    {
        [self showMicrophoneAnimated:YES];
    }
    else
    {
        // Open the Home view
        HomeView *homeView = [[HomeView alloc] initWithNibName:@"HomeView" bundle:nil];
        [homeView setSendTo:talkingWith];
        [homeView setSendType:strSendType];
        [homeView setDisableMenu:YES];
        
        [homeView setUseDataSourceIndexing:YES];
        
        [self.navigationController pushViewController:homeView animated:YES];
    }
}

- (void)playMessage:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    // Proximity Sensor
    UIDevice *device = [UIDevice currentDevice];
    //device.proximityMonitoringEnabled = YES;
    device.proximityMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(proximityChanged:)
     name:@"UIDeviceProximityStateDidChangeNotification"
     object:device];
    
    UITableViewCell *cell = (UITableViewCell *)[[button.superview superview] superview];
    NSIndexPath *indexPath = [self.tableThread indexPathForCell:cell];
    
    // Get the message id
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    // Get the message file from the directory
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
    NSString *filename = [NSString stringWithFormat:@"Audio%@",[dict objectForKey:@"id"]];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:filename];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        filePath = [documentsPath stringByAppendingPathComponent:[dict objectForKey:@"message_body"]];
    }
    
    TFLog(@"Playing audio file: %@",filePath);
    
    NSData *audioFile = [NSData dataWithContentsOfFile:filePath];
    
    TFLog(@"Playing file size: %i",[audioFile length]);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        if (![currentMessage isEqualToString:filePath])
        {
            avPlayer = [[AVAudioPlayer alloc] initWithData:audioFile error:NULL];
            [avPlayer setDelegate:self];
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [avPlayer prepareToPlay];
            currentMessage = filePath;
        }
        
        if ([defaults boolForKey:@"Speaker"])
        {
            UInt32 doChangeDefaultRoute = 1;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
        }
        
        UInt32 allowBluetoothInput = 1;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                sizeof (allowBluetoothInput),
                                &allowBluetoothInput);
        
        [avPlayer play];
        //device.proximityMonitoringEnabled = YES;
        /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(proximityChanged:) 
                                                     name:@"UIDeviceProximityStateDidChangeNotification" 
                                                   object:device];*/
    }
    else
    {
        TFLog(@"File,  %@, doesn't exist",filePath);
    }
}

- (void)pauseMessage:(id)sender
{
    // Proximity Sensor
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
    
    [avPlayer pause];
    device.proximityMonitoringEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"UIDeviceProximityStateDidChangeNotification" 
                                                  object:device];
}

- (void)stopMessage:(id)sender
{
    // Proximity Sensor
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
    
    [avPlayer stop];
    device.proximityMonitoringEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"UIDeviceProximityStateDidChangeNotification" 
                                                  object:device];
    avPlayer = nil;
    currentMessage = nil;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"UIDeviceProximityStateDidChangeNotification" 
                                                  object:device];
    isPlaying = NO;
}

- (void)setMessageAsFavorite:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    // Get the cell view and cell index path
    UIView *parentView = (UIView *)button.superview;
    UIView *bubbleView = (UIView *)parentView.superview;
    UITableViewCell *cell = (UITableViewCell *)bubbleView.superview;
    NSIndexPath *indexPath = [self.tableThread indexPathForCell:cell];
    
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    NSNumber *messageId = [dict objectForKey:@"id"];
    
    // Get the core data object
    NSString *where = [NSString stringWithFormat:@"id = %@", messageId];
    NSArray *results = [coreDataClass searchEntity:@"Messages" Conditions:where Sort:@"" Ascending:NO andLimit:1];
    NSManagedObject *object = [results objectAtIndex:0];
    
    // Get the current value
    NSString *status = [dictFavorites objectForKey:messageId];
    NSNumber *favorite = nil;
    if ([status isEqualToString:@"set"])
    {
        favorite = [NSNumber numberWithInt:0];
        [button setBackgroundImage:[UIImage imageNamed:@"bttn_fave"] forState:UIControlStateNormal];
        [object setValue:[NSNumber numberWithInt:0] forKey:@"is_favorite"];
        [dictFavorites removeObjectForKey:[object valueForKey:@"id"]];
    }
    else
    {
        favorite = [NSNumber numberWithInt:1];
        [button setBackgroundImage:[UIImage imageNamed:@"bttn_fave_selected"] forState:UIControlStateNormal];
        [object setValue:[NSNumber numberWithInt:1] forKey:@"is_favorite"];
        [dictFavorites setObject:@"set" forKey:[object valueForKey:@"id"]];
    }
    [coreDataClass saveContext];
    
    // prepare the json data
    NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:favorite, @"favorite", nil];
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@message/%@", kAPIURL, messageId];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest apiCall:jsonData Method:@"POST" URL:url];
}

#pragma mark - Table View Methods

- (void)markThreadAsRead
{
    NSString *where, *peopleConditions;
    
    if ([[dictPerson valueForKey:kFriendKey] intValue] > 0)
    {
        where = [NSString stringWithFormat:@"(sender_id = %@ OR recipient_id = %@) AND group_id = 0",
                 [self getUserId],
                 [self getUserId]];
        peopleConditions = [NSString stringWithFormat:@"user_id = %@", [self getUserId]];
    }
    else
    {
        where = [NSString stringWithFormat:@"group_id = %@", [self getGroupId]];
        peopleConditions = @"";
    }
    
    // Get a list of messages
    NSArray *messages = [coreDataClass getData:@"Messages" Conditions:where Sort:@"create_date" Ascending:YES];
    
    // Add favorites to a dictionary
    [dictFavorites removeAllObjects];
    for (NSManagedObject *message in messages)
    {
        if ([[message valueForKey:@"is_favorite"] intValue] == 1)
        {
            [dictFavorites setObject:@"set" forKey:[message valueForKey:@"id"]];
        }
    }
    
    [self requestSetToRead:messages];
}

- (void)populateTableCellData
{
    NSString *where, *peopleConditions;
    
    if ([[dictPerson valueForKey:kFriendKey] intValue] > 0)
    {
        where = [NSString stringWithFormat:@"(sender_id = %@ OR recipient_id = %@) AND group_id = 0",
                 [self getUserId],
                 [self getUserId]];
        peopleConditions = [NSString stringWithFormat:@"user_id = %@", [self getUserId]];
    }
    else
    {
        where = [NSString stringWithFormat:@"group_id = %@", [self getGroupId]];
        peopleConditions = @"";
    }
    
    // Get a list of messages
    NSArray *messages = [coreDataClass getData:@"Messages" Conditions:where Sort:@"create_date" Ascending:YES];
    
    // Get a list of friends images and personIds to display
    NSArray *results = [coreDataClass getData:@"People" Conditions:peopleConditions Sort:@"" Ascending:NO];
    
    // Convert the friends into a dictionary
    dictPeople = [[NSMutableDictionary alloc] init];
    NSInteger resultCount = [results count];
    for (int i = 0; i < resultCount; i++)
    {
        NSManagedObject *objPerson = [results objectAtIndex:i];
        NSString *personPhoto   = [objPerson valueForKey:@"photo"];
        NSNumber *personId      = [objPerson valueForKey:@"id"];
        NSString *strName       = (NSString *)[objPerson valueForKey:@"first_name"];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              personId, @"id",
                              personPhoto, @"photo",
                              strName, @"name", nil];
        [dictPeople setObject:dict forKey:[objPerson valueForKey:@"user_id"]];
    }
    
    [refreshTimer invalidate];
    refreshTimer = nil;
    
    NSMutableArray *arrMessages     = [coreDataClass convertToDict:messages];
    
    //>---------------------------------------------------------------------------------------------------
    //>     I added this row in table, in order to display a button, so we can let user press it, to
    //>     load more messages if he wants
    //>---------------------------------------------------------------------------------------------------
    if (arrMessages.count > 0)
    {
        //>     Enable Edit button, if we have some messages
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        
        //>---------------------------------------------------------------------------------------------------
        //>     Check for total number of messages, and show button Load More if not all messages
        //>     were downloaded
        //>---------------------------------------------------------------------------------------------------
        if (!self.iMaxNumberOfMessages)
        {
            NSString *condition;
            
            if ([[dictPerson valueForKey:kFriendKey] intValue] > 0)
            {
                condition               = [NSString stringWithFormat:@"friend_id = %@", [dictPerson valueForKey:kFriendKey]];
            }
            else
            {
                condition               = [NSString stringWithFormat:@"group_id = %@", [dictPerson valueForKey:@"group_id"]];
            }
            
            CoreDataClass *core = [[CoreDataClass alloc] init];
            NSArray *resultThreads = [core searchEntity:@"Message_threads" Conditions:condition Sort:@"" Ascending:NO andLimit:1];
            
            if (resultThreads.count > 0)
            {
                NSManagedObject *thread             = [resultThreads objectAtIndex:0];
                self.iMaxNumberOfMessages           = [[thread valueForKey:kCoreData_Thread_TotalNumber] intValue];
            }
        }
        
        DLog(@"Max number of messages: %d", self.iMaxNumberOfMessages);
        if (arrMessages.count < self.iMaxNumberOfMessages)
        {
            NSDictionary *dictInfo          = [NSDictionary dictionaryWithObjectsAndKeys:kLoadMore, @"message_header", nil];
            [arrMessages insertObject:dictInfo atIndex:0];
        }
    }
    else
    {
       
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    
    self.arrCellData = arrMessages;
}

- (void)requestSetToRead:(NSArray *)messages
{
    NSInteger unread = [messages count];
    
    if (unread > 0)
    {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate updateUnreadMessages:[[NSUserDefaults standardUserDefaults] integerForKey:@"UnreadMessages"] - unread];
        
        // Prepare the json data
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"read", nil];
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        // Save to core data
        NSString *where;
        NSString *strFriendOrGroupID;
        
        if ([[dictPerson valueForKey:kFriendKey] intValue] > 0)
        {
            where               = [NSString stringWithFormat:@"friend_id = %@", [dictPerson valueForKey:kFriendKey]];
            strFriendOrGroupID  = [NSString stringWithFormat:@"friend/%@", [dictPerson valueForKey:kFriendKey]];
        }
        else
        {
            where               = [NSString stringWithFormat:@"group_id = %@", [dictPerson valueForKey:@"group_id"]];
            strFriendOrGroupID  = [NSString stringWithFormat:@"group/%@", [dictPerson valueForKey:@"group_id"]];
        }
        
        //>---------------------------------------------------------------------------------------------------
        //>     Ben 09/24/2012 - Ticket #87
        //>
        //>     Instead of old method, we will just send "read":1 to server for current group, so the unread
        //>     number of messages will be 0.
        //>---------------------------------------------------------------------------------------------------
        // Make the API request
        NSString *url = [NSString stringWithFormat:@"%@message/update/%@", kAPIURL, strFriendOrGroupID];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"requestSetToRead"];
        [APIrequest apiCall:jsonData Method:@"POST" URL:url];
        
        CoreDataClass *core = [[CoreDataClass alloc] init];
        NSArray *results = [core searchEntity:@"Message_threads" Conditions:where Sort:@"" Ascending:NO andLimit:1];
        if ([results count] > 0)
        {
            NSManagedObject *object = [results objectAtIndex:0];
            if ([[object valueForKey:@"unread"] intValue] > 0)
            {
                [object setValue:[NSNumber numberWithInt:0] forKey:@"unread"];
                [core saveContext];
            }
        }
        
        //>     I don't think we need this for now.
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu" object:nil];
    }
}

- (void)btnEdit_Pressed
{
    if (self.tableThread.editing)
    {
        [self.tableThread setEditing:NO animated:YES];
        
        //>     Add Edit button on top bar
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(btnEdit_Pressed)];
        
        self.navigationItem.rightBarButtonItem = button;
    }
    else
    {
        [self.tableThread setEditing:YES animated:YES];
        
        //>     Add Edit button on top bar
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(btnEdit_Pressed)];
        
        self.navigationItem.rightBarButtonItem = button;
    }
}

- (CGFloat)labelHeight:(NSString *)text
{
    CGSize constraint = CGSizeMake(198, 20000.0f);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    CGFloat height = MAX(size.height, 44.0f);
    
    return height;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
        if ([[dict objectForKey:@"message_header"] isEqualToString:kLoadMore])
        {
            return NO;
        }
    }
    
    // Return YES if you want the specified item to be editable.
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Detemine if it's in editing mode
    if (self.tableThread.editing)
    {
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get the message id
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@message/delete/%@", kAPIURL, [dict objectForKey:@"id"]];
    
    NSString *selector = @"deleteMessage";
    
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 [dict objectForKey:@"id"], @"id",
                                 nil];
    
    [[serverConnection arrRequests] addObject:dictRequest];
    [serverConnection startQueue];
    CoreDataClass *core = [[CoreDataClass alloc] init];
    
    NSString *where = [NSString stringWithFormat:@"id = %@", [dict objectForKey:@"id"]];
    NSArray *results = [core searchEntity:@"Messages" Conditions:where Sort:@"" Ascending:YES andLimit:1];
    if ([results count] > 0)
    {
        NSManagedObject *message = [results objectAtIndex:0];
        [self deleteAudioFile:[message valueForKey:@"id"]];
    }
    
    // Remove the row from the table
    [self.arrCellData removeObjectAtIndex:indexPath.row];
    NSArray *deleteIndexPaths = [NSArray arrayWithObject:indexPath];
    
    [self.tableThread beginUpdates];
    [self.tableThread deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableThread endUpdates];
    
    // Delete the thread messages from core data
    [core deleteAll:@"Messages" Conditions:where];
    
    //>     Decrease number of kCoreData_
    self.iMaxNumberOfMessages--;
    
    [core saveContext];
    
    //>---------------------------------------------------------------------------------------------------
    //>     If last message in thread was deleted, then disable Edit
    //>---------------------------------------------------------------------------------------------------
    if (self.arrCellData.count == 0)
    {
        [self.tableThread setEditing:NO];
        self.navigationItem.rightBarButtonItem  = nil;
    }
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.arrCellData count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    CGFloat height = 82;
    if ([[dict objectForKey:@"message_header"] isEqualToString:@"Text Message"])
    {
        NSString *text;
        if ([[dict objectForKey:@"message_body"] isKindOfClass:[NSString class]])
        {
            text = [dict objectForKey:@"message_body"];
        }
        else
        {
            text = @"";
        }
        
        height = [self labelHeight:text] + 33;
    }
    else
        if ([[dict objectForKey:@"message_header"] isEqualToString:kLoadMore])
        {
            height = 60;
        }
    
    return height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *TextIdentifier         = @"TextCell";
    static NSString *AudioIdentifier        = @"AudioCell";
    static NSString *LoadMoreIdentifier     = @"LoadMore";
    
    if (sUserVisibleDateFormatter == nil)
    {
        sUserVisibleDateFormatter = [[NSDateFormatter alloc] init];
        [sUserVisibleDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [sUserVisibleDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [sUserVisibleDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }
    else
    {
        [sUserVisibleDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [sUserVisibleDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [sUserVisibleDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    NSDictionary *person = [dictPeople objectForKey:[dict objectForKey:@"sender_id"]];
    
    UIButton *bttnFave, *bttnPlay, *bttnPause, *bttnStop,*bttnRefreshAudio;
    UIImageView *rowIcon, *audioView, *msgView;
    UIImageView *imgFrame;
    UILabel *msgLabel, *dateLabel, *notifyLabel, *lblFriendName;
    
    UITableViewCell *cell = nil;
    if ([[dict objectForKey:@"message_header"] isEqualToString:kLoadMore])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreIdentifier];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            //>---------------------------------------------------------------------------------------------------
            //>     We must show a button here, to let user press to load more messages
            //>---------------------------------------------------------------------------------------------------
            float cellWidth         = cell.frame.size.width;
            float cellHeight        = [self tableView:tableView heightForRowAtIndexPath:indexPath];
            float btnWidth          = 120;
            float btnHeight         = 40;
            
            UIButton *btnLoadMore   = [UIButton buttonWithType:UIButtonTypeCustom];
            [btnLoadMore setFrame:CGRectMake((cellWidth - btnWidth)/2, (cellHeight - btnHeight)/2, btnWidth, btnHeight)];
            [btnLoadMore setTitle:@"Load More" forState:UIControlStateNormal];
            [btnLoadMore setBackgroundImage:[UIImage imageNamed:@"bttn_rounded.png"] forState:UIControlStateNormal];
            [btnLoadMore addTarget:self action:@selector(downloadMoreMessages) forControlEvents:UIControlEventTouchDown];
            
            [cell.contentView addSubview:btnLoadMore];
        }
    }
    else
        if ([[dict objectForKey:@"message_header"] isEqualToString:@"Text Message"])
        {
            cell = [tableView dequeueReusableCellWithIdentifier:TextIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextIdentifier];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                // row icon
                rowIcon = [[UIImageView alloc] init];
                rowIcon.contentMode = UIViewContentModeScaleAspectFill;
                rowIcon.tag = 4000;
                [cell.contentView addSubview:rowIcon];
                
                // image frame
                imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_msg.png"]];
                imgFrame.tag = 4001;
                [cell.contentView addSubview:imgFrame];
                
                // text date
                dateLabel = [[UILabel alloc] init];
                dateLabel.font = [UIFont systemFontOfSize:12];
                dateLabel.textColor = [UIColor lightGrayColor];
                dateLabel.backgroundColor = [UIColor clearColor];
                dateLabel.tag = 4002;
                [cell.contentView addSubview:dateLabel];
                
                // friend name
                lblFriendName                   = [[UILabel alloc] init];
                lblFriendName.font              = [UIFont systemFontOfSize:12];
                lblFriendName.textColor         = [UIColor lightGrayColor];
                lblFriendName.backgroundColor   = [UIColor clearColor];
                lblFriendName.tag               = 4003;
                lblFriendName.textAlignment     = UITextAlignmentCenter;
                [cell.contentView addSubview:lblFriendName];
                
                msgView = [[UIImageView alloc] init];
                msgView.tag = 3001;
                
                // text message
                msgLabel = [[UILabel alloc] init];
                msgLabel.font = [UIFont systemFontOfSize:15];
                msgLabel.textColor = [UIColor darkGrayColor];
                msgLabel.numberOfLines = 0;
                msgLabel.backgroundColor = [UIColor clearColor];
                msgLabel.lineBreakMode = UILineBreakModeWordWrap;
                msgLabel.tag = 4004;
                [msgView addSubview:msgLabel];
                
                [cell.contentView addSubview:msgView];
            }
            else
            {
                rowIcon = (UIImageView *)[cell viewWithTag:4000];
                imgFrame = (UIImageView *)[cell viewWithTag:4001];
                dateLabel = (UILabel *)[cell viewWithTag:4002];
                lblFriendName = (UILabel *)[cell viewWithTag:4003];
                msgLabel = (UILabel *)[cell viewWithTag:4004];
                msgView = (UIImageView *)[cell viewWithTag:3001];
            }
            
            CGFloat viewXCoord, iconXCoord;
            NSString *strName;
            if ([[dict objectForKey:@"sender_id"] intValue] == [[NSUserDefaults standardUserDefaults] integerForKey:@"UserID"])
            {
                rowIcon.image = myUserImage;
                dateLabel.textAlignment = UITextAlignmentLeft;
                msgView.image = [[UIImage imageNamed:@"bg_msg_right.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
                viewXCoord = 12;
                iconXCoord = 250;
                
                strName     = [NSString stringWithFormat:@"%@", (NSString *)[defaults objectForKey:@"UserFirstName"]];
            }
            else
            {
                rowIcon.image = [self downloadCellImage:person forIndexPath:indexPath];
                dateLabel.textAlignment = UITextAlignmentRight;
                msgView.image = [[UIImage imageNamed:@"bg_msg_left.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
                viewXCoord = 72;
                iconXCoord = 10;
                strName     = [NSString stringWithFormat:@"%@", (NSString *)[person objectForKey:@"name"]];
            }
            
            NSString *text = nil;
            if ([[dict objectForKey:@"message_body"] isKindOfClass:[NSString class]])
            {
                text = [dict objectForKey:@"message_body"];
                text = [[text stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"] mutableCopy];
            }
            else
            {
                text = @"";
            }
            
            CGFloat textHeight = [self labelHeight:text];
            CGFloat cellHeight = textHeight + 33;
            
            msgLabel.text = text;
            msgLabel.frame = CGRectMake(18, 3, 198, textHeight);
            
            msgView.frame = CGRectMake(viewXCoord, 4, 236, textHeight + 8);
            
            dateLabel.text = [sUserVisibleDateFormatter stringFromDate:[dict objectForKey:@"create_date"]];
            dateLabel.frame = CGRectMake(22, (cellHeight - 22), 278, 20);
            
            // Set the contacts info
            CGFloat iconYCoord = cellHeight - 77;
            rowIcon.frame = CGRectMake(iconXCoord + 6, iconYCoord + 6, 48, 48);
            imgFrame.frame = CGRectMake(iconXCoord, iconYCoord, 60, 60);
            
            lblFriendName.frame = CGRectMake(iconXCoord, (cellHeight - 22), 60, 20);
            lblFriendName.text  = strName;
        }
        else
        {
            cell = [tableView dequeueReusableCellWithIdentifier:AudioIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AudioIdentifier];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                // row icon
                rowIcon = [[UIImageView alloc] init];
                rowIcon.contentMode = UIViewContentModeScaleAspectFill;
                rowIcon.tag = 4000;
                [cell.contentView addSubview:rowIcon];
                
                // image frame
                imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_msg.png"]];
                imgFrame.tag = 4001;
                [cell.contentView addSubview:imgFrame];
                
                // text date
                dateLabel = [[UILabel alloc] init];
                dateLabel.font = [UIFont systemFontOfSize:12];
                dateLabel.textColor = [UIColor lightGrayColor];
                dateLabel.backgroundColor = [UIColor clearColor];
                dateLabel.tag = 4002;
                [cell.contentView addSubview:dateLabel];
                
                // friend name
                lblFriendName                   = [[UILabel alloc] init];
                lblFriendName.font              = [UIFont systemFontOfSize:12];
                lblFriendName.textColor         = [UIColor lightGrayColor];
                lblFriendName.backgroundColor   = [UIColor clearColor];
                lblFriendName.tag               = 4003;
                lblFriendName.textAlignment     = UITextAlignmentCenter;
                [cell.contentView addSubview:lblFriendName];
                
                audioView = [[UIImageView alloc] initWithFrame:CGRectMake(68, 4, 236, 57)];
                audioView.userInteractionEnabled = YES;
                audioView.tag = 3000;
                
                // play button
                bttnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
                bttnPlay.frame = CGRectMake(18, 8, 49, 41);
                [bttnPlay setBackgroundImage:[UIImage imageNamed:@"bttn_play"] forState:UIControlStateNormal];
                [bttnPlay addTarget:self action:@selector(playMessage:) forControlEvents:UIControlEventTouchUpInside];
                bttnPlay.tag = 5000;
                [audioView addSubview:bttnPlay];
                
                // pause button
                bttnPause = [UIButton buttonWithType:UIButtonTypeCustom];
                bttnPause.frame = CGRectMake(67, 8, 49, 41);
                [bttnPause setBackgroundImage:[UIImage imageNamed:@"bttn_pause"] forState:UIControlStateNormal];
                [bttnPause addTarget:self action:@selector(pauseMessage:) forControlEvents:UIControlEventTouchUpInside];
                bttnPause.tag = 5001;
                [audioView addSubview:bttnPause];
                
                // stop button
                bttnStop = [UIButton buttonWithType:UIButtonTypeCustom];
                bttnStop.frame = CGRectMake(116, 8, 49, 41);
                [bttnStop setBackgroundImage:[UIImage imageNamed:@"bttn_stop"] forState:UIControlStateNormal];
                [bttnStop addTarget:self action:@selector(stopMessage:) forControlEvents:UIControlEventTouchUpInside];
                bttnStop.tag = 5002;
                [audioView addSubview:bttnStop];
                
                // favorite button
                bttnFave = [UIButton buttonWithType:UIButtonTypeCustom];
                bttnFave.frame = CGRectMake(169, 8, 49, 41);
                [bttnFave addTarget:self action:@selector(setMessageAsFavorite:) forControlEvents:UIControlEventTouchUpInside];
                bttnFave.tag = 5003;
                [audioView addSubview:bttnFave];
                
                // notify label
                notifyLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, 204, 44)];
                notifyLabel.font = [UIFont systemFontOfSize:15];
                notifyLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1];
                notifyLabel.backgroundColor = [UIColor colorWithRed:0.972 green:0.988 blue:0.988 alpha:1];
                notifyLabel.tag = 5004;
                [audioView addSubview:notifyLabel];
                
                //refresh button
                
                bttnRefreshAudio = [UIButton buttonWithType:UIButtonTypeCustom];
                [bttnRefreshAudio setBackgroundColor:[UIColor clearColor]];
                bttnRefreshAudio.frame = CGRectMake(68, 4, 236, 57);
                [bttnRefreshAudio addTarget:self action:@selector(refreshTapped) forControlEvents:UIControlEventTouchUpInside];
                bttnRefreshAudio.tag = 5005;
                [audioView addSubview:bttnRefreshAudio];
                
                [cell.contentView addSubview:audioView];
            }
            else
            {
                rowIcon = (UIImageView *)[cell viewWithTag:4000];
                imgFrame = (UIImageView *)[cell viewWithTag:4001];
                dateLabel = (UILabel *)[cell viewWithTag:4002];
                lblFriendName = (UILabel *)[cell viewWithTag:4003];
                audioView = (UIImageView *)[cell viewWithTag:3000];
                bttnFave = (UIButton *)[audioView viewWithTag:5003];
                bttnRefreshAudio = (UIButton *)[audioView viewWithTag:5005];
                notifyLabel = (UILabel *)[cell viewWithTag:5004];
            }
            
            CGFloat viewXCoord, iconXCoord;
            NSString *strName;
            if ([[dict objectForKey:@"sender_id"] intValue] == [[NSUserDefaults standardUserDefaults] integerForKey:@"UserID"])
            {
                rowIcon.image = myUserImage;
                dateLabel.textAlignment = UITextAlignmentLeft;
                audioView.image = [[UIImage imageNamed:@"bg_msg_right.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
                viewXCoord = 12;
                iconXCoord = 250;
                
                strName     = [NSString stringWithFormat:@"%@", (NSString *)[defaults objectForKey:@"UserFirstName"]];
            }
            else
            {
                rowIcon.image = [self downloadCellImage:person forIndexPath:indexPath];
                dateLabel.textAlignment = UITextAlignmentRight;
                audioView.image = [[UIImage imageNamed:@"bg_msg_left.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
                viewXCoord = 72;
                iconXCoord = 10;
                
                strName     = [NSString stringWithFormat:@"%@", (NSString *)[person objectForKey:@"name"]];
            }
            
            audioView.frame = CGRectMake(viewXCoord, 4, 236, 57);
            
            NSString *status = [dictFavorites objectForKey:[dict objectForKey:@"id"]];
            if ([[dict objectForKey:@"id"] isEqualToNumber:[NSNumber numberWithInt:0]])
            {
                [bttnFave setBackgroundImage:[UIImage imageNamed:@"bttn_fave"] forState:UIControlStateNormal];
                [bttnFave setEnabled:NO];
            }
            else
            {
                [bttnFave setEnabled:YES];
                
                if ([status isEqualToString:@"set"])
                {
                    [bttnFave setBackgroundImage:[UIImage imageNamed:@"bttn_fave_selected"] forState:UIControlStateNormal];
                }
                else
                {
                    [bttnFave setBackgroundImage:[UIImage imageNamed:@"bttn_fave"] forState:UIControlStateNormal];
                }
            }
            
            CGFloat cellHeight = 82;
            
            dateLabel.text = [sUserVisibleDateFormatter stringFromDate:[dict objectForKey:@"create_date"]];
            dateLabel.frame = CGRectMake(22, (cellHeight - 22), 278, 20);
            
            // Set the contacts info
            CGFloat iconYCoord = cellHeight - 77;
            rowIcon.frame = CGRectMake(iconXCoord + 6, iconYCoord + 6, 48, 48);
            imgFrame.frame = CGRectMake(iconXCoord, iconYCoord, 60, 60);
            
            notifyLabel.text = NSLocalizedString(@"PREPARING TO DOWNLOAD", nil);
            notifyLabel.hidden = [self requestAudioFiles:dict withLabel:notifyLabel];
            bttnRefreshAudio.hidden = notifyLabel.hidden;
            lblFriendName.frame = CGRectMake(iconXCoord, (cellHeight - 22), 60, 20);
            lblFriendName.text  = strName;
        }
    
    return cell;
}

#pragma mark - Download images and audio

- (BOOL)requestAudioFiles:(NSDictionary *)message withLabel:(UILabel *)label
{
    BOOL fileFound = NO;
    NSNumber *messageID = [message objectForKey:@"id"];
    
    // Get the message file from the directory
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
    // Does the MP3 exist
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Audio%@", messageID]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    
    TFLog(@"MP3 file, %@, doesn't exist.",filePath);
    
    // Does the WAV exist
    if ([[message objectForKey:@"message_body"] isKindOfClass:[NSString class]]) {
        filePath = [documentsPath stringByAppendingPathComponent:[message objectForKey:@"message_body"]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            fileFound = YES;
        }
    }
    
    TFLog(@"WAV file, %@, doesn't exist.",filePath);
    
    if ([[message objectForKey:@"message_path"] isKindOfClass:[NSString class]]) {
        AudioMessages *avFiles = [dictDownloadAudio objectForKey:messageID];
        if (avFiles == nil) {
            AudioMessages *avFiles = [[AudioMessages alloc] init];
            [dictDownloadAudio setObject:@"GET" forKey:messageID];
            [avFiles setDelegate:self];
            [avFiles setNotifyLabel:label];
            [avFiles audioFromURL:[message objectForKey:@"message_path"] withID:messageID andBody:[message objectForKey:@"message_body"]];
        }
    }
    else
    {
       // UIView *parentView = label.superview;
        //UIButton *audioRefresh = (UIButton *)[parentView viewWithTag:5004];
        if (fileFound == NO)
        {
            //UIView *audioView = label.
            
          //  audioRefresh.hidden = NO;
            //label.text = NSLocalizedString(@"MESSAGE IS UNAVAILABLE", nil);
            
            label.text = NSLocalizedString(@"DOWNLOAD AGAIN", nil);
            return NO;
        }
    }
    
    return fileFound;
}

- (void)audioDidDownload:(BOOL)success statusLabel:(UILabel *)label messageBody:(NSString *)body messageID:(NSNumber *)messageID
{
    [dictDownloadAudio removeObjectForKey:messageID];
    
    // Get the message file from the directory
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
    // Check for WAV file and delete it.
    if (body != nil && [body length] > 0) {
        // Build the full path
        NSString *filePath = [documentsPath stringByAppendingPathComponent:body];
        
        // Delete the audio file from the device.
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        BOOL isDir;
        if ([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
            TFLog(@"Deleting audio: %@", filePath);
            [fileManager removeItemAtPath:filePath error:&error];
            if (error) {
                DLog(@"Unable to delete audio file: %@", [error localizedDescription]);
            }
        }
    }
    
    if (success) {
        TFLog(@"Audio Successfully downloaded");
        label.hidden = YES;
    } else {
        //label.text = NSLocalizedString(@"MESSAGE DOWNLOAD FAILED", nil);
        label.text = NSLocalizedString(@"DOWNLOAD AGAIN", nil);
    }
}

- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath
{
    if (![[cellData objectForKey:@"photo"] isKindOfClass:[NSString class]]) {
        return defaultImage;
    }
    
    UIImage *local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
    if (local) {
        return local;
    }
    
    if (!dictDownloadImages) {
        self.dictDownloadImages = [[NSMutableDictionary alloc] init];
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:[cellData objectForKey:@"id"]];
    if (objImage == nil) {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = indexPath;
        objImage.personId = [cellData objectForKey:@"id"];
        objImage.delegate = self;
        objImage.saveLocally = YES;
        [dictDownloadImages setObject:objImage forKey:[cellData objectForKey:@"id"]];
        [objImage imageFromURL:[cellData objectForKey:@"photo"]];
    } else if (objImage.cachedImage) {
        return objImage.cachedImage;
    }
    
    return defaultImage;
}

- (void)imageDidFinishLoading:(NSString *)personId image:(UIImage *)image userInfo:(id)userInfo
{
    NSArray *visiblePaths = [self.tableThread indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        NSDictionary *cellData = [self.arrCellData objectAtIndex:indexPath.row];
        
        NSInteger idForCell = [[cellData objectForKey:@"sender_id"] intValue];
        NSInteger idForPerson = [personId intValue];
        
        if (idForCell == idForPerson) {
            UITableViewCell *cell = [self.tableThread cellForRowAtIndexPath:indexPath];
            UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
            rowIcon.image = image;
        }
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == INVALID_DATA_TAG) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}


- (id)getUserId
{
    return [dictPerson objectForKey:kFriendKey];
}

- (id)getGroupId
{
    return [dictPerson objectForKey:@"group_id"];
}

/* JMR
- (void)pushNotificationReceived:(NSNotification *)notification {
    [defaults setInteger:0 forKey:@"PushedGroup"];
    [defaults setInteger:0 forKey:@"PushedUser"];
    
    if ([[dictPerson valueForKey:@"group_id"] intValue] > 0) {
        [self requestAllMessagesForGroup];
    } else if ([[dictPerson valueForKey:kFriendKey] intValue] > 0) {
        [self requestAllMessagesForUser];
    }
}
*/
- (void)pushNotificationReceived:(NSDictionary *)userInfo {
    
    NSDictionary *extras = [userInfo objectForKey:@"extra"];
    NSString *action = [extras objectForKey:@"action"];
    
    if ([action isEqualToString:NEW_MESSAGE_NOTIFICATION])
    {
        NSInteger user = [[extras objectForKey:@"user_id"] intValue];
        
        if ((user > 0) && (user == [[self getUserId] intValue]))
        {
            [self refreshTapped];
        }
        else
        {
            NSInteger group = [[extras objectForKey:@"group_id"] intValue];
            if ((group  > 0) && (group == [[self getGroupId] intValue]))
            {
                [self refreshTapped];
            }
        }
    } 
}
@end
