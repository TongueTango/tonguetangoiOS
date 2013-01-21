//
//  FeedbackView.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/19/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "FeedbackView.h"

@implementation FeedbackView

@synthesize delegate;
@synthesize bttnRateUs;
@synthesize bttnFeedback;
@synthesize partnersEmailLabel;

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
    [FlurryAnalytics logEvent:@"Visited Feedback View."];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather"]];
    
    // Set the image for the buttons
    [self.bttnRateUs setTitle:NSLocalizedString(@"RATE US 5 STARS", nil) forState:UIControlStateNormal];
    [self.bttnFeedback setTitle:NSLocalizedString(@"EMAIL FEEDBACK", nil) forState:UIControlStateNormal];
    
    self.partnersEmailLabel.text = NSLocalizedString(@"EMAIL FOR PARTNERSHIP", nil);
    
    openEmail = NO;
}

- (void)viewDidUnload
{
    [self setDelegate:nil];
    [self setBttnRateUs:nil];
    [self setBttnFeedback:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (openEmail && [delegate respondsToSelector:@selector(openFeedbackEmail)]) {
        [delegate openFeedbackEmail];
    }
    if (rateApp && [delegate respondsToSelector:@selector(openFeedbackEmail)]) {
        [delegate openRateThisApp];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)openToRateApp:(id)sender
{
    rateApp = YES;
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)openFeedbackEmail:(id)sender
{
    openEmail = YES;
    [self dismissModalViewControllerAnimated:YES];
}

@end
