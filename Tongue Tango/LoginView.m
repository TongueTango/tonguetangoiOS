//
//  LoginView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/8/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "LoginView.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "CoreDataClass.h"
#define PADDING_RIGHT 10.0

@implementation LoginView

@synthesize textUsername, textPassword;
@synthesize buttonLogin;
@synthesize bttnForgot;
@synthesize coreDataClass;
@synthesize squareAndMask;
@synthesize theHUD;
@synthesize serverConnection;



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

- (void)handleCanceButton:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)createSigInButton
{
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SIGN IN", nil) 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(checkLogin)];
    self.navigationItem.rightBarButtonItem = button;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Ready the User Defaults
    defaults = [NSUserDefaults standardUserDefaults];
    // bug #US19
    self.coreDataClass = [CoreDataClass sharedInstance];
    
    // Add the custom navigation bar title
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    // Add tsign in button to the navigation bar
    [self createSigInButton];
    
    // Setup the text fields and or label
    NSString *imageFile = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"bg_input.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imageFile];
    self.textUsername.background = [image stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    self.textPassword.background = [image stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    
    // Delegate the login fields
    [textUsername setDelegate:self];
    [textPassword setDelegate:self];
    textPassword.placeholder = NSLocalizedString(@"PASSWORD", nil);
    textUsername.placeholder = NSLocalizedString(@"USERNAME", nil);
    [buttonLogin setTitle: NSLocalizedString(@"SIGN IN", nil)forState:(UIControlStateNormal)];
    [bttnForgot setTitle: NSLocalizedString(@"FORGOT", nil) forState:(UIControlStateNormal)];

    
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT, 20)];
    self.textUsername.leftView = paddingView;
    self.textUsername.leftViewMode = UITextFieldViewModeAlways;
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PADDING_RIGHT , 20)];
    self.textPassword.leftView = paddingView;
    self.textPassword.leftViewMode = UITextFieldViewModeAlways;
    
    // Prepare the loading screen in case it's needed later
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"LOGGING IN", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
    [textUsername becomeFirstResponder];
    squareAndMask = [[SquareAndMask alloc] init];
}

- (void)viewDidUnload
{
    [self setBttnForgot:nil];
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

- (IBAction)openWebsite:(id)sender
{
    NSString *strURL = [NSString stringWithFormat:@"%@forgot", kROOTURL];
    
    // Open the link in Safari
    NSURL *url = [[NSURL alloc] initWithString:strURL];

    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Keyboard Methods

- (IBAction)hideKeyboard:(id)sender
{
    [textUsername resignFirstResponder];
    [textPassword resignFirstResponder];
}


// Done was selected on the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
		
        if (textField == textPassword)
		{
			[textPassword resignFirstResponder];
		}else{
			[textUsername resignFirstResponder];
			[textPassword becomeFirstResponder];
		}
        return YES;
    }
    return NO;
}

- (IBAction)closeLogin
{
    [self dismissModalViewControllerAnimated:NO];
}

- (IBAction)checkLogin {
    
    DLog(@"");
    
    // Hide keyboard every time the login button is pressed
    [self hideKeyboard:nil];
    
    NSString *textUser = [textUsername.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *textPass = [textPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
                         
    if ([textUser isEqualToString:@""] || 
        [textPass isEqualToString:@""]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN ERROR", nil) 
                                                        message:NSLocalizedString(@"MISSING UN PW", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        
    } 
    else {
        [self setVisibleLoadingView:YES];
        
        // Information about the device
        UIDevice *dev = [UIDevice currentDevice];
        NSString *deviceUuid = [self getUUID];
        NSString *deviceModel = dev.model;
        NSString *deviceSystemVersion = dev.systemVersion;
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              textUsername.text, @"username",
                              textPassword.text, @"passwd",
                              deviceUuid, @"unique_id",
                              @"iOS", @"device_type",
                              [defaults objectForKey:@"DeviceToken"], @"push_token",
                              deviceModel, @"model",
                              deviceSystemVersion, @"version",
                              nil];
        
        //convert object to data
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dict];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        //NSString *url = [NSString stringWithFormat:@"%@login",kAPIURL];
        NSString *url = [NSString stringWithFormat:@"%@user/login",kAPIURL]; //new v2
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"login"];
        DLog(@"Login call");
        [APIrequest apiCall:jsonData Method:@"POST" URL:url];
    } 
}

- (void)setVisibleLoadingView:(BOOL)isVisible {
    DLog(@"%@", (isVisible ? @"YES": @"NO"));
    if (isVisible) {
         [self.navigationController.navigationBar setUserInteractionEnabled:NO];
        [theHUD show];
    } 
    else {
         [self.navigationController.navigationBar setUserInteractionEnabled:YES];
        [theHUD hide];
    }
}

- (void)connectionAlert:(NSString *)message
{
    if (!message) {
        message = NSLocalizedString(@"LOGIN ERROR MESSAGE", nil);
    }
    
    DLog(@"Login Error: %@",message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN ERROR" , nil)
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
                                          otherButtonTitles:nil, nil];
    [alert show]; 
    [self setVisibleLoadingView:NO];
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    if ([dictJSON objectForKey:@"code"]) {
        
        [self setVisibleLoadingView:NO];
        
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
                
        if ([ref isEqualToString:@"login"] && ![defaults objectForKey:@"UserToken"]) {

            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate resetUserDefaults];
        
        }
    }
    
    if ([ref isEqualToString:@"login"]) {
        if ([dictJSON objectForKey:@"token"]) {
            [defaults setInteger:[[dictJSON objectForKey:@"user_id"] intValue] forKey:@"UserID"];
            [defaults setObject:[dictJSON objectForKey:@"token"] forKey:@"UserToken"];
            [defaults setObject:[dictJSON objectForKey:@"first_name"] forKey:@"UserFirstName"];
            [defaults setObject:[dictJSON objectForKey:@"last_name"] forKey:@"UserLastName"];
            [defaults setObject:[dictJSON objectForKey:@"email_address"] forKey:@"UserEmail"];
            [defaults setObject:[dictJSON objectForKey:@"username"] forKey:@"UserUsername"];
            [defaults setObject:[dictJSON objectForKey:@"phone_number"] forKey:@"UserPhone"];
            
            [defaults setInteger:LoginModeTongueTango forKey:@"LoginMode"];
            
            [defaults synchronize];
            
             DLog(@"Login call finish");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu" object:nil];
            
            if ([dictJSON objectForKey:@"tt_friends"])
            {
                
                
                NSArray *arrFriends = [dictJSON objectForKey:@"tt_friends"];
                NSArray *arrPeople = [dictJSON objectForKey:@"fb_friends"];
                NSArray *arrPending = [dictJSON objectForKey:@"pending_friends"];
                
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
            
            // Hotfix until we analize what is going on with the serevr response
            BOOL isPhotoNil = [[dictJSON objectForKey:@"photo"] isKindOfClass:[NSNull class]];
            
            // Original if without the hotfix
            // if ([[dictJSON objectForKey:@"photo"] length] > 7) {
            
            if ( !isPhotoNil && [[dictJSON objectForKey:@"photo"] length] > 7) {
                [squareAndMask setDelegate:self];
                [squareAndMask imageFromURL:[dictJSON objectForKey:@"photo"]];
            } 
            else {
                [self closeLogin];
            }
            [textUsername resignFirstResponder];
            [textPassword resignFirstResponder];
            
           

            
            //[self setVisibleLoadingView:NO];
            
        } 
        else {
            [self setVisibleLoadingView:NO];
        }
    }
}

- (void)imageDidFail
{
    [self setVisibleLoadingView:NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN ERROR", nil) 
                                                    message:@"An error occurred with your profile image.  To update your image, select Profile from the menu and tap on Set Picture."
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)imageDidFinishLoading:(NSString *)personId image:(UIImage *)image userInfo:(id)userInfo
{
    if (image) {
        NSData *dataImage = UIImagePNGRepresentation(image);
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
        [dataImage writeToFile:filePath atomically:YES];
        [defaults setObject:filePath forKey:@"UserImage"];
    }
    //[self setVisibleLoadingView:NO];
    [self closeLogin];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView dismissWithClickedButtonIndex:-1 animated:NO];
    [self closeLogin];
}

@end
