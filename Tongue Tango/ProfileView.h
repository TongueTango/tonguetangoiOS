//
//  ProfileView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FacebookHelper.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"
#import "TwitterHelper.h"

@interface ProfileView : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate>
{
    BOOL onscreen;
    NSData *dataUserImage;
    NSMutableDictionary *dictSettings;
    NSUserDefaults *defaults;
    
    UIColor *themeColor;
    UIImage *myUserImage;
    UIImageView *cellImageView;
    UIImagePickerController* imagePickerController;
    UIActionSheet *imageActionSheet;
    
    TwitterHelper *twHelper;
    FacebookHelper *fbHelper;
    NSInteger intField;
    
    NSString *firstNameString;
    NSString *lastNameString;
    NSString *emailString;
    NSString *phoneString;
    BOOL isLogout;
    BOOL isUpdateFbUser;
}

@property (strong, nonatomic) NSMutableArray *arrProfile;
@property (strong, nonatomic) NSMutableArray *arrSocial;
@property (strong, nonatomic) NSMutableArray *arrCellData;

@property (strong, nonatomic) IBOutlet UITableView *tableProfile;
@property (strong, nonatomic) UITextField *activeField;

@property (strong, nonatomic) TwitterHelper *twHelper;
@property (strong, nonatomic) FacebookHelper *fbHelper;

@property (strong, nonatomic) IBOutlet UIButton *sociaLogoutButton;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;
@property (strong, nonatomic) IBOutlet UIButton *myThemesButton;
@property (strong, nonatomic) IBOutlet UIButton *myMicsButton;
@property (strong, nonatomic) IBOutlet UIButton *editPasswordButton;


- (void)registerForKeyboardNotifications;
- (IBAction)selectPhoto;

- (void)imagePickerController:(UIImagePickerController *)picker 
        didFinishPickingImage:(UIImage *)image 
                  editingInfo:(NSDictionary *)editingInfo;

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
- (void)setUserImage:(UIImage *)profileImage;
- (void)saveButtonTapped;
- (void)saveProfile:(BOOL)alert;

- (void)populateTableCellData;

- (IBAction)logoutAction;
- (IBAction)editPasswordAction;
- (IBAction)myThemesAction;
- (IBAction)myMicsAction;

@end