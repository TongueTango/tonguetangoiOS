//
//  RegistrationView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SquareAndMask.h"
#import "ProgressHUD.h"
#import "KeychainItemWrapper.h"
#import "ServerConnection.h"
#import "HomeView.h"

@class UNPWEmailView;
@class EmailPhoneView;
@class CoreDataClass;


@interface RegistrationView : UIViewController <UITextFieldDelegate, UIApplicationDelegate,UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIAlertViewDelegate> 
{
    BOOL isImageSet;
    NSData *dataUserImage;
    NSUserDefaults *defaults;
    UIImagePickerController* imagePickerController;
    UIActionSheet *imageActionSheet;
    UIView *loadingScreen;
}

@property (strong, nonatomic) NSData *dataUserImage;

@property (strong, nonatomic) NSArray *accounts;
@property (strong, nonatomic) UIImagePickerController* imagePickerController;
@property (strong, nonatomic) IBOutlet UIImageView *imageViewPhoto;
@property (strong, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (strong, nonatomic) IBOutlet UITextField *fieldLastName;
@property (strong, nonatomic) IBOutlet UITextField *fieldUserName;
@property (strong, nonatomic) IBOutlet UITextField *fieldPassword;
@property (strong, nonatomic) IBOutlet UITextField *fieldRetryPassword;
@property (strong, nonatomic) IBOutlet UITextField *fieldEmail;
@property (strong, nonatomic) IBOutlet UIButton *buttonPhoto;


@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong, nonatomic) SquareAndMask *squareAndMask;
@property (strong, nonatomic) ProgressHUD *theHUD;



- (void)setUserImage:(UIImage *)profileImage;
- (void)saveProfile;
- (IBAction)selectPhoto;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
- (void)showFirstSyncView;
@end