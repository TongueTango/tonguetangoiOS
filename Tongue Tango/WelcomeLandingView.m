//
//  WelcomeLandingView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/7/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "WelcomeLandingView.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "SquareAndMask.h"

@implementation WelcomeLandingView

@synthesize loginView;
@synthesize registrationView;
@synthesize textWelcome;
@synthesize theHUD;
@synthesize fbHelper;
@synthesize twHelper;
@synthesize btnLoginWithFB;
@synthesize btnSignUp;
@synthesize btbLogin;
@synthesize labelSignIn;
@synthesize labelOr;
@synthesize coreDataClass;
@synthesize dataUserImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)shortcut {
    [self dismissModalViewControllerAnimated:NO];
    NSDictionary *dict = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kViewHome] forKey:@"viewNumber"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadView" object:nil userInfo:dict];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    if (self.loginView.view.superview == nil) {
        self.loginView = nil;
    }
    
    if (self.registrationView.view.superview == nil) {
        self.registrationView = nil;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [TestFlight passCheckpoint:@"Launched Tongue Tango."];
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Add the custom navigation bar title
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    self.textWelcome.text = NSLocalizedString(@"WELCOME MESSAGE", nil);
    [btnLoginWithFB setTitle:NSLocalizedString(@"CONNECT FB", nil) forState:UIControlStateNormal];
    //[btnLoginWithTW setTitle:NSLocalizedString(@"CONNECT TW", nil) forState:UIControlStateNormal];
    [btnSignUp setTitle:NSLocalizedString(@"SIGN UP BUTTON", nil) forState:UIControlStateNormal];
    [btbLogin setTitle:NSLocalizedString(@"SIGN IN", nil) forState:UIControlStateNormal];
    self.labelOr.text = NSLocalizedString(@"OR", nil);
    self.labelSignIn.text = NSLocalizedString(@"SIGN IN LABEL", nil);
    
    // Setting Shadown Colors
    //[self.btnLoginWithTW.titleLabel setShadowOffset:CGSizeMake(0.0f, -1.0f)];
    [self.btnLoginWithFB.titleLabel setShadowOffset:CGSizeMake(0.0f, -1.0f)];
    [self.btnSignUp.titleLabel setShadowOffset:CGSizeMake(0.0f, -1.0f)];
    [self.btbLogin.titleLabel setShadowOffset:CGSizeMake(0.0f, -1.0f)];
    [self.textWelcome setShadowOffset:CGSizeMake(0.0f, -1.0f)];
    [self.labelSignIn setShadowOffset:CGSizeMake(0.0f, -1.0f)];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.tintColor = DEFAULT_THEME_COLOR;
    [self.navigationController popViewControllerAnimated:YES];
    
    // Start the Facebook and Twitter connection
    fbHelper = [FacebookHelper sharedInstance];
    fbHelper.delegate = self;
    
    twHelper = [TwitterHelper sharedInstance];
    twHelper.delegate = self;
    
    // Prepare the loading screen in case it's needed later
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"LOGGING IN", nil) willAnimate:YES addToView:self.view];
    [theHUD create];

    self.coreDataClass = [CoreDataClass sharedInstance];
}


- (void)viewDidUnload
{
    self.textWelcome = nil;
    [self setBtnLoginWithFB:nil];
    //[self setBtnLoginWithTW:nil];
    [self setBtnSignUp:nil];
    [self setBtbLogin:nil];
    [self setLabelSignIn:nil];
    [self setLabelOr:nil];
    [super viewDidUnload];
}

// Done was selected on the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)setupBackButton {
    // change back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BACK", nil) 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:nil 
                                                                  action:nil]; 
    [[self navigationItem] setBackBarButtonItem:backButton]; 
}


- (void)openRegistration {
    [self setupBackButton];
    [self resetUserDefaults];
    RegistrationView *oView = [[RegistrationView alloc] initWithNibName:@"RegistrationView" bundle:nil];
    [self.navigationController pushViewController:oView animated:YES];
}

- (void)openLogin {
    [self setupBackButton];
    [self resetUserDefaults];
    LoginView *oView = [[LoginView alloc] initWithNibName:@"LoginView" bundle:nil];
    [self.navigationController pushViewController:oView animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Facebook Methods

- (IBAction)connectToFacebook:(id)sender {
    [self resetUserDefaults];
    if ([fbHelper isLoggedIn]) {
        [fbHelper getMyInfo];
    } 
    else {
        [fbHelper login];
    }
    
}

- (void)fbDidReturnLogin:(BOOL)success
{
    [theHUD show];
    if (success) {
        
        /*
         Added By Aftab Baig
         Sets fb_sync to true as facebook login automatically sync user's friends.
         */
        [defaults setBool:YES forKey:@"fb_sync"];
        [defaults synchronize];
        
        [fbHelper getMyInfo];
    } 
    else {
        
        // Hide the loading screen;
        [theHUD hide];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                                        message:NSLocalizedString(@"FB ERROR", nil) 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)fbDidReturnRequest:(BOOL)success:(NSMutableArray *)result {
   
    if (success) {
        // Verify the Facebook token default is set
        if ([[defaults objectForKey:@"FBAccessTokenKey"] length] > 0) {
            TFLog(@"Retrieved Facebook data. YOUR TOKEN:%@",[defaults objectForKey:@"FBAccessTokenKey"]);
        } 
        else {
            success = NO;
        }
        
        NSDictionary *dict = [result objectAtIndex:0];
        
        // Set the users facebook id default
        if ([[dict objectForKey:@"facebook_id"] length] > 0) {
            [defaults setObject:[dict objectForKey:@"facebook_id"] forKey:@"FBIdentifier"];
        } 
        else {
            success = NO;
        }
        
        // Set the first name default
        if ([[dict objectForKey:@"firstname"] length] > 0) {
            [defaults setObject:[dict objectForKey:@"firstname"] forKey:@"UserFirstName"];
        } else {
            success = NO;
        }
        
        // Set the last name default
        if ([dict objectForKey:@"lastname"]) {
            [defaults setObject:[dict objectForKey:@"lastname"] forKey:@"UserLastName"];
        } else {
            [defaults setObject:@"" forKey:@"UserLastName"];
        }
        
        // Set the email address default
        if ([dict objectForKey:@"email"]) {
            [defaults setObject:[dict objectForKey:@"email"] forKey:@"UserEmail"];
        } else {
            [defaults setObject:@"" forKey:@"UserEmail"];
        }
        
        // Get the facebook image
        self.dataUserImage = [self getUsersImage:[dict objectForKey:@"facebook_id"]];
        
        if (success) {
            // Set defaults not used by Facebook
            [defaults setObject:@"" forKey:@"UserUsername"];
            [defaults setObject:@"" forKey:@"UserPassword"];
            [defaults setObject:@"" forKey:@"TWAuthData"];
            
            [defaults setInteger:LoginModeFacebook forKey:@"LoginMode"];
            
            [self saveProfile];
        }
    }
    
    if (!success) {
        // Hide the loading screen;
        [theHUD hide];

        // TODO JMR test this branch
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate resetUserDefaults];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil)
                                                        message:NSLocalizedString(@"FB ERROR2", nil)
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                              otherButtonTitles:nil];
        [alert show];
    }
    /* added by Aftab Baig */
    else
    {
        
    }
}

- (NSData *)getUsersImage:(NSString *)facebookId {
    // Get the object image
    NSString *url = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture?type=large", facebookId];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    return data;
}

#pragma mark - Twitter Methods

- (IBAction)connectToTwitter:(id)sender {
    [self resetUserDefaults];
    [twHelper login];
    [theHUD show];
}

- (void)twDidReturnLogin:(BOOL)success {
    
    if (success) {
        
        NSString *username = [defaults objectForKey:@"TWUsername"];
        [self handleTwitterResponse:username];
        
    } 
    else {
        [theHUD hide];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                                        message:NSLocalizedString(@"TW ERROR", nil) 
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                              otherButtonTitles:nil];
        [alert show];
        
        // TODO JMR test this branch
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate resetUserDefaults];
    }
}

- (void)twDidReturnRequest:(BOOL)success {
    [theHUD hide];
}

- (void)handleTwitterResponse:(NSString *)username {
    BOOL success = YES;
    
    // Verify the Twitter Auth token default is set
    if ([[defaults objectForKey:@"TWAuthData"] length] > 0) {
        DLog(@"%@", [defaults objectForKey:@"TWAuthData"]);
        TFLog(@"Retreived Twitter data. YOUR TOKEN:%@",[defaults objectForKey:@"TWAuthData"]);
    } 
    else {
        success = NO;
    }
    
    // Get the user info
    NSString *userURL = [[NSString alloc] initWithFormat:@"https://api.twitter.com/1/users/show.json?screen_name=%@&include_entities=true", username];
    NSData *profileInfo = [NSData dataWithContentsOfURL:[NSURL URLWithString:userURL]];
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:profileInfo encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    NSString *firstName;
    NSString *lastName;
    NSString *fullname;
    
    if ([dictJSON objectForKey:@"name"]) {
        fullname = [dictJSON objectForKey:@"name"];
        
        if ([fullname length] > 0) {
            NSRange textRange;
            textRange =[fullname rangeOfString:@" "];
            
            if (textRange.location != NSNotFound) {
                NSString *firstname = [fullname substringToIndex:NSMaxRange(textRange)];
                firstName = [firstname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *lastname = [fullname substringFromIndex:NSMaxRange(textRange)];
                lastName = [lastname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            } 
            else {
                firstName = fullname;
                lastName = @"Twitter";
            }
        }
    }
    
    // Set the first name default
    if ([firstName length] > 0) {
        [defaults setObject:firstName forKey:@"UserFirstName"];
    } 
    else if ([username length] > 0) {
        [defaults setObject:username forKey:@"UserFirstName"];
    } 
    else {
        success = NO;
    }
    
    // Set the last name default
    [defaults setObject:lastName forKey:@"UserLastName"];

    
    NSString *imageURL = [[NSString alloc] initWithFormat:@"https://api.twitter.com/1/users/profile_image?screen_name=%@&size=original", username];
    self.dataUserImage = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
    
    if (success) {
        // Set the defaults not used by Twitter
        [defaults setObject:@"" forKey:@"UserUsername"];
        [defaults setObject:@"" forKey:@"UserPassword"];
        [defaults setObject:@"" forKey:@"FBIdentifier"];
        [defaults setObject:@"" forKey:@"FBAccessTokenKey"];
        
        [defaults setInteger:LoginModeTwitter forKey:@"LoginMode"];
        
        [self saveProfile];
    }
    else {

        // TODO JMR test this branch
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate resetUserDefaults];
    }
}

#pragma mark - Tongue Tango buttons

- (IBAction)connectToTongueTango:(UIButton *)sender {
    [self openLogin];
}

- (IBAction)sigUpTongueTango:(UIButton *)sender {
    [self openRegistration];
}


#pragma mark - Load Views

- (NSString *)getUUID {
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

- (void)saveProfile {
    [theHUD show];
    
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
    
    NSString *url = [NSString stringWithFormat:@"%@user/login",kAPIURL];
    DLog(@"URL: %@",url);
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"login"];
    [APIrequest apiCall:jsonData Method:@"POST" URL:url];
}

- (void)connectionAlert:(NSString *)message {
    
    if (!message) {
        message = NSLocalizedString(@"LOGIN ERROR MESSAGE", nil);
    }
    
    DLog(@"Login Error: %@",message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN ERROR" , nil)
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"Connection failed: %@", [error description]);
    
    // reset data from last social connection attempt
    LoginMode lm = [defaults integerForKey:@"LoginMode"];
    
    
    
    UIAlertView *alert;
    
    if (lm == LoginModeTwitter) {
        [twHelper logout];
        [self resetUserDefaults];
        alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                           message:NSLocalizedString(@"TW ERROR", nil) 
                                          delegate:self 
                                 cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                 otherButtonTitles:nil];
    }
    else if (lm == LoginModeFacebook) {
        [fbHelper logout];
        [self resetUserDefaults];
        alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil) 
                                           message:NSLocalizedString(@"FB CONNECTION ERROR", nil) 
                                          delegate:nil
                                 cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                 otherButtonTitles:nil];
    }

    [theHUD hide];
    [alert show];
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    DLog(@"RESPONSE: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"])
    {
        [theHUD hide];
        
        NSString *errMessage;
        
        if ([[dictJSON objectForKey:@"message"] isKindOfClass:[NSString class]])
        {
            errMessage = [dictJSON objectForKey:@"message"];
        }
        else
            if ([[dictJSON objectForKey:@"message"] isKindOfClass:[NSDictionary class]])
            {
                NSArray *values = [[dictJSON objectForKey:@"message"] allValues];
                if ([[values objectAtIndex:0] isKindOfClass:[NSString class]])
                {
                    errMessage = [values objectAtIndex:0];
                }
            }
        
        [self connectionAlert:errMessage];
    }
    else
        if ([ref isEqualToString:@"login"])
        {
            if ([dictJSON objectForKey:@"token"])
            {
                [defaults setInteger:[[dictJSON objectForKey:@"user_id"] intValue] forKey:@"UserID"];
                [defaults setObject:[dictJSON objectForKey:@"token"] forKey:@"UserToken"];
                [defaults setObject:[dictJSON objectForKey:@"phone_number"] forKey:@"UserPhone"];
                
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
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
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
                
                if (dataUserImage.length > 0)
                {
                    NSString *url = [NSString stringWithFormat:@"%@user",kAPIURL];
                    ServerConnection *APIrequest = [[ServerConnection alloc] init];
                    [APIrequest setDelegate:self];
                    [APIrequest setReference:@"uploadPhoto"];
                    [APIrequest sendFileWithData:dataUserImage Method:@"POST"
                                             URL:url
                                            JSON:nil
                                        fileName:@"userimage.png"];
                }
                else
                {
                    [self showHomeView];
                }
            }
            else
            {
                [theHUD hide];
            }
        }
        else
            if ([ref isEqualToString:@"uploadPhoto"])
            {
                
                UIImage *profileImage = [UIImage imageWithData:self.dataUserImage];
                [Utils saveUserImage:profileImage];
                
                [self showHomeView];
            }
}

- (void)hideView
{
    [theHUD hide];
    [self.navigationController dismissModalViewControllerAnimated:NO];
}

- (void)finishShowingThisView
{
    [self performSelectorOnMainThread:@selector(hideView) withObject:nil waitUntilDone:YES];

}

- (void)showHomeView
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.homeViewController.shouldOpenSync = YES;
        
    [self performSelector:@selector(finishShowingThisView) withObject:nil afterDelay:1.0];
}

- (void)resetUserDefaults
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate resetUserDefaults];
}


- (void)setUserImage:(UIImage *)profileImage
{
    NSData *imageData = UIImagePNGRepresentation(profileImage);
    
    if (imageData.length > 0)
    {
        
        SquareAndMask *squareAndMask = [[SquareAndMask alloc] init];
        UIImage *maskedImage = [squareAndMask maskImage:profileImage];
        NSData *dataImage = UIImagePNGRepresentation(maskedImage);
        
       // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //NSString *documentsPath = [paths objectAtIndex:0];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];

        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
        [dataImage writeToFile:filePath atomically:YES];
        [defaults setObject:filePath forKey:@"UserImage"];
    }
}

@end
