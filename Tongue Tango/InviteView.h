//
//  InviteView.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/7/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import "FacebookHelper.h"

@interface InviteView : UIViewController <UIAlertViewDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, AVAudioPlayerDelegate, AVAudioSessionDelegate>
{
    id delegate;
    NSUserDefaults *defaults;
    NSDictionary *dictPerson;
    NSIndexPath *sentIndexPath;
    
    NSMutableArray *arrCellData;
    NSMutableData *responseData;
    
    AVAudioPlayer *avPlayer;
    AVAudioSession *audioSession;
    
    NSString *strFullName;
    NSString *strEmail;
    NSString *strPhone;
    NSInteger rowNumber;
    
    UIWebView *videoView;
    FacebookHelper *fbHelper;
    BOOL loadedWeb;
    BOOL audioIsPlaying;
}

@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) NSString *audioURL;
@property (strong, nonatomic) NSDictionary *dictPerson;
@property (strong, nonatomic) NSIndexPath *sentIndexPath;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) NSMutableArray *arrCellData;

@property (strong, nonatomic) IBOutlet UITableView *tableInvites;
@property (strong, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (strong, nonatomic) FacebookHelper *fbHelper;

@property (strong, nonatomic) IBOutlet UIButton *bttnClose;
@property (strong, nonatomic) IBOutlet UIButton *bttnTapAway;

- (void)sendEmailWithURL:(NSString *)_audioURL;
- (void)sendEmail;
- (void)sendSMS;
- (void)closeView;
- (void)openEmailComposer;
- (void)openSMSComposer;

- (IBAction)playVideo;
- (void)embedYouTube:(NSString *)urlString frame:(CGRect)frame;
- (void)proximityChanged:(NSNotification *)notification;
- (void)resetEmail;

@end

@protocol RequestingView <NSObject>
@optional
- (void)makeFriend:(NSDictionary *)dict indexPath:(NSIndexPath *)index;
@end