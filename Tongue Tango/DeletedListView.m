//
//  DeletedListView.m
//  Tongue Tango
//
//  Created by Adnan@Sohail on 9/24/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "DeletedListView.h"

@interface DeletedListView ()

@end

@implementation DeletedListView

@synthesize arrDeletedList;
@synthesize arrCellData;
@synthesize dictDeletedList;
@synthesize dictDownloadImages;
@synthesize theHUD;

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
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"DELETED LIST", nil)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self.dictDownloadImages removeAllObjects];
    
    [self setDictDeletedList:nil];
    [self setArrDeletedList:nil];
    [self setArrCellData:nil];
    [self setTheHUD:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [arrDeletedList removeAllObjects];
    
    //[self populateTableCellData];
    [self queryDeletedFriends];
    [deletedListTableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //self.fieldGroupTitle.text = @"";
    [theHUD hide];
}

#pragma  mark - delete list
-(void) queryDeletedFriends
{
    // Make the API request
    
    NSString *url = [NSString stringWithFormat:@"%@contact/delete",kROOTURL]; //New v2
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"deletelist"];
    [APIrequest apiCall:nil Method:@"POST" URL:url];
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
    
    if ([ref isEqualToString:@"deletelist"])
    {
        if ([dictJSON objectForKey:@"deleted_friend_list"])
        {
            dictDeletedList = (NSMutableDictionary *)dictJSON;
            NSArray *arrList = (NSArray *)[dictJSON objectForKey:@"deleted_friend_list"];
            
            if([arrList count] > 0)
            {
                [self populateTableCellData];
                [deletedListTableView reloadData];
            }
            else
            {
                
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tongue Tango" , nil)
                                                                message:NSLocalizedString(@"No Records Found.", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                      otherButtonTitles:nil, nil];
                [alert show];
                
            }
        }
    }
}


- (void)populateTableCellData
{
//    CoreDataClass *core = [[CoreDataClass alloc] init];
//    
//    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    // NSInteger myUserID = [defaults integerForKey:@"UserID"];
//    
//    NSArray *members = [[dictDeletedList objectForKey:@"members"] componentsSeparatedByString:@","];
//    
//    // Get the friends that are currently memmbers
//    NSMutableArray *arrTempMembers = [[NSMutableArray alloc] init];
//    for (NSString *member in members) {
//        NSString *where = [NSString stringWithFormat:@"user_id = %@", member];
//        NSArray *friend = [core searchEntity:@"People" Conditions:where Sort:@"" Ascending:YES andLimit:1];
//        
//        if ([friend count] > 0) {
//            [arrTempMembers addObject:[friend objectAtIndex:0]];
//            [arrDeletedList addObject:[[friend objectAtIndex:0] valueForKey:@"user_id"]];
//        }
//    }
//    
//    self.arrCellData = [NSMutableArray arrayWithArray:arrDeletedList];
    
     NSArray *members = (NSArray *)[dictDeletedList objectForKey:@"deleted_friend_list"];
    
    self.arrCellData = (NSMutableArray *)members;
    
    [deletedListTableView reloadData];
    
}


#pragma mark UITableViewDelegate
// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.arrCellData count];
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
    if (cell == nil) {
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
        [actionButton setTitle:NSLocalizedString(@"Add", nil) forState:UIControlStateNormal];
        [actionButton setTitle:NSLocalizedString(@"", nil) forState:UIControlStateSelected];
        [actionButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        [actionButton setImage:[UIImage imageNamed:@"bttn_add_done"] forState:UIControlStateSelected];
        [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
        
        
    } else {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        imgFrame = (UIImageView *)[cell viewWithTag:4001];
        mainLabel = (UILabel *)[cell viewWithTag:4002];
        actionButton = (UIButton *)[cell viewWithTag:4003];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    // set the contacts info
    rowIcon.image = [UIImage imageNamed:@"userpic_placeholder_male"];//[self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
    imgFrame.hidden = NO;
    
    mainLabel.text = [NSString stringWithFormat:@"%@",[dict objectForKey:@"username"]];
    
    return cell;
}

- (IBAction)buttonTapped:(id)sender
{
    
    UIButton *button = (UIButton *)sender;
    
    button.selected = !button.selected;
    if (button.selected) {
        [button setBackgroundImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    } else {
        [button setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
    }
    
    
}


#pragma mark - Asynchronous image loading methods

- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType
{
    UIImage *imageDefault;
    NSString *imageID;
    BOOL savedLocal;
    
    if (![[cellData objectForKey:@"photo"] isKindOfClass:[NSString class]]) {
        return imageDefault;
    }
    
    if (savedLocal) {
        UIImage *local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
        if (local) {
            return local;
        }
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:imageID];
    if (objImage == nil) {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = indexPath;
        objImage.personId = [cellData objectForKey:@"id"];
        objImage.delegate = self;
        objImage.saveLocally = savedLocal;
        [dictDownloadImages setObject:objImage forKey:imageID];
        [objImage imageFromURL:[cellData objectForKey:@"photo"]];
    } else if (objImage.cachedImage) {
        return objImage.cachedImage;
    }
    return imageDefault;
}

- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image userInfo:(id)userInfo
{
    if (userInfo) {
        NSIndexPath *indexPath = (NSIndexPath *)userInfo;
        UITableViewCell *cell = [deletedListTableView cellForRowAtIndexPath:indexPath];
        UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
        rowIcon.image = image;
    }
}



@end
