//
//  FriendsListView.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/9/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "FriendsListView.h"
#import "AddContactsToGroupView.h"
#import "AppDelegate.h"
#import "RemoveFromGroupView.h"
#import "Constants.h"
#import "UAPush.h"

#define k_UIAlertView_Tag_RemoveMe          200

static NSDateFormatter *sUserVisibleDateFormatter;

@implementation FriendsListView

@synthesize showBackButton;
@synthesize arrFriends;
@synthesize arrGroups;
@synthesize arrCellData;
@synthesize arrSectionTitles;
@synthesize dictActivity;
@synthesize dictDownloadImages;
@synthesize groupFriend;

@synthesize bttnRefresh;
@synthesize labelSubtitle;
@synthesize tableFriends;

@synthesize addContactsToGroupView;
@synthesize addFriendsView;
@synthesize homeView;
@synthesize dictSelectedGroup = _dictSelectedGroup;
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

    if (self.addContactsToGroupView.view.superview == nil) {
        self.addContactsToGroupView = nil;
    }
}

#pragma mark - Navigation bar buttons

- (void)openAddFriendsView
{
    
}

- (void)openAddContactsToGroupView {
    if (!self.addContactsToGroupView) {
        self.addContactsToGroupView = [[AddContactsToGroupView alloc] initWithNibName:@"AddContactsToGroupView" bundle:nil];
    }
    [self.addContactsToGroupView setDictGroup:nil];
    [self.addContactsToGroupView setRemoveFromGroupView:nil];
    [self.navigationController pushViewController:self.addContactsToGroupView animated:YES];
}

- (void)createAddButton:(NSString *)type
{
    UIImage *image;
    SEL select;
    if ([type isEqualToString:@"Friend"]) {
        image = [UIImage imageNamed:@"bttn_nav_add_friend"];
        select = @selector(openAddFriendsView);
    } else {
        image = [UIImage imageNamed:@"bttn_nav_add_group"];
        select = @selector(openAddContactsToGroupView);
    }
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:select];
    self.navigationItem.rightBarButtonItem = button;
}

- (void)createMenuButton
{
    UIImage *image = [UIImage imageNamed:@"icon_menu"];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(toggleMove)];
    self.navigationItem.leftBarButtonItem = button;
}

- (IBAction)goHome:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createHomeButton {
    UIImage *image = [UIImage imageNamed:@"bttn-home"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(goHome:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = barButton;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Friends List View."];
    
    // Set the backbround image for this view
    self.tableFriends.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:@"TONGUE TANGO"];
    
    // Set the custom buttons in the navigation bar
    if (!showBackButton) {
        [self createHomeButton];
    }
    [self createRefreshButton];
    
    serverConnection = [ServerConnection sharedInstance];
    
    // Set a default user image
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    defaultGroup = [UIImage imageNamed:@"userpic_placeholder_group"];
    self.dictDownloadImages = [NSMutableDictionary dictionary];
    self.dictActivity = [[NSMutableDictionary alloc] init];
    
}

- (void)viewDidUnload
{
    [self.dictDownloadImages removeAllObjects];
    
    [self setArrFriends:nil];
    [self setArrGroups:nil];
    [self setArrCellData:nil];
    [self setArrSectionTitles:nil];
    [self setDictActivity:nil];
    [self setBttnRefresh:nil];
    [self setLabelSubtitle:nil];
    [self setTableFriends:nil];
    
    [self setAddContactsToGroupView:nil];
    [self setAddFriendsView:nil];
    [self setHomeView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    processCall = YES;
    [self switchTables:nil];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"ThemeID"] == 0)
    {
        self.searchDisplayController.searchBar.tintColor = [UIColor blackColor];
    }
    else
    {
        UIColor *themeColor;
        themeColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                     green:([defaults integerForKey:@"ThemeGreen"]/255.0) 
                                      blue:([defaults integerForKey:@"ThemeBlue"]/255.0) 
                                     alpha:1];
        self.searchDisplayController.searchBar.tintColor = themeColor;
    }
    
    //[self.tableFriends reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationReceived:) name:@"pushNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    processCall = NO;
    
    [requestTimer invalidate];
    requestTimer = nil;
    
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadFriendsOnly" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadGroups" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)pushNotificationReceived:(NSNotification *)notification {
    [self requestData];
}

#pragma mark - Delete files from the device

- (void)deleteUserImage:(NSString *)photo
{
    if ([photo isKindOfClass:[NSString class]]) {
        NSString *strURL = (NSString *)photo;
        
        // Find the image on the device
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *fileName = [[strURL lastPathComponent] stringByDeletingPathExtension];
        
        if ([fileName length] > 0) {
            if ([fileName isEqualToString:@"picture"]) {
                NSArray *pathParts = [strURL componentsSeparatedByString:@"/"];
                fileName = [NSString stringWithFormat:@"%@-userimage", [pathParts objectAtIndex:([pathParts count] - 2)]];
            }
            
            // Build the full path
            NSString *imagePath = [documentsPath stringByAppendingPathComponent:fileName];
            TFLog(@"Deleting image: %@", imagePath);
            
            // Delete the image file from the device.
            NSError *error = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            BOOL isDir;
            if ([fileManager fileExistsAtPath:imagePath isDirectory:&isDir] && !isDir) {
                [fileManager removeItemAtPath:imagePath error:&error];        
                if (error) {
                    DLog("An error occurred while deleting the file.");
                }
            }
        }
    }
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

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"Connection failed: %@", [error description]);
    callInProgress = NO;
    
    if ([ref isEqualToString:@"buttonAction"])
    {
        NSString *strUserId = (NSString *)userInfo;
        [dictActivity removeObjectForKey:strUserId];
    }
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"FriendsListView->connectionDidFinishLoading");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    // NSLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"])
    {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if([ref isEqualToString:@"reject"])
    {
        DLog(@"API: %@", dictJSON);
        
        [self requestData];
    }
}

- (void)requestData
{
    [self rotateRefresh];
    
    // Make the API request
    NSString *url;
    NSString *selector;
    if (currentTable == kListFriends)
    {
        url = [NSString stringWithFormat:@"%@contact",kAPIURL];
        selector = @"reloadFriendsOnly";
    }
    else
    {
        url = [NSString stringWithFormat:@"%@group/list",kAPIURL];
        selector = @"reloadGroups";
    }
    
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

- (void)reloadTable {
    [self populateTableCellData];
    [tableFriends reloadData];
}

- (IBAction)refreshTapped
{
    [self requestData];
}

- (void)rotateRefresh
{
    [refreshTimer invalidate];
    refreshTimer = nil;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:44];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 target:self selector:@selector(hadleTimer:) userInfo:nil repeats:YES];
    
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
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath;
    if (isSearchResults) {
        indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
    } else {
        indexPath = [self.tableFriends indexPathForCell:cell];
    }
    
    NSDictionary *dict = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (indexPath.section == 2) {
        
        // Open the Home view
        [homeView setSendTo:[[dict objectForKey:@"user_id"] intValue]];
        [homeView setSendType:@"ToFriend"];
        [self.navigationController popViewControllerAnimated:YES];
        
    } else {
        
        // Find the check mark
        UIImageView *checkmark = (UIImageView *)[cell viewWithTag:4005];
        checkmark.hidden = NO;
        button.hidden = YES;
        
        NSString *strUserId = [[dict objectForKey:@"id"] stringValue];
        [dictActivity setValue:@"set" forKey:strUserId];
        
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
        
        // Update core data
        CoreDataClass *core = [[CoreDataClass alloc] init];
        NSString *where = [NSString stringWithFormat:@"id = %@", strUserId];
        NSArray *results = [core searchEntity:@"People" Conditions:where Sort:@"" Ascending:NO andLimit:1];
        if ([results count] > 0) {
            NSManagedObject *object = [results objectAtIndex:0];
            [object setValue:[NSNumber numberWithInt:1] forKey:@"is_friend"];
            [object setValue:nil forKey:@"status"];
            [core saveContext];
        }
    }
}

-(void)handleRemoveMeButton:(id)sender
{
    DLog(@"handle Remove me ");
    
    if (self.dictSelectedGroup)
    {
        NSString *blockedGroupId = [self.dictSelectedGroup objectForKey:@"id"];
        
        NSString *url = [NSString stringWithFormat:@"%@group/reject/%@",kROOTURL,blockedGroupId]; //New v2
        
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"reject"];
        [APIrequest apiCall:nil Method:@"GET" URL:url];
    }
}

#pragma mark - Table View Methods

- (void)populateTableCellData {
    CoreDataClass *core = [CoreDataClass sharedInstance];
    
    if (currentTable == kListFriends) {
        // Set the property that contains pending, and active friends
        NSArray *results = [core getData:@"People" Conditions:@"is_friend = 0 AND status = 'invited_you'" Sort:@"first_name" Ascending:YES];
        NSMutableArray *arrPending = [core convertToDict:results];
        
        results = [core getData:@"People" Conditions:@"is_friend = 1" Sort:@"first_name" Ascending:YES];
        NSMutableArray *arrActive  = [core convertToDict:results];
        
        self.arrSectionTitles = [NSMutableArray arrayWithObjects:
                                 @"",
                                 NSLocalizedString(@"PENDING FRIENDS", nil),
                                 NSLocalizedString(@"ACTIVE FRIENDS", nil),
                                 nil];
        
        NSArray *arrAddFriends = [[NSArray alloc] initWithObjects:
                                  [NSDictionary dictionaryWithObject:NSLocalizedString(@"ADD FRIENDS", nil) forKey:@"message"], nil];
        arrPending = [self sortPeopleByFirstName:arrPending];
        arrActive = [self sortPeopleByFirstName:arrActive];
        
        self.arrFriends  = [NSMutableArray arrayWithObjects:arrAddFriends, arrPending, arrActive, nil];
        self.arrCellData = [NSMutableArray arrayWithArray:arrFriends];
    } 
    else {
        if ([self.searchDisplayController.searchBar.text length] == 0) {
            // Set the property that contains the groups
            NSArray *results = [core getData:@"Groups" Conditions:@"delete_date = nil" Sort:@"name" Ascending:YES];
            NSMutableArray *arrTempGroups = [core convertToDict:results];
            
            self.arrSectionTitles = [NSMutableArray arrayWithObjects:@"", nil];
            self.arrGroups  = [NSMutableArray arrayWithObject:arrTempGroups];
            self.arrGroups = [self sortPeopleByFirstName:arrGroups];
            self.arrCellData = [NSMutableArray arrayWithArray:arrGroups];
        }
        else {
            [self handleSearchForTerm:self.searchDisplayController.searchBar.text];
        }
    }
    [refreshTimer invalidate];
    refreshTimer = nil;
}

- (void)switchTables:(id)sender
{
    if ([groupFriend isEqualToString:@"Groups"]) {
        currentTable = kListGroups;
        
        labelSubtitle.text = NSLocalizedString(@"GROUPS", nil);
        [self createAddButton:@"Group"];
        [self requestData];
    } else {
        currentTable = kListFriends;
        
        labelSubtitle.text = NSLocalizedString(@"FRIENDS", nil);
        [self createAddButton:@"Friend"];
        if (!showBackButton) {
            [self requestData];
        } else {
            requestTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(requestData) userInfo:nil repeats:NO];
        }
    }
    [self populateTableCellData];
    [tableFriends reloadData];
}

// Sort an array of people by their first name
- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people
{
    NSArray *descriptors;
    if (currentTable == kListFriends) {
        NSSortDescriptor *firstDescriptor =
        [[NSSortDescriptor alloc] initWithKey:@"first_name"
                                    ascending:YES
                                     selector:@selector(localizedCaseInsensitiveCompare:)];
        
        NSSortDescriptor *lastDescriptor =
        [[NSSortDescriptor alloc] initWithKey:@"last_name"
                                    ascending:YES
                                     selector:@selector(localizedCaseInsensitiveCompare:)];
        descriptors = [NSArray arrayWithObjects:firstDescriptor, lastDescriptor, nil];
    } else {
        NSSortDescriptor *firstDescriptor =
        [[NSSortDescriptor alloc] initWithKey:@"name"
                                    ascending:YES
                                     selector:@selector(localizedCaseInsensitiveCompare:)];
        descriptors = [NSArray arrayWithObjects:firstDescriptor, nil];
    }
    
    NSArray *arrSorted = [people sortedArrayUsingDescriptors:descriptors];
    
    return [NSMutableArray arrayWithArray:arrSorted];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict      = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (currentTable == kListFriends)
    {
        [[self.arrCellData objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
        
        NSArray *deleteIndexPaths = [NSArray arrayWithObject:indexPath];
        [self.tableFriends beginUpdates];
        [self.tableFriends deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableFriends endUpdates];
        
        [self.arrFriends removeAllObjects];
        [self.arrFriends addObjectsFromArray:self.arrCellData];
        
        NSString *strUserId = [[dict objectForKey:@"id"] stringValue];
        [dictActivity removeObjectForKey:strUserId];
        
        CoreDataClass *core = [[CoreDataClass alloc] init];
        NSString *where = [NSString stringWithFormat:@"id = %@", strUserId];
        NSArray *results = [core searchEntity:@"People" Conditions:where Sort:@"" Ascending:NO andLimit:1];
        if ([results count] > 0)
        {
            NSManagedObject *object = [results objectAtIndex:0];
            [object setValue:[NSNumber numberWithInt:0] forKey:@"is_friend"];
            [object setValue:nil forKey:@"status"];
            [core saveContext];
        }
        
        // prepare the json data
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:[dict objectForKey:@"id"], @"user_id", nil];
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        
        // Make the API request
        NSString *url = [NSString stringWithFormat:@"%@contact?person_id=%@", kAPIURL, [dict objectForKey:@"id"]];
        
        NSString *selector = @"deleteFriend";
        
        NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                     url, @"url",
                                     selector, @"selector",
                                     @"DELETE", @"method",
                                     jsonString, @"json_string",
                                     @"", @"file_name",
                                     @"", @"file_path",
                                     [dict objectForKey:@"id"], @"id",
                                     nil];
        
        [[serverConnection arrRequests] addObject:dictRequest];
        
        [serverConnection startQueue];
    } 
    else
    {
        NSInteger myUserID = [[NSUserDefaults standardUserDefaults] integerForKey:@"UserID"];
        
        if ([[dict objectForKey:@"user_id"] intValue] == myUserID)
        {
            [self.arrGroups removeAllObjects];
            [self.arrGroups addObjectsFromArray:self.arrCellData];
           
            // Delete the image file from the device.
            if ([[dict objectForKey:@"photo"] isKindOfClass:[NSString class]]) {
                [self deleteUserImage:[dict objectForKey:@"photo"]];
            }
            
            CoreDataClass *core = [CoreDataClass sharedInstance];
            NSString *conditions = [NSString stringWithFormat:@"id = %@", [dict objectForKey:@"id"]];
            NSArray *result = [core searchEntity:@"Groups" Conditions:conditions Sort:@"" Ascending:NO andLimit:1];
            
            if (result) {
                NSManagedObject *object = [result objectAtIndex:0];
                
                if (sUserVisibleDateFormatter == nil) {
                    sUserVisibleDateFormatter = [[NSDateFormatter alloc] init];
                    [sUserVisibleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                }
                NSDate *dateFromString = [sUserVisibleDateFormatter dateFromString:@"2001-01-01 00:00:00"];
                [object setValue:dateFromString forKey:@"delete_date"];
            }
            
            //lets remove that from local db
            
            
            NSString *strWhere1,*strWhere;
            strWhere1 = [NSString stringWithFormat:@"group_id = %@", [dict objectForKey:@"id"]];
            strWhere = [NSString stringWithFormat:@"group_id = %@", [dict objectForKey:@"id"]];
          
            
            [core deleteAll:@"Message_threads" Conditions:strWhere1];
            [core deleteAll:@"Messages" Conditions:strWhere];
            
            [core saveContext];
            
            // Make the API request
//            NSString *url = [NSString stringWithFormat:@"%@group/%@", kAPIURL, [dict objectForKey:@"id"]];
             NSString *url = [NSString stringWithFormat:@"%@group/delete?id=%@", kAPIURL,[dict objectForKey:@"id"]];
            
            NSString *selector = @"deleteGroup";
            
            NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                         url, @"url",
                                         selector, @"selector",
                                         @"DELETE", @"method",
                                         @"", @"json_string",
                                         @"", @"file_name",
                                         @"", @"file_path",
                                         [dict objectForKey:@"id"], @"id",
                                         nil];
            
            [[serverConnection arrRequests] addObject:dictRequest];
            [serverConnection startQueue];
            
            [self handleSearchForTerm:@""];
            self.searchDisplayController.searchBar.text = @"";
            [self resetSearch];
            [self requestData];
            [self.tableFriends reloadData];
            
        } 
        else
        {
            self.dictSelectedGroup  = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REMOVE ME TITLE" , nil)
                                                            message:NSLocalizedString(@"REMOVE ME MESSAGE" , nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"CANCEL_BUTTON_TITLE", nil) 
                                                  otherButtonTitles:NSLocalizedString(@"YES_BUTTON_TITLE", nil), nil];
            alert.tag           = k_UIAlertView_Tag_RemoveMe;
            [alert show];
        }
    }
}

// Customize the number of sections in the table view.
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
    sectionLabel.font = [UIFont boldSystemFontOfSize:19];
    sectionLabel.textColor = [UIColor colorWithWhite:0.37 alpha:1];
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
    if ([[self.arrSectionTitles objectAtIndex:section] isEqualToString:@""]) {
        return 0;
    }
    
    if ([[self.arrCellData objectAtIndex:section] count]) {
        return 31;
    }
    
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (currentTable == kListFriends) {
        return NSLocalizedString(@"BLOCK", nil);
    } else {
        return NSLocalizedString(@"DELETE", nil);
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *AddIdentifier = @"AddCell";
    static NSString *FriendIdentifier = @"FriendCell";
    static NSString *GroupIdentifier = @"GroupCell";
    
    UIImageView *rowIcon, *checkImage;
    UIImageView *imgFrame;
    UILabel *mainLabel;
    UIButton *actionButton;
    
    UITableViewCell *cell = nil;
    if (currentTable == kListFriends) {
        
        if (indexPath.section == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:AddIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AddIdentifier];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                
                // main label
                mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 24, 185, 20)];
                mainLabel.backgroundColor = [UIColor clearColor];
                mainLabel.font = [UIFont boldSystemFontOfSize:19];
                mainLabel.text = NSLocalizedString(@"ADD FRIENDS", nil);
                mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
                [cell.contentView addSubview:mainLabel];
                
            }
        } 
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:FriendIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FriendIdentifier];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                // row icon
                rowIcon = [[UIImageView alloc] initWithFrame:CGRectMake(13, 12, 42, 42)];
                rowIcon.contentMode = UIViewContentModeScaleAspectFill;
                rowIcon.backgroundColor = [UIColor clearColor];
                rowIcon.tag = 4000;
                [cell.contentView addSubview:rowIcon];
                
                // image frame
                imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_contacts.png"]];
                imgFrame.tag = 4001;
                imgFrame.frame = CGRectMake(10, 9, 48, 48);
                [cell.contentView addSubview:imgFrame];
                
                // main label
                mainLabel = [[UILabel alloc] init];
                mainLabel.font = [UIFont boldSystemFontOfSize:19];
                mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
                mainLabel.backgroundColor = [UIColor clearColor];
                mainLabel.tag = 4002;
                [cell.contentView addSubview:mainLabel];
                
                // action button
                actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
                actionButton.frame = CGRectMake(249, 17, 65, 33);
                actionButton.tag = 4003;
                actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
                [actionButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
                [actionButton setTitle:NSLocalizedString(@"ACCEPT", nil) forState:UIControlStateNormal];
                [actionButton setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
                [actionButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
                [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
                [actionButton setBackgroundColor:[UIColor clearColor]];
                [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
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
            
            // set the row icon
            rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
            
            // set the main label
            mainLabel.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
            mainLabel.frame = CGRectMake(68, 24, 185, 20);
                        
            // set the action button and activity indicator
            if ([[dict objectForKey:@"is_friend"] intValue] == 1) {
                actionButton.hidden = YES;
                checkImage.hidden = YES;
            } else {
                NSString *status = [dictActivity objectForKey:[[dict objectForKey:@"id"] stringValue]];
                if ([status isEqualToString:@"set"]) {
                    actionButton.hidden = YES;
                    checkImage.hidden = NO;
                } else {
                    actionButton.hidden = NO;
                    checkImage.hidden = YES;
                }
            }
        }

    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:GroupIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GroupIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundColor = [UIColor clearColor];
            
            // row icon
            rowIcon = [[UIImageView alloc] initWithFrame:CGRectMake(13, 12, 42, 42)];
            rowIcon.contentMode = UIViewContentModeScaleAspectFill;
            rowIcon.backgroundColor = [UIColor clearColor];
            rowIcon.tag = 4000;
            [cell.contentView addSubview:rowIcon];
            
            // image frame
            imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_contacts.png"]];
            imgFrame.tag = 4001;
            imgFrame.frame = CGRectMake(10, 9, 48, 48);
            [cell.contentView addSubview:imgFrame];
            
            // main label
            mainLabel = [[UILabel alloc] init];
            mainLabel.font = [UIFont boldSystemFontOfSize:19];
            mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
            mainLabel.backgroundColor = [UIColor clearColor];
            mainLabel.tag = 4002;
            [cell.contentView addSubview:mainLabel];
        } else {
            rowIcon = (UIImageView *)[cell viewWithTag:4000];
            mainLabel = (UILabel *)[cell viewWithTag:4002];
        }
        // Get the data for this cell
        NSDictionary *dict = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        
        // set the row icon
        rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kGroupImage];
        
        // set the main label
        mainLabel.frame = CGRectMake(68, 24, 220, 20);
        mainLabel.text = [dict objectForKey:@"name"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (currentTable == kListFriends && indexPath.section == 0)
    {
        [self openAddFriendsView];
    } 
    else
        if (currentTable == kListGroups)
        {
            RemoveFromGroupView *removeFromGroupView = [[RemoveFromGroupView alloc] initWithNibName:@"RemoveFromGroupView" bundle:nil];
            NSDictionary *dict = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            removeFromGroupView.dictGroup = [NSMutableDictionary dictionaryWithDictionary:dict];
            [self.navigationController pushViewController:removeFromGroupView animated:YES];
        }
    
    [self.tableFriends deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Asynchronous image loading methods

- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType
{
    UIImage *imageDefault;
    NSString *imageID;
    if (imageType == kUserImage)
    {
        imageID = [NSString stringWithFormat:@"u%@", [cellData objectForKey:@"id"]];
        imageDefault = defaultImage;
    }
    else
    {
        imageID = [NSString stringWithFormat:@"g%@", [cellData objectForKey:@"id"]];
        
        /* Added By Aftab Baig */
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"GroupImage%@",
                                                                            [cellData objectForKey:@"id"]]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath])
        {
            UIImage *imgGroup = [SquareAndMask imageFromDevice:filePath];
            imageDefault = imgGroup;
        }
        else
        {
            imageDefault = defaultGroup;
        }
        /* End Added By Aftab Baig */
            
    }
    
    if (![[cellData objectForKey:@"photo"] isKindOfClass:[NSString class]])
    {
        return imageDefault;
    }
    
    UIImage *local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
    if (local)
    {
        return local;
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:imageID];
    if (objImage == nil)
    {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = indexPath;
        objImage.personId = [cellData objectForKey:@"id"];
        objImage.delegate = self;
        objImage.saveLocally = YES;
        [dictDownloadImages setObject:objImage forKey:imageID];
        [objImage imageFromURL:[cellData objectForKey:@"photo"]];
    }
    else
        if (objImage.cachedImage)
        {
            return objImage.cachedImage;
        }
    
    return imageDefault;
}

- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image userInfo:(id)userInfo
{
    NSIndexPath *indexPath = (NSIndexPath *)userInfo;
    UITableViewCell *cell;
    if (isSearchResults) {
        cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    } else {
        cell = [self.tableFriends cellForRowAtIndexPath:indexPath];
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
    if (currentTable == kListFriends) {
        self.arrSectionTitles = [NSMutableArray arrayWithObjects:
                                 @"",
                                 NSLocalizedString(@"PENDING FRIENDS", nil),
                                 NSLocalizedString(@"ACTIVE FRIENDS", nil),
                                 nil];
        
        [self.arrCellData addObjectsFromArray:arrFriends];
    } else {
        self.arrSectionTitles = [NSMutableArray arrayWithObjects:@"", nil];
        [self.arrCellData addObjectsFromArray:arrGroups]; 
    }
    isSearchResults = NO;
}

- (void)handleSearchForTerm:(NSString *)searchText
{
    NSMutableArray *arrSearch;
    if (currentTable == kListFriends)
    {
        arrSearch = [arrFriends mutableDeepCopy];
    }
    else
    {
        arrSearch = [arrGroups mutableDeepCopy];
    }
    
    int sectionCount = [arrSearch count];
    for (int i = 0; i < sectionCount; i++) {
        
        int searchCount = [[arrSearch objectAtIndex:i] count];
        NSMutableIndexSet *rowsToRemove = [[NSMutableIndexSet alloc] init];
        
        for (int j = 0; j < searchCount; j++) {
            NSDictionary *dict = [[arrSearch objectAtIndex:i] objectAtIndex:j];
            NSString *name;
            if (currentTable == kListFriends) {
                name = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
            } else {
                name = [dict objectForKey:@"name"];
            }
            if ([name rangeOfString:searchText options:NSCaseInsensitiveSearch].location == NSNotFound) {
                [rowsToRemove addIndex:j];
            }
        }
        
        if (rowsToRemove.count > 0)
        {
            [[arrSearch objectAtIndex:i] removeObjectsAtIndexes:rowsToRemove];
        }
    }
    
    [self.arrCellData removeAllObjects];
    [self.arrCellData addObjectsFromArray:arrSearch];
    isSearchResults = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0)
    {
        [self resetSearch];
        [self.tableFriends reloadData];
        return;
    }
    [self handleSearchForTerm:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchDisplayController.searchBar.text = @"";
    [self resetSearch];
    [self.tableFriends reloadData];
    [searchBar resignFirstResponder];
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

#pragma mark - Alert View

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == k_UIAlertView_Tag_RemoveMe)
    {
        if (buttonIndex == 1)
        {
            [self handleRemoveMeButton:nil];
        }
    }
}

@end
