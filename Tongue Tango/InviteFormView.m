//
//  InviteFormView.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "InviteFormView.h"
#import "InviteView.h"

@implementation InviteFormView

@synthesize inviteView;

@synthesize toolBar;
@synthesize fieldFirst;
@synthesize fieldLast;
@synthesize fieldEmail;
@synthesize fieldPhone;
@synthesize labelInstructions;
@synthesize labelOr;

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

- (BOOL)isValidEmail:(NSString *)checkString
{
//    strictFilter = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
//    laxFilter = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    
    NSString *emailRegex = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (BOOL)isValidPhone:(NSString *)checkString
{
    NSString *phoneRegex = @"[23456789][0-9]{6}([0-9]{3})?";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
    return [phoneTest evaluateWithObject:checkString];
}

- (void)handleNextButton:(id)sender
{
    NSString *strFirstName = self.fieldFirst.text;
    NSString *strLastName = self.fieldLast.text;
    NSString *strEmail = self.fieldEmail.text;
    NSString *strPhone = self.fieldPhone.text;
    NSString *errMessage;
    
    BOOL formOK = YES;
    
    if ([strFirstName isEqualToString:@""] && [strLastName isEqualToString:@""]) {
        errMessage = NSLocalizedString(@"PLEASE ENTER NAME", nil);
        formOK = NO;
    } else {
        
        if ([strEmail isEqualToString:@""] && [strPhone isEqualToString:@""]) {
            errMessage = NSLocalizedString(@"PLEASE ENTER EMAIL", nil);
            formOK = NO;
        } else {
            
            if (![strEmail isEqualToString:@""]) {
                if (![self isValidEmail:strEmail]) {
                    errMessage = NSLocalizedString(@"INVALID EMAIL", nil);
                    formOK = NO;
                }
            }
            
            if (![strPhone isEqualToString:@""]) {
                if (![self isValidPhone:strPhone]) {
                    errMessage = NSLocalizedString(@"INVALID PHONE", nil);
                    formOK = NO;
                }
            }
        }
    }
    
    if (formOK) {
        if (!self.inviteView) {
            self.inviteView = [[InviteView alloc] initWithNibName:@"InviteView" bundle:nil];
        }
        
        NSString *strTempName = [NSString stringWithFormat:@"%@ %@", strFirstName, strLastName];
        NSString *strFullName = [strTempName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              strFirstName, @"first_name",
                              strLastName, @"last_name",
                              strFullName, @"fullname",
                              [NSArray arrayWithObject:strEmail], @"email",
                              [NSArray arrayWithObject:strPhone], @"phone",
                              nil];
        
        [FlurryAnalytics logEvent:@"Completed Invite Form."];
        
        [self.inviteView setDictPerson:dict];
        [self.inviteView resetEmail];
        [self.navigationController pushViewController:self.inviteView animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INVITE FORM ERROR", nil)
                                                        message:errMessage
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)createNextButton
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"NEXT", nil)
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(handleNextButton:)];
    self.navigationItem.rightBarButtonItem = button;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Invite Form View."];
    
    // Set the backbround image for this view
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:k_UIImage_BackgroundImageNamePNG]];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    // Set a custom cancel button in the toolbar
    [self createNextButton];
    
    // Stretch the backgrounds of the longer text fields
    self.fieldEmail.background = [[UIImage imageNamed:@"bg_input.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    self.fieldPhone.background = [[UIImage imageNamed:@"bg_input.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    
    // Localize the text
    self.fieldFirst.placeholder = NSLocalizedString(@"FIRST NAME", nil);
    self.fieldLast.placeholder = NSLocalizedString(@"LAST NAME", nil);
    self.fieldEmail.placeholder = NSLocalizedString(@"EMAIL", nil);
    self.fieldPhone.placeholder = NSLocalizedString(@"PHONE NUMBER", nil);
    self.labelInstructions.text = NSLocalizedString(@"INVITE MESSAGE", nil);
    self.labelOr.text = NSLocalizedString(@"OR", nil);
    
    self.fieldFirst.delegate = self;
    self.fieldLast.delegate = self;
    self.fieldEmail.delegate = self;
    self.fieldPhone.delegate = self;
    
    [self.fieldFirst becomeFirstResponder];
}

- (void)viewDidUnload
{
    [self setFieldFirst:nil];
    [self setFieldLast:nil];
    [self setFieldEmail:nil];
    [self setFieldPhone:nil];
    [self setToolBar:nil];
    [self setLabelInstructions:nil];
    [self setLabelOr:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    if (textField.returnKeyType == UIReturnKeyNext) {
        NSInteger nextTag = textField.tag + 1;
        // Try to find next responder
        UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
        if (nextResponder) {
            [nextResponder becomeFirstResponder];
        } else {
            [textField resignFirstResponder];
        }
    }
    
    if (textField.returnKeyType == UIReturnKeyDone) {
        [self handleNextButton:nil];
    }
    
    return NO;
}

@end
