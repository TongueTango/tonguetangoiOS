//
//  NotificationsView.m
//  Tongue Tango
//
//  Created by Johana Moccetti on 7/24/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "NotificationsView.h"
#import "CoreDataClass.h"
#import "UA_SBJsonWriter.h"
#import "SquareAndMask.h"
#import "ServerConnection.h"
#import "MessageThreadDetailView.h"
#import "AppDelegate.h"

#define SEGMENTED_CONTROL_MESSAGES_INDEX 0
#define SEGMENTED_CONTROL_INVITATIONS_INDEX 1


@interface NotificationsView ()

@end


static NSDateFormatter *sUserVisibleDateFormatter;

@implementation NotificationsView

@synthesize tableView;
@synthesize arrPendingFriends;
@synthesize arrPendingGroups;
@synthesize typeSegmentedControl;
@synthesize serverConnection;
@synthesize arrMessages;
@synthesize bttnRefreshFriends;
@synthesize bttnRefreshMessages;
@synthesize titleLabel;
@synthesize isGroupInvitationArrived;
@synthesize notifyView;
@synthesize lblNotifyMessage;
@synthesize notifyMessage;
@synthesize arrPendingFriendsTemp;
@synthesize arrPendingGroupsTemp;
@synthesize arrMessagesTemp;
@synthesize dictCollapse;
@synthesize activityIndicator;
@synthesize isFriendPushNotify;
@synthesize isExternalPush;
@synthesize isExternalPushFrnd;
//@synthesize segmentedControlView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil showPendingFriends:(BOOL)show
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        showPendingFriends = show;
        loadInvitations = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    //>---------------------------------------------------------------------------------------------------
    //>     Setup refresh header view
    //>---------------------------------------------------------------------------------------------------
    if (_refreshHeaderView == nil)
    {
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		view.delegate = self;
		[self.tableView addSubview:view];
		_refreshHeaderView = view;
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    serverConnection = [ServerConnection sharedInstance];
    
    // Customize segment controller title
    [self.typeSegmentedControl setTitle:NSLocalizedString(@"MESSAGES", nil) 
                      forSegmentAtIndex:SEGMENTED_CONTROL_MESSAGES_INDEX];
    
    [self.typeSegmentedControl setTitle:NSLocalizedString(@"INVITATIONS LABEL", nil) 
                      forSegmentAtIndex:SEGMENTED_CONTROL_INVITATIONS_INDEX];
    
    titleLabel.font = [UIFont boldSystemFontOfSize:19];
    titleLabel.textColor = [UIColor colorWithWhite:0.37 alpha:1];
    titleLabel.backgroundColor = [UIColor clearColor];

    dictActivity = [[NSMutableDictionary alloc] init];
    
    //self.typeSegmentedControl.selectedSegmentIndex = showPendingFriends;
    
//    if (loadInvitations) {
//        [self requestInvitationsData];
//        loadInvitations = NO;
//    }
    
    arrMessagesTemp = [[NSMutableArray alloc] init];
    arrPendingFriendsTemp =[[NSMutableArray alloc] init];
    arrPendingGroupsTemp = [[NSMutableArray alloc] init];
    isLoading = NO;
    collapsSection = -1;
    
    dictCollapse = [[NSMutableDictionary alloc] init];
    
    if(self.isExternalPush)
    {
        [dictCollapse setObject:@"NO" forKey:@"0"];
    }
    else
    {
        [dictCollapse setObject:@"YES" forKey:@"0"];
    }
    if(self.isExternalPushFrnd)
    {
        [dictCollapse setObject:@"NO" forKey:@"1"];
    }
    else{
        [dictCollapse setObject:@"YES" forKey:@"1"];
    }
    
    [dictCollapse setObject:@"NO" forKey:@"2"];
    
    
    
    
}


-(void) hideNotification
{
    [UIView animateWithDuration :3
                           delay: 3
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          
                          notifyView.frame = CGRectMake(0, -50, 320, 46);
                          [self.tableView setFrame:CGRectMake(0, 0, 320, 416)];
                      }
                      completion:^(BOOL finished){
                           notifyView.alpha = 0;
                          
                          
                          //activityIndicator.hidden = NO;
                          [activityIndicator setFrame:CGRectMake(8, 48, 20, 20)];
                          //titleLabel.hidden = NO;
                          [titleLabel setFrame:CGRectMake(37,45,179,25)];
                      }];
}
-(void) showHideNotification
{
    //activityIndicator.hidden = YES;
    //titleLabel.hidden = YES;
    [activityIndicator setFrame:CGRectMake(8, -40, 20, 20)];
    [titleLabel setFrame:CGRectMake(37,-41,179,25)];
    notifyView.alpha = 1;
    [UIView animateWithDuration :2
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          
                          [self.tableView setFrame:CGRectMake(0, 46, 320, 400)];
                          notifyView.frame = CGRectMake(0, 0, 320, 46);
                      }
                      completion:^(BOOL finished){
                         // [self hideNotification];
                          [self performSelector:@selector(hideNotification) withObject:nil afterDelay:2];
                          
                      }];
}



- (void)btnEdit_Pressed
{
    if (self.tableView.editing)
    {
        [self.tableView setEditing:NO animated:YES];
        
        //>     Add Edit button on top bar
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(btnEdit_Pressed)];
        
        self.navigationItem.rightBarButtonItem = button;
    }
    else
    {
        [self.tableView setEditing:YES animated:YES];
        
        //>     Add Edit button on top bar
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(btnEdit_Pressed)];
        
        self.navigationItem.rightBarButtonItem = button;
    }
}


- (void)createEditButton
{
    //>     Add Edit button on top bar
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(btnEdit_Pressed)];
    
    self.navigationItem.rightBarButtonItem = button;
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

- (void)configureSegmentedControl:(UIColor *)color {
    
    [typeSegmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    typeSegmentedControl.tintColor = color;
    [typeSegmentedControl setSegmentedControlStyle:UISegmentedControlStyleBezeled];
    
    //segmentedControlView.backgroundColor = color;
}

- (void)viewWillAppear:(BOOL)animated { 
    
    [super viewWillAppear:animated];

    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"NOTIFICATIONS", nil)];
    
    if ([defaults integerForKey:@"ThemeID"] == 0) {
        themeColor = [UIColor darkGrayColor];
    } else {
        themeColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                     green:([defaults integerForKey:@"ThemeGreen"]/255.0) 
                                      blue:([defaults integerForKey:@"ThemeBlue"]/255.0) 
                                     alpha:1];
    }
    
    //[self configureSegmentedControl:themeColor];
    
    [self populateFriendsData];
    [self populateMessagesData];
    
    
    //[self configureTableTitle];
    self.bttnRefreshMessages.hidden = NO;
    self.bttnRefreshFriends.hidden = YES;
     
    //[self refreshTapped:nil];
    
     [self requestMessageThreads];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updateThread" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateMessagesData) name:@"updateThread" object:nil];
    
    ////self.isFriendPushNotify = YES;
    //self.notifyMessage = @"Ash is your friend now. :)";
    //if(self.isGroupInvitationArrived)
    //{
       // self.isGroupInvitationArrived = YES;
        //self.notifyMessage = @"You got new invitation from Group : My Testing Go Now.";
        //lblNotifyMessage.text = @"You got new invitation from Group : My Testing Go Now.";
      
      // lblNotifyMessage.text = self.notifyMessage;
       // [self showHideNotification];
        //[self performSelector:@selector(invitationClose) withObject:nil afterDelay:5.0];
    //}
}

-(void) invitationClose :(NSString *)key
{
    if([key isEqualToString:@"group"])
    {
        self.isGroupInvitationArrived = NO;
    }
    else
    {
        self.isFriendPushNotify = NO;
    }
    [self.tableView reloadData];
}

#pragma mark - read data from database

- (void)populateFriendsData {

    CoreDataClass *core = [CoreDataClass sharedInstance];
        
    NSArray *results = [core getData:@"People" 
                              Conditions:@"is_friend = 0 AND status = 'invited_you'" 
                                    Sort:@"first_name" 
                               Ascending:YES];
        
    NSMutableArray *arrPending = [core convertToDict:results];
    self.arrPendingFriends = [self sortPeopleByFirstName:arrPending];

    [refreshInvitationsTimer invalidate];
    refreshInvitationsTimer = nil;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate updatePendingFriends:[arrPending count]];
}


- (void)populateMessagesData {
    
    CoreDataClass *core = [CoreDataClass sharedInstance];
    NSArray *coreThreads = [core getData:@"Message_threads" Conditions:@"" Sort:@"create_date" Ascending:NO];
    
    NSArray *allFriends = [core getData:@"People" Conditions:@"is_friend > 0" Sort:@"" Ascending:YES];
    NSMutableDictionary *dictFriends = [[NSMutableDictionary alloc] init];
    for (NSManagedObject *friend in allFriends) {
        [dictFriends setObject:friend forKey:[friend valueForKey:@"user_id"]];
    }
    
    //For Blocked People
    NSArray *allBlockedFriends = [core getData:@"BlockedPeople" Conditions:@"" Sort:@"" Ascending:YES];
    for (NSManagedObject *friendblock in allBlockedFriends)
    {
        [dictFriends setObject:friendblock forKey:[friendblock valueForKey:@"user_id"]];
    }
    
    
    NSInteger unread = 0;
        
    NSMutableArray *arrData = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *thread in coreThreads)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [thread valueForKey:@"create_date"], @"create_date",
                                     [thread valueForKey:@"unread"], @"unread",
                                     [thread valueForKey:@"friend_id"], @"friend_id",
                                     [thread valueForKey:@"group_id"], @"group_id",
                                     [thread valueForKey:@"id"], @"thread_id",
                                     nil];
        unread += [[thread valueForKey:@"unread"] intValue];
        
        if ([[thread valueForKey:@"friend_id"] intValue] > 0) {
            // Add a persons data to the array
            NSManagedObject *object = [dictFriends objectForKey:[thread valueForKey:@"friend_id"]];
            
            if (object) {
                [dict setValue:[object valueForKey:@"id"] forKey:@"id"];
                [dict setValue:[object valueForKey:@"first_name"] forKey:@"first_name"];
                [dict setValue:[object valueForKey:@"last_name"] forKey:@"last_name"];
                [dict setValue:[object valueForKey:@"photo"] forKey:@"photo"];
            } else {
                [dict setValue:@"Unknown" forKey:@"first_name"];
                [dict setValue:@"User" forKey:@"last_name"];
            }
            [arrData addObject:dict];
        } else if ([[thread valueForKey:@"group_id"] intValue] > 0) {
            // Add a groups data to the array
            NSString *where = [NSString stringWithFormat:@"id = '%@'", [thread valueForKey:@"group_id"]];
            NSArray *group = [core searchEntity:@"Groups" Conditions:where Sort:@"" Ascending:NO andLimit:1];
            
            if ([group count] > 0) {
                NSManagedObject *object = [group objectAtIndex:0];
                
                [dict setValue:[object valueForKey:@"id"] forKey:@"id"];
                [dict setValue:[object valueForKey:@"name"] forKey:@"first_name"];
                [dict setValue:@"" forKey:@"last_name"];
                [dict setValue:[object valueForKey:@"photo"] forKey:@"photo"];
            } else {
                DLog(@"Unknown Group : %@",[thread description]);
                
                //Lets search in Block Group
                 NSArray *groupblock = [core searchEntity:@"BlockedGroups" Conditions:where Sort:@"" Ascending:NO andLimit:1];
                
                if ([groupblock count] > 0) {
                    NSManagedObject *object = [groupblock objectAtIndex:0];
                    
                    [dict setValue:[object valueForKey:@"id"] forKey:@"id"];
                    [dict setValue:[object valueForKey:@"name"] forKey:@"first_name"];
                    [dict setValue:@"" forKey:@"last_name"];
                    [dict setValue:[object valueForKey:@"photo"] forKey:@"photo"];
                }
                else{
                    [dict setValue:@"Unknown" forKey:@"first_name"];
                    [dict setValue:@"Group" forKey:@"last_name"];
                }
            }
            [arrData addObject:dict];
        }
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate updateUnreadMessages:unread];
    
    [refreshMessagesTimer invalidate];
    refreshMessagesTimer = nil;
    
    self.arrMessages = [NSMutableArray arrayWithArray:arrData];
    
    if([self.arrMessages count] > 0)
    {
        [self createEditButton];
    }
}


#pragma mark - table view methods

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    if(section == 0){
//        return  NSLocalizedString(@"PENDING FRIENDS", nil);
//    }
//    else if (section == 1)
//    {
//        return  NSLocalizedString(@"MESSAGES", nil);
//    }
//}
// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger result = 0;
    //if (self.typeSegmentedControl.selectedSegmentIndex == 1) {
    BOOL isCollapse = NO;
    if (section == 0)
    {
        
        if(self.isGroupInvitationArrived && [self.arrPendingGroups count] > 0)
            result = [self.arrPendingGroups count] + 1;
        else
            result = [self.arrPendingGroups count];
        
        if([self.arrPendingGroupsTemp count] > 0 && result == 0)
        {
            isCollapse = YES;
        }
        
        
    }
    else if (section == 1)
    {
        if(self.isFriendPushNotify && [self.arrPendingFriends count] > 0)
            result = [self.arrPendingFriends count] + 1;
        else
            result = [self.arrPendingFriends count];
        if([self.arrPendingFriendsTemp count] > 0 && result == 0)
        {
            isCollapse = YES;
        }
        
    }
    else
    {
            result = [self.arrMessages count];
        
            if([self.arrMessagesTemp count] > 0 && result == 0)
            {
                isCollapse = YES;
            }
    }

    NSString *strKey = [NSString stringWithFormat:@"%d",section];
    NSString *collapse = [dictCollapse objectForKey:strKey];
    
    if([collapse isEqualToString:@"YES"] )
    {
        isCollapse = YES;
       
       // collapsSection = -1;
        result = 0 ;
    }
    if([self.arrMessages count] == 0 && isDeleted && section == 2)
    {
        
        self.navigationItem.rightBarButtonItem = nil;
         [self.tableView setEditing:NO animated:YES];
        //[dictCollapse setObject:@"YES" forKey:@"2"];
        isDeleted = NO;
        isCollapse = YES;
        result = 0;
    }
    
    //For display message
    if (result == 0 && isCollapse == NO)
        result = 1;
    return result;
}

- (void)configureTableTitle {
    
    if (typeSegmentedControl.selectedSegmentIndex == 0) {
        showPendingFriends = NO;
        //titleLabel.text = NSLocalizedString(@"MESSAGES", nil);
        titleLabel.text = NSLocalizedString(@"NOTIFICATIONS", nil);
        self.bttnRefreshMessages.hidden = NO;
        self.bttnRefreshFriends.hidden = YES;
    }
    else {
        showPendingFriends = YES;
        titleLabel.text = NSLocalizedString(@"PENDING FRIENDS", nil);
        self.bttnRefreshMessages.hidden = YES;
        self.bttnRefreshFriends.hidden = NO;
    }
}

- (IBAction)changeNotificationsType:(id)sender {
   // [self configureTableTitle];
    [self.tableView reloadData];
}

// Sort an array of people by their first name
- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people {
    NSArray *descriptors;
    NSSortDescriptor *firstDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"first_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSSortDescriptor *lastDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"last_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    descriptors = [NSArray arrayWithObjects:firstDescriptor, lastDescriptor, nil];
    
    
    NSArray *arrSorted = [people sortedArrayUsingDescriptors:descriptors];
    return [NSMutableArray arrayWithArray:arrSorted];
}

- (UITableViewCell *) groupCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *FriendIdentifier = @"FriendCell";
    UIImageView *rowIcon, *checkImage;
    UIImageView *imgFrame;
    UILabel *mainLabel;
    UIButton *actionButton;
    UIButton *rejectButton;
    
    UITableViewCell *cell  = [self.tableView dequeueReusableCellWithIdentifier:FriendIdentifier];
    //cell = nil;
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
        mainLabel.font = [UIFont boldSystemFontOfSize:17];
        mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4002;
        [cell.contentView addSubview:mainLabel];
        
        // action button
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        actionButton.frame = CGRectMake(180, 17, 65, 33);
        actionButton.tag = 4003;
        actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [actionButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [actionButton setTitle:NSLocalizedString(@"ACCEPT", nil) forState:UIControlStateNormal];
        [actionButton setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
        [actionButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        [actionButton setBackgroundColor:[UIColor clearColor]];
        [actionButton addTarget:self action:@selector(buttonGroupAccept:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
        
        // // reject button
        rejectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rejectButton.frame = CGRectMake(249, 17, 65, 33);
        rejectButton.tag = 4004;
        rejectButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [rejectButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [rejectButton setTitle:NSLocalizedString(@"Reject", nil) forState:UIControlStateNormal];
        [rejectButton setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
        [rejectButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [rejectButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        [rejectButton setBackgroundColor:[UIColor clearColor]];
        [rejectButton addTarget:self action:@selector(buttonGroupReject:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:rejectButton];
        
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
    NSDictionary *dict;
    if(self.isGroupInvitationArrived){
        dict = [self.arrPendingGroups objectAtIndex:indexPath.row - 1 ];
    }
    else{
           dict = [self.arrPendingGroups objectAtIndex:indexPath.row];
    }
    
    // set the row icon
    rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
    
    // set the main label
    mainLabel.text = [NSString stringWithFormat:@"%@",[dict objectForKey:@"name"]];
    //mainLabel.autoresizesSubviews
    mainLabel.frame = CGRectMake(65, 24, 105, 20);
    
    // set the action button and activity indicator
    
    // set the action button and activity indicator
//    if ([[dict objectForKey:@"is_friend"] intValue] == 1) {
//        actionButton.hidden = YES;
//        checkImage.hidden = YES;
//    }
//    else {
//        NSString *status = [dictActivity objectForKey:[[dict objectForKey:@"id"] stringValue]];
//        if ([status isEqualToString:@"set"]) {
//            actionButton.hidden = YES;
//            checkImage.hidden = NO;
//        } else {
//            actionButton.hidden = NO;
//            checkImage.hidden = YES;
//        }
//    }
    return cell;
}


- (UITableViewCell *)friendCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *FriendIdentifier = @"FriendCell";
    UIImageView *rowIcon, *checkImage;
    UIImageView *imgFrame;
    UILabel *mainLabel;
    UIButton *actionButton;
    
    UITableViewCell *cell  = [self.tableView dequeueReusableCellWithIdentifier:FriendIdentifier];
    
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
   // NSDictionary *dict = [self.arrPendingFriends objectAtIndex:indexPath.row];
    
    NSDictionary *dict;
    if(self.isFriendPushNotify){
        dict = [self.self.arrPendingFriends objectAtIndex:indexPath.row - 1 ];
    }
    else{
        dict = [self.self.arrPendingFriends objectAtIndex:indexPath.row];
    }
    
    // set the row icon
    rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
    
    // set the main label
    mainLabel.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
    mainLabel.frame = CGRectMake(68, 24, 185, 20);
    
    // set the action button and activity indicator
    
    // set the action button and activity indicator
    if ([[dict objectForKey:@"is_friend"] intValue] == 1) {
        actionButton.hidden = YES;
        checkImage.hidden = YES;
    } 
    else {
        NSString *status = [dictActivity objectForKey:[[dict objectForKey:@"id"] stringValue]];
        if ([status isEqualToString:@"set"]) {
            actionButton.hidden = YES;
            checkImage.hidden = NO;
        } else {
            actionButton.hidden = NO;
            checkImage.hidden = YES;
        }
    }
    return cell;
}

- (UITableViewCell *)messageCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MessageCell";
    
    if (sUserVisibleDateFormatter == nil)
    {
        sUserVisibleDateFormatter = [[NSDateFormatter alloc] init];
        [sUserVisibleDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [sUserVisibleDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [sUserVisibleDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }
    else
    {
        [sUserVisibleDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [sUserVisibleDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [sUserVisibleDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }

    
    UIImageView *rowIcon, *imgFrame, *badgeView;
    UILabel *mainLabel, *detailLabel, *badgeLabel;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
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
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 16, 185, 20)];
        mainLabel.font = [UIFont boldSystemFontOfSize:19];
        mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4002;
        [cell.contentView addSubview:mainLabel];
        
        // detail label
        detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 35, 250, 19)];
        detailLabel.font = [UIFont systemFontOfSize:15];
        detailLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        detailLabel.backgroundColor = [UIColor clearColor];
        detailLabel.tag = 4003;
        [cell.contentView addSubview:detailLabel];
        
        // badge view
        badgeView = [[UIImageView alloc] init];
        badgeView.image = [[UIImage imageNamed:@"bg_menu_badge.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        badgeView.backgroundColor = themeColor;
        //[badgeView.layer setCornerRadius:2];
        badgeView.tag = 4004;
        [cell.contentView addSubview:badgeView];
        
        // badge label
        badgeLabel = [[UILabel alloc] init];
        badgeLabel.font = [UIFont boldSystemFontOfSize:16];
        badgeLabel.textAlignment = UITextAlignmentCenter;
        badgeLabel.textColor = [UIColor whiteColor];
        badgeLabel.tag = 4005;
        badgeLabel.backgroundColor = [UIColor clearColor];
        [badgeView addSubview:badgeLabel];
        
    } else {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        imgFrame = (UIImageView *)[cell viewWithTag:4001];
        mainLabel = (UILabel *)[cell viewWithTag:4002];
        detailLabel = (UILabel *)[cell viewWithTag:4003];
        badgeView = (UIImageView *)[cell viewWithTag:4004];
        badgeLabel = (UILabel *)[cell viewWithTag:4005];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [self.arrMessages objectAtIndex:indexPath.row];
    
    if ([[dict valueForKey:@"friend_id"] intValue] > 0) {
        rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
    } else {
        rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kGroupImage];
    }
    mainLabel.text = [NSString stringWithFormat:@"%@ %@", [dict objectForKey:@"first_name"], [dict objectForKey:@"last_name"]];
    
    if ([dict objectForKey:@"create_date"]) {
        detailLabel.text = [sUserVisibleDateFormatter stringFromDate:[dict objectForKey:@"create_date"]];
    }
    
    if ([[dict objectForKey:@"unread"] intValue] > 0) {
        badgeLabel.text = [NSString stringWithFormat:@"%@", [dict objectForKey:@"unread"]];
        CGFloat labelWidth = [self getLabelWidth:badgeLabel.text];
        badgeView.frame = CGRectMake(290 - labelWidth, 22, labelWidth, 22);
        badgeLabel.frame = CGRectMake(0, 0, labelWidth, 22);
        badgeView.hidden = NO;
    } else {
        badgeView.hidden = YES;
    }
    
    return cell;


}

- (UITableViewCell *) blankCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *BlankIdentifier = @"BlankCell";
  
    UILabel *mainLabel;
   
    
    UITableViewCell *cell  = [self.tableView dequeueReusableCellWithIdentifier:BlankIdentifier];
    cell = nil;
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BlankIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
       
        // main label
        mainLabel = [[UILabel alloc] init];
        mainLabel.font = [UIFont systemFontOfSize:14];
        mainLabel.textColor = [UIColor grayColor];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4002;
        mainLabel.textAlignment = UITextAlignmentCenter;
        mainLabel.frame = CGRectMake(10, 24, 300, 20);
        NSString *labelMessage = @"";
        if(indexPath.section == 0)
        {
            if(self.isGroupInvitationArrived)
            {
                
                labelMessage = self.notifyMessage;
                
            }
            else
            {
                labelMessage = @"You don't have any pending alerts.";
            }
        }
        else if (indexPath.section == 1)
        {
            
            if(self.isFriendPushNotify)
            {
                
                labelMessage = self.notifyMessage;
                
            }
            else
            {
                labelMessage = @"You don't have any pending alerts.";
            }

        }
        else if (indexPath.section == 2)
        {
            labelMessage = @"You don't have any pending messages for now.";
        }
        mainLabel.text = labelMessage;
        [cell.contentView addSubview:mainLabel];
    }
    return cell;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    //if (self.typeSegmentedControl.selectedSegmentIndex == 1) {
    if (indexPath.section == 0)
    {
        if([arrPendingGroups count] > 0)
        {
            if(self.isGroupInvitationArrived && indexPath.row == 0)
            {
                cell = [self blankCellForRowAtIndexPath:indexPath];    
            }
            else
            {
            
                cell = [self groupCellForRowAtIndexPath:indexPath];
            }
        }
        else {
            cell = [self blankCellForRowAtIndexPath:indexPath];
        }
    }
    else if (indexPath.section == 1)
    {
        if([arrPendingFriends count] > 0) {
            cell = [self friendCellForRowAtIndexPath:indexPath];
        }
        else {
            cell = [self blankCellForRowAtIndexPath:indexPath];
        }
    }
    else
    {
        if([arrMessages count] > 0)
        {
            cell = [self messageCellForRowAtIndexPath:indexPath];
        }
    
        else {
            cell = [self blankCellForRowAtIndexPath:indexPath];
        }
    }
    return cell;
        
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    return 67;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2)
    {
        return YES;
    }
    
    // Return YES if you want the specified item to be editable.
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Detemine if it's in editing mode
    if (self.tableView.editing)
    {
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get the message id
    NSDictionary *dict = [self.arrMessages objectAtIndex:indexPath.row];
    
    CoreDataClass *core = [[CoreDataClass alloc] init];
    
    NSString *strWhere1,*strWhere;
    
    if([[dict objectForKey:@"friend_id"] intValue] > 0 )
    {
        strWhere1 = [NSString stringWithFormat:@"friend_id = %@", [dict objectForKey:@"friend_id"]];
        strWhere = [NSString stringWithFormat:@"sender_id = %@", [dict objectForKey:@"friend_id"]];
    }
    else
    {
        strWhere1 = [NSString stringWithFormat:@"group_id = %@", [dict objectForKey:@"group_id"]];
        strWhere = [NSString stringWithFormat:@"group_id = %@", [dict objectForKey:@"group_id"]];
    }
    
    [core deleteAll:@"Message_threads" Conditions:strWhere1];
    [core deleteAll:@"Messages" Conditions:strWhere];
    [core saveContext];
    
    
    NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                             [dict objectForKey:@"thread_id"], @"thread_id",
                             [dict objectForKey:@"friend_id"], @"friend_id",
                             [dict objectForKey:@"group_id"], @"group_id",
                             nil];
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@message/deleteThread/", kAPIURL]; //New v2
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"deleteThread"];
    [APIrequest apiCall:jsonData Method:@"POST" URL:url];
    
    // Remove the row from the table
    [self.arrMessages removeObjectAtIndex:indexPath.row];
    NSArray *deleteIndexPaths = [NSArray arrayWithObject:indexPath];
    
    
    isDeleted = YES;
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}


-(void)checkIsLoading
{
	if(isLoading)
    {
		return;
	}
    else
    {
		//how far down did we pull?
		double down = tableView.contentOffset.y;
        DLog(@"Down : %f",down);
		//if(down <= -65)
        if(down <= -0)
        {
			
            isLoading = YES;
            [self requestMessageThreads];
		}
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //DLog(@"Scrollview down : %f",scrollView.contentOffset.y);
    
    //[self checkIsLoading];
}


//Refresh After invitation accept
-(void)refreshAfterAdd :(NSNotification *) notify
{
    if([self.arrPendingFriends count] > 0 )
    {
        [self.arrPendingFriends removeObjectAtIndex:selectedIndex];
        [self.tableView reloadData];
        DLog(@"refreshAfterAdd - Success");
    }
    DLog(@"refreshAfterAdd");
}

-(void)refreshAcceptRejectGroup :(NSNotification *) notify
{
    if([self.arrPendingGroups count] > 0 )
    {
        [self.arrPendingGroups removeObjectAtIndex:selectedIndex];
        [self.tableView reloadData];
        DLog(@"refreshAcceptRejectGroup - Success");
    }
}
-(void) AcceptOrRejectGroupCall:(BOOL) isAccept
{
    
    NSDictionary *dict = [self.arrPendingGroups objectAtIndex:selectedIndex];
    NSString *url;
    if(isAccept)
    {
        url = [NSString stringWithFormat:@"%@group/accept/%@", kAPIURL,[dict objectForKey:@"id"]];
            
    }
    else
    {
         url = [NSString stringWithFormat:@"%@group/reject/%@", kAPIURL,[dict objectForKey:@"id"]];
    }
    
    //Add friend selector
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"acceptRejectGroup" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAcceptRejectGroup:) name:@"acceptRejectGroup" object:nil];
    // Make the API request
   
   
    
    NSString *selector = @"acceptRejectGroup";
    
    NSDictionary *dictRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                 url, @"url",
                                 selector, @"selector",
                                 @"GET", @"method",
                                 @"", @"json_string",
                                 @"", @"file_name",
                                 @"", @"file_path",
                                 nil];
    
    [[serverConnection arrRequests] addObject:dictRequest];
    
    [serverConnection startQueue];

}

-(IBAction) buttonGroupReject:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSDictionary *dict = [self.arrPendingGroups objectAtIndex:indexPath.row];
    
    selectedIndex = indexPath.row;
    DLog(@"Accept group data : %@",[dict description]);
    [self AcceptOrRejectGroupCall:NO];
}
- (IBAction)buttonGroupAccept:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSDictionary *dict = [self.arrPendingGroups objectAtIndex:indexPath.row];
    
    selectedIndex = indexPath.row;
    
    DLog(@"Accept group data : %@",[dict description]);
    [self AcceptOrRejectGroupCall:YES];
    
}
- (IBAction)buttonTapped:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSDictionary *dict = [self.arrPendingFriends objectAtIndex:indexPath.row];
    
    
    selectedIndex = indexPath.row;
    //New for test
//    [self.arrPendingFriends removeObjectAtIndex:indexPath.row];
//    [self.tableView reloadData];
//    
//    return;
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
    
    
    
    //Add friend selector
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addFriend" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAfterAdd:) name:@"addFriend" object:nil];
    // Make the API request
    //NSString *url = [NSString stringWithFormat:@"%@contact", kAPIURL];
    NSString *url = [NSString stringWithFormat:@"%@contact/create", kAPIURL];
    
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


#pragma mark - Asynchronous image loading methods

- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType {
    
    UIImage *imageDefault;
    NSString *imageID;
    if (imageType == kUserImage) {
        imageID = [NSString stringWithFormat:@"u%@", [cellData objectForKey:@"id"]];
        imageDefault = [UIImage imageNamed:@"userpic_placeholder_male"];
    } else {
        imageID = [NSString stringWithFormat:@"g%@", [cellData objectForKey:@"id"]];
        imageDefault = [UIImage imageNamed:@"userpic_placeholder_group"];
    }
    
    if (![[cellData objectForKey:@"photo"] isKindOfClass:[NSString class]]) {
        return imageDefault;
    }
    
    UIImage *local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
    if (local) {
        return local;
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:imageID];
    if (objImage == nil) {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = indexPath;
        objImage.personId = [cellData objectForKey:@"id"];
        objImage.delegate = self;
        objImage.saveLocally = YES;
        [dictDownloadImages setObject:objImage forKey:imageID];
        [objImage imageFromURL:[cellData objectForKey:@"photo"]];
    } else if (objImage.cachedImage) {
        return objImage.cachedImage;
    }
    
    return imageDefault;
}

- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image userInfo:(id)userInfo {
    NSIndexPath *indexPath = (NSIndexPath *)userInfo;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
    rowIcon.image = image;
}

#pragma mark - API server methods

- (void)connectionAlert:(NSString *)message {
    
    if (!message) {
        message = NSLocalizedString(@"REQUEST ERROR MESSAGE", nil);
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REQUEST ERROR" , nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"Connection failed: %@", [error description]);
    callInProgress = NO;
    
    if ([ref isEqualToString:@"buttonAction"]) {
        NSString *strUserId = (NSString *)userInfo;
        [dictActivity removeObjectForKey:strUserId];
    }
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo {
    
    DLog(@"");
    
    if ([ref isEqualToString:@"buttonAction"]) {
        UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
        NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSDictionary *dictJSON = [parser objectWithString:responseString];
        
        if ([dictJSON objectForKey:@"code"]) {
            [self connectionAlert:[dictJSON objectForKey:@"message"]];
        }
    }
    else if ([ref isEqualToString:@"deleteThread"])
    {
        
        
        UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
        NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSDictionary *dictJSON = [parser objectWithString:responseString];
        
        if ([dictJSON objectForKey:@"code"])
        {
            [self connectionAlert:[dictJSON objectForKey:@"message"]];
        }
    
    }
    else {
        UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
        NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSDictionary *dictJSON = [parser objectWithString:responseString];
        
        if ([dictJSON objectForKey:@"code"]) {
            [self connectionAlert:[dictJSON objectForKey:@"message"]];
        }
        /*
         if (boolPushed) {
         boolPushed = NO;
         }*/
    }
}


- (void)requestMessageThreads
{
    NSString *url = [NSString stringWithFormat:@"%@message/conversations",kAPIURL];
    NSString *selector = @"reloadConversations";
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMessagesTable) name:selector object:nil];
    
    [serverConnection setRefreshTimer:refreshMessagesTimer];
    [serverConnection startQueue];
}

- (void)handleTimer:(NSTimer *)timer {
	angleMessages += 0.1;
	if (angleMessages > 6.283) { 
		angleMessages = 0;
	}
	
	CGAffineTransform transform=CGAffineTransformMakeRotation(angleMessages);
	bttnRefreshMessages.transform = transform;
}

- (void)rotateRefresh {
    [refreshMessagesTimer invalidate];
    refreshMessagesTimer = nil;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:44];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    refreshMessagesTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 
                                                            target:self 
                                                          selector:@selector(handleTimer:) 
                                                          userInfo:nil 
                                                           repeats:YES];
    
    [UIView commitAnimations];
}

- (CGFloat)getLabelWidth:(NSString *)text {
    CGSize constraint = CGSizeMake(320, 22);
    CGSize labelSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:16] 
                        constrainedToSize:constraint 
                            lineBreakMode:UILineBreakModeWordWrap];
    CGFloat labelWidth = labelSize.width + 14;
    
    return labelWidth;
}

- (void)reloadMessagesTable
{
    DLog(@"");
    
    [self populateMessagesData];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.arrPendingGroups = appDelegate.pendingGroups;
    
    [self.tableView reloadData];
    
    [self doneLoadingTableViewData];
    
    NSString *collapse = [dictCollapse objectForKey:@"0"];
    NSString *collapsefriend = [dictCollapse objectForKey:@"1"];
 
    if(self.isGroupInvitationArrived && [collapse isEqualToString:@"NO"])
    {
        NSString *key = @"group";
        [self performSelector:@selector(invitationClose:) withObject:key afterDelay:5.0];
    }
    //Check collapse and push
    if(self.isFriendPushNotify && [collapsefriend isEqualToString:@"NO"])
    {
        NSString *key = @"friend";
        [self performSelector:@selector(invitationClose:) withObject:key afterDelay:5.0];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2)
    {
        MessageThreadDetailView *messageThreadDetailView = [[MessageThreadDetailView alloc] initWithNibName:@"MessageThreadDetailView" 
                                                                                                     bundle:nil];
       
        NSDictionary *dict = [self.arrMessages objectAtIndex:indexPath.row];
        
        NSMutableDictionary *mDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
        
        if ([[dict objectForKey:@"friend_id"] intValue] > 0)
        {
            [mDict setValue:[dict objectForKey:@"friend_id"] forKey:kFriendKey];
            messageThreadDetailView.toID    = [[dict objectForKey:@"friend_id"] intValue];
        }
        
        messageThreadDetailView.dictPerson = mDict;
        [self.navigationController pushViewController:messageThreadDetailView animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *result = nil;

    if (section == 0)
    {
        result = NSLocalizedString(@"Groups", nil);
    }
    else if (section == 1)
    {
       result = NSLocalizedString(@"Friends", nil);
    }
    else
    {
        
        result = NSLocalizedString(@"MESSAGES", nil);
    }

//    if (typeSegmentedControl.selectedSegmentIndex == 0) {
//        result = NSLocalizedString(@"MESSAGES", nil);
//    }
//    else {
//        result = NSLocalizedString(@"PENDING FRIENDS", nil);
//    }
    return result;
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:self.tableView titleForHeaderInSection:section];
    
    if (sectionTitle == nil)
    {
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
    
    
    // row icon
    UIImageView *rowIcon = [[UIImageView alloc] initWithFrame:CGRectMake(300, 10, 9, 9)];
    rowIcon.contentMode = UIViewContentModeScaleAspectFill;
    rowIcon.backgroundColor = [UIColor clearColor];
    [rowIcon setImage:[UIImage imageNamed:@"DownArrow"]];
    
    rowIcon.tag = 4000;
    [view addSubview:rowIcon];
    
    
    UIButton *btnUpDown = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnUpDown setFrame:CGRectMake(0, 0, 320, 35)];
//    [btnUpDown setImage:[UIImage imageNamed:@"DownArrow"] forState:UIControlStateNormal];
//    [btnUpDown setImage:[UIImage imageNamed:@"UpArrow"] forState:UIControlStateSelected];
    btnUpDown.tag  = section;
    [btnUpDown addTarget:self action:@selector(collapseSection:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    if ([self.arrMessagesTemp count] > 0 && section == 2)
    {
        [rowIcon setImage:[UIImage imageNamed:@"UpArrow"]];
        [btnUpDown setSelected:YES];
    }
    else if ([self.arrPendingFriendsTemp count] > 0 && section == 1)
    {
        [rowIcon setImage:[UIImage imageNamed:@"UpArrow"]];
        [btnUpDown setSelected:YES];
    }
    else if ([self.arrPendingGroupsTemp count] > 0 && section == 0)
    {
        [rowIcon setImage:[UIImage imageNamed:@"UpArrow"]];
        [btnUpDown setSelected:YES];
    }
    
    
    NSString *strKey = [NSString stringWithFormat:@"%d",section];
    NSString *collapse = [dictCollapse objectForKey:strKey];
    
    if([collapse isEqualToString:@"YES"])
    {
         [btnUpDown setSelected:YES];
        [rowIcon setImage:[UIImage imageNamed:@"UpArrow"]];
    }


    [view addSubview:btnUpDown];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 31;
}


//Collapse Section
-(void) collapseSection:(id) sender
{
    UIButton *btn = (UIButton *) sender;
    
      
    if ([btn isSelected])
    {
        [btn setSelected:NO];
        
        BOOL isNeedRefresh = NO;
        if(btn.tag == 0)
        {
            DLog(@"Group Section Collapse Closed");
            self.arrPendingGroups = [NSMutableArray arrayWithArray:self.arrPendingGroupsTemp];
            [self.arrPendingGroupsTemp removeAllObjects];
            
            if([self.arrPendingGroups count] > 0)
            {
                isNeedRefresh = YES;
            }
        }
        else if (btn.tag == 1)
        {
            DLog(@"Friends Section Collapse Closed");
            self.arrPendingFriends = [NSMutableArray arrayWithArray:self.arrPendingFriendsTemp];
            [self.arrPendingFriendsTemp removeAllObjects];
            
            if([self.arrPendingFriends count] > 0)
            {
                isNeedRefresh = YES;
            }
        }
        else if (btn.tag == 2)
        {
            DLog(@"Messages Section Collapse Closed");
            self.arrMessages = [NSMutableArray arrayWithArray:self.arrMessagesTemp];
            [self.arrMessagesTemp removeAllObjects];
            
            if([self.arrMessages count] > 0)
            {
                isNeedRefresh = YES;
            }
        
        }
        
        NSString *strKey = [NSString stringWithFormat:@"%d",btn.tag];
        [dictCollapse setObject:@"NO" forKey:strKey];
        
        
        
        //Check now
        NSString *collapse = [dictCollapse objectForKey:@"0"];
        NSString *collapsefriend = [dictCollapse objectForKey:@"1"];
        
        if(self.isGroupInvitationArrived && [collapse isEqualToString:@"NO"])
        {
            NSString *key = @"group";
            [self performSelector:@selector(invitationClose:) withObject:key afterDelay:5.0];
        }
        //Check collapse and push
        if(self.isFriendPushNotify && [collapsefriend isEqualToString:@"NO"])
        {
            NSString *key = @"friend";
            [self performSelector:@selector(invitationClose:) withObject:key afterDelay:5.0];
        }
        

        //collapsSection = -1;
        //if(isNeedRefresh)
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:btn.tag] withRowAnimation:UITableViewRowAnimationFade];
        
    }
    else
    {
        [btn setSelected:YES];
        
        BOOL isNeedRefresh = NO;
        if(btn.tag == 0)
        {
            DLog(@"Group Section Collapse Open");
            self.arrPendingGroupsTemp = [NSMutableArray arrayWithArray:self.arrPendingGroups];
            [self.arrPendingGroups removeAllObjects];
            if([self.arrPendingGroupsTemp count] > 0)
            {
                isNeedRefresh = YES;
            }
        }
        else if (btn.tag == 1)
        {
            DLog(@"Friends Section Collapse Open");
            self.arrPendingFriendsTemp = [NSMutableArray arrayWithArray:self.arrPendingFriends];
            [self.arrPendingFriends removeAllObjects];
            
            if([self.arrPendingFriendsTemp count] > 0)
            {
                isNeedRefresh = YES;
            }
            
        }
        else if (btn.tag == 2)
        {
            DLog(@"Messages Section Collapse Open");
            self.arrMessagesTemp = [NSMutableArray arrayWithArray:self.arrMessages];
            [self.arrMessages removeAllObjects];
            
            if([self.arrMessagesTemp count] > 0)
            {
                isNeedRefresh = YES;
            }
        
        }
        
        
               
        NSString *strKey = [NSString stringWithFormat:@"%d",btn.tag];
        [dictCollapse setObject:@"YES" forKey:strKey];
      
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:btn.tag] withRowAnimation:UITableViewRowAnimationFade];
        
        
               
    }
    
    //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    //[self.tableView scrollToRowAtIndexPath:indexPath
    //                      atScrollPosition:UITableViewScrollPositionTop
    //                              animated:YES];
    
}
- (void)refreshTapped:(id)sender
{
    
    
    if (self.typeSegmentedControl.selectedSegmentIndex == 0)
    {
        [self requestMessageThreads];
    }
    else
    {
        [self requestInvitationsData];
    }
}

- (void)requestInvitationsData
{
    [self rotateRefreshInvitations];
    
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@contact",kAPIURL];
    NSString *selector = @"reloadFriendsOnly";
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFriendsTable) name:selector object:nil];
    
    [serverConnection setRefreshTimer:refreshInvitationsTimer];
    [serverConnection startQueue];
}

- (void)handleTimerInvitations:(NSTimer *)timer
{
	angleInvitations += 0.1;
	if (angleInvitations > 6.283)
    {
		angleInvitations = 0;
	}
	
	CGAffineTransform transform=CGAffineTransformMakeRotation(angleInvitations);
	bttnRefreshFriends.transform = transform;
}

- (void)rotateRefreshInvitations
{
    [refreshInvitationsTimer invalidate];
    refreshInvitationsTimer = nil;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:44];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    refreshInvitationsTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 
                                                            target:self 
                                                          selector:@selector(handleTimerInvitations:) 
                                                          userInfo:nil 
                                                           repeats:YES];
    
    [UIView commitAnimations];
}

- (void)reloadFriendsTable
{
    DLog(@"");
    
    [self populateFriendsData];
    
    // TODO stop the refresh button
    
    //if (self.typeSegmentedControl.selectedSegmentIndex == 1) {
        [self.tableView reloadData];
    //}
}

- (void)pushNotificationReceived:(NSDictionary *)userInfo
{
    NSDictionary *extras = [userInfo objectForKey:@"extra"];
    NSString *action = [extras objectForKey:@"action"];
    
    if ([action isEqualToString:NEW_MESSAGE_NOTIFICATION])
    {
        [self requestMessageThreads];
    } 
    else if ([action isEqualToString:FRIEND_REQUEST_NOTIFICATION])
    {
        [self requestInvitationsData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadConversations" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadFriendsOnly" object:nil];
    [refreshMessagesTimer invalidate];
    [refreshInvitationsTimer invalidate];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource
{
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	isLoading = YES;
    [self requestMessageThreads];
}

- (void)doneLoadingTableViewData
{
	//  model should call this when its done loading
	isLoading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return isLoading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [NSDate date]; // should return date data source was last changed
}

@end
