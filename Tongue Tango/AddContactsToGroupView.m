//
//  AddContactsToGroupView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "AddContactsToGroupView.h"
#import "Constants.h"
#import <QuartzCore/QuartzCore.h>

@implementation AddContactsToGroupView

@synthesize removeFromGroupView;
@synthesize dictGroup;

@synthesize arrMemberList;
@synthesize arrCellData;
@synthesize dictActivity;
@synthesize dictDownloadImages;

@synthesize tableFriends;
@synthesize fieldGroupTitle;
@synthesize imagePickerController;

@synthesize coreDataClass;
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
}

#pragma mark - Navigation bar buttons

- (void)handleSavebutton:(id)sender
{
    
    [self saveGroupChanges:YES andExit:YES];
}

- (void)createSaveButton
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SAVE", nil) 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(handleSavebutton:)];
    self.navigationItem.rightBarButtonItem = button;
}

- (void)handleCancelButton:(id)sender
{
    if (doSaveChanges) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SAVE GROUP TITLE", nil)
                                                        message:NSLocalizedString(@"SAVE GROUP MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) 
                                              otherButtonTitles:NSLocalizedString(@"SAVE", nil), nil];
        alert.tag = 1001;
        [alert show];
        return;
    } else {
        if (removeFromGroupView) {
            if ([removeFromGroupView respondsToSelector:@selector(setDictGroup:)]) {
                [removeFromGroupView setDictGroup:self.dictGroup];
            }
        }
        [theHUD hide];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)createCancelButton
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CANCEL", nil) 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(handleCancelButton:)];
    self.navigationItem.leftBarButtonItem = button;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1001) {
        if (buttonIndex == 0) {
            doSaveChanges = NO;
            [theHUD hide];
            if (removeFromGroupView) {
                if ([removeFromGroupView respondsToSelector:@selector(setDictGroup:)]) {
                    [removeFromGroupView setDictGroup:self.dictGroup];
                }
            }
            [self.navigationController popViewControllerAnimated:YES];
        } else if (buttonIndex == 1) {
            //[theHUD show];
            [self saveGroupChanges:YES andExit:YES];
        }
    } else if (alertView.tag == 1002) {
        [fieldGroupTitle becomeFirstResponder];
    }
}

- (void)setupGroupHeader
{
    
    /* Added By Aftab Baig */
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"GroupImage%d",
                                                                        [groupID intValue]]];
    
    NSLog(@"header image found");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath])
    {
        UIImage *imgGroup = [SquareAndMask imageFromDevice:filePath];
        defaultGroup = imgGroup;
    }
    /* End Added By Aftab Baig */

    
    // group image
    groupImageView = [[UIImageView alloc] initWithImage:defaultGroup];
    groupImageView.frame = CGRectMake(13, 3, 42, 42);
    groupImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:groupImageView];
    
    // image frame
    UIImageView *imgFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userpic_contacts.png"]];
    imgFrame.frame = CGRectMake(10, 0, 48, 48);
    [self.view addSubview:imgFrame];
    
    fieldGroupTitle.placeholder = NSLocalizedString(@"GROUP NAME" , nil);
    
    // action button
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(254, 8, 63, 33);
    actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [actionButton setImage:[UIImage imageNamed:@"icon_camera.png"] forState:UIControlStateNormal];
    [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [actionButton setBackgroundImage:[[UIImage imageNamed:@"bttn_message_send"] stretchableImageWithLeftCapWidth:20 
                                                                                                    topCapHeight:0] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(selectPhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:actionButton];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Create A Group View."];
    
    // Set the background image for this view
    self.tableFriends.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    [self createSaveButton];
    [self createCancelButton];
    
    // Set a default user image
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    defaultGroup = [UIImage imageNamed:@"userpic_placeholder_group"];
    self.dictDownloadImages = [NSMutableDictionary dictionary];
    [self setupGroupHeader];
    
    // Prepare a variable that will store whether or not a user has been added.
    self.dictActivity = [[NSMutableDictionary alloc] init];
    self.arrMemberList = [[NSMutableArray alloc] init];
    
    // Prepare the loading screen in case it's needed later
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"SAVING GROUP", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
    doSaveChanges = NO;
}

- (void)viewDidUnload
{
    [self.dictDownloadImages removeAllObjects];
    
    [self setTheHUD:nil];
    [self setArrMemberList:nil];
    [self setArrCellData:nil];
    [self setDictActivity:nil];
    [self setImagePickerController:nil];
    [self setTableFriends:nil];
    [self setFieldGroupTitle:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!coreDataClass) {
        coreDataClass = [CoreDataClass sharedInstance];
    }
    [dictActivity removeAllObjects];
    
    self.fieldGroupTitle.delegate = self;
    if ([self.dictGroup objectForKey:@"name"])
    {
        self.fieldGroupTitle.text = [self.dictGroup objectForKey:@"name"];
        groupImageView.image = [self downloadCellImage:dictGroup forIndexPath:nil imageType:kGroupImage];
    }
    else
    {
        [self.fieldGroupTitle becomeFirstResponder];
        groupImageView.image = defaultGroup;
    }
    
    [self populateTableCellData];
    [self.tableFriends reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.fieldGroupTitle.text = @"";
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

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    [self.navigationController.view setUserInteractionEnabled:YES];
    [theHUD hide];
    DLog(@"Connection failed: %@", [error description]);
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    DLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"])
    {
        [self.navigationController.view setUserInteractionEnabled:YES];
        [theHUD hide];
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"updateExistingGroup"])
    {
        [self.navigationController.view setUserInteractionEnabled:YES];
        if ([dictJSON objectForKey:@"group"])
        {
            // Create a comma delimited list of members
            NSDictionary *group = [dictJSON objectForKey:@"group"];
            NSMutableArray *memberList = [[NSMutableArray alloc] init];
            for (NSDictionary *member in [group objectForKey:@"members"])
            {
                if ([member objectForKey:@"user_id"])
                {
                    [memberList addObject:[member objectForKey:@"user_id"]];
                }
            }
            NSString *memberlist = [memberList componentsJoinedByString:@","];
            
            // Get this one object from core data
            CoreDataClass *core = [[CoreDataClass alloc] init];
            NSString *where = [NSString stringWithFormat:@"id = %@", [group objectForKey:@"id"]];
            NSArray *result = [core searchEntity:@"Groups" Conditions:where Sort:@"" Ascending:NO andLimit:1];
            
            // Update the name and member list in core data
            if (result)
            {
                NSManagedObject *object = [result objectAtIndex:0];
                [object setValue:[group objectForKey:@"name"] forKey:@"name"];
                [object setValue:memberlist forKey:@"members"];
            }
            
            // Update the dictionary
            [dictGroup setValue:[group objectForKey:@"name"] forKey:@"name"];
            [dictGroup setValue:memberlist forKey:@"members"];
            
            doSaveChanges = NO;
        }
    }
    else
        if ([ref isEqualToString:@"createNewGroup"])
        {
            [self.navigationController.view setUserInteractionEnabled:YES];
            if ([dictJSON objectForKey:@"group"])
            {
                NSDictionary *group = [dictJSON objectForKey:@"group"];
                [dictGroup setObject:[group objectForKey:@"id"] forKey:@"id"];
                [dictGroup setObject:[group objectForKey:@"name"] forKey:@"name"];
                
                CoreDataClass *core = [[CoreDataClass alloc] init];
                [core addGroup:group];
                
                doSaveChanges = NO;
            }
        }
        else
            if ([ref isEqualToString:@"uploadPhoto"])
            {
               
            }
    
    // Check if exiting this view
    if ([[userInfo objectAtIndex:0] boolValue])
    {
        if (removeFromGroupView)
        {
            if ([removeFromGroupView respondsToSelector:@selector(setDictGroup:)])
            {
                [removeFromGroupView setDictGroup:self.dictGroup];
            }
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [theHUD hide];
    }
}

#pragma mark - Photo Methods

- (IBAction)selectPhoto:(id)sender
{
    if ([dictGroup objectForKey:@"id"]) {
        if ([arrMemberList count] > 0) {
            [self saveGroupChanges:YES andExit:NO];
        }
        [self openActionSheetMenu];
    } else {
        if ([fieldGroupTitle.text isEqualToString:@""]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GROUP NAME TITLE", nil) 
                                                            message:NSLocalizedString(@"GROUP NAME DESC", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                                  otherButtonTitles:nil];
            alert.tag = 1002;
            [alert show];
        } else {
            [self.fieldGroupTitle resignFirstResponder];
            //[theHUD show];
            [self saveGroupChanges:YES andExit:NO];
            [self openActionSheetMenu];
        }
    }
}

- (void)openActionSheetMenu
{
    // Ask to open either the camera or the photo library
    imageActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"GROUP PICTURE", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"PICTURE ANSWER1", nil), NSLocalizedString(@"PICTURE ANSWER2", nil), nil];
    
    // Show the sheet
    [imageActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Initiate the image picker
    if (imagePickerController == nil) {
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        [imagePickerController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    }
    
    // Open either the camera or the photo library
    switch (buttonIndex) {
        case 0:
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                [imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceFront];
            } else {
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
    if (buttonIndex == 0 || buttonIndex == 1) {
        [self presentModalViewController:imagePickerController animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    // Dismiss the image selection and change the button background with the picked image
    [picker dismissModalViewControllerAnimated:YES];
    
    //>     Show new image
    //[self setupGroupHeader];
    
    // Upload the image to the server
    [self saveGroupImage:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - Friends Action Methods

- (void)saveGroupChanges:(BOOL)save andExit:(BOOL)exit
{
    [fieldGroupTitle resignFirstResponder];
    //NSString *name = self.fieldGroupTitle.text;
    NSString *name = [self.fieldGroupTitle.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([name length] == 0){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GROUP NAME TITLE", nil)
                                                        message:NSLocalizedString(@"GROUP NAME DESC", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        alert.tag = 1002;
        [alert show];

       // name = NSLocalizedString(@"GROUP NAME" , nil);
    }
    else{
        [self.navigationController.view setUserInteractionEnabled:NO];
        [theHUD show];
        // Prepare the json data
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                                 name, @"name",
                                 [self.arrMemberList componentsJoinedByString:@","], @"members",
                                 nil];
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        DLog(@"save JSON:%@", jsonString);
        
        if ([dictGroup objectForKey:@"id"])
        {
            // Update an existing group.
            // Make the API request
            NSString *url = [NSString stringWithFormat:@"%@group/update?id=%@", kAPIURL, [dictGroup objectForKey:@"id"]];
            ServerConnection *APIrequest = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setUserInfo:[NSArray arrayWithObject:[NSNumber numberWithBool:exit]]];
            [APIrequest setReference:@"updateExistingGroup"];
            [APIrequest apiCall:jsonData Method:@"POST" URL:url];
            
        }
        else
        {
            // Create a new group.
            // Make the API request
            NSString *url = [NSString stringWithFormat:@"%@group/create", kAPIURL];
            ServerConnection *APIrequest = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setReference:@"createNewGroup"];
            [APIrequest setUserInfo:[NSArray arrayWithObject:[NSNumber numberWithBool:exit]]];
            [APIrequest apiCall:jsonData Method:@"POST" URL:url];
        }
    }
}

- (void)saveGroupImage:(UIImage *)newImage
{
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
    
    NSString *strMembers;
    if ([self.arrMemberList count] > 0)
    {
        strMembers = [self.arrMemberList componentsJoinedByString:@","];
    }
    else
    {
        strMembers = @"";
    }
    
    NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:
                             self.fieldGroupTitle.text, @"name",
                             strMembers, @"members",
                             nil];
    UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
    NSString *jsonString = [writer stringWithObject:dictAPI];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Send the users image to the server
    NSString *url = [NSString stringWithFormat:@"%@group/update/%@", kAPIURL, [dictGroup objectForKey:@"id"]];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"uploadPhoto"];
    [APIrequest sendFileWithData:dataImage Method:@"POST" URL:url JSON:jsonData fileName:@"groupimage.png"];
    
    DLog(@"URL:%@ JSON:%@", url, jsonString);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.fieldGroupTitle resignFirstResponder];
    //[theHUD show];
    [self saveGroupChanges:YES andExit:NO];
    return YES;
}

- (IBAction)buttonTapped:(id)sender
{
    [self.fieldGroupTitle resignFirstResponder];
    if ([dictGroup objectForKey:@"id"] == nil)
    {
        //[theHUD show];
        [self saveGroupChanges:YES andExit:NO];
        return;
    }
    doSaveChanges = YES;
    
    UIButton *button = (UIButton *)sender;
    button.hidden = YES;
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *cell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableFriends indexPathForCell:cell];
    
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    NSString *strUserId = [[dict objectForKey:@"user_id"] stringValue];
    [dictActivity setValue:@"set" forKey:strUserId];
    
    // Find the check mark
    UIImageView *checkmark = (UIImageView *)[cell viewWithTag:4005];
    checkmark.hidden = NO;
    
    // Add this friend to the array
    [self.arrMemberList addObject:[dict objectForKey:@"user_id"]];
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
    [arrMemberList removeAllObjects];
    
    NSArray *friends = [coreDataClass getData:@"People" Conditions:@"is_friend = 1" Sort:@"first_name" Ascending:YES];
    NSInteger myUserID = [[NSUserDefaults standardUserDefaults] integerForKey:@"UserID"];
    
    if ([dictGroup objectForKey:@"id"]) {
        // NSLog(@"Group Data:%@", dictGroup);
        NSArray *members = [[dictGroup objectForKey:@"members"] componentsSeparatedByString:@","];
        
        // Get the friends that are currently memmbers
        for (NSString *member in members) {
            [dictActivity setValue:@"set" forKey:member];
            NSInteger userID = [member intValue];
            
            if (userID != myUserID) {
                [self.arrMemberList addObject:[NSNumber numberWithInt:userID]];
            }
        }
    } else {
        self.dictGroup = [[NSMutableDictionary alloc] init];
    }
    
    self.arrCellData = [self sortPeopleByFirstName:[coreDataClass convertToDict:friends]];
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
    
    UIImageView *rowIcon, *checkImage;
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
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 24, 185, 20)];
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
        [actionButton setTitle:NSLocalizedString(@"ADD", nil) forState:UIControlStateNormal];
        [actionButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
		[actionButton setBackgroundColor:[UIColor clearColor]];
        [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
        
        // check mark
        checkImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bttn_add_done"]];
        checkImage.frame = CGRectMake(0, 0, 30, 23);
        checkImage.center = actionButton.center;
        checkImage.hidden = YES;
        checkImage.tag = 4005;
        [cell.contentView addSubview:checkImage];

    } else {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        imgFrame = (UIImageView *)[cell viewWithTag:4001];
        mainLabel = (UILabel *)[cell viewWithTag:4002];
        actionButton = (UIButton *)[cell viewWithTag:4003];
        checkImage = (UIImageView *)[cell viewWithTag:4005];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    // set the contacts info
    rowIcon.image = [self downloadCellImage:dict forIndexPath:indexPath imageType:kUserImage];
    imgFrame.hidden = NO;
    
    mainLabel.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
    
    // set the activity indicator, add button, and check mark
    NSString *strUserId = [[dict objectForKey:@"user_id"] stringValue];
    NSString *status = [dictActivity objectForKey:strUserId];
    
    if ([status isEqualToString:@"set"]) {
        actionButton.hidden = YES;
        checkImage.hidden = NO;
    } else {
        actionButton.hidden = NO;
        checkImage.hidden = YES;
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
        imageID = [NSString stringWithFormat:@"g%@", [cellData objectForKey:@"id"]];
        imageDefault = defaultGroup;
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
    NSIndexPath *indexPath = (NSIndexPath *)userInfo;
    
    if (indexPath)
    {
        UITableViewCell *cell = [self.tableFriends cellForRowAtIndexPath:indexPath];
        UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
        rowIcon.image = image;
    }
    else
    {
        
    }
    
}


@end
