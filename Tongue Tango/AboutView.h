//
//  AboutView.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/29/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface AboutView : UIViewController <MFMailComposeViewControllerDelegate> {
    NSInteger shakeCount;
    BOOL shakeNow;
}

@property (strong, nonatomic) IBOutlet UIButton *bttnWebsite;
@property (strong, nonatomic) IBOutlet UIButton *bttnFacebook;
@property (strong, nonatomic) IBOutlet UIButton *bttnTwitter;
@property (strong, nonatomic) IBOutlet UIButton *bttnOpenFeedback;
@property (strong, nonatomic) IBOutlet UIButton *bttnTerms;
@property (strong, nonatomic) IBOutlet UIImageView *imgTT;


- (IBAction)openLink:(id)sender;
- (IBAction)openFeedback:(id)sender;
- (void)openRateThisApp;
- (void)openFeedbackEmail;

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event;
- (BOOL)canBecomeFirstResponder;
- (void)triggerNow;
- (void)stopNow;

@end
