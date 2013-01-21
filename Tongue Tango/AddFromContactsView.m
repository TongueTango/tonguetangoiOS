//
//  AddFromContactsView.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/7/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "AddFromContactsView.h"
#import "InviteView.h"
#import "Constants.h"

@implementation AddFromContactsView

@synthesize delegate;
@synthesize viewToDisplay;
@synthesize tableContacts;

@synthesize viewMessagePrompt;
@synthesize buttonConnect;
@synthesize bttnRefresh;
@synthesize indicateConnect;
@synthesize messageConnect;

@synthesize selectedUsers;
@synthesize arrMyContacts;
@synthesize arrFbContacts;
@synthesize arrCellData;
@synthesize arrSectionTitles;
@synthesize dictActivity;
@synthesize dictDownloadImages;
@synthesize serverConnection;
@synthesize arrAddressBookPeople;

@synthesize fbHelper;
@synthesize inviteView = _inviteView;

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
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)createRefreshButton
{
    bttnRefresh = [UIButton buttonWithType:UIButtonTypeCustom];
    [bttnRefresh setFrame:CGRectMake(280, 0, 36, 36)];
    [bttnRefresh setImage:[UIImage imageNamed:@"bttn_refresh"] forState:UIControlStateNormal];
    [bttnRefresh setBackgroundColor:[UIColor clearColor]];
    [bttnRefresh addTarget:self action:@selector(refreshTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bttnRefresh];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Add Contacts View."];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    serverConnection = [ServerConnection sharedInstance];
    
    // Set the backbround image for this view
    UIColor *bgColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    self.tableContacts.backgroundColor = bgColor;
    self.viewMessagePrompt.backgroundColor = bgColor;
    [self createRefreshButton];
    [self.view bringSubviewToFront:self.viewMessagePrompt];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    // set the property that will be used to create the table section titles
    if (viewToDisplay == kShowContacts) {
        self.arrSectionTitles = [NSMutableArray arrayWithObjects:
                                 NSLocalizedString(@"TT CONTACTS", nil), 
                                 NSLocalizedString(@"INVITE TO TT", nil),
                                 nil];
    } else {
        self.arrSectionTitles = [NSMutableArray arrayWithObjects:
                                 NSLocalizedString(@"TT FRIENDS", nil), 
                                 NSLocalizedString(@"FB FRIENDS", nil),
                                 nil];
    }
    
    // Set the Facebook Connect button background
    UIImage *bgButton = [UIImage imageNamed:@"bttn_facebook.png"];
    self.buttonConnect.titleLabel.textColor = [UIColor darkGrayColor];

    [self.buttonConnect setBackgroundImage:bgButton forState:UIControlStateNormal];
    [self.buttonConnect setTitle:NSLocalizedString(@"CONNECT FB", nil) forState:UIControlStateNormal];
    
    // Set a default user image
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    self.dictDownloadImages = [NSMutableDictionary dictionary];
    
    // set to specifiy if the current table data is display search results
    isSearchResults = NO;
    
    [self launchFriendRequest];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Prepare the activity dictionary
    if (self.dictActivity.count == 0) {
        self.dictActivity = [[NSMutableDictionary alloc] init];
    }
    // Append any previously selected people
    for (id key in selectedUsers) {
        if (![dictActivity objectForKey:key]) {
            id value = [selectedUsers objectForKey:key];
            [dictActivity setObject:value forKey:key];
        }
    }
    [tableContacts reloadData];
}

- (void)viewDidUnload
{
    [self.dictDownloadImages removeAllObjects];
    
    [self setTableContacts:nil];
    [self setViewMessagePrompt:nil];
    [self setButtonConnect:nil];
    [self setIndicateConnect:nil];
    [self setMessageConnect:nil];
    [self setBttnRefresh:nil];
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadFriends" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)launchFriendRequest
{
    switch (viewToDisplay) {
        case kShowContacts:
        {
            DLog(@"Loading Contacts...");
            [self switchPromptMessage:kShowPromptContactsActivity];
            
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                arrAddressBookPeople = [self getAllAddressBookPeople];
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    if ([arrAddressBookPeople count] > 0) {
                        NSMutableArray *arrSortedPeople = [self sortPeopleByFirstName:arrAddressBookPeople];
                        if ([defaults boolForKey:@"ABAccess"]) {
                            [self requestContacts:arrSortedPeople];
                        } else {
                            self.arrMyContacts = [NSMutableArray arrayWithObjects:[[NSArray alloc] init], arrSortedPeople, nil];
                            self.arrCellData = [NSMutableArray arrayWithArray:arrMyContacts];
                            [self.tableContacts reloadData];
                        }
                    }
                });
            });
            
            break;
        }
        case kShowFacebook:
        {
            DLog(@"Loading Facebook...");
            
            if (!fbHelper) {
                fbHelper = [FacebookHelper sharedInstance];
                fbHelper.delegate = self;
            }
            
            // Get all the people from the facebook
            if (!self.arrFbContacts) {
                [self requestFriends];
                
                if ([fbHelper isLoggedIn]) {
                    [self switchPromptMessage:kShowPromptFacebookActivity];
                } else {
                    [self switchPromptMessage:kShowPromptFacebookConnect];
                }
            } else {
                self.arrFbContacts = [self removeMeAndDuplicates:arrFbContacts];
                self.arrCellData = [NSMutableArray arrayWithArray:arrFbContacts];
                [self.tableContacts reloadData];
            }
            
            if ([defaults objectForKey:@"FBAccessTokenKey"]) {
                [self reloadTable];
            }
            
            break;
        }
        default:
            break;
    }
}

- (void)makeFriend:(NSDictionary *)dict indexPath:(NSIndexPath *)index;
{
    [dictActivity setObject:@"set" forKey:[dict objectForKey:@"id"]];
    UITableViewCell *cell;
    if (isSearchResults) {
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:index];
    } else {
        cell = [self.tableContacts cellForRowAtIndexPath:index];
    }
    
    // find the check mark image
    UIButton *button = (UIButton *)[cell viewWithTag:4004];
    button.hidden = YES;
    
    UIImageView *checkmark = (UIImageView *)[cell viewWithTag:4006];
    checkmark.hidden = NO;
}

#pragma mark - Facebook methods

- (IBAction)connectToFacebook:(id)sender
{
    [self switchPromptMessage:kShowPromptFacebookActivity];
    [fbHelper login];
}

- (void)fbDidReturnLogin:(BOOL)success
{
    if (success) {
        [fbHelper getMyInfo];
        [self.tableContacts reloadData];
    } else {
        [self switchPromptMessage:kShowPromptFacebookError];
    }
}

- (void)fbDidReturnRequest:(BOOL)success:(NSMutableArray *)result
{
    if (success) {
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

#pragma mark - Address Book methods

// Create an array of people data from the Address Book
- (NSMutableArray *)getAllAddressBookPeople
{
    // create the address book (AB) array
    ABAddressBookRef addressBook = ABAddressBookCreate();
    NSArray *arrAllPeople = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSMutableArray *arrReturn = [NSMutableArray array];
    
    SquareAndMask *objImage = [[SquareAndMask alloc] init];
    
    if (arrAllPeople != nil) {
        
        // build an array containing dictionaries for each person
        NSInteger peopleCount = [arrAllPeople count];
        for (int i = 0; i < peopleCount; i++) {
            ABRecordRef thisPerson = (__bridge ABRecordRef)[arrAllPeople objectAtIndex:i];
            
            // get this persons name
            NSString *strFirstName = (__bridge_transfer NSString *)ABRecordCopyValue(thisPerson, kABPersonFirstNameProperty);
            NSString *strLastName = (__bridge_transfer NSString *)ABRecordCopyValue(thisPerson, kABPersonLastNameProperty);
            
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
            
            // get this persons image data
            UIImage *image;
            if(ABPersonHasImageData(thisPerson)){
                UIImage *tmpImage = [UIImage imageWithData:(__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(thisPerson, 0)];
                image = [objImage maskImage:tmpImage];
            } else {
                image = defaultImage;
            }
            
            // skip this person if both first and last names are not available
            if (strFirstName || strLastName) {
                
                // make sure both first and last names have values since we'll be sorting by them
                if (!strFirstName) {
                    strFirstName = strLastName;
                    strLastName = @" ";
                }
                if (!strLastName) {
                    strLastName = @" ";
                }
                
                // save the data to a dictionary and save the dictionary into an array
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: 
                                      personId, @"addressbookid", [NSString stringWithFormat:@"AB%@", personId], @"id", image, @"photo",
                                      strFirstName, @"first_name", strLastName, @"last_name", 
                                      arrAllEmailAddresses, @"email", arrAllPhoneNumbers, @"phone",
                                      nil];
                [arrReturn addObject:dict];
            }
        }
    }
    CFRelease(addressBook);
    
    return arrReturn;
}

// Sort an array of people by their first name
- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people
{
    NSSortDescriptor *firstDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"first_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSSortDescriptor *lastDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"last_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSArray *descriptors = [NSArray arrayWithObjects:firstDescriptor, lastDescriptor, nil];
    NSArray *arrSorted = [people sortedArrayUsingDescriptors:descriptors];
    
    return [NSMutableArray arrayWithArray:arrSorted];
}

#pragma mark - API server methods

- (void)switchPromptMessage:(int)status
{
    switch (status) {
        case kHidePrompt:
            [self.searchDisplayController.searchBar setHidden:NO];
            [self.viewMessagePrompt setHidden:YES];
            [indicateConnect stopAnimating];
            break;
            
        case kShowPromptContactsActivity:
            [messageConnect setText:NSLocalizedString(@"AB ACTIVITY", nil)];
            [self.searchDisplayController.searchBar setHidden:YES];
            [self.viewMessagePrompt setHidden:NO];
            [buttonConnect setHidden:YES];
            [indicateConnect startAnimating];
            break;
            
        case kShowPromptContactsEmpty:
            [messageConnect setText:NSLocalizedString(@"AB ERROR", nil)];
            [self.searchDisplayController.searchBar setHidden:YES];
            [self.viewMessagePrompt setHidden:NO];
            [buttonConnect setHidden:YES];
            [indicateConnect stopAnimating];
            break;
            
        case kShowPromptContactsError:
            [messageConnect setText:NSLocalizedString(@"AB NO ENTRIES", nil)];
            [self.searchDisplayController.searchBar setHidden:YES];
            [self.viewMessagePrompt setHidden:NO];
            [buttonConnect setHidden:YES];
            [indicateConnect stopAnimating];
            break;
            
        case kShowPromptFacebookActivity:
            [messageConnect setText:NSLocalizedString(@"FB ACTIVITY", nil)];
            [self.searchDisplayController.searchBar setHidden:YES];
            [self.viewMessagePrompt setHidden:NO];
            [buttonConnect setHidden:YES];
            [indicateConnect startAnimating];
            break;
            
        case kShowPromptFacebookConnect:
            [messageConnect setText:NSLocalizedString(@"FB CONNECT", nil)];
            [self.searchDisplayController.searchBar setHidden:YES];
            [self.viewMessagePrompt setHidden:NO];
            [buttonConnect setHidden:NO];
            [indicateConnect stopAnimating];
            break;
            
        case kShowPromptFacebookError:
            [messageConnect setText:NSLocalizedString(@"FB ERROR", nil)];
            [self.searchDisplayController.searchBar setHidden:YES];
            [self.viewMessagePrompt setHidden:NO];
            [buttonConnect setHidden:NO];
            [indicateConnect stopAnimating];
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 20) {
        if (buttonIndex == 0) {
            [defaults setBool:YES forKey:@"showFriendNotification"];
        }
    }
}

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

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"Connection failed: %@", [error description]);
    if ([ref isEqualToString:@"requestContacts"]) {
        [refreshTimer invalidate];
        refreshTimer = nil;
    }
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    // NSLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"]) {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"saveFacebook"]) {
        if ([dictJSON objectForKey:@"code"]) {
            [fbHelper logout];
            [self switchPromptMessage:kShowPromptFacebookError];
        } else {
            [self requestFriends];
        }
    } else if ([ref isEqualToString:@"requestContacts"]) {
        
        if ([dictJSON objectForKey:@"tt_friends"]) {
            
            CoreDataClass *core = [[CoreDataClass alloc] init];
            NSArray *ttFriends = [dictJSON objectForKey:@"tt_friends"];
            
            NSMutableArray *arrDoesHaveTT = [[NSMutableArray alloc] init];
            NSMutableArray *arrDontHaveTT = [[NSMutableArray alloc] init];
            
            NSInteger peopleCount = [userInfo count];
            for (NSInteger i = 0; i < peopleCount; i++) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[userInfo objectAtIndex:i]];
                
                BOOL onTT = NO;
                for (NSDictionary *friend in ttFriends) {
                    if ([[dict objectForKey:@"addressbookid"] isEqualToNumber:[friend objectForKey:@"unique_id"]]) {
                        [dict setValue:[friend objectForKey:@"user_id"] forKey:@"user_id"];
                        [dict setValue:[friend objectForKey:@"person_id"] forKey:@"id"];
                        onTT = YES;
                        break;
                    }
                }
                
                if (onTT) {
                    
                    NSString *strUserId = [[dict objectForKey:@"id"] stringValue];
                    
                    NSString *where = [NSString stringWithFormat:@"id=%@ AND (status='invited' OR is_friend = 1) AND first_name != '%@' AND last_name != '%@'", strUserId, [defaults objectForKey:@"UserFirstName"], [defaults objectForKey:@"UserLastName"]];
                    if ([core doesDataExist:@"People" Conditions:where]) {
                        [dictActivity setObject:@"set" forKey:strUserId];
                    }
                    
                    [arrDoesHaveTT addObject:dict];
                } else {
                    [arrDontHaveTT addObject:dict];
                }
            }
            
            // Set the property that contains address book contacts
            self.arrMyContacts = [NSMutableArray arrayWithObjects:arrDoesHaveTT, arrDontHaveTT, nil];
            
            // Set the property that will be used to output the table
            self.arrMyContacts = [self removeMeAndDuplicates:arrMyContacts];
            self.arrCellData = [NSMutableArray arrayWithArray:arrMyContacts];
            [self.tableContacts reloadData];
            
            [self switchPromptMessage:kHidePrompt];
            [refreshTimer invalidate];
            refreshTimer = nil;
            
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:recordStart];
            TFLog(@"Completed request contacts time: %f", interval);
        }
    }
}

// Send contacts to the server to find people that have this app
- (void)requestContacts:(NSMutableArray *)people
{
    recordStart = [NSDate date];
    
    [self rotateRefresh];
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    NSInteger peopleCount = [people count];
    for (int i = 0; i < peopleCount; i++) {
        NSDictionary *dict = [people objectAtIndex:i];
        
        NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                                [dict objectForKey:@"addressbookid"], @"unique_id",
                                [NSString stringWithFormat:@"AB%@",[dict objectForKey:@"addressbookid"]], @"id",
                                [dict objectForKey:@"email"], @"emails",
                                [dict objectForKey:@"phone"], @"phones",
                                nil];
        
        [contacts addObject:person];
    }
    
    TFLog(@"Contact count: %i", [contacts count]);
    
    NSDictionary *dictAPI = [NSDictionary dictionaryWithObject:contacts forKey:@"contacts"];
    
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@contact/search",kAPIURL];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"requestContacts"];
    [APIrequest setUserInfo:people];
    [APIrequest apiCall:jsonData Method:@"POST" URL:url];
}

- (void)reloadTable {
    [self populateTableCellData];
    [self.tableContacts reloadData];
}

- (void)requestFriends
{
    [self rotateRefresh];
    
    // Make the API request
    NSString *url;
    NSString *selector;
    url = [NSString stringWithFormat:@"%@contact",kAPIURL];
    selector = @"reloadFriends";
    
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 nil];
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:selector object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:selector object:nil];
    
    [serverConnection setRefreshTimer:refreshTimer];
    [serverConnection startQueue];
}

- (IBAction)refreshTapped
{
    if (viewToDisplay == kShowContacts) {
        
        // bug #US18 Original
        arrAddressBookPeople = [self getAllAddressBookPeople];
        
        if ([arrAddressBookPeople count] > 0) {
            NSMutableArray *arrSortedPeople = [self sortPeopleByFirstName:arrAddressBookPeople];
            if ([defaults boolForKey:@"ABAccess"]) {
                [self requestContacts:arrSortedPeople];
            } else {
                self.arrMyContacts = [NSMutableArray arrayWithObjects:[[NSArray alloc] init], arrSortedPeople, nil];
                self.arrCellData = [NSMutableArray arrayWithArray:arrMyContacts];
                [self.tableContacts reloadData];
            }
        }
    } else {
        [self requestFriends];
    }
}

- (void)rotateRefresh
{
    [refreshTimer invalidate];
    refreshTimer = nil;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:44];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 target: self selector:@selector(hadleTimer:) userInfo: nil repeats: YES];
    
    [UIView commitAnimations];
}

- (void)hadleTimer:(NSTimer *)timer
{
	refreshAngle += 0.1;
	if (refreshAngle > 6.283) { 
		refreshAngle = 0;
	}
	
	CGAffineTransform transform=CGAffineTransformMakeRotation(refreshAngle);
	bttnRefresh.transform = transform;
}

- (IBAction)buttonTapped:(id)sender
{
    UIButton *button = (UIButton *)sender;
    UIView *parentView = (UIView *)button.superview;
    
    // Find the table cell view
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    
    // Find the check mark image
    UIImageView *checkmark = (UIImageView *)[cell viewWithTag:4005];
    
    NSIndexPath *indexPath;
    if (isSearchResults) {
        indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
    } else {
        indexPath = [self.tableContacts indexPathForCell:cell];
    }
    
    NSDictionary *dict = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (indexPath.section == 0) {
        button.hidden = YES;
        checkmark.hidden = NO;
        
        NSString *strUserId = [[dict objectForKey:@"id"] stringValue];
        [dictActivity setValue:@"set" forKey:strUserId];
        
        CoreDataClass *core = [[CoreDataClass alloc] init];
        NSString *where = [NSString stringWithFormat:@"id = %@", strUserId];
        NSArray *results = [core searchEntity:@"People" Conditions:where Sort:@"" Ascending:NO andLimit:1];
        if ([results count] > 0) {
            NSManagedObject *object = [results objectAtIndex:0];
            [object setValue:@"invited" forKey:@"status"];
            [core saveContext];
        }
        
        // Prepare the json data
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:strUserId, @"person_id", nil];
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        
        // Make the API request
        NSString *url = [NSString stringWithFormat:@"%@contact", kAPIURL];
        NSString *selector = @"addFriend";
        NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                     url, @"url",
                                     selector, @"selector",
                                     @"POST", @"method",
                                     jsonString, @"json_string",
                                     @"", @"file_name",
                                     @"", @"file_path",
                                     [dict objectForKey:@"id"], @"id",
                                     nil];
        
        [[serverConnection arrRequests] addObject:dictRequest];
        [serverConnection startQueue];
        
        // Remove this person from suggestions
        if ([delegate respondsToSelector:@selector(removeSuggestion:)]) {
            [delegate removeSuggestion:[dict objectForKey:@"id"]];
        }
        
        // Notify the user
        if (![defaults boolForKey:@"showFriendNotification"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tongue-Tastic!" , nil)
                                                            message:NSLocalizedString(@"Now we are just waiting for your friend to accept you..." , nil)
                                                           delegate:self
                                                  cancelButtonTitle:@"Don't Tell Me Again"
                                                  otherButtonTitles:@"OK", nil];
            
            alert.tag = 20;
            [alert show];
        }
    } 
    else {
        if (!self.inviteView) {
            self.inviteView = [[InviteView alloc] initWithNibName:@"InviteView" bundle:nil];
        }
        
        [self.inviteView setDelegate:self];
        [self.inviteView setSentIndexPath:indexPath];
        [self.inviteView setDictPerson:dict];
        [self.inviteView resetEmail];
        if ([delegate respondsToSelector:@selector(addFriendsViewPushViewController:animated:)]) {
            [delegate addFriendsViewPushViewController:self.inviteView animated:YES];
        }       
    }
}

#pragma mark - Table View methods

- (void)populateTableCellData
{
    if (viewToDisplay == kShowFacebook) {
        CoreDataClass *core = [[CoreDataClass alloc] init];
        
        NSString *where = [NSString stringWithFormat:@"on_tt = 1 AND facebook_id > 0"];
        NSArray *results = [core getData:@"People" Conditions:where Sort:@"first_name" Ascending:YES];
        NSMutableArray *arrDoesHaveTT = [core convertToDict:results];
        
        where = [NSString stringWithFormat:@"on_tt = 0 AND facebook_id > 0"];
        results = [core getData:@"People" Conditions:where Sort:@"first_name" Ascending:YES];
        NSMutableArray *arrDontHaveTT = [core convertToDict:results];
        
        self.arrFbContacts = [NSMutableArray arrayWithObjects:arrDoesHaveTT, arrDontHaveTT, nil];
        
        // set the property that will be used to output the table
        self.arrFbContacts = [self removeMeAndDuplicates:arrFbContacts];
        self.arrCellData = [NSMutableArray arrayWithArray:arrFbContacts];
        
        if ([defaults integerForKey:@"LoginMode"] == LoginModeFacebook) {
            [self switchPromptMessage:kHidePrompt];
        }
    }
    else {
        [self switchPromptMessage:kHidePrompt];
    }
    [refreshTimer invalidate];
    refreshTimer = nil;
}

- (NSMutableArray *)removeMeAndDuplicates:(NSMutableArray *)people {
    NSString *prevFirst = @"";
    NSString *prevLast = @"";
    NSString *myFirstName = [defaults objectForKey:@"UserFirstName"];
    NSString *myLastName = [defaults objectForKey:@"UserLastName"];
    for (int i=0; i<[people count];i++) {
        NSMutableArray *arrTemp = [people objectAtIndex:i];
        for (int j=0; j<[[people objectAtIndex:i] count]; j++) {
            NSMutableDictionary *itemAtIndex = [arrTemp objectAtIndex:j];
            if (([[[itemAtIndex objectForKey:@"first_name"] lowercaseString] isEqualToString:[myFirstName lowercaseString]] && [[[itemAtIndex objectForKey:@"last_name"] lowercaseString] isEqualToString:[myLastName lowercaseString]]) || ([[[itemAtIndex objectForKey:@"first_name"] lowercaseString] isEqualToString:[prevFirst lowercaseString]] && [[[itemAtIndex objectForKey:@"last_name"] lowercaseString] isEqualToString:[prevLast lowercaseString]])) {
                [arrTemp removeObjectAtIndex:j];
            }
            prevFirst = [itemAtIndex objectForKey:@"first_name"];
            prevLast = [itemAtIndex objectForKey:@"last_name"];
        }
        [people replaceObjectAtIndex:i withObject:arrTemp];
    }
    
    return people;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.arrCellData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.arrCellData objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 67;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.arrSectionTitles objectAtIndex:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
    // Create label with section title
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(17, 4, 302, 23)];
    sectionLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    sectionLabel.textColor = [UIColor colorWithRed:0.372 green:0.372 blue:0.372 alpha:1.0];
    sectionLabel.backgroundColor = [UIColor clearColor];
    sectionLabel.text = sectionTitle;
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 31)];
    view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"category_title_bar.png"]];
    [view addSubview:sectionLabel];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([[self.arrCellData objectAtIndex:section] count]) {
        return 31;
    } else {
        return 0;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UIImageView *rowIcon, *imgFrame, *checkImage;
    UILabel *mainLabel;
    UIButton *actionButton;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // row icon
        rowIcon = [[UIImageView alloc] initWithFrame:CGRectMake(13, 12, 42, 42)];
        rowIcon.contentMode = UIViewContentModeScaleAspectFill;
        rowIcon.tag = 4000;
        [cell.contentView addSubview:rowIcon];
        
        // image frame
        imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_contacts.png"]];
        imgFrame.tag = 4001;
        imgFrame.frame = CGRectMake(10, 9, 48, 48);
        [cell.contentView addSubview:imgFrame];
        
        // main label
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 24, 180, 20)];
        mainLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
        mainLabel.textColor = [UIColor colorWithRed:0.463 green:0.463 blue:0.459 alpha:1.0];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4002;
        [cell.contentView addSubview:mainLabel];
        
        // action button
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        actionButton.frame = CGRectMake(249, 17, 65, 33);
        actionButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        [actionButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [actionButton setTitleShadowColor:[UIColor colorWithWhite:1.0 alpha:1] forState:UIControlStateNormal];
        [actionButton setTitleColor:[UIColor colorWithRed:0.5137 green:0.5137 blue:0.5137 alpha:1.0] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
		[actionButton setBackgroundColor:[UIColor clearColor]];
        [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        actionButton.tag = 4003;
        [cell.contentView addSubview:actionButton];
        
        // check mark
        checkImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bttn_add_done"]];
        checkImage.frame = CGRectMake(271, 21, 30, 23);
        checkImage.hidden = YES;
        checkImage.tag = 4005;
        [cell.contentView addSubview:checkImage];
        
    } else {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        mainLabel = (UILabel *)[cell viewWithTag:4002];
        actionButton = (UIButton *)[cell viewWithTag:4003];
        checkImage = (UIImageView *)[cell viewWithTag:4005];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    // Set the row icon
    if (viewToDisplay == kShowContacts) {
        rowIcon.image = [dict objectForKey:@"photo"];
    } else {
        rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath];
    }
    
    // Set the main label
    mainLabel.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
    
    if (indexPath.section == 0) {
        [actionButton setTitle:NSLocalizedString(@"ADD", nil) forState:UIControlStateNormal];        
    }
    else {
        [actionButton setTitle:NSLocalizedString(@"INVITE", nil) forState:UIControlStateNormal];
    }
    
    
    // set the activity indicator, add button, and check mark
    NSString *tempStatus;
    if ([[dict objectForKey:@"status"] isKindOfClass:[NSString class]]) {
        tempStatus = [dict objectForKey:@"status"];
    } else {
        tempStatus = @"";
    }
    
    // set the activity indicator, add button, and check mark
    NSString *status;
    if ([[dict objectForKey:@"id"] isKindOfClass:[NSNumber class]]) {
        NSString *strUserId = [[dict objectForKey:@"id"] stringValue];
        status = [dictActivity objectForKey:strUserId];
    }
    if ([status isEqualToString:@"set"]) {
        actionButton.hidden = YES;
        checkImage.hidden = NO;
    } else if ([[dict objectForKey:@"is_friend"] intValue] || [tempStatus isEqualToString:@"invited"]) {
        actionButton.hidden = YES;
        checkImage.hidden = NO;
    } else {
        actionButton.hidden = NO;
        checkImage.hidden = YES;
    }

    return cell;
}

#pragma mark - Asynchronous image loading methods

- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath
{
    if (![[cellData objectForKey:@"photo"] isKindOfClass:[NSString class]]) {
        return defaultImage;
    }
    
    if ([cellData objectForKey:@"is_friend"]) {
        UIImage *local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
        if (local) {
            return local;
        }
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:[cellData objectForKey:@"id"]];
    if (objImage == nil) {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = indexPath;
        objImage.delegate = self;
        [dictDownloadImages setObject:objImage forKey:[cellData objectForKey:@"id"]];
        [objImage imageFromURL:[cellData objectForKey:@"photo"]];
        
    } else if (objImage.cachedImage) {
        return objImage.cachedImage;
    }
    return defaultImage;
}

- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image userInfo:(id)userInfo
{
    NSIndexPath *indexPath = (NSIndexPath *)userInfo;
    UITableViewCell *cell;
    if (isSearchResults) {
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    } else {
        cell = [self.tableContacts cellForRowAtIndexPath:indexPath];
    }
    UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
    rowIcon.image = image;
}

#pragma mark - Search table methods

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    UIImageView *anImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    controller.searchResultsTableView.backgroundView = anImage;
    controller.searchResultsTableView.separatorColor = SEPARATOR_LINE_COLOR;
}

- (void)resetSearch
{
    [self.arrCellData removeAllObjects];
    if (viewToDisplay == kShowContacts) {
        [self.arrCellData addObjectsFromArray:arrMyContacts];
        
        self.arrSectionTitles = [NSMutableArray arrayWithObjects:
                                 NSLocalizedString(@"TT CONTACTS", nil), 
                                 NSLocalizedString(@"INVITE TO TT", nil),
                                 nil];
    } else {
        [self.arrCellData addObjectsFromArray:arrFbContacts];
        
        self.arrSectionTitles = [NSMutableArray arrayWithObjects:
                                 NSLocalizedString(@"TT FRIENDS", nil), 
                                 NSLocalizedString(@"FB FRIENDS", nil),
                                 nil];
    }
    
    isSearchResults = NO;
}

- (void)handleSearchForTerm:(NSString *)searchText
{
    NSMutableArray *arrSearch;
    if (viewToDisplay == kShowFacebook) {
        arrSearch = [arrFbContacts mutableDeepCopy];
    } else {
        arrSearch = [arrMyContacts mutableDeepCopy];
    }

    int sectionCount = [arrSearch count];
    for (int i = 0; i < sectionCount; i++) {
        
        int searchCount = [[arrSearch objectAtIndex:i] count];
        NSMutableIndexSet *rowsToRemove = [[NSMutableIndexSet alloc] init];
        
        for (int j = 0; j < searchCount; j++) {
            NSDictionary *dict = [[arrSearch objectAtIndex:i] objectAtIndex:j];
            NSString *fullname = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
            if ([fullname rangeOfString:searchText options:NSCaseInsensitiveSearch].location == NSNotFound) {
                [rowsToRemove addIndex:j];
            }
        }
        
        if (rowsToRemove.count > 0) {
            [[arrSearch objectAtIndex:i] removeObjectsAtIndexes:rowsToRemove];
        }
    }
    
    NSString *searchTitle = [NSString stringWithFormat:NSLocalizedString(@"TOP RESULTS", nil), searchText];
    NSString *inviteSectionTitle;
    if (viewToDisplay == kShowContacts) {
        inviteSectionTitle = NSLocalizedString(@"INVITE TO TT", nil);
    }
    else {
        inviteSectionTitle = NSLocalizedString(@"FB FRIENDS", nil);
    }
    self.arrSectionTitles = [NSMutableArray arrayWithObjects:
                             searchTitle,
                             inviteSectionTitle,
                             nil];

    [self.arrCellData removeAllObjects];
    [self.arrCellData addObjectsFromArray:arrSearch];
    isSearchResults = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        [self resetSearch];
        [self.tableContacts reloadData];
        return;
    }
    [self handleSearchForTerm:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchDisplayController.searchBar.text = @"";
    [self resetSearch];
    [self.tableContacts reloadData];
    [searchBar resignFirstResponder];
}


@end
