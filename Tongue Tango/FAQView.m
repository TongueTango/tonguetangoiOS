//
//  FAQView.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "FAQView.h"
#import <QuartzCore/QuartzCore.h>

@implementation FAQView
@synthesize theHUD;

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
    // add the menu button to the navigation bar
    UIImage *image = [UIImage imageNamed:@"icon_menu"];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(toggleMove)];
    self.navigationItem.leftBarButtonItem = button;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited FAQs."];
    
    UISwipeGestureRecognizer *recognizerRight;
    recognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(moveRight)];
    [recognizerRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizerRight];
    
    UISwipeGestureRecognizer *recognizerLeft;
    recognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeft)];
    [recognizerLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:recognizerLeft];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    // Set a custom menu button in the navigation bar
    [self createMenuButton];
    
    // Prepare the loading screen in case it's needed later
    theHUD = [[ProgressHUD alloc] initWithText:@"Loading FAQ..." willAnimate:YES addToView:self.view];
    [theHUD create];
    [theHUD show];
    
    // Setup the webview
    UIWebView *webFAQ = [[UIWebView alloc] initWithFrame:CGRectMake(0, 36, 320, 380)];
    [webFAQ setScalesPageToFit:YES];
    [self.view addSubview:webFAQ];
    webFAQ.alpha = 0;
    
    NSURL *url = [NSURL URLWithString:@"http://tonguetango.com/faqs/"];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:44];
    [webFAQ setDelegate:self];
    [webFAQ loadRequest:request];
}

- (void)viewDidUnload
{
    [self setTheHUD:nil];
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [theHUD hide];
    webView.alpha = 1;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Display menu

- (IBAction)moveView:(float)xCoord {
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews
                      animations:^{
                          [self.navigationController.view setCenter:CGPointMake(xCoord, 230)];
                      }
                      completion:nil];
}

- (IBAction)moveRight {
    [self moveView:435];
}

- (IBAction)moveLeft {
    [self moveView:160];
}

- (IBAction)toggleMove {
    if (self.navigationController.view.center.x == 160) {
        [self moveView:435];
    } else {
        [self moveView:160];
    }
}

@end
