//
//  MessageThreadDetailView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioMessages.h"
#import "CoreDataClass.h"
#import "HomeView.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"

@interface MessageThreadDetailView : UIViewController <AVAudioPlayerDelegate, AVAudioSessionDelegate,AVAudioRecorderDelegate>
{
    NSDictionary *dictPerson;
    NSMutableDictionary *dictPeople;
    NSMutableDictionary *dictFavorites;
    UIImage *defaultImage;
    UIImage *myUserImage;
    AVAudioPlayer *avPlayer;
    AVAudioSession *audioSession;
    NSInteger currentThemeID, downloadCount, currentMicID;

    NSUserDefaults *defaults;
    BOOL downloadError;
    BOOL boolPushed;
    
    NSMutableDictionary *dictDownloadImages;
    NSMutableDictionary *dictDownloadAudio;
    NSTimer *refreshTimer;
    float angle;
    
    //Audion Player
    BOOL isPlaying;
    NSString *recorderFilePath;
    
    AVAudioRecorder *recorder_ ;
	BOOL isAudioSetUp_ ;
    
    NSString *newFileName;
    NSInteger groupID;
}

@property (strong,nonatomic) NSString *socialToID;
@property (nonatomic) NSInteger toID;
@property (nonatomic) BOOL openFromRoot;
@property (strong, nonatomic) NSDictionary *dictPerson;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong, nonatomic) NSString *currentMessage;

@property (strong, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (strong, nonatomic) IBOutlet UIView *msgButtonBar;
@property (strong, nonatomic) IBOutlet UIButton *buttonRecord;
@property (strong, nonatomic) IBOutlet UIButton *buttonText;
@property (strong, nonatomic) IBOutlet UIButton *buttonCamera;
@property (strong, nonatomic) IBOutlet UITableView *tableThread;
@property (strong, nonatomic) IBOutlet UIImageView *imageBG;
@property (strong, nonatomic) UIButton *bttnRefresh;

@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong, nonatomic) ServerConnection *serverConnection;
@property (nonatomic, assign) NSInteger iMaxNumberOfMessages;


@property (strong, nonatomic) IBOutlet UIImageView *imageMicrophone;
@property (strong, nonatomic) IBOutlet UIView *viewMicBG;
#pragma mark - Record View
@property (strong, nonatomic) IBOutlet UIButton *bttnDelete;
@property (strong, nonatomic) IBOutlet UIButton *bttnPreview;
@property (strong, nonatomic) IBOutlet UIButton *bttnRecord;
@property (strong, nonatomic) IBOutlet UIButton *bttnSend;
@property (strong, nonatomic) IBOutlet UIImageView *imageRecTab;
@property (strong, nonatomic) IBOutlet UIView *viewRecord;


- (void)reloadTable;
- (IBAction)openHomeView:(id)sender;
- (void)scrollToBottom:(BOOL)animated;
- (void)requestSomeMessagesForUser;
- (void)requestSomeMessagesForGroup;

- (IBAction)refreshTapped;
- (void)rotateRefresh;
- (void)hadleTimer:(NSTimer *)timer;

- (void)proximityChanged:(NSNotification *)notification;
- (void)createMenuButton;

- (void)populateTableCellData;
- (void)requestSetToRead:(NSArray *)messages;

// Download images and audio
- (BOOL)requestAudioFiles:(NSDictionary *)message withLabel:(UILabel *)label;
- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath;

- (void)pushNotificationReceived:(NSDictionary *)userInfo;

@end
