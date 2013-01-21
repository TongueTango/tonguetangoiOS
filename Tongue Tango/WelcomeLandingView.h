//
//  WelcomeLandingView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/7/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RegistrationView.h"
#import "FirstSyncView.h"
#import "LoginView.h"

@interface WelcomeLandingView : UIViewController <UINavigationControllerDelegate, UIActionSheetDelegate, UITextFieldDelegate>
{
    LoginView *loginView;
    RegistrationView *registrationView;
    UIActionSheet *accountActionSheet;
    NSUserDefaults *defaults;
    NSDictionary *loginDictionary;
}

@property (strong, nonatomic) LoginView *loginView;
@property (strong, nonatomic) RegistrationView *registrationView;
@property (strong, nonatomic) IBOutlet UILabel *textWelcome;
@property (strong, nonatomic) ProgressHUD *theHUD;
@property (strong, nonatomic) FacebookHelper *fbHelper;
@property (strong, nonatomic) TwitterHelper *twHelper;
@property (strong, nonatomic) IBOutlet UIButton *btnLoginWithFB;
@property (strong, nonatomic) IBOutlet UIButton *btnLoginWithTW;
@property (strong, nonatomic) IBOutlet UIButton *btnSignUp;
@property (strong, nonatomic) IBOutlet UIButton *btbLogin;
@property (strong, nonatomic) IBOutlet UILabel *labelSignIn;
@property (strong, nonatomic) IBOutlet UILabel *labelOr;

@property (strong) NSData *dataUserImage;

@property (strong, nonatomic) CoreDataClass *coreDataClass;

- (void)openRegistration;
- (void)openLogin;
- (IBAction)shortcut;

- (IBAction)connectToFacebook:(id)sender;
- (IBAction)connectToTwitter:(id)sender;
- (IBAction)connectToTongueTango:(UIButton *)sender;
- (IBAction)sigUpTongueTango:(UIButton *)sender;


@end