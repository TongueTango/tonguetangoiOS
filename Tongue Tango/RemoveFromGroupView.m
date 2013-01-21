//
//  AddGroupView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "RemoveFromGroupView.h"
#import "AddContactsToGroupView.h"
#import "Constants.h"

@implementation RemoveFromGroupView

@synthesize arrMemberList;
@synthesize arrCellData;
@synthesize dictGroup;
@synthesize dictDownloadImages;

@synthesize tableFriends;
@synthesize fieldGroupTitle;
@synthesize imagePickerController;

@synthesize addContactsToGroupView;
@synthesize theHUD;

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
    [self.dictDownloadImages removeAllObjects];
}

#pragma mark - Navigation bar buttons

- (void)openAddFriendsView
{
    
    if (doSaveChanges)
    {
        [theHUD show];
        [self saveGroupChanges:YES andExit:NO action:@"openAddFriendsView:"];
    } 
    else
    {
        if (!self.addContactsToGroupView)
        {
            self.addContactsToGroupView = [[AddContactsToGroupView alloc] initWithNibName:@"AddContactsToGroupView" bundle:nil];
        }
        
        [self.addContactsToGroupView setDictGroup:dictGroup];
        [self.addContactsToGroupView setRemoveFromGroupView:self];
        [self.navigationController pushViewController:self.addContactsToGroupView animated:YES];
    }
}

- (void)createAddFriendsButton
{
    // add the menu button to the navigation bar
    UIImage *image = [UIImage imageNamed:@"bttn_nav_add_friend"];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(openAddFriendsView)];
    self.navigationItem.rightBarButtonItem = button;
}

- (void)handleDoneButton:(id)sender
{
    //>-------------------------------------------------------------------------------------------------
    //>     Ben 09/04/2012: Based on bug no. 9406
    //>
    //>     Solution: When Done button pressed, check if group name is different than the name in db
    //>     If different, save new group name
    //>-------------------------------------------------------------------------------------------------
    if (![[self.dictGroup objectForKey:@"name"] isEqualToString:self.fieldGroupTitle.text])
    {
        doSaveChanges = YES;
        [self.fieldGroupTitle resignFirstResponder];
    }
    
    if (doSaveChanges)
    {
        [theHUD show];
        [self saveGroupChanges:YES andExit:YES action:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)createDoneButton
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DONE", nil) 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(handleDoneButton:)];
    self.navigationItem.leftBarButtonItem = button;
}

-(void) handleRemoveMeButton :(id) sender
{
    DLog(@"handle Remove me ");
    
    NSString *blockedGroupId = [self.dictGroup objectForKey:@"id"];
    
    NSString *url = [NSString stringWithFormat:@"%@group/reject/%@",kROOTURL,blockedGroupId]; //New v2
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"reject"];
    [APIrequest apiCall:nil Method:@"GET" URL:url];
}

- (void)createRemoveMeButton
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Remove Me", nil)
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(handleRemoveMeButton:)];
    self.navigationItem.rightBarButtonItem = button;
}


- (void)setupGroupHeader
{    
    // group image
    groupImageView = [[UIImageView alloc] initWithImage:defaultGroup];
    groupImageView.frame = CGRectMake(13, 3, 42, 42);
    groupImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:groupImageView];
    
    // image frame
    UIImageView *imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_contacts.png"]];
    imgFrame.frame = CGRectMake(10, 0, 48, 48);
    [self.view addSubview:imgFrame];
    
    // action button
    photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    photoButton.frame = CGRectMake(254, 8, 63, 33);
    photoButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [photoButton setImage:[UIImage imageNamed:@"icon_camera.png"] forState:UIControlStateNormal];
    [photoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [photoButton setBackgroundImage:[[UIImage imageNamed:@"bttn_message_send"] stretchableImageWithLeftCapWidth:20 
                                                                                                    topCapHeight:0] forState:UIControlStateNormal];
    [photoButton addTarget:self action:@selector(selectPhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:photoButton];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Edit Group View."];
    
    // Set the background image for this view
    self.tableFriends.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    
    [self createDoneButton];
    
    // Set a default user image
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    defaultGroup = [UIImage imageNamed:@"userpic_placeholder_group"];
    self.dictDownloadImages = [NSMutableDictionary dictionary];
    
    // Prepare a variable that will store whether or not a user has been added.
    self.arrMemberList = [[NSMutableArray alloc] init];
    
    // Prepare the loading screen in case it's needed later
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"SAVING GROUP", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
    doSaveChanges = NO;
}

- (void)viewDidUnload
{
    [self.dictDownloadImages removeAllObjects];
    
    [self setDictGroup:nil];
    [self setArrMemberList:nil];
    [self setArrCellData:nil];
    [self setImagePickerController:nil];
    [self setAddContactsToGroupView:nil];
    [self setTheHUD:nil];
    [self setTableFriends:nil];
    [self setFieldGroupTitle:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupGroupHeader];
    
    [arrMemberList removeAllObjects];
    
    self.fieldGroupTitle.delegate = self;
    self.fieldGroupTitle.text = [self.dictGroup objectForKey:@"name"];
    
    
    DLog(@"current Group : %@",[self.dictGroup description]);
    groupImageView.image = [self downloadCellImage:dictGroup forIndexPath:nil imageType:kGroupImage];
    
    [self populateTableCellData];    
    [self.tableFriends reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //self.fieldGroupTitle.text = @"";
    [self.fieldGroupTitle resignFirstResponder];
    [theHUD hide];
    
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    // NSLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"]) {
        [self.navigationController.view setUserInteractionEnabled:YES];
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"updateExistingGroup"]) {
        // NSLog(@"Returned group: %@", [dictJSON objectForKey:@"group"]);
        [self.navigationController.view setUserInteractionEnabled:YES];
        if ([[dictJSON objectForKey:@"group"] objectForKey:@"name"]) {
            
            // Create a comma delimited list of members
            NSDictionary *group = [dictJSON objectForKey:@"group"];
            NSMutableArray *memberList = [[NSMutableArray alloc] init];
            for (NSDictionary *member in [group objectForKey:@"members"]) {
                if ([member objectForKey:@"user_id"]) {
                    [memberList addObject:[member objectForKey:@"user_id"]];
                }
            }
            NSString *memberlist = [memberList componentsJoinedByString:@","];
            
            // Get this one object from core data
            CoreDataClass *core = [[CoreDataClass alloc] init];
            NSString *where = [NSString stringWithFormat:@"id = %@", [group objectForKey:@"id"]];
            NSArray *result = [core searchEntity:@"Groups" Conditions:where Sort:@"" Ascending:NO andLimit:1];
            
            // Update the name and member list in core data
            if (result) {
                NSManagedObject *object = [result objectAtIndex:0];
                [object setValue:[group objectForKey:@"name"] forKey:@"name"];
                [object setValue:memberlist forKey:@"members"];
                [core saveContext];
            }
            
            // Update the dictionary
            [dictGroup setValue:[group objectForKey:@"name"] forKey:@"name"];
            [dictGroup setValue:memberlist forKey:@"members"];
            doSaveChanges = NO;
            
            // Navigate to the next view
            NSString *action = (NSString *)userInfo;
            if ([action isEqualToString:@"openAddFriendsView:"]) {
                [self openAddFriendsView];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        } else {
            DLog(@"ERROR JSON:%@", dictJSON);
        }
    }
    else if ([ref isEqualToString:@"uploadPhoto"]) {
        DLog(@"End Uploading here"); 
        DLog(@"API: %@", dictJSON);
        
        if ([dictJSON objectForKey:@"group"]) {
            
            // Create a comma delimited list of members
            NSDictionary *group = [dictJSON objectForKey:@"group"];
            
            CoreDataClass *core = [[CoreDataClass alloc] init];
            NSString *where = [NSString stringWithFormat:@"id = %@", [group objectForKey:@"id"]];
            NSArray *result = [core searchEntity:@"Groups" Conditions:where Sort:@"" Ascending:NO andLimit:1];
            
            if (result) {
                NSManagedObject *object = [result objectAtIndex:0];
                [object setValue:[group objectForKey:@"photo"] forKey:@"photo"];
                [core saveContext];
            }
            [self.navigationController.view setUserInteractionEnabled:YES];
        }
        
        [theHUD hide];
        DLog(@"End after save Uploading here");
        doSaveChanges = NO;
    }
    else if([ref isEqualToString:@"reject"])
    {
          DLog(@"API: %@", dictJSON);
        [self.navigationController.view setUserInteractionEnabled:YES];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
}

#pragma mark - Photo Methods

- (IBAction)selectPhoto:(id)sender
{
    // Ask to open either the camera or the photo library
    imageActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"How would you like to set the group picture?", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"Take Picture", nil), NSLocalizedString(@"Choose Picture", nil), nil];
    
    // Show the sheet
    [imageActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Initiate the image picker
    if (imagePickerController == nil)
    {
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        [imagePickerController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    }
    
    // Open either the camera or the photo library
    switch (buttonIndex)
    {
        case 0:
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES)
            {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                [imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceFront];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CAMERA UNAVAILABLE", nil)
                                                                message:NSLocalizedString(@"CAMERA NOT AVAILABLE", nil)
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
                buttonIndex = -1;
            }
            break;
        case 1:
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        default:
            break;
    }
    if (buttonIndex == 0 || buttonIndex == 1)
    {
        [self presentModalViewController:imagePickerController animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    // Dismiss the image selection and change the button background with the picked image
    [picker dismissModalViewControllerAnimated:YES];
    
    // Upload the image to the server
    [self saveGroupImage:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - Friends Action Methods

- (void)saveGroupChanges:(BOOL)save andExit:(BOOL)exit action:(NSString *)action
{
    [self.navigationController.view setUserInteractionEnabled:NO];
    // Prepare the json data
    NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                             self.fieldGroupTitle.text, @"name",
                             [self.arrMemberList componentsJoinedByString:@","], @"members",
                             nil];
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@group/update/%@", kAPIURL, [dictGroup objectForKey:@"id"]];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setUserInfo:action];
    [APIrequest setReference:@"updateExistingGroup"];
    [APIrequest apiCall:jsonData Method:@"POST" URL:url];
}

- (void)saveGroupImage:(UIImage *)newImage
{
    [self.navigationController.view setUserInteractionEnabled:NO];
    DLog(@"Start saving Uploading here");
    // Upload this data
    NSData *dataImage = UIImagePNGRepresentation(newImage);
        
    // Save this data
    NSData *dataMasked = [SquareAndMask maskImage:newImage withImage:[UIImage imageNamed:@"mask"]];
    groupImageView.image = [UIImage imageWithData:dataMasked];
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"GroupImage%@", 
                                                                        [self.dictGroup objectForKey:@"id"]]];
    
    [dataMasked writeToFile:filePath atomically:YES];
        
    NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                             self.fieldGroupTitle.text, @"name",
                             [self.arrMemberList componentsJoinedByString:@","], @"members",
                             nil];
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    [theHUD show];
    
    DLog(@"Start Uploading here");
    // Send the users image to the server
    NSString *url = [NSString stringWithFormat:@"%@group/update/%@", kAPIURL, [dictGroup objectForKey:@"id"]];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"uploadPhoto"];
    [APIrequest sendFileWithData:dataImage Method:@"POST" URL:url JSON:jsonData fileName:@"groupimage.png"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.fieldGroupTitle resignFirstResponder];
    if (![[self.dictGroup objectForKey:@"name"] isEqualToString:self.fieldGroupTitle.text]) {
        doSaveChanges = YES;
    }
    return YES;
}

- (IBAction)buttonTapped:(id)sender
{
    doSaveChanges = YES;
    
    UIButton *button = (UIButton *)sender;
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableFriends indexPathForCell:cell];
    
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    // Remove this friend from the array
    [self.arrMemberList removeObject:[dict objectForKey:@"user_id"]];
    
    // Remove from the table
    [self.arrCellData removeObjectAtIndex:indexPath.row];
    NSArray *deleteIndexPaths = [[NSArray alloc] initWithObjects:
                                 [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], nil];
    
    [self.tableFriends beginUpdates];
    [self.tableFriends deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableFriends endUpdates];
}

#pragma mark - Table View Methods

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

- (void)populateTableCellData
{
    CoreDataClass *core = [[CoreDataClass alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger myUserID = [defaults integerForKey:@"UserID"];
    if ([[dictGroup objectForKey:@"user_id"] intValue] == myUserID)
    {
        groupCreatorID = myUserID;
        isGroupCreator = YES;
        [self createAddFriendsButton];
        photoButton.hidden = NO;
        self.fieldGroupTitle.enabled = YES;
    }
    else
    {
        groupCreatorID = [[dictGroup objectForKey:@"user_id"] intValue];
        isGroupCreator = NO;
        photoButton.hidden = YES;
        //self.navigationItem.rightBarButtonItem = nil;
        [self createRemoveMeButton];
        self.fieldGroupTitle.enabled = NO;
    }
    
    DLog(@"Group Data:%@", dictGroup);
    
   // NSString *testmembers = @"1264,1266";
    //NSArray *members = [testmembers componentsSeparatedByString:@","];
    
    NSString *strMembers = [dictGroup objectForKey:@"members"];
    if([strMembers length] > 0){
        NSArray *members = [[dictGroup objectForKey:@"members"] componentsSeparatedByString:@","];
        
        // Get the friends that are currently memmbers
        NSMutableArray *arrTempMembers = [[NSMutableArray alloc] init];
        for (NSString *member in members)
        {
            NSString *where = [NSString stringWithFormat:@"user_id = %@", member];
            NSArray *friend = [core searchEntity:@"People" Conditions:where Sort:@"" Ascending:YES andLimit:1];
            
            if ([friend count] > 0)
            {
                [arrTempMembers addObject:[friend objectAtIndex:0]];
                [arrMemberList addObject:[[friend objectAtIndex:0] valueForKey:@"user_id"]];
            }
        }
        
        self.arrCellData = [self sortPeopleByFirstName:[core convertToDict:arrTempMembers]];
    }
    [self.tableFriends reloadData];
}

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
    UILabel *mainLabel, *detailLabel;
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
        mainLabel = [[UILabel alloc] init];
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
        [actionButton setTitle:NSLocalizedString(@"REMOVE", nil) forState:UIControlStateNormal];
        [actionButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
        
        // detail label
        detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 35, 250, 19)];
        detailLabel.text = NSLocalizedString(@"GROUP OWNER", nil);
        detailLabel.font = [UIFont systemFontOfSize:12];
        detailLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        detailLabel.backgroundColor = [UIColor clearColor];
        detailLabel.tag = 4004;
        [cell.contentView addSubview:detailLabel];

    }
    else
    {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        imgFrame = (UIImageView *)[cell viewWithTag:4001];
        mainLabel = (UILabel *)[cell viewWithTag:4002];
        actionButton = (UIButton *)[cell viewWithTag:4003];
        detailLabel = (UILabel *)[cell viewWithTag:4004];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    // set the contacts info
    rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
    imgFrame.hidden = NO;
    
    mainLabel.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
    
    // Remove the edit button if you are not the owner of the group
    if (isGroupCreator)
    {
        mainLabel.frame = CGRectMake(68, 24, 187, 20);
        detailLabel.hidden = YES;
        actionButton.hidden = NO;
    }
    else
    {
        actionButton.hidden = YES;
        if (groupCreatorID == [[dict objectForKey:@"user_id"] intValue])
        {
            mainLabel.frame = CGRectMake(68, 18, 195, 20);
            detailLabel.hidden = NO;
        }
        else
        {
            mainLabel.frame = CGRectMake(68, 24, 195, 20);
            detailLabel.hidden = YES;
        }
    }
    
    return cell;
}

#pragma mark - Asynchronous image loading methods

- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType
{
    UIImage *imageDefault;
    NSString *imageID;
    BOOL savedLocal;
    if (imageType == kUserImage)
    {
        imageID = [NSString stringWithFormat:@"u%@", [cellData objectForKey:@"id"]];
        imageDefault = defaultImage;
        savedLocal = [[cellData objectForKey:@"is_friend"] boolValue];
    }
    else
    {
        //imageID = [NSString stringWithFormat:@"g%@", [cellData objectForKey:@"id"]];
        imageID = [NSString stringWithFormat:@"GroupImage%@", [cellData objectForKey:@"id"]];
        imageDefault = defaultGroup;
        savedLocal = YES;
    }
    
    if (![[cellData objectForKey:@"photo"] isKindOfClass:[NSString class]])
    {
        return imageDefault;
    }
    
    if (savedLocal)
    {
        //UIImage *local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
        UIImage *local = [SquareAndMask imageFromDevice:imageID];
        if (local)
        {
            return local;
        }
        else {
            local = [SquareAndMask imageFromDevice:[cellData objectForKey:@"photo"]];
            if (local) {
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
        UITableViewCell *cell = [self.tableFriends cellForRowAtIndexPath:indexPath];
        UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
        rowIcon.image = image;
    }
    else
    {
        groupImageView.image = image;
    }
}

@end
