//
//  BlockListView.m
//  Tongue Tango
//
//  Created by Adnan@Sohail on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "BlockListView.h"

@interface BlockListView ()

@end

@implementation BlockListView

@synthesize arrBlockList;
@synthesize arrCellData;
@synthesize dictBlockList;
@synthesize dictDownloadImages;
@synthesize theHUD;
@synthesize serverConnection,blockListTableView;
@synthesize arrBlockGroup;

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
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"BLOCK LIST", nil)];
    
     serverConnection = [ServerConnection sharedInstance];
    
    CoreDataClass *core = [[CoreDataClass alloc] init];
    
    self.arrBlockGroup = [core convertToDict:[core getData:@"BlockedGroups" Conditions:@"" Sort:@"name" Ascending:YES]];
    self.arrCellData = [core convertToDict:[core getData:@"BlockedPeople" Conditions:@"" Sort:@"first_name" Ascending:YES]];
    [self.blockListTableView reloadData];
    
    isAnyBlockedFriendOrGroup  = NO;
    [self queryBlockFriends];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self.dictDownloadImages removeAllObjects];
    
    [self setDictBlockList:nil];
    [self setArrBlockList:nil];
    [self setArrCellData:nil];
    [self setTheHUD:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [arrBlockList removeAllObjects];
    
    //[self populateTableCellData];
    [blockListTableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //self.fieldGroupTitle.text = @"";
    [theHUD hide];
}


-(void) queryBlockFriends
{
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@contact/block", kAPIURL]; //New v2
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"blocklist"];
    [APIrequest apiCall:nil Method:@"GET" URL:url];
}

- (void)setVisibleLoadingView:(BOOL)isVisible
{
    DLog(@"%@", (isVisible ? @"YES": @"NO"));
    if (isVisible)
    {
        [self.navigationController.navigationBar setUserInteractionEnabled:NO];
        [theHUD show];
    }
    else {
        [self.navigationController.navigationBar setUserInteractionEnabled:YES];
        [theHUD hide];
    }
}

- (void)connectionAlert:(NSString *)message
{
     [self.navigationController.view setUserInteractionEnabled:YES];
    if (!message) {
        message = NSLocalizedString(@"LOGIN ERROR MESSAGE", nil);
    }
    
    DLog(@"Login Error: %@",message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN ERROR" , nil)
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
     [self.navigationController.view setUserInteractionEnabled:YES];
    DLog(@"Connection failed: %@", [error description]);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONNECT ERROR" , nil)
                                                    message:NSLocalizedString(@"UNABLE TO CONNECT", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
    [self setVisibleLoadingView:NO];
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    if ([dictJSON objectForKey:@"code"])
    {
        [self setVisibleLoadingView:NO];
        
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"blocklist"])
    {
        //BOOL isAnyBlockedFriendOrGroup  = NO;
        CoreDataClass *core = [[CoreDataClass alloc] init];
        if ([dictJSON objectForKey:@"block_list"])
        {
            self.dictBlockList              = (NSMutableDictionary *)dictJSON;
            NSArray *arrBlockedFriendsList  = (NSArray *)[dictJSON objectForKey:@"block_list"];
            
            if([arrBlockedFriendsList count] > 0)
            {
                isAnyBlockedFriendOrGroup   = YES;
//                [self populateTableCellData];
                [self.blockListTableView reloadData];
            }
            else{
                
                [core deleteAll:@"BlockedPeople" Conditions:@""];
                [core saveContext];
            }
             [self populateTableCellData];
            [blockListTableView reloadData];
        }
        
        if ([dictJSON objectForKey:@"block_group_list"])
        {
            NSArray *arrBlockedGroupsList   = (NSArray *)[dictJSON objectForKey:@"block_group_list"];
            self.arrBlockGroup              = (NSMutableArray *)[NSMutableArray arrayWithArray:arrBlockedGroupsList];
            
            if([arrBlockedGroupsList count] > 0)
            {
                isAnyBlockedFriendOrGroup   = YES;
               // [self populateTableCellData];
             
            }
            else{
                [core deleteAll:@"BlockedGroups" Conditions:@""];
                [core saveContext];
                
            }
             [self populateTableCellData];
               [blockListTableView reloadData];
            
            [self.navigationController.view setUserInteractionEnabled:YES];
        }
        
        //>     If no blocked friend or group, display a message
        if(!isAnyBlockedFriendOrGroup)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tongue Tango" , nil)
                                                            message:NSLocalizedString(@"No Records Found.", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil, nil];
            [alert show];
            [self.blockListTableView reloadData];
            [self.navigationController.view setUserInteractionEnabled:YES];
        }
    }
    
    if([ref isEqualToString:@"unblock"])
    {
        DLog(@"unblock response : %@",[dictJSON description]);
        
        [self.arrCellData removeAllObjects];
        [self.arrBlockGroup removeAllObjects];
        [self queryBlockFriends];
        
        
        if(isGroupUnBlocked){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadGroups" object:nil];
        }
        else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"queueFriends" object:nil];
        }
    }
}

- (void)populateTableCellData
{
    NSArray *members = (NSArray *)[dictBlockList objectForKey:@"block_list"];
    
    self.arrCellData = (NSMutableArray *)members;
    
    [blockListTableView reloadData];
}


#pragma mark UITableViewDelegate


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
    return result;
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:self.blockListTableView titleForHeaderInSection:section];
    
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
    
    return view;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 31;
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    int result;
    if(section == 0)
    {
        result = [self.arrBlockGroup count];
    }
    else
    {
        result = [self.arrCellData count];
    }
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 67;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UIImageView *rowIcon;
    UIImageView *imgFrame;
    UILabel *mainLabel;
    UIButton *actionButton;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
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
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 25, 250, 19)];
        mainLabel.font = [UIFont boldSystemFontOfSize:19];
        mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4002;
        [cell.contentView addSubview:mainLabel];
        
        // action button
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        actionButton.frame = CGRectMake(248, 17, 65, 33);
        actionButton.tag = 4003;
        actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [actionButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [actionButton setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
        [actionButton setTitle:NSLocalizedString(@"Unblock", nil) forState:UIControlStateNormal];
        [actionButton setTitle:NSLocalizedString(@"", nil) forState:UIControlStateSelected];
        [actionButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        [actionButton setImage:[UIImage imageNamed:@"bttn_add_done"] forState:UIControlStateSelected];
        [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
    }
    else
    {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        imgFrame = (UIImageView *)[cell viewWithTag:4001];
        mainLabel = (UILabel *)[cell viewWithTag:4002];
        actionButton = (UIButton *)[cell viewWithTag:4003];
        
        actionButton.selected = NO;
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        
    }
    
    // set the contacts info
    rowIcon.image = [UIImage imageNamed:@"userpic_placeholder_male"];
    imgFrame.hidden = NO;
    
    // Get the data for this cell
    NSDictionary *dict;
    
    if(indexPath.section == 0)
    {
        dict                = [self.arrBlockGroup objectAtIndex:indexPath.row];
        mainLabel.text      = [NSString stringWithFormat:@"%@",[dict objectForKey:@"name"]];
        rowIcon.image       = [self downloadCellImage:dict forIndexPath:indexPath imageType:kGroupImage];
    }
    else
    {
        dict                = [self.arrCellData objectAtIndex:indexPath.row];
        
        
        NSString *lastName = [NSString stringWithFormat:@"%@",[dict objectForKey:@"last_name"]==nil?[dict objectForKey:@"lastname"]:[dict objectForKey:@"last_name"]];
       
        if([lastName length] > 0)
        {
            lastName = [lastName substringToIndex:1];
            lastName = [NSString stringWithFormat:@"%@...",lastName];
        }
       

        NSString *firstName     = [NSString stringWithFormat:@"%@",[dict objectForKey:@"first_name"]==nil?[dict objectForKey:@"firstname"]:[dict objectForKey:@"first_name"]];
        mainLabel.text = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        rowIcon.image       = [self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
    }

    return cell;
}

-(void) unblockFriend:(NSString *) blockedUserId
{
    
    CoreDataClass *core = [[CoreDataClass alloc] init];
    [core deleteAll:@"BlockedPeople" Conditions:[NSString stringWithFormat:@"user_id = %@",blockedUserId]];
    
    isAnyBlockedFriendOrGroup = YES;
    NSString *url = [NSString stringWithFormat:@"%@contact/unblock?id=%@",kROOTURL,blockedUserId]; //New v2
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"unblock"];
    [APIrequest apiCall:nil Method:@"POST" URL:url];
}

-(void) unblockGroup:(NSString *) blockedGroupId
{
    
    CoreDataClass *core = [[CoreDataClass alloc] init];
    [core deleteAll:@"BlockedGroups" Conditions:[NSString stringWithFormat:@"id = %@",blockedGroupId]];
    
    isAnyBlockedFriendOrGroup = YES;
    NSString *url = [NSString stringWithFormat:@"%@group/unblock?id=%@",kROOTURL,blockedGroupId]; //New v2
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"unblock"];
    [APIrequest apiCall:nil Method:@"POST" URL:url];
}

- (IBAction)buttonTapped:(id)sender
{
    
    UIButton *button = (UIButton *)sender;
    
    
    [self.navigationController.view setUserInteractionEnabled:NO];
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [blockListTableView indexPathForCell:cell];

    if(indexPath.section == 0)
    {
        if([self.arrBlockGroup count] > indexPath.row )
        {
            NSDictionary *dict = [self.arrBlockGroup objectAtIndex:indexPath.row];
            
            DLog(@"Dictinary : %@",[dict description]);
            button.selected = !button.selected;
            if (button.selected) {
                [button setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
            } else {
                [button setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
            }
            
            isGroupUnBlocked = YES;
            [self unblockGroup:[dict objectForKey:@"group_id"]];
        }
        
    }
    else
    {
        
        if([self.arrCellData count] > indexPath.row )
        {
            NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
            button.selected = !button.selected;
            if (button.selected) {
                [button setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
            } else {
                [button setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
            }
            
            isGroupUnBlocked = NO;
            [self unblockFriend:[dict objectForKey:@"blocked_user_id"]];
        }
    }
    

}


#pragma mark - Asynchronous image loading methods

- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType
{
    UIImage *imageDefault = [UIImage imageNamed:@"userpic_placeholder_male"];
    NSString *imageID;
    BOOL savedLocal;
    
    if (imageType == kUserImage)
    {
        imageID = [NSString stringWithFormat:@"u%@", [cellData objectForKey:@"id"]];
        
        savedLocal = YES;
    }
    else
    {
        //imageID = [NSString stringWithFormat:@"g%@", [cellData objectForKey:@"id"]];
        imageID = [NSString stringWithFormat:@"GroupImage%@", [cellData objectForKey:@"id"]];
       
        savedLocal = YES;
    }

    
    if (![[cellData objectForKey:@"photo"] isKindOfClass:[NSString class]])
    {
        return imageDefault;
    }
    
    if (savedLocal)
    {
        UIImage *local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
        if (local)
        {
            return local;
        }
        else
        {
            local = [SquareAndMask imageFromDevice:imageID];
            if (local)
            {
                return local;
            }
        }

        
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:imageID];
    if (objImage == nil)
    {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = indexPath;
        objImage.personId = [cellData objectForKey:@"id"];
        objImage.delegate = self;
        objImage.saveLocally = savedLocal;
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
    if (userInfo)
    {
        NSIndexPath *indexPath = (NSIndexPath *)userInfo;
        UITableViewCell *cell = [blockListTableView cellForRowAtIndexPath:indexPath];
        UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
        rowIcon.image = image;
    }
}


@end
