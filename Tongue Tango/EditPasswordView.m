//
//  EditPasswordView.m
//  Tongue Tango
//
//  Created by Johana Moccetti on 7/27/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "EditPasswordView.h"
#import "ServerConnection.h"

#define TEXT_FIELD_TAG 4002

@interface EditPasswordView ()

@end


@implementation EditPasswordView

@synthesize arrCellData;
@synthesize tableProfile;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Edit Password View."];
    
    // Ready the User Defaults
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"TONGUE TANGO", nil)];
    
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CANCEL", nil) 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(cancelAction)];
    self.navigationItem.leftBarButtonItem = button;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DONE", nil) 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:self  
                                                                  action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeID"] == 0) {
        themeColor = DEFAULT_THEME_COLOR;
    } 
    else {
        themeColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                     green:([defaults integerForKey:@"ThemeGreen"]/255.0) 
                                      blue:([defaults integerForKey:@"ThemeBlue"]/255.0) 
                                     alpha:1];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat result = 10.0;
    if (section == 0) {
        result = 40.0;
    }
    return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle;
    if (section == 0) {
        sectionTitle = NSLocalizedString(@"CHANGE PASSWORD", nil);
    } 
    else {
        sectionTitle = @"";
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 290, 20)];
    label.text = sectionTitle;
    label.font = [UIFont boldSystemFontOfSize:18.0];
    label.textColor = [UIColor blackColor];
    label.backgroundColor = [UIColor clearColor];
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    [view addSubview:label];
    
    return view;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITextField *textField;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        
        textField = [[UITextField alloc] initWithFrame:CGRectMake(12, 12, 276.0, 25)];
        textField.tag = TEXT_FIELD_TAG;
        textField.backgroundColor = [UIColor clearColor];
        textField.textColor = themeColor;
        textField.font = [UIFont systemFontOfSize:18.0];
        textField.minimumFontSize = 12;
        textField.adjustsFontSizeToFitWidth = YES;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.delegate = self;
        textField.secureTextEntry = YES;
        textField.clearsOnBeginEditing = NO;
        [cell.contentView addSubview:textField];
        
    } 
    else {
        textField = (UITextField *)[cell viewWithTag:TEXT_FIELD_TAG];
    }
    
    if (indexPath.row == 0) {
        textField.returnKeyType = UIReturnKeyNext;
        newPasswordField = textField;
        textField.placeholder = NSLocalizedString(@"NEW PASSWORD PLACEHOLDER", nil);
    }
    else {
        textField.returnKeyType = UIReturnKeyDone;
        confirmPasswordField = textField;
        textField.placeholder = NSLocalizedString(@"RETYPE PASSWORD PLACEHOLDER", nil);
    }
    
    return cell;
}

- (void)doneAction {
    [activeField resignFirstResponder];
    
    NSString *newPwd = [newPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *confirmPwd = [confirmPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([newPwd length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"ENTER_NEW_PASSWORD_MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else if ([confirmPwd length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"RETYPE_NEW_PASSWORD_MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else if (![newPwd isEqualToString:confirmPwd]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"NEW_PASSWORD_DONT_MATCH_ERROR_MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else {
    
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:newPwd, @"passwd", nil];
    
        // Convert object to data
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *url = [NSString stringWithFormat:@"%@user", kAPIURL];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"saveProfile"];
        [APIrequest apiCall:jsonData Method:@"POST" URL:url];
    }
}

- (void)cancelAction {
    [activeField resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
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
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo {
    DLog(@"");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    if ([dictJSON objectForKey:@"code"]) {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"saveProfile"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"PASSWORD UPDATED" , nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                              otherButtonTitles:nil];
        
        [alert show];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    activeField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == newPasswordField) {
        [confirmPasswordField becomeFirstResponder];
    }
    else {
        [confirmPasswordField resignFirstResponder];
    }
    return NO;
}

@end
