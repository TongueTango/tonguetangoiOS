//
//  TwitterPostViewController.m
//  Tongue Tango
//
//  Created by Gap User on 7/31/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "TwitterPostViewController.h"

@interface TwitterPostViewController ()
- (void)createCancelButton;
- (void)createTweetButton;
- (void)updateCountLabel;
@end

@implementation TwitterPostViewController

@synthesize labelCount;
@synthesize textView;
@synthesize message;
@synthesize link;
@synthesize twHelper;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    twHelper = [TwitterHelper sharedInstance];
    
    // Change the color of the navigation bar.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if ([defaults integerForKey:@"ThemeID"] == 0) {
        navigationBar.tintColor = DEFAULT_THEME_COLOR;
    } else {
        navigationBar.tintColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) green:([defaults integerForKey:@"ThemeGreen"]/255.0) blue:([defaults integerForKey:@"ThemeBlue"]/255.0) alpha:1];
    }
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"NEW TWEET", nil)];
    
    // Create the navigation buttons
    [self createCancelButton];
    [self createTweetButton];
    
    //Set the text view
    self.textView.text = [NSString stringWithFormat:@"%@ %@", message, link];
    [self.textView becomeFirstResponder];
    
    [self updateCountLabel];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)createCancelButton {
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CANCEL", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = barButton;    
}

- (void)createTweetButton {
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"TWEET", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(tweetAction:)];
    self.navigationItem.rightBarButtonItem = barButton;    
}

#pragma mark - Create message

- (void)updateCountLabel {
    NSInteger remaining = 140 - [self.textView.text length];
    self.labelCount.text = [NSString stringWithFormat:@"%d", remaining];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)tweetAction:(id)sender {
    NSLog(@"Tweet");
    NSString *textViewMessage = textView.text;
    [twHelper postTextMessage:textViewMessage];
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Text View Delegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updateCountLabel];
}  

@end
