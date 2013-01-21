//
//  FavoritesView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "FavoritesView.h"
#import "AppDelegate.h"
#import "Constants.h"

static NSDateFormatter *sUserVisibleDateFormatter;

@implementation FavoritesView

@synthesize currentButton;
@synthesize arrCellData;
@synthesize tableFavorites;
@synthesize coreDataClass;
@synthesize dictDownloadImages;

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Favorites View."];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Set the backbround image for this view
    self.tableFavorites.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"MY FAVORITES", nil)];
    
    // Set the audio player
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    myUserImage = [UIImage imageWithContentsOfFile:[[NSUserDefaults standardUserDefaults] objectForKey:@"UserImage"]];
    if (!myUserImage) {
        myUserImage = defaultImage;
    }
    self.dictDownloadImages = [NSMutableDictionary dictionary];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self.dictDownloadImages removeAllObjects];
    [self setTableFavorites:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self populateTableCellData];
    [self queryFavoriteList];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) queryFavoriteList
{
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@message/favorites", kAPIURL]; //New v2
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"favlist"];
    [APIrequest apiCall:nil Method:@"GET" URL:url];
}

- (void)proximityChanged:(NSNotification *)notification {
    
    DLog(@"Proximity changed");
	UIDevice *device = [notification object];
    if (device.proximityState == 1) {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        if ([defaults boolForKey:@"Speaker"]) {
            [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        } else {
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        }
    }
}

#pragma mark - Friends Action Methods

- (void)resetCurrentButton
{
    [currentButton setBackgroundImage:[UIImage imageNamed:@"bttn_play_faves"] forState:UIControlStateNormal];
    [currentButton removeTarget:self action:@selector(pauseAudio:) forControlEvents:UIControlEventTouchUpInside];
    [currentButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];   
}

- (void)setButtonToPause
{
    [currentButton setBackgroundImage:[UIImage imageNamed:@"bttn_pause_faves"] forState:UIControlStateNormal];
    [currentButton removeTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [currentButton addTarget:self action:@selector(pauseAudio:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)buttonTapped:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    // Proximity Sensor
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
    
    if (currentButton == button) {
       
        //if (device.proximityMonitoringEnabled == YES)
            
        
        [avPlayer play];
        device.proximityMonitoringEnabled = YES;
        [self setButtonToPause];
        
        
        return;
    } else {
        [self resetCurrentButton];
    }
    currentButton = button;
    
    // Find the table cell view to get the users information
    UIView *parentView = (UIView *)button.superview;
    UITableViewCell *tableCell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableFavorites indexPathForCell:tableCell];
    
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    // Get the message file from the dictionary
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    documentsPath = [documentsPath stringByAppendingPathComponent:kAudioDirectory];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Audio%@", [dict objectForKey:@"id"]]];
    NSData *audioFile = [NSData dataWithContentsOfFile:filePath];
    
    [self setButtonToPause];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        avPlayer = [[AVAudioPlayer alloc] initWithData:audioFile error:NULL];
        [avPlayer setDelegate:self];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        if ([defaults boolForKey:@"Speaker"]) {
            UInt32 doChangeDefaultRoute = 1;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
        }
        
        UInt32 allowBluetoothInput = 1;
        AudioSessionSetProperty(
                                kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                sizeof (allowBluetoothInput),
                                &allowBluetoothInput);
        
        [avPlayer prepareToPlay];
        [avPlayer play];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityChanged:) name:@"UIDeviceProximityStateDidChangeNotification" object:device];
    } else {
        DLog(@"Audio is not available.");
    }
}

- (IBAction)pauseAudio:(id)sender
{
    if ([avPlayer isPlaying]) {
        [avPlayer pause];
        [self resetCurrentButton];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self resetCurrentButton];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
    currentButton = nil;
    avPlayer = nil;
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
    
    DLog(@"API: %@", dictJSON);
    if ([dictJSON objectForKey:@"code"]) {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"removeMessageFromFavorites"])
    {
        
        NSString *where = [NSString stringWithFormat:@"id = %@", userInfo];
        NSArray *results = [coreDataClass searchEntity:@"Messages" Conditions:where Sort:@"" Ascending:NO andLimit:1];
        if([results count] > 0)
        {
            NSManagedObject *object = [results objectAtIndex:0];
            [object setValue:[NSNumber numberWithInt:0] forKey:@"is_favorite"];
        }
    }
    else if ([ref isEqualToString:@"favlist"])
    {
        
        
        
        self.arrCellData = (NSMutableArray *)[dictJSON objectForKey:@"messages"];
        
        
        if ([self.arrCellData count] == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tongue Tango" , nil)
                                                            message:NSLocalizedString(@"No Records Found.", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil, nil];
            [alert show];

        }
        [tableFavorites reloadData];
    }

    
}

#pragma mark - Table View Methods

- (void)populateTableCellData
{
    // Get a list of favorite messages
    coreDataClass = [CoreDataClass sharedInstance];
    NSArray *results = [coreDataClass getData:@"Messages" Conditions:@"is_favorite = 1" Sort:@"create_date" Ascending:YES];
    arrMessages = [coreDataClass convertToDict:results];    
    
    // Get a list of friends
    dictPeople = [[NSMutableDictionary alloc] init];
    results = [coreDataClass getData:@"People" Conditions:@"is_friend = 1" Sort:@"first_name" Ascending:YES];
    
    // Convert the friends into a dictionary
    NSInteger resultsCount = [results count];
    for (int i = 0; i < resultsCount; i++) {
        
        NSManagedObject *objPerson = [results objectAtIndex:i];
        NSString *personName = [NSString stringWithFormat:@"%@ %@", [objPerson valueForKey:@"first_name"], [objPerson valueForKey:@"last_name"]];
        NSString *personPhoto = [objPerson valueForKey:@"photo"];
        NSString *personId = [objPerson valueForKey:@"id"];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:personId, @"id", personPhoto, @"photo", personName, @"fullname", nil];
        
        NSString *pKey = [NSString stringWithFormat:@"%@",[objPerson valueForKey:@"user_id"]];
        [dictPeople setObject:dict forKey:pKey];
    }
    
    // Add myself to the dictionary
    NSString *myName = [NSString stringWithFormat:@"%@ %@", [defaults objectForKey:@"UserFirstName"], [defaults objectForKey:@"UserLastName"]];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:myName, @"fullname", nil];
    
    NSString *selfKey = [NSString stringWithFormat:@"%d",[defaults integerForKey:@"UserID"]];
    [dictPeople setObject:dict forKey:selfKey];
    //[dictPeople setObject:dict forKey:[NSNumber numberWithInt:[defaults integerForKey:@"UserID"]]];
    
    //self.arrCellData = [[NSMutableArray alloc] initWithArray:arrMessages];
    //[tableFavorites reloadData];
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"REMOVE", nil);
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if([self.arrCellData count] > 0 )
    {
        NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
            
        // prepare the json data
        NSDictionary *dictAPI = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"favorite", nil];
        UA_SBJsonWriter *writer = [[UA_SBJsonWriter alloc] init];
        NSString *jsonString = [writer stringWithObject:dictAPI];
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        // Make the API request
        NSString *url = [NSString stringWithFormat:@"%@message/%@", kAPIURL, [dict objectForKey:@"id"]];
        ServerConnection *APIrequest = [[ServerConnection alloc] init];
        [APIrequest setDelegate:self];
        [APIrequest setReference:@"removeMessageFromFavorites"];
        [APIrequest setUserInfo:[dict objectForKey:@"id"]];
        [APIrequest apiCall:jsonData Method:@"POST" URL:url];
        
        // Remove from the table
        [self.arrCellData removeObjectAtIndex:indexPath.row];
        NSArray *deleteIndexPaths = [[NSArray alloc] initWithObjects:
                                     [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], nil];
        
        [self.tableFavorites beginUpdates];
        [self.tableFavorites deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableFavorites endUpdates];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    // NSLog(@"Sections: %i", [self.arrCellData count]);
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
    
    if (sUserVisibleDateFormatter == nil) {
        sUserVisibleDateFormatter = [[NSDateFormatter alloc] init];
        [sUserVisibleDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [sUserVisibleDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [sUserVisibleDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }
    
    UIImageView *rowIcon;
    UIImageView *imgFrame;
    UILabel *mainLabel, *detailLabel;
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
        
        // action button
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        actionButton.frame = CGRectMake(248, 17, 65, 33);
        actionButton.tag = 4004;
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_play_faves"] forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
        
    } else {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        imgFrame = (UIImageView *)[cell viewWithTag:4001];
        mainLabel = (UILabel *)[cell viewWithTag:4002];
        actionButton = (UIButton *)[cell viewWithTag:4004];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    NSString *strSenderId = [dict objectForKey:@"user_id"];
    NSDictionary *person = [dictPeople objectForKey:strSenderId];
    DLog(@"Person : %@",[dictPeople objectForKey:strSenderId]);
    // set the contacts info
    if ([[dict objectForKey:@"user_id"] intValue] == [[NSUserDefaults standardUserDefaults] integerForKey:@"UserID"]) {
        rowIcon.image = myUserImage;
    } else {
        rowIcon.image = [self downloadCellImage:[person objectForKey:@"photo"] withID:[person objectForKey:@"id"] forIndexPath:indexPath];
    }
    
    if ([dict objectForKey:@"first_name"]) {
        //mainLabel.text = [person objectForKey:@"fullname"];
        mainLabel.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
    } else {
        mainLabel.text = NSLocalizedString(@"UNKNOWN USER", nil);
    }
    
    if ([dict objectForKey:@"create_date"]) {
        
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd H:mm:ss"];
        NSString *strDate = [dict objectForKey:@"create_date"];
        NSDate *date1 = [dateFormat dateFromString:strDate];
        //detailLabel.text = [sUserVisibleDateFormatter stringFromDate:[dict objectForKey:@"create_date"]];
        detailLabel.text = [sUserVisibleDateFormatter stringFromDate:date1];
      
    }
    
    return cell;
}

#pragma mark - Asynchronous image loading methods

- (UIImage *)downloadCellImage:(NSString *)photo withID:(NSNumber *)personId forIndexPath:(NSIndexPath *)indexPath
{
    if (![photo isKindOfClass:[NSString class]]) {
        return defaultImage;
    }
    
    UIImage *local = [SquareAndMask imageFromDevice:photo];
    if (local) {
        return local;
    }
    
    SquareAndMask *objImage = [dictDownloadImages objectForKey:personId];
    if (objImage == nil) {
        objImage = [[SquareAndMask alloc] init];
        objImage.userInfo = indexPath;
        objImage.personId = personId;
        objImage.delegate = self;
        objImage.saveLocally = YES;
        [dictDownloadImages setObject:objImage forKey:personId];
        [objImage imageFromURL:photo];
    } else if (objImage.cachedImage) {
        return objImage.cachedImage;
    }
    
    return defaultImage;
}

- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image
{
    NSArray *visiblePaths = [self.tableFavorites indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        NSDictionary *cellData = [self.arrCellData objectAtIndex:indexPath.row];
        
        NSInteger idForCell = [[cellData objectForKey:@"sender_id"] intValue];
        NSInteger idForPerson = [personId intValue];
        
        if (idForCell == idForPerson) {
            UITableViewCell *cell = [self.tableFavorites cellForRowAtIndexPath:indexPath]; 
            UIImageView *rowIcon = (UIImageView *)[cell viewWithTag:4000];
            rowIcon.image = image;
        }
    }
}

#pragma mark - Display menu

- (IBAction)moveView:(float)xCoord {
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [UIView animateWithDuration :.2
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          [self.navigationController.view setCenter:CGPointMake(xCoord, 230)];
                      }
                      completion:^(BOOL finished){
                      }];
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

@end
