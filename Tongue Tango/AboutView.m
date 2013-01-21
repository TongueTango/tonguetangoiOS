//
//  AboutView.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/29/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "AboutView.h"
#import "FeedbackView.h"
#import <QuartzCore/QuartzCore.h>

@implementation AboutView

@synthesize bttnWebsite;
@synthesize bttnFacebook;
@synthesize bttnTwitter;
@synthesize bttnOpenFeedback;
@synthesize bttnTerms;
@synthesize imgTT;

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited About View."];
    
    
    // Set the backbround image for this view
    CGRect deviceFrame      = [[UIScreen mainScreen] bounds];
    UIImageView *bgImage    = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, deviceFrame.size.width, deviceFrame.size.height)];
    bgImage.image           = [UIImage imageNamed:@"bg_list_white_leather"];
    [self.view insertSubview:bgImage atIndex:0];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];

    
    // Set the button backgrounds and titles
    [self.bttnWebsite setTitle:NSLocalizedString(@"WEBSITE", nil) forState:UIControlStateNormal];
    [self.bttnFacebook setTitle:NSLocalizedString(@"FACEBOOK", nil) forState:UIControlStateNormal];
    [self.bttnTwitter setTitle:NSLocalizedString(@"TWITTER", nil) forState:UIControlStateNormal];
    [self.bttnTerms setTitle:NSLocalizedString(@"TERMS OF USE", nil) forState:UIControlStateNormal];
    
    shakeCount = 0;
    shakeNow = 0;

}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self setBttnWebsite:nil];
    [self setBttnFacebook:nil];
    [self setBttnTwitter:nil];
    [self setBttnOpenFeedback:nil];
    [self setBttnTerms:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
    
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark - Button actions

- (IBAction)openLink:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSString *strURL;
    
    switch (button.tag) {
        case 1001:
            strURL = @"http://www.tonguetango.com";
            break;
        case 1002:
            strURL = @"http://www.facebook.com/TongueTango";
            break;
        case 1003:
            strURL = @"http://twitter.com/#!/TongueTango";
            break;
        case 1004:
            strURL = @"http://www.youtube.com/user/TongueTango";
            break;
        case 1005:
            strURL = @"http://www.linkedin.com/company/tongue-tango";
            break;
        case 1006:
            strURL = @"http://tonguetango.com/privacy-policy/";
            break;
        default:
            break;
    }
    
    // Open the link in Safari
    NSURL *url = [[NSURL alloc] initWithString:strURL];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)openRateThisApp {
    NSString *strURL = @"http://itunes.apple.com/us/app/tongue-tango/id472642395?mt=8";
    NSURL *url = [[NSURL alloc] initWithString:strURL];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)openFeedback:(id)sender
{    
    self.navigationController.view.layer.shadowOpacity = 0;
    FeedbackView *feedback= [[FeedbackView alloc] initWithNibName:@"FeedbackView" bundle:nil];
    feedback.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    feedback.delegate = self;
    [self presentModalViewController:feedback animated:YES];
}

- (void)openFeedbackEmail
{
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    
    if ([MFMailComposeViewController canSendMail]) {
        mailViewController.mailComposeDelegate = self;
        
        // Change the color of the mailViewController navigation bar.
        UINavigationBar *navigationBar = mailViewController.navigationBar;
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeID"] == 0) {
            navigationBar.tintColor = DEFAULT_THEME_COLOR;
        } else {
            navigationBar.tintColor = [UIColor colorWithRed:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeRed"]/255.0) green:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeGreen"]/255.0) blue:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeBlue"]/255.0) alpha:1];
        }
        
        // Set the email subject and recipient.
        [mailViewController setSubject:@"Feedback"];
        [mailViewController setToRecipients:[NSArray arrayWithObjects:@"Feedback@tonguetango.com", nil]];
        
        // Open the Mail app
        [self presentModalViewController:mailViewController animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL UNAVAILABLE", nil)
                                                        message:NSLocalizedString(@"EMAIL NOT SETUP", nil)
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil];
        [alert show]; 
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller 
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Display menu


-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)triggerNow {
    shakeNow = YES;
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(stopNow)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)stopNow {
    shakeNow = NO;
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(hideImage)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)hideImage {
    imgTT.alpha = 0;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (shakeCount == 0) {
        [NSTimer scheduledTimerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(triggerNow)
                                       userInfo:nil
                                        repeats:NO];
    }
    shakeCount++;
    if (shakeCount >= 2) {
        [self.view bringSubviewToFront:imgTT];
        imgTT.alpha = 1;
    }
}

@end
