//
//  ProfileView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "ProfileView.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "SettingsView.h"
#import "Utils.h"
#import "EditPasswordView.h"
#import "FavoritesView.h"
#import "PickThemeView.h"
#import "PickMicrophoneView.h"
#import "BlockListView.h"
#import "DeletedListView.h"
#import "ExtrasView.h"

#define USER_INFO_SECTION   0
#define FAVORITES_SECTION   1
#define BLOCKLIST_SECTION   2
//#define DELETELIST_SECTION  3
#define TWITTER_SECTION     3
#define FACEBOOK_SECTION    3
#define PASSWORD_SECTION    4


@implementation ProfileView

@synthesize arrProfile, arrSocial;
@synthesize arrCellData;
@synthesize tableProfile;
@synthesize activeField;
@synthesize twHelper;
@synthesize fbHelper;
@synthesize logoutButton;
@synthesize sociaLogoutButton;
@synthesize editPasswordButton;
@synthesize myMicsButton;
@synthesize myThemesButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
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
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Navigation bar buttons

- (void)createMenuButton
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage *image = [UIImage imageNamed:@"bttn-home"];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 2, 33, 33)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:button];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:view];
    self.navigationItem.leftBarButtonItem = barButton;
}

- (void)createSettingsButton
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
    UIImage *image = [UIImage imageNamed:@"bttn-settings.png"];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 2, 33, 33)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [view addSubview:button];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:view];
    self.navigationItem.rightBarButtonItem = barButton;
}

- (void)createNavigationButtons
{
    [self createMenuButton];
    [self createSettingsButton];
}

- (void)createCancelButton
{
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CANCEL", nil) 
                                                                  style:UIBarButtonItemStyleBordered 
                                                                 target:self 
                                                                 action:@selector(cancelAction)];
    self.navigationItem.leftBarButtonItem = barButton;
}

- (void)createDoneButton
{
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DONE", nil) 
                                                                  style:UIBarButtonItemStyleBordered 
                                                                 target:self 
                                                                 action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = barButton;
}

- (void)createEditionButtons
{
    [self createCancelButton];
    [self createDoneButton];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    isLogout = NO;
    [FlurryAnalytics logEvent:@"Visited Profile View."];
    
    // Ready the User Defaults
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Set the backbround image for this view
    self.tableProfile.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"PROFILE", nil)];
    
    // Set custom in the navigation bar
    [self createNavigationButtons];    
    
    // Start the Facebook and Twitter connection
    fbHelper = [FacebookHelper sharedInstance];
    fbHelper.delegate = self;
    twHelper = [TwitterHelper sharedInstance];
    twHelper.delegate = self;
    
    isUpdateFbUser = YES;
    
    dictSettings = [[NSMutableDictionary alloc] init];

    [self registerForKeyboardNotifications];
    [self populateTableCellData];
    
    [self.logoutButton setTitle:NSLocalizedString(@"LOGOUT BUTTON TITLE", nil) 
            forState:UIControlStateNormal];
    
    [self.editPasswordButton setTitle:NSLocalizedString(@"EDIT PASSWORD BUTTON TITLE", nil) 
                       forState:UIControlStateNormal];
    
    [self.sociaLogoutButton setTitle:NSLocalizedString(@"LOGOUT BUTTON TITLE", nil) 
                       forState:UIControlStateNormal];
    
    
    [self.myThemesButton setTitle:NSLocalizedString(@"MY THEMES", nil) 
                            forState:UIControlStateNormal];
    
    
    [self.myMicsButton setTitle:NSLocalizedString(@"MY MICS", nil) 
                            forState:UIControlStateNormal];
    
    CGPoint scrollPoint = CGPointMake(320, 800);
    [self.tableProfile setContentOffset:scrollPoint];
    //[self.tableProfile setBounds:CGRectMake(0, 0, 320, 800)];
    

}

- (void)viewDidUnload
{
    myUserImage = nil;
    dictSettings = nil;
    imagePickerController = nil;
    imageActionSheet = nil;
    
    [self setActiveField:nil];
    [self setArrCellData:nil];
    [self setArrProfile:nil];
    [self setArrSocial:nil];
    [self setTableProfile:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    intField = 0;
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeID"] == 0)
    {
        themeColor = DEFAULT_THEME_COLOR;
    }
    else
    {
        themeColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                     green:([defaults integerForKey:@"ThemeGreen"]/255.0) 
                                      blue:([defaults integerForKey:@"ThemeBlue"]/255.0) 
                                     alpha:1];
    }
    
    for(UITableViewCell *tableCell in [tableProfile subviews])
    {
        if([tableCell isKindOfClass:[UITableViewCell class]])
        {
            UILabel *valueLabel = (UILabel *)[tableCell viewWithTag:4002];
            
            valueLabel.textColor = themeColor;
        }
    }
    
    if ([fbHelper isLoggedIn])
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *theFilePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:theFilePath])
        {
            myUserImage = [UIImage imageWithContentsOfFile:theFilePath];
        }
//        else
//        {
//            [fbHelper getProfilePic];
//        }
        [fbHelper getProfilePic];
    }
    else
    {
        // Set a default user image
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
            myUserImage = [UIImage imageNamed:@"userpic_placeholder_male"];
        }
    }
    
    DLog(@"Username : %@",[defaults objectForKey:@"UserFirstName"]);
}

- (void)viewWillDisappear:(BOOL)animated
{
    /*
    if ([defaults objectForKey:@"UserToken"]) {
        [self saveProfile:NO];
    }
     */
    
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    fbHelper.delegate = self;
    twHelper.delegate = self;
    
    [self populateTableCellData];
    [self.tableProfile reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Keyboard Handling
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    tableProfile.contentInset = contentInsets;
    tableProfile.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
        [tableProfile setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    tableProfile.contentInset = contentInsets;
    tableProfile.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self createEditionButtons];
    
    activeField = textField;
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)activeField.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableProfile indexPathForCell:cell];
    
    // Scroll to the top
    [self.tableProfile scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{    
    [textField resignFirstResponder];
    activeField = nil;
}

- (void)updateTextFieldStrings:(UITextView *)textField {
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)textField.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableProfile indexPathForCell:cell];
    
    if (indexPath.section == USER_INFO_SECTION) {
        switch (indexPath.row) {
            case 0:
            {
                firstNameString = textField.text;
                break;
            }
            case 1:
            {
                lastNameString = textField.text;
                break;
            }
            case 2:
            {
                emailString = textField.text;
                break;
            }
            default:
            {
                phoneString = textField.text;
                break;
            }
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    // UITableViewCell *cell = [self.tableProfile cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:USER_INFO_SECTION]];
    
    if ( [self profileDataIsValid] == NO )
        return NO;

        [self saveTextFields];
        [textField resignFirstResponder];
        [self createNavigationButtons];
        if ([defaults objectForKey:@"UserToken"])
        {
            [self saveProfile:NO];
        }
    
    return YES;
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

- (void)saveTextFields
{
    UITableViewCell *cell;
    
    for (int row = 0; row < 4; row++)
    {
        cell = [self.tableProfile cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:USER_INFO_SECTION]];
        switch (row)
        {
            case 0:
            {
                NSDictionary *dict = [self.arrProfile objectAtIndex:0];
                NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [dict objectForKey:@"title"], @"title", firstNameString, @"value", nil];
                [self.arrProfile replaceObjectAtIndex:0 withObject:newDict];
                [dictSettings setObject:firstNameString forKey:@"first_name"];
                [defaults setObject:firstNameString forKey:@"UserFirstName"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu" object:nil];
                break;
            }
            case 1:
            {
                NSDictionary *dict = [self.arrProfile objectAtIndex:1];
                NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [dict objectForKey:@"title"], @"title", lastNameString, @"value", nil];
                [self.arrProfile replaceObjectAtIndex:1 withObject:newDict];
                [dictSettings setObject:lastNameString forKey:@"last_name"];
                [defaults setObject:lastNameString forKey:@"UserLastName"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu" object:nil];
                break;
            }
            case 2:
            {
                
                
                   
                    NSDictionary *dict = [self.arrProfile objectAtIndex:2];
                    NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [dict objectForKey:@"title"], @"title", emailString, @"value", nil];
                    [self.arrProfile replaceObjectAtIndex:2 withObject:newDict];
                    [defaults setObject:emailString forKey:@"UserEmail"];
                    
                    if (emailString)
                    {
                        [dictSettings setObject:emailString forKey:@"email_address"];
                    }
                    else
                    {
                        if ([dictSettings objectForKey:@"email_address"])
                        {
                            [dictSettings removeObjectForKey:@"email_address"];
                        }
                    }
        
                    break;
                
            }
            case 3:
            {
                NSDictionary *dict = [self.arrProfile objectAtIndex:3];
                NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [dict objectForKey:@"title"], @"title", phoneString, @"value", nil];
                [self.arrProfile replaceObjectAtIndex:3 withObject:newDict];
                [defaults setObject:phoneString forKey:@"UserPhone"];
                if (phoneString)
                {
                    [dictSettings setObject:phoneString forKey:@"phone"];
                }
                else
                {
                    if ([dictSettings objectForKey:@"phone"])
                    {
                        [dictSettings removeObjectForKey:@"phone"];
                    }
                }
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

- (void)resetTextFields
{
    UITextField *textField;
    UITableViewCell *cell;
    
    for (int row = 0; row < 4; row++)
    {
        cell = [self.tableProfile cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:USER_INFO_SECTION]];
        textField = (UITextField *)[cell viewWithTag:4002];
        NSDictionary *dict = [self.arrProfile objectAtIndex:row];
        switch (row)
        {
            case 0:
            {
                firstNameString = [dict objectForKey:@"value"];
                textField.text = firstNameString;
                break;
            }
            case 1:
            {
                lastNameString = [dict objectForKey:@"value"];
                textField.text = lastNameString;
                break;
            }
            case 2:
            {
                emailString = [dict objectForKey:@"value"];
                textField.text = emailString;
                break;
            }
            default:
            {
                phoneString = [dict objectForKey:@"value"];
                textField.text = phoneString;
                break;
            }
        }
    }
}

#pragma mark - Social Login
- (IBAction)buttonTapped:(id)sender
{
    // Cancel editing
    [self cancelAction];
    
    // drill down to find the buttons parent view
    UIButton *button = (UIButton *)sender;
    UIView *parentView = (UIView *)button.superview;
    
    // find the table cell view to get the users information
    UITableViewCell *tableCell = (UITableViewCell *)parentView.superview;
    
    UIActivityIndicatorView *activity;
    // find the activity indicator for this view
    for (UIView *thisView in parentView.subviews)
    {
        if ([thisView isMemberOfClass:[UIActivityIndicatorView class]])
        {
            activity = (UIActivityIndicatorView *)thisView;
            [activity startAnimating];
        }
    }
    button.hidden = YES;
    
    NSIndexPath *indexPath = [self.tableProfile indexPathForCell:tableCell];
    
    NSLog(@"%d, %d", [defaults integerForKey:@"LoginMode"], indexPath.row);
    
    if (indexPath.section == 3)
    {
        
        [fbHelper setUserInfo:[NSArray arrayWithObjects:activity, button, nil]];
        if ([fbHelper isLoggedIn])
        {
            [fbHelper logout];
        }
        else
        {
            [fbHelper login];
        }

        
//        [twHelper setUserInfo:[NSArray arrayWithObjects:activity, button, nil]];
//        if ([twHelper isLoggedIn])
//        {
//            [twHelper logout];
//        }
//        else
//        {
//            [twHelper login];
//        }
    }
    else {
        
        [fbHelper setUserInfo:[NSArray arrayWithObjects:activity, button, nil]];
        if ([fbHelper isLoggedIn])
        {
            [fbHelper logout];
        }
        else
        {
            [fbHelper login];
        }
    }
}

- (void)twDidReturnLogout:(BOOL)success
{
    if (success)
    {
        NSArray *userInfo = [twHelper userInfo];
        UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[userInfo objectAtIndex:0];
        UIButton *button = (UIButton *)[userInfo objectAtIndex:1];
        
        [activity stopAnimating];
        [button setTitle:NSLocalizedString(@"LOGIN", nil) forState:UIControlStateNormal];
        button.hidden = NO;
        [tableProfile reloadData];
    }
}

- (void)twDidReturnLogin:(BOOL)success
{
    if (success)
    {
        NSArray *userInfo = [twHelper userInfo];
        UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[userInfo objectAtIndex:0];
        UIButton *button = (UIButton *)[userInfo objectAtIndex:1];
        
        [activity stopAnimating];
        [button setTitle:NSLocalizedString(@"LOGOUT", nil) forState:UIControlStateNormal];
        button.hidden = NO;
        
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [defaults objectForKey:@"TWAuthData"], @"twitter_auth_token",
                                 nil];
        
        // Convert object to data
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *url = [NSString stringWithFormat:@"%@user",kAPIURL];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"saveTwitter"];
        [APIrequest apiCall:jsonData Method:@"POST" URL:url];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                                        message:NSLocalizedString(@"TW ERROR", nil) 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)fbDidReturnLogout:(BOOL)success
{
    if (success)
    {
        NSArray *userInfo = [fbHelper userInfo];
        
        if ([userInfo count] > 1)
        {
            UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[userInfo objectAtIndex:0];
            [activity stopAnimating];
            
            UIButton *button = (UIButton *)[userInfo objectAtIndex:1];
            [button setTitle:NSLocalizedString(@"LOGIN", nil) forState:UIControlStateNormal];
            button.hidden = NO;
        }
        
        [defaults setBool:NO forKey:@"fb_sync"];
    }
}

- (void)fbDidReturnLogin:(BOOL)success
{
    if (success)
    {
        NSArray *userInfo = [fbHelper userInfo];
        UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[userInfo objectAtIndex:0];
        UIButton *button = (UIButton *)[userInfo objectAtIndex:1];
        
        [activity stopAnimating];
        [button setTitle:NSLocalizedString(@"LOGOUT", nil) forState:UIControlStateNormal];
        button.hidden = NO;
        
        [fbHelper getProfilePic];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                                        message:NSLocalizedString(@"FB ERROR", nil) 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)fbDidReturnRequest:(BOOL)success:(NSMutableArray *)result
{
    if (success)
    {
        
        DLog(@"Letst see result count : %d",[result count]);
        if([result count] > 0 && isUpdateFbUser)
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
            
            NSString *url = [NSString stringWithFormat:@"%@user/update/",kAPIURL];
            ServerConnection *APIrequest = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setReference:@"saveFacebook"];
            [APIrequest apiCall:jsonData Method:@"POST" URL:url];
            isUpdateFbUser = NO;
        }
    }
}

- (void)fbDidReturnProfilePic:(UIImage*)profilePic
{
    
    if(isLogout == NO)
    {
        myUserImage         = [SquareAndMask maskImage:profilePic];
        
        NSData *dataImage   = UIImagePNGRepresentation(myUserImage);
        
        //>     Save user image locally
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
        [dataImage writeToFile:filePath atomically:YES];
        [defaults setObject:filePath forKey:@"UserImage"];
        
        //>     Reload table
        [self populateTableCellData];
        [self.tableProfile reloadData];
        [fbHelper getMyInfo];
    }
}

#pragma mark - Photo Methods

- (IBAction)selectPhoto
{
    // Ask to open either the camera or the photo library
    imageActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"How would you like to set your picture?", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"Take Picture", nil), NSLocalizedString(@"Choose Picture", nil), nil];
    
    // Show the sheet
    [imageActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Initiate the image picker
    if (imagePickerController == nil)
    {
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        [imagePickerController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    }
    
    // Open either the camera or the photo library
    switch (buttonIndex)
    {
        case 0:
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES)
            {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                [imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceFront];
            }
            break;
        case 1:
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        default:
            break;
    }
    
    if (buttonIndex == 0 || buttonIndex == 1)
    {
        [self presentModalViewController:imagePickerController animated:YES];
    }
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

- (void)setUserImage:(UIImage *)profileImage
{
    dataUserImage = UIImagePNGRepresentation(profileImage);
    
    myUserImage = [SquareAndMask maskImage:profileImage];
    NSData *dataImage = UIImagePNGRepresentation(myUserImage);
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
    [dataImage writeToFile:filePath atomically:YES];
    [defaults setObject:filePath forKey:@"UserImage"];
    
    // Send the users image to the server
    NSString *url = [NSString stringWithFormat:@"%@user/update", kAPIURL];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"uploadPhoto"];
    [APIrequest sendFileWithData:dataUserImage Method:@"POST" URL:url JSON:nil fileName:@"userimage.png"];
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

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSLog(@"responseString:%@",responseString);
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    // NSLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"])
    {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"saveProfile"])
    {
        if ([userInfo boolValue])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"PROFILE UPDATED" , nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                                  otherButtonTitles:nil,
                                  nil];
            
            [alert show];
        }
    }
    else
        if ([ref isEqualToString:@"uploadPhoto"])
        {
            cellImageView.image = myUserImage;
        }
}

- (void)saveButtonTapped
{
    [self saveProfile:YES];
}

- (void)saveProfile:(BOOL)alert
{
    [activeField resignFirstResponder];

    NSDictionary *dictAPI = [NSDictionary dictionaryWithDictionary:dictSettings];
    
    // Convert object to data
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    NSLog(@"jsonString:%@",jsonString);
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
   // NSString *url = [NSString stringWithFormat:@"%@user",kAPIURL];
     NSString *url = [NSString stringWithFormat:@"%@user/update",kAPIURL]; //v2 new
    NSLog(@"url:%@",url);
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"saveProfile"];
    [APIrequest setUserInfo:[NSNumber numberWithBool:alert]];
    [APIrequest apiCall:jsonData Method:@"POST" URL:url];
}

#pragma mark - Table View

- (void)populateTableCellData
{
    // Set the properties that contain profile values
    if ([defaults integerForKey:@"LoginMode"] == LoginModeTongueTango)
    {
        self.arrProfile = [NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    NSLocalizedString(@"FIRST NAME", nil),    @"title",
                                                                    [defaults objectForKey:@"UserFirstName"], @"value", nil],
                                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    NSLocalizedString(@"LAST NAME", nil),     @"title",
                                                                    [defaults objectForKey:@"UserLastName"],  @"value", nil],
                                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    NSLocalizedString(@"EMAIL", nil),         @"title",
                                                                    [defaults objectForKey:@"UserEmail"],     @"value", nil],
                                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    NSLocalizedString(@"PHONE", nil),         @"title",
                                                                    [defaults objectForKey:@"UserPhone"],     @"value", nil],
                                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    NSLocalizedString(@"SET PICTURE", nil),   @"title",
                                                                    @"",                                      @"value", nil], nil];
        
        self.logoutButton.hidden = NO;
        self.editPasswordButton.hidden = NO;
        self.sociaLogoutButton.hidden = YES;
        
        //=>    create separate arrays for facebook and tweeter
//        self.arrSocial = [NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Twitter", @"title",
//                           [NSNumber numberWithBool:[twHelper isLoggedIn]], @"value", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", @"title",
//                                                                                            [NSNumber numberWithBool:[fbHelper isLoggedIn]], @"value", nil], nil];
    }
    else
    {
        self.arrProfile = [NSMutableArray arrayWithObjects:
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            NSLocalizedString(@"FIRST NAME", nil), @"title",
                            [defaults objectForKey:@"UserFirstName"], @"value",
                            nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            NSLocalizedString(@"LAST NAME", nil), @"title",
                            [defaults objectForKey:@"UserLastName"], @"value",
                            nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            NSLocalizedString(@"EMAIL", nil), @"title",
                            [defaults objectForKey:@"UserEmail"], @"value",
                            nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            NSLocalizedString(@"PHONE", nil), @"title",
                            [defaults objectForKey:@"UserPhone"], @"value",
                            nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            NSLocalizedString(@"PICTURE", nil), @"title",
                            @"", @"value",
                            nil],
                           nil];
        
        self.logoutButton.hidden = YES;
        self.editPasswordButton.hidden = YES;
        self.sociaLogoutButton.hidden = NO;
        
//        if ([defaults integerForKey:@"LoginMode"] == LoginModeFacebook)
//        {
//            self.arrSocial = [NSMutableArray arrayWithObjects:
//                              [NSDictionary dictionaryWithObjectsAndKeys:
//                               @"Twitter", @"title",
//                               [NSNumber numberWithBool:[fbHelper isLoggedIn]], @"value",
//                               nil],
//                              nil];
//        }
//        else
//        {
            // for twitter
            self.arrSocial = [NSMutableArray arrayWithObjects:
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               @"Facebook", @"title",
                               [NSNumber numberWithBool:[fbHelper isLoggedIn]], @"value",
                               nil], nil];
            
       // }
    }
    
    //=>    create arrays for faverite and block list cells
    NSMutableArray *arrFavorites = [NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"MY FAVORITES", nil), @"title", nil]];
    NSMutableArray *arrBlockList = [NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"My Block List", nil), @"title", nil]];
        
   // NSMutableArray *arrTwitter = [NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Twitter", @"title",[NSNumber numberWithBool:[twHelper isLoggedIn]], @"value", nil]];
    NSMutableArray *arrFacebook = [NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", @"title",
                                                                   [NSNumber numberWithBool:[fbHelper isLoggedIn]], @"value", nil]];

    // set the property that will be used to output the table
   // self.arrCellData = [NSMutableArray arrayWithObjects:arrProfile, arrFavorites, arrBlockList, arrTwitter, arrFacebook, nil];
     self.arrCellData = [NSMutableArray arrayWithObjects:arrProfile, arrFavorites, arrBlockList, arrFacebook, nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.arrCellData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.arrCellData objectAtIndex:section] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = nil;
    if (section == USER_INFO_SECTION)
    {
        sectionTitle = NSLocalizedString(@"PERSONAL INFO", nil);
    } 
    else
        if (section == PASSWORD_SECTION)
        {
            sectionTitle = NSLocalizedString(@"CHANGE PASSWORD", nil);
        }
        else
            if (section == FACEBOOK_SECTION)
            {
                sectionTitle = NSLocalizedString(@"SOCIAL NETWORKING", nil);
            }
    
    UIView *view = nil;
    
    if (sectionTitle)
    {
        NSLog(@"sectionTitle:%@",sectionTitle);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, 290, 20)];
        label.text = sectionTitle;
        label.font = [UIFont boldSystemFontOfSize:18.0];
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        
        // Create header view and add label as a subview
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
        [view addSubview:label];
    }
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat result = 30;
    if (section == FAVORITES_SECTION || section == BLOCKLIST_SECTION)
    {
        result = 0.0;
    }
    return result;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*) indexPath 
{
    if (indexPath.section == USER_INFO_SECTION && indexPath.row == 4)
    {
        return 67;
    }
    return 44;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UILabel *mainLabel;
    UIButton *socialButton;
    UITextField *textField;
    UIActivityIndicatorView *activity;
    UIImageView *rowIcon, *imgFrame;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSInteger yPos;
    
    if (indexPath.section == USER_INFO_SECTION && indexPath.row == 4)
    {
        yPos = 23;
    } 
    else
    {
        yPos = 12;
    }
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, yPos, 275, 20)];
        mainLabel.font = [UIFont boldSystemFontOfSize:17.0];
        mainLabel.textColor = [UIColor blackColor];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4000;
        [cell.contentView addSubview:mainLabel];
        
        // add button
        socialButton = [UIButton buttonWithType:UIButtonTypeCustom];
        socialButton.frame = CGRectMake(225, 5, 65, 33);
        socialButton.tag = 4001;
        socialButton.hidden = YES;
        socialButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [socialButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [socialButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [socialButton setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
        [socialButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [socialButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        [socialButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:socialButton];
        
        textField = [[UITextField alloc] initWithFrame:CGRectMake(115, 12, 175, 25)];
        textField.tag = 4002;
        textField.backgroundColor = [UIColor clearColor];
        textField.font = [UIFont systemFontOfSize:18.0];
        textField.minimumFontSize = 12;
        textField.adjustsFontSizeToFitWidth = YES;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.returnKeyType = UIReturnKeyDone;
        textField.delegate = self;
        textField.textAlignment = UITextAlignmentRight;
        //textField.backgroundColor = [UIColor redColor];
        [cell.contentView addSubview:textField];
        
        rowIcon = [[UIImageView alloc] initWithFrame: CGRectMake(235, 5, 56, 56)];
        rowIcon.contentMode = UIViewContentModeScaleAspectFill;
        rowIcon.backgroundColor = [UIColor clearColor];
        rowIcon.tag = 4003;
        [cell.contentView addSubview:rowIcon];

        // image frame
        imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_contacts.png"]];
        imgFrame.tag = 4004;
        imgFrame.frame = CGRectMake(233, 2, 62, 62);
        [cell.contentView addSubview:imgFrame];
        
        // activity indicator
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activity setCenter:socialButton.center];
        activity.tag = 4005;
        [cell.contentView addSubview:activity];
    }
    else
    {
        mainLabel = (UILabel *)[cell viewWithTag:4000];
        socialButton = (UIButton *)[cell viewWithTag:4001];
        textField = (UITextField *)[cell viewWithTag:4002];
        rowIcon  = (UIImageView *)[cell viewWithTag:4003]; 
        imgFrame = (UIImageView *)[cell viewWithTag:4004]; 
        activity = (UIActivityIndicatorView *)[cell viewWithTag:4005]; 
    }
    
    
    textField.textColor = themeColor;
    
    // Get the data for this cell
    NSDictionary *dict = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if ((indexPath.section == USER_INFO_SECTION && indexPath.row == 4))
    {
        if ([defaults integerForKey:@"LoginMode"] == LoginModeTongueTango)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundColor = [UIColor whiteColor];
        }
        else
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = PROFILE_CELL_DISABLED_BACKGROUND_COLOR;
        }
        mainLabel.textAlignment = UITextAlignmentLeft;
    } 
    else
        if (indexPath.section == USER_INFO_SECTION)
        {
            // fields are not editable for FB and twitter login
            textField.enabled = ([defaults integerForKey:@"LoginMode"] == LoginModeTongueTango);
        
            if (textField.enabled)
            {
                cell.backgroundColor = [UIColor whiteColor];
            }
            else
            {
                cell.backgroundColor = PROFILE_CELL_DISABLED_BACKGROUND_COLOR;
            }
            
            
            //Phone number enabled for facebook login
            if(indexPath.row == 3 && ([defaults integerForKey:@"LoginMode"] == LoginModeFacebook))
            {
                textField.enabled = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
        else
            if ((indexPath.section == PASSWORD_SECTION && indexPath.row == 0))
            {
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                mainLabel.textAlignment = UITextAlignmentCenter;
            }
            else
            {
                mainLabel.textAlignment = UITextAlignmentLeft;
            }
    
    if (indexPath.section == FAVORITES_SECTION || indexPath.section == BLOCKLIST_SECTION)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }   
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Personal Info
    if (indexPath.section == USER_INFO_SECTION)
    {
        textField.secureTextEntry = NO;
        socialButton.hidden = YES;
        [activity stopAnimating];
        
        if (indexPath.row < 4)
        {
            textField.hidden = NO;
            rowIcon.hidden = YES;
            imgFrame.hidden = YES;
        }
        
        switch (indexPath.row)
        {
            case 0:
                textField.placeholder = NSLocalizedString(@"FIRST NAME", nil);
                textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                textField.keyboardType = UIKeyboardTypeDefault;
                if (!firstNameString)
                {
                    firstNameString = [dict objectForKey:@"value"];
                }
                textField.text = firstNameString;
                break;
            case 1:
                textField.placeholder = NSLocalizedString(@"LAST NAME", nil);
                textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                textField.keyboardType = UIKeyboardTypeDefault;
                if (!lastNameString)
                {
                    lastNameString = [dict objectForKey:@"value"];                    
                }
                textField.text = lastNameString;
                break;
            case 2:
                if ([defaults integerForKey:@"LoginMode"] == LoginModeTongueTango)
                {
                    textField.placeholder = NSLocalizedString(@"EMAIL", nil);        
                }
                else
                {
                    textField.placeholder = nil;
                }
                textField.keyboardType = UIKeyboardTypeEmailAddress;
                if (!emailString)
                {
                    emailString = [dict objectForKey:@"value"];                    
                }
                textField.text = emailString;
                break;
            case 3:
                if ([defaults integerForKey:@"LoginMode"] == LoginModeTongueTango)
                {
                    textField.placeholder = NSLocalizedString(@"PHONE", nil);        
                }
                else
                {
                    textField.placeholder = nil;
                }
                textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                if (!phoneString)
                {
                    phoneString = [dict objectForKey:@"value"];                    
                }
                textField.text = phoneString;
                break;
            default:
                textField.hidden = YES;
                rowIcon.hidden = NO;
                imgFrame.hidden = NO;
                rowIcon.image = myUserImage;
                cellImageView = rowIcon;
                break;
        }
        [textField addTarget:self action:@selector(updateTextFieldStrings:) forControlEvents:UIControlEventEditingChanged];
        
    }
    else
    if (indexPath.section == PASSWORD_SECTION)
    {
        rowIcon.hidden = YES;
        imgFrame.hidden = YES;
        [activity stopAnimating];
        
        switch (indexPath.row)
        {
            case 0:
                textField.hidden = YES;
                break;
            default:
                textField.secureTextEntry = YES;
                textField.hidden = NO;
                socialButton.hidden = YES;
                
                if ([dict objectForKey:@"value"])
                {
                    textField.text = [dict objectForKey:@"value"];
                }
                else
                {
                    textField.text = @"";
                }
                break;
        }
        textField.text = [dict objectForKey:@"value"];
        textField.placeholder = nil;

    }
    else
    if (indexPath.section == TWITTER_SECTION || indexPath.section == FACEBOOK_SECTION )
    {
        rowIcon.hidden = YES;
        imgFrame.hidden = YES;
        textField.hidden = YES;
        socialButton.hidden = NO;
        [activity stopAnimating];
        
        if (indexPath.section == FACEBOOK_SECTION)
        {
            if ([defaults integerForKey:@"LoginMode"] == LoginModeFacebook) {
                socialButton.enabled = NO;
            }
        }
    
        if ([[dict objectForKey:@"value"] boolValue])
        {
            [socialButton setTitle:NSLocalizedString(@"LOGOUT", nil) forState:UIControlStateNormal];
        }
        else
        {
            [socialButton setTitle:NSLocalizedString(@"LOGIN", nil) forState:UIControlStateNormal];
        }
    }
    else
    if (indexPath.section == FAVORITES_SECTION || indexPath.section == BLOCKLIST_SECTION)
    {
        rowIcon.hidden = YES;
        imgFrame.hidden = YES;
        [activity stopAnimating];
        textField.hidden = YES;
    }
    
    mainLabel.text = [dict objectForKey:@"title"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == USER_INFO_SECTION && indexPath.row == 4)
    {
        [self cancelAction];
        
        if ([defaults integerForKey:@"LoginMode"] == LoginModeTongueTango)
        {
            [self selectPhoto];
        }
    }
    else
        if (indexPath.section == PASSWORD_SECTION && indexPath.row == 0)
        {
            [activeField resignFirstResponder];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"LOGOUT QUESTION", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"NOT NOW", nil)
                                              otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
            [alert show];
        }
        else
            if (indexPath.section == FAVORITES_SECTION)
            {
                [self showFavorites];
            }
            else
                if (indexPath.section == BLOCKLIST_SECTION)
                {
                    [self showBlockList];
                }
    
    //=>    deselect the cell
    [self.tableProfile deselectRowAtIndexPath:indexPath animated:YES];
}

// specify the height of your footer section
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    //differ between your sections or if you
    //have only on section return a static value
    if (section == USER_INFO_SECTION)
    {
        return 60;
    }
    else
        if (section == FACEBOOK_SECTION)
        {
            return 65;
        }
    else if (section == TWITTER_SECTION) //Newly added
            {
                return 65;
            }
    
    
    return 0;
}

// custom view for footer. will be adjusted to default or specified footer height
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    if (section == USER_INFO_SECTION)
    {
        if(footerView == nil)
        {
            //allocate the view if it doesn't exist yet
            footerView  = [[UIView alloc] init];
            
            //=>    create button for MY THEMES
            UIButton *btnMyThemes = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [btnMyThemes setFrame:CGRectMake(10, 10, 140, 45)];
            [btnMyThemes setTitle:NSLocalizedString(@"MY THEMES", nil) forState:UIControlStateNormal];
            [btnMyThemes.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
            btnMyThemes.titleLabel.textColor = [UIColor blackColor];
            [btnMyThemes addTarget:self action:@selector(myThemesAction) forControlEvents:UIControlEventTouchUpInside];
                        
            //=>    create button for MY MISC
            UIButton *btnMyMisc = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [btnMyMisc setFrame:CGRectMake(170, 10, 140, 45)];
            [btnMyMisc setTitle:NSLocalizedString(@"MY MICS", nil) forState:UIControlStateNormal];
            [btnMyMisc.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
            btnMyMisc.titleLabel.textColor = [UIColor blackColor];
            [btnMyMisc addTarget:self action:@selector(myMicsAction) forControlEvents:UIControlEventTouchUpInside];
                        
            //=>    add both buttons to the view
            [footerView addSubview:btnMyThemes];
            [footerView addSubview:btnMyMisc];
        }
    }
    else
        if (section == TWITTER_SECTION) //Previously Facebook_Section
        {
            if(footerView == nil)
            {
                //allocate the view if it doesn't exist yet
                footerView  = [[UIView alloc] init];
                
                //=>    create button for LOGOUT
                UIButton *btnLogOut = [UIButton buttonWithType:UIButtonTypeCustom];
                [btnLogOut setFrame:CGRectMake(10, 10, 300, 45)];
                [btnLogOut setImage:[UIImage imageNamed:@"logout_large_btn.png"] forState:UIControlStateNormal];
                [btnLogOut addTarget:self action:@selector(logoutAction) forControlEvents:UIControlEventTouchUpInside];
                
                [footerView addSubview:btnLogOut];
            }
        }
    
    //return the view for the footer
    return footerView;
}


#pragma mark - Alert Box Handling

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        isLogout = YES;
        // Open Welcome View via RootView
        if ([fbHelper isLoggedIn])
        {
            [fbHelper logout];
        }
        if ([twHelper isLoggedIn])
        {
            [twHelper logout];
        }
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate resetUserDefaults];
       
        [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanMemory" object:nil];
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)cancelAction
{
    [self resetTextFields];
    [activeField resignFirstResponder];
    [self createNavigationButtons];
}

//Validate Phone number
-(BOOL)validatePhoneWithString:(NSString *)phone
{
    NSString *str = @"^([0-9]+)?(\\.([0-9]{1,2})?)?$";
    NSPredicate *no = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",str];
    return [no evaluateWithObject:phone];
}
- (BOOL)profileDataIsValid
{
    BOOL result = YES;
    NSString *newFirstName = [firstNameString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *newLastName = [lastNameString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
   
     NSString *newemailString = [emailString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *newPhoneString = [phoneString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([newFirstName length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"PROFILE_ENTER_FIRST_NAME", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        result = NO;
    }
    else
        if ([newLastName length] == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"PROFILE_ENTER_LAST_NAME", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
            [alert show];
            result = NO;
        }
    
    else if ([newemailString isEqualToString:@""] || ![self isValidEmail:newemailString] || [newemailString length]==0 )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL_INVALID", nil)
                                                        message:NSLocalizedString(@"INVALID EMAIL", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil, nil];
        [alert show];
       
         result = NO;
    }
    else if([newPhoneString length] > 0)
    {
        result = [self validatePhoneWithString:newPhoneString];
        
        if(!result){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PHONE_INVALID", nil)
                                                        message:NSLocalizedString(@"INVALID PHONE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil, nil];
        [alert show];
        }
        
    }
    
        return result;
}

- (void)doneAction
{
    if ([self profileDataIsValid])
    {
        
        [self saveTextFields];
        [activeField resignFirstResponder];
        [self createNavigationButtons];
        if ([defaults objectForKey:@"UserToken"])
        {
            [self saveProfile:YES];
        }
    }
}

- (void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)settingsButtonPressed:(id)sender
{
    [self setupBackButton];
    SettingsView *settings = [[SettingsView alloc] initWithNibName:@"SettingsView" bundle:nil];
    [self.navigationController pushViewController:settings animated:YES];
}

- (void)setupBackButton
{
    // change back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"PROFILE", nil) 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:nil 
                                                                  action:nil]; 
    [[self navigationItem] setBackBarButtonItem:backButton]; 
}

- (void)logoutAction
{
    // Cancel editing
    [self cancelAction];
    
    [activeField resignFirstResponder];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"LOGOUT QUESTION", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"NOT NOW", nil)
                                          otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
    
    [alert show];
}


- (void)editPasswordAction
{
    // Cancel editing
    [self cancelAction];
    
    EditPasswordView *pwdView = [[EditPasswordView alloc] initWithNibName:@"EditPasswordView" bundle:nil];
    [self.navigationController pushViewController:pwdView animated:YES];
}

- (void)showFavorites
{
    // Cancel editing
    [self cancelAction];
    
    [self setupBackButton];
    FavoritesView *favorites = [[FavoritesView alloc] initWithNibName:@"FavoritesView" bundle:nil];
    [self.navigationController pushViewController:favorites animated:YES];
}

- (void)showBlockList
{
    // Cancel editing
    [self cancelAction];
    
    [self setupBackButton];
    BlockListView *blockList = [[BlockListView alloc] initWithNibName:@"BlockListView" bundle:nil];
    [self.navigationController pushViewController:blockList animated:YES];
}

- (void)myThemesAction
{
    // Cancel editing
    [self cancelAction];
    
    [self setupBackButton];
    
    // 2012/09/23 MOD Richard
    PickThemeView *pickThemeView = [[PickThemeView alloc] initWithNibName:@"PickThemeView" bundle:nil];
    [self.navigationController pushViewController:pickThemeView animated:YES];
    //ExtrasView *extras = [[ExtrasView alloc] initWithNibName:@"ExtrasView" bundle:nil];
    //[self.navigationController pushViewController:extras animated:YES];
    // END
}

- (void)myMicsAction
{
    // Cancel editing
    [self cancelAction];
    
    [self setupBackButton];
    PickMicrophoneView *pickMicrophoneView = [[PickMicrophoneView alloc] initWithNibName:@"PickMicrophoneView" bundle:nil];
    [self.navigationController pushViewController:pickMicrophoneView animated:YES];
}

@end