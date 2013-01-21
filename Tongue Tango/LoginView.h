//
//  LoginView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/8/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FacebookHelper.h"
#import "TwitterHelper.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"
#import "KeychainItemWrapper.h"
#import "ProgressHUD.h"

@class CoreDataClass;

@interface LoginView : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    NSUserDefaults *defaults;
    
}

@property (strong, nonatomic) IBOutlet UITextField *textUsername;
@property (strong, nonatomic) IBOutlet UITextField *textPassword;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogin;


@property (strong, nonatomic) IBOutlet UIButton *bttnForgot;

@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong, nonatomic) SquareAndMask *squareAndMask;
@property (strong) ProgressHUD *theHUD;
@property (strong, nonatomic) ServerConnection *serverConnection;

- (IBAction)closeLogin;
- (IBAction)checkLogin;


- (IBAction)hideKeyboard:(id)sender;
- (IBAction)openWebsite:(id)sender;

@end
