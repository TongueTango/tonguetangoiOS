//
//  FirstSyncView.m
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "FirstSyncView.h"
#import "FacebookHelper.h"

@interface FirstSyncView ()

@end

@implementation FirstSyncView

@synthesize tblType=_tblType;
@synthesize alertView=_alertView;
@synthesize fbHelper=_fbHelper;
@synthesize theHUD=_theHUD;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *btnNext = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextTapped:)];
        self.navigationItem.rightBarButtonItem = btnNext;
    }
    return self;
}

-(void)nextTapped:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fbHelper = [FacebookHelper sharedInstance];
    self.fbHelper.delegate = self;
    
    // Prepare the loading screen in case it's needed later
    self.theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"SYNCING", nil) willAnimate:YES addToView:self.navigationController.view];
    [self.theHUD create];

    // Add the custom navigation bar title
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - tableview delegate & datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

-(UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    NSString *title;
    SyncType syncType;
    
    if (0 == indexPath.row)
    {
        title = NSLocalizedString(@"FROM MY CONTACT LIST", nil);
        syncType = SyncTypeContacts;
    }
    else
    {
        title = NSLocalizedString(@"FACEBOOK FRIENDS", nil);
        syncType = SyncTypeFacebook;
    }
    
    SyncCell *cell = [SyncCell createCell:title forType:syncType];
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    return 44.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - sync cell delegate
-(void)shouldSyncFor:(SyncType)type
{
    if (type == SyncTypeContacts)
    {
        //>---------------------------------------------------------------------------------------------------
        //>     First, if iOS 6, we need to see if user already allowed for contacts to be used in the app
        //>---------------------------------------------------------------------------------------------------
        if (ABAddressBookRequestAccessWithCompletion != NULL)
        {
            //>---------------------------------------------------------------------------------------------------
            //>     This is for iOS 6 only
            //>---------------------------------------------------------------------------------------------------
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            
            DLog(@"Contacts Authorisation: %ld", ABAddressBookGetAuthorizationStatus());
            
            if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
            {
                [self allow];
            }
            else
                if ((ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ||
                    (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted))
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Address Book"
                                                                    message:@"You need to give permission from Settings>Privacy>Contacts to access your contacts"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
                else
                {
                    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                        // Do whatever you need.
                        
                        if (granted)
                        {
                            [self allow];
                        }
                        else
                            if ((ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ||
                                (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted))
                            {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Address Book"
                                                                                message:@"You need to give permission from Settings > Privacy > Contacts to access your contacts"
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                                [alert show];
                            }
                    });
                }
        }
        else
        {
            //>---------------------------------------------------------------------------------------------------
            //>     For iOS < 6
            //>---------------------------------------------------------------------------------------------------
            self.alertView = [[SyncAlertView alloc] initWithNibName:@"SyncAlertView" bundle:nil];
            self.alertView.delegate = self;
            [self.view addSubview:self.alertView.view];
        }
    }
    else if (type == SyncTypeFacebook)
    {
        if ([self.fbHelper isLoggedIn])
        {
            [self pairFBFriends];
        }
        else
        {
            [self.fbHelper login];
        }
    }
}

- (void)fbDidReturnLogin:(BOOL)success
{
    if (success) {
        [self pairFBFriends];
    }
    else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR", nil)
                                                        message:NSLocalizedString(@"FB ERROR", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)fbDidReturnRequest:(BOOL)success:(NSMutableArray *)result {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
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
        
        if (success)
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
            
            NSString *url = [NSString stringWithFormat:@"%@user",kAPIURL];
            ServerConnection *APIrequest = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setReference:@"saveFacebook"];
            [APIrequest apiCall:jsonData Method:@"POST" URL:url];
        }
    }
    
    if (!success) {
        
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

// Create an array of people data from the Address Book
- (NSMutableArray *)getAllAddressBookPeople
{
    // create the address book (AB) array
    ABAddressBookRef addressBook = ABAddressBookCreate();
    NSArray *arrAllPeople = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSMutableArray *arrReturn = [NSMutableArray array];
    
    if (arrAllPeople != nil) {
        
        // build an array containing dictionaries for each person
        NSInteger peopleCount = [arrAllPeople count];
        for (int i = 0; i < peopleCount; i++) {
            ABRecordRef thisPerson = (__bridge ABRecordRef)[arrAllPeople objectAtIndex:i];
            
            // get this persons email addresses
            ABMultiValueRef multi1 = ABRecordCopyValue(thisPerson, kABPersonEmailProperty);
            NSArray *arrAllEmailAddresses = (__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(multi1);
            if (!arrAllEmailAddresses) {
                arrAllEmailAddresses = [[NSArray alloc] init];
            }
            CFRelease(multi1);
            
            // get this persons phone numbers
            ABMultiValueRef multi2 = ABRecordCopyValue(thisPerson, kABPersonPhoneProperty);
            NSArray *arrAllPhoneNumbers = (__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(multi2);
            if (!arrAllPhoneNumbers) {
                arrAllPhoneNumbers = [[NSArray alloc] init];
            }
            CFRelease(multi2);
            
            // get this persons id
            int intPersonId = (int)ABRecordGetRecordID(thisPerson);
            NSNumber *personId = [NSNumber numberWithInt:intPersonId];
            
            // save the data to a dictionary and save the dictionary into an array
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  personId, @"addressbookid", [NSString stringWithFormat:@"AB%@", personId], @"id",
                                  arrAllEmailAddresses, @"email", arrAllPhoneNumbers, @"phone",
                                  nil];
            [arrReturn addObject:dict];
        }
    }
    CFRelease(addressBook);
    
    return arrReturn;
}

- (void)pairFBFriends
{
    
    [self.theHUD show];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fbToken = [defaults objectForKey:@"FBAccessTokenKey"];
    
    NSString *jsonString = [NSString stringWithFormat:@"{\"facebook_access_token\":\"%@\"",fbToken];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@contact/search",kAPIURL];
    ServerConnection *apiRequest = [[ServerConnection alloc] init];
    [apiRequest setDelegate:self];
    [apiRequest setReference:@"pairFacebook"];
    [apiRequest apiCall:jsonData Method:@"POST" URL:url];

}

// Send contacts to the server to pair
- (void)pairContacts:(NSMutableArray *)people
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *personalEmail = [defaults objectForKey:@"UserEmail"];
    NSString *personalPhone = [defaults objectForKey:@"UserPhone"];
    
    [self.theHUD show];
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    NSInteger peopleCount = [people count];
    
    for (int i=0; i<peopleCount; i++) {
        
        NSDictionary *dict = [people objectAtIndex:i];
        
        BOOL ownEmail = NO;
        NSArray *emails = [dict objectForKey:@"email"];
        for (int i=0; i<emails.count; i++)
        {
            if ([[emails objectAtIndex:i] isEqualToString:personalEmail])
            {
                ownEmail = YES;
            }
        }
        
        BOOL ownPhone = NO;
        NSArray *phones = [dict objectForKey:@"phone"];
        for (int i=0; i<phones.count; i++)
        {
            if ([[phones objectAtIndex:i] isEqualToString:personalPhone])
            {
                ownPhone = YES;
            }
        }
        
        if (!ownEmail && !ownPhone)
        {
            NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [dict objectForKey:@"addressbookid"], @"u",
                                    [dict objectForKey:@"email"], @"e",
                                    [dict objectForKey:@"phone"], @"p",
                                    nil];
            
            
            [contacts addObject:person];
        }
    }
    
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:contacts];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@contact/search",kAPIURL];
    ServerConnection *apiRequest = [[ServerConnection alloc] init];
    [apiRequest setDelegate:self];
    [apiRequest setReference:@"pairContacts"];
    [apiRequest setUserInfo:people];
    [apiRequest apiCallForPairing:jsonData Method:@"POST" URL:url];
    
}

#pragma mark - API server methods

- (void)connectionAlert:(NSString *)message
{
    [self.theHUD hide];
    
    if (!message) {
        message = NSLocalizedString(@"REQUEST ERROR MESSAGE", nil);
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sync"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil];
    [alert show];
    
    [self.tblType reloadData];
}

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    NSLog(@"Connection failed: %@", [error description]);
    [self.theHUD hide];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REQUEST ERROR" , nil)
                                                    message:[error localizedDescription]
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil];
    [alert show];
    
    [self.tblType reloadData];
    
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    if ([dictJSON objectForKey:@"code"])
    {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([ref isEqualToString:@"pairFacebook"])
    {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Successfully Synced"
                                                        message:@"All your Facebook friends will automatically be added"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        [defaults setBool:YES forKey:@"fb_sync"];
        [defaults synchronize];
        [self.tblType reloadData];
    }
    
    if ([ref isEqualToString:@"pairContacts"])
    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Successfully Synced"
//                                                        message:@"All your contacts will automatically be added"
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
        
        [defaults setBool:YES forKey:@"ab_sync"];
        [defaults synchronize];
        [self.tblType reloadData];
    }
    
    [self.theHUD hide];

}

#pragma mark - Sync Alert Delegate

-(void)allow
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *abPeople = [self getAllAddressBookPeople];
        dispatch_async( dispatch_get_main_queue(), ^{
            [self pairContacts:abPeople];
        });
    });

}

-(void)cancel
{
    [self.tblType reloadData];
}


@end
