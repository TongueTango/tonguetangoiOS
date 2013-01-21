//
//  RegistrationView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "RegistrationView.h"
#import "SquareAndMask.h"
#import "CoreDataClass.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "AppDelegate.h"

#define PADDING_RIGHT 10.0


@implementation RegistrationView

@synthesize dataUserImage;
@synthesize accounts;
@synthesize imagePickerController;
@synthesize imageViewPhoto;
@synthesize fieldFirstName, fieldLastName;
@synthesize squareAndMask;
@synthesize fieldUserName;
@synthesize fieldPassword;
@synthesize fieldRetryPassword;
@synthesize fieldEmail;
@synthesize buttonPhoto;
@synthesize theHUD;
@synthesize coreDataClass;

#define ssFieldNumberCount 6

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)createContinueButton
{
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CONTINUE", nil) 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self  
                                                              action:@selector(continueSignUp)];
    self.navigationItem.rightBarButtonItem = button;
}

-(BOOL) isValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (void) continueSignUp
{
    [fieldFirstName resignFirstResponder];
    [fieldLastName resignFirstResponder];
    [fieldEmail resignFirstResponder];
    [fieldPassword resignFirstResponder];
    [fieldRetryPassword resignFirstResponder];
    [fieldUserName resignFirstResponder];
    
    NSString *textField = [fieldFirstName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // Verify at least a first name is set
    if ([textField isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO NAME TITLE", nil) 
                                                        message:NSLocalizedString(@"NO NAME MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        alert.tag = 1002;
        [alert show];
        return;
    }
    
    textField = [fieldLastName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    // Verify last name is set
    if ([textField isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO LAST NAME TITLE", nil) 
                                                        message:NSLocalizedString(@"NO LAST NAME MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        alert.tag = 1002;
        [alert show];
        return;
    }
    
    // Verify a email is valid if was texted
    textField = [fieldEmail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![textField isEqualToString:@""] && ![self isValidEmail:textField] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL_INVALID", nil) 
                                                        message:NSLocalizedString(@"INVALID EMAIL", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;     
    }  
    
    // Verify a username has been set
    textField = [fieldUserName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([textField isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO USERNAME TITLE", nil) 
                                                        message:NSLocalizedString(@"PLEASE CREATE USERNAME", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
  
    
    // Verify a password has been set
    textField = [fieldPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];    
    if ([textField isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO PASSWORD TITLE", nil) 
                                                        message:NSLocalizedString(@"NO PASSWORD MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }  
    
    // Verify a confirmation password has been set
    textField = [fieldRetryPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];    
    if ([textField isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO CONFIRMATION PASSWORD TITLE", nil) 
                                                        message:NSLocalizedString(@"NO CONFIRMATION PASSWORD MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    // Verify the confirm password matches
    textField = [fieldRetryPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![textField isEqualToString:fieldPassword.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO MATCH PASSWORD TITLE", nil) 
                                                        message:NSLocalizedString(@"NO MATCH PASSWORD MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    //Verify if image was set
    if (!isImageSet) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO IMAGE TITLE", nil) 
                                                        message:NSLocalizedString(@"NO IMAGE MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"NO THANKS", nil) 
                                              otherButtonTitles:NSLocalizedString(@"SET PICTURE", nil), nil];
        
        alert.tag = 1001;
        [alert show];
        return;
    }    

    [self setNewProfile];
     
}
- (void) setNewProfile {
    
    // Set the first name default
    [defaults setObject:fieldFirstName.text forKey:@"UserFirstName"];
    [defaults setObject:fieldLastName.text forKey:@"UserLastName"];
    [defaults setObject:fieldUserName.text forKey:@"UserUsername"];
    [defaults setObject:fieldPassword.text forKey:@"UserPassword"];
    [defaults setObject:@"" forKey:@"UserPhone"];
    [defaults setObject:fieldEmail.text forKey:@"UserEmail"];
    
    // Set other defaults not used by username and password registration
    [defaults setObject:@"" forKey:@"TWAuthData"];
    [defaults setObject:@"" forKey:@"FBIdentifier"];
    [defaults setObject:@"" forKey:@"FBAccessTokenKey"];
    
    [defaults synchronize];
    [self saveProfile];    
}

- (void) setVisibleLoadingView:(bool) isVisible {
    if (isVisible) {
        [self.navigationController.navigationBar setUserInteractionEnabled:NO];
        [theHUD show];
    } else {
        [self.navigationController.navigationBar setUserInteractionEnabled:YES];
        [theHUD hide];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Add the custom navigation bar title
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    // Delegate the name fields
    [fieldFirstName setDelegate:self];
    [fieldLastName setDelegate:self];
    [fieldEmail setDelegate:self];
    [fieldPassword setDelegate:self];
    [fieldRetryPassword setDelegate:self];
    [fieldUserName setDelegate:self];
    
    fieldFirstName.placeholder = NSLocalizedString(@"FIRST NAME", nil);
    fieldLastName.placeholder = NSLocalizedString(@"LAST NAME", nil);
    fieldEmail.placeholder = NSLocalizedString(@"EMAIL", nil);
    fieldPassword.placeholder = NSLocalizedString(@"PASSWORD", nil);
    fieldRetryPassword.placeholder = NSLocalizedString(@"CONFIRM PASSWORD", nil);
    fieldUserName.placeholder = NSLocalizedString(@"USERNAME", nil);
    
    //Padding text fields
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT, 20)];
    fieldUserName.leftView = paddingView;
    fieldUserName.leftViewMode = UITextFieldViewModeAlways;
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT, 20)];
    fieldRetryPassword.leftView = paddingView;
    fieldRetryPassword.leftViewMode = UITextFieldViewModeAlways;
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT, 20)];
    fieldPassword.leftView = paddingView;
    fieldPassword.leftViewMode = UITextFieldViewModeAlways;
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT, 20)];
    fieldEmail.leftView = paddingView;
    fieldEmail.leftViewMode = UITextFieldViewModeAlways;
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT, 20)];
    fieldFirstName.leftView = paddingView;
    fieldFirstName.leftViewMode = UITextFieldViewModeAlways;
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT, 20)];
    fieldLastName.leftView = paddingView;
    fieldLastName.leftViewMode = UITextFieldViewModeAlways;
    
    //Create continue buttom
    [self createContinueButton];
    
    // Ready the defaults
    defaults = [NSUserDefaults standardUserDefaults];
    
    squareAndMask = [[SquareAndMask alloc] init];
    isImageSet = NO;
    dataUserImage = [[NSData alloc] init];
    
    // Prepare the loading screen in case it's needed later
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"CREATING ACCOUNT", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
    
}

- (void)viewDidUnload
{
    fieldFirstName = nil;
    fieldLastName = nil;
    [self setFieldUserName:nil];
    [self setFieldPassword:nil];
    [self setFieldRetryPassword:nil];
    [self setFieldEmail:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate resetUserDefaults];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)setUserImage:(UIImage *)profileImage
{
    NSData *imageData = UIImagePNGRepresentation(profileImage);
    
    if (imageData.length > 0) {
        isImageSet = YES;
        dataUserImage = imageData;
        
        UIImage *maskedImage = [squareAndMask maskImage:profileImage];
        NSData *dataImage = UIImagePNGRepresentation(maskedImage);
        
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
        [dataImage writeToFile:filePath atomically:YES];
        [defaults setObject:filePath forKey:@"UserImage"];
        
        [buttonPhoto setBackgroundImage:[UIImage imageNamed:@"userpic_register"] forState:UIControlStateNormal];
        [imageViewPhoto setImage:maskedImage];
    }
}

- (IBAction)selectPhoto
{
    // Ask to open either the camera or the photo library
    imageActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"PICTURE ANSWER1", nil), NSLocalizedString(@"PICTURE ANSWER2", nil), nil];
    
    // Show the sheet
    [imageActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Initiate the image picker
    if (imagePickerController == nil) {
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        [imagePickerController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    }
    
    // Open either the camera or the photo library
    switch (buttonIndex) {
        case 0:
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                [imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceFront];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CAMERA UNAVAILABLE", nil)
                                                                message:NSLocalizedString(@"CAMERA NOT AVAILABLE", nil)
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                                      otherButtonTitles:nil, nil];
                [alert show];
                buttonIndex = -1;
            }
            break;
        case 1:
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        default:
            break;
    }
    if (buttonIndex == 0 || buttonIndex == 1) {
        [self presentModalViewController:imagePickerController animated:YES];
    }
}


#pragma mark - Alert View

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {

}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    // Dismiss the image selection and change the button background with the picked image
    [picker dismissModalViewControllerAnimated:YES];
    [self setUserImage:image];
    
    TFLog(@"Saved Image File Path: %@",[defaults objectForKey:@"UserImage"]);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - Keyboard Methods

// Done was selected on the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger nextTag = textField.tag + 1;

    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        [fieldFirstName resignFirstResponder];
        [fieldLastName resignFirstResponder];        
        [fieldPassword resignFirstResponder];
        [fieldRetryPassword resignFirstResponder];
        [fieldEmail resignFirstResponder];
        return YES;
    }
    
    return NO;
}

#pragma mark - Load Views

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1001) {
        [alertView dismissWithClickedButtonIndex:-1 animated:NO];
        if (buttonIndex == 0) {
            isImageSet = YES;
            [defaults setObject:@"" forKey:@"UserImage"];
            [self setNewProfile];
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        } else if (buttonIndex == 1) {
            [self selectPhoto];
        }
    }
}

- (NSString *)getUUID
{
    NSString *keychainUuid = [Keychain getStringForKey:@"com.tonguetango.uuid"];
    if (keychainUuid) {
        return keychainUuid;
    }
    
    // Create the UUID
    CFUUIDRef theUuid = CFUUIDCreate(NULL);
    NSString *deviceUuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUuid);
    [Keychain setString:deviceUuid forKey:@"com.tonguetango.uuid"];
    CFRelease(theUuid);
    
    return deviceUuid;
}


#pragma mark - Setup an account

- (void)saveProfile
{
    [self setVisibleLoadingView:YES];
    
    // Save user info to local and remote DB
    TFLog(@"First Name: %@",[defaults objectForKey:@"UserFirstName"]);
    TFLog(@"Last Name: %@",[defaults objectForKey:@"UserLastName"]);
    TFLog(@"Email: %@",[defaults objectForKey:@"UserEmail"]);
    TFLog(@"Phone: %@",[defaults objectForKey:@"UserPhone"]);
    TFLog(@"Image: %@",[defaults objectForKey:@"UserImage"]);
    TFLog(@"Username: %@",[defaults objectForKey:@"UserUsername"]);
    TFLog(@"Password: ****");
    
	// Information about the device
    UIDevice *dev = [UIDevice currentDevice];
    NSString *deviceUuid = [self getUUID];
	NSString *deviceModel = dev.model;
	NSString *deviceSystemVersion = dev.systemVersion;
    
    // Verify a device token is saved to defaults
    if (![defaults objectForKey:@"DeviceToken"]) {
        [defaults setObject:@"" forKey:@"DeviceToken"];
    }
    if (![defaults objectForKey:@"FBIdentifier"]) {
        [defaults setObject:@"" forKey:@"FBIdentifier"];
    }
    if (![defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults setObject:@"" forKey:@"FBAccessTokenKey"];
    }
    if (![defaults objectForKey:@"TWAuthData"]) {
        [defaults setObject:@"" forKey:@"TWAuthData"];
    }
    if (![defaults objectForKey:@"UserEmail"]) {
        [defaults setObject:@"" forKey:@"UserEmail"];
    }
    if (![defaults objectForKey:@"UserPhone"]) {
        [defaults setObject:@"" forKey:@"UserPhone"];
    }
    
    NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"", @"gender",
                             @"home", @"email_type",
                             @"iOS", @"device_type",
                             [defaults objectForKey:@"UserFirstName"], @"first_name",
                             [defaults objectForKey:@"UserLastName"], @"last_name",
                             [defaults objectForKey:@"UserUsername"], @"username",
                             [defaults objectForKey:@"UserPassword"], @"passwd",
                             [defaults objectForKey:@"UserEmail"], @"email_address",
                             [defaults objectForKey:@"UserPhone"], @"phone",
                             [defaults objectForKey:@"FBIdentifier"], @"facebook_id",
                             [defaults objectForKey:@"FBAccessTokenKey"], @"facebook_access_token",
                             [defaults objectForKey:@"TWAuthData"], @"twitter_auth_token",
                             [defaults objectForKey:@"DeviceToken"], @"push_token",
                             deviceUuid, @"unique_id",
                             deviceModel, @"model",
                             deviceSystemVersion, @"version",
                             nil];
    
    // Convert object to data
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    DLog(@"SENDING: %@",jsonString);
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@user/registration/",kAPIURL]; //New v2
    //NSString *url = [NSString stringWithFormat:@"%@user/",kAPIURL];
    DLog(@"URL: %@",url);
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"login"];
    [APIrequest apiCall:jsonData Method:@"POST" URL:url];
}

- (void)connectionAlert:(NSString *)message
{
    if (!message) {
        message = NSLocalizedString(@"LOGIN ERROR MESSAGE", nil);
    }
    
    DLog(@"Login Error: %@",message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SIGN IN ERROR" , nil)
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}



- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"Connection failed: %@", [error description]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR" , nil)
                                                    message:NSLocalizedString(@"UNABLE TO CONNECT", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                          otherButtonTitles:nil];
    [alert show];  
    [self setVisibleLoadingView:NO];
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    DLog(@"RESPONSE: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"]) {
        [self setVisibleLoadingView:NO];
        
        NSString *errMessage;
        if ([[dictJSON objectForKey:@"message"] isKindOfClass:[NSString class]]) {
            errMessage = [dictJSON objectForKey:@"message"];
        } else if ([[dictJSON objectForKey:@"message"] isKindOfClass:[NSDictionary class]]) {
            NSArray *values = [[dictJSON objectForKey:@"message"] allValues];
            if ([[values objectAtIndex:0] isKindOfClass:[NSString class]]) {
                errMessage = [values objectAtIndex:0];
            }
        }
        
        [self connectionAlert:errMessage];
    } else if ([ref isEqualToString:@"login"]) {
        if ([dictJSON objectForKey:@"token"]) {
            [self setVisibleLoadingView:NO];
            [defaults setInteger:[[dictJSON objectForKey:@"user_id"] intValue] forKey:@"UserID"];
            [defaults setObject:[dictJSON objectForKey:@"token"] forKey:@"UserToken"];
            
            [defaults setInteger:LoginModeTongueTango forKey:@"LoginMode"];
            
            // bug US19: name not changing
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu" object:nil];
            
            if ([dictJSON objectForKey:@"tt_friends"])
            {
                NSArray *arrFriends = [dictJSON objectForKey:@"tt_friends"];
                NSArray *arrPeople = [dictJSON objectForKey:@"fb_friends"];
                NSArray *arrPending = [dictJSON objectForKey:@"pending_friends"];
                
                // BUG US19
                // Find the directory on the device
                NSError *error = nil;
                NSFileManager *fileMgr = [NSFileManager defaultManager];
                //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
                // Loop through the friends and remove all images.
                NSArray *files = [fileMgr contentsOfDirectoryAtPath:documentsPath error:&error];
                for (NSString *file in files)
                {
                    if (![file isEqualToString:@"TongueTango.sqlite"])
                    {
                        [fileMgr removeItemAtPath:[documentsPath stringByAppendingPathComponent:file] error:&error];
                    }
                }
                
                // Loop through the friends and remove all audio.
                NSString *audioPath = [paths objectAtIndex:0];
                audioPath = [audioPath stringByAppendingPathComponent:kAudioDirectory];
                NSArray *audiofiles = [fileMgr contentsOfDirectoryAtPath:audioPath error:&error];
                for (NSString *file in audiofiles)
                {
                    if (![file isEqualToString:@"TongueTango.sqlite"])
                    {
                        [fileMgr removeItemAtPath:[documentsPath stringByAppendingPathComponent:file] error:&error];
                    }
                }

                [coreDataClass cleanDatabase];
                
                [coreDataClass addPeople:arrFriends];
                [coreDataClass addPeople:arrPeople];
                [coreDataClass addPeople:arrPending];
            }
            
            // Send the users image to the server
            if (dataUserImage.length > 0) {
                NSString *url = [NSString stringWithFormat:@"%@user",kAPIURL];
                ServerConnection *APIrequest = [[ServerConnection alloc] init];
                [APIrequest setDelegate:self];
                [APIrequest setReference:@"uploadPhoto"];
                [APIrequest sendFileWithData:dataUserImage Method:@"POST" URL:url JSON:nil fileName:@"userimage.png"];
            } else {
                [self setVisibleLoadingView:NO];
                // Sets the flag off to show the tutorial overlay
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kTutorialAlreadyDisplayed"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self showFirstSyncView];
                [self dismissModalViewControllerAnimated:YES];
            }
        } else {
            [self setVisibleLoadingView:NO];
        }
    } else if ([ref isEqualToString:@"uploadPhoto"]) {
        [self setVisibleLoadingView:NO];
        // Sets the flag off to show the tutorial overlay
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kTutorialAlreadyDisplayed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self showFirstSyncView];
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(void)showFirstSyncView
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.homeViewController.shouldOpenSync = YES;
}

@end
