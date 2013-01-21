//
//  PickMicrophoneView.m
//  Tongue Tango
//
//  Created by Chris Serra on 3/12/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "PickMicrophoneView.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "ExtrasView.h"

#define VERIFY_HISTORY_TIME_OUT_TAG 30

@interface PickMicrophoneView ()

@end

@implementation PickMicrophoneView

@synthesize strCallReference = _strCallReference;
@synthesize tableMics;
@synthesize labelSubtitle;
@synthesize arrMic;
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

- (void)refreshMicrophones
{
    arrMic = [[NSMutableArray alloc] init];
    if ([defaults boolForKey:@"Mics"])
    {
        CoreDataClass *core = [[CoreDataClass alloc] init];
        NSArray *results = [core getData:@"Products_content" Conditions:@"content_type_id = 4" Sort:@"name" Ascending:YES];
        NSMutableArray *tempArrMic = [core convertToDict:results];
        
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        
        for (int i=0; i < [tempArrMic count]; i++)
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[tempArrMic objectAtIndex:i]];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Mic%i", [[dict objectForKey:@"id"] intValue]]];
            
            [dict setObject:filePath forKey:@"path"];
            [arrMic addObject:dict];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSString *url = [dict objectForKey:@"data"];
                
                ServerConnection *Imgrequest = [[ServerConnection alloc] init];
                [Imgrequest setDelegate:self];
                [Imgrequest setUserInfo:filePath];
                [Imgrequest setReference:@"downloadMic"];
                self.strCallReference = @"downloadMic";
                [Imgrequest getImage:url];
            }
        }
    }
    [arrMic insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                          @"Default", @"name",
                          @"0", @"id",
                          nil] atIndex:0];
    
    [self.tableMics reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!didLoadProducts)
    {
        isCheckingProducts = YES;
        
        theHUD.theText = NSLocalizedString(@"CHECKING PURCHASES", nil);
        [theHUD show];
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0
                                                        target:self
                                                      selector:@selector(timeout:)
                                                      userInfo:nil
                                                       repeats:NO];
        [self requestProductData];
    }
    
    [self refreshMicrophones];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Microphone Settings View."];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Set the backbround image for this view
    self.tableMics.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    // Add custom nav bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"MICROPHONES", nil)];
    
    // Set the view title
    self.labelSubtitle.text = NSLocalizedString(@"MICROPHONES", nil);
    
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"CHECKING PURCHASES", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
    
    didLoadProducts = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsLoaded:) name:kProductsLoadedNotification object:nil];
}

- (void)viewDidUnload
{
    [self setLabelSubtitle:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductsLoadedNotification object:nil];
}

#pragma mark - Load Products

- (void)requestProducts
{
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@product",kAPIURL];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"getAllProducts"];
    self.strCallReference   = @"getAllProducts";
    [APIrequest apiCall:nil Method:@"GET" URL:url];
}

- (void)requestProductData
{
    if (isCheckingProducts)
    {
        // Grab from Core Data
        CoreDataClass *core = [[CoreDataClass alloc] init];
        NSArray *results = [core getData:@"Products" Conditions:@"NOT ios_product_id CONTAINS[cd] '.skin.'" Sort:@"descript" Ascending:YES];
        NSMutableArray *savedProducts  = [core convertToDict:results];
        
        if ([savedProducts count] == 0)
        {
            [self requestProducts];
        }
        else
        {
            // Create Set of products
            NSMutableSet *theProducts = [NSMutableSet setWithObjects:nil,nil];
            for (NSDictionary *theProduct in savedProducts)
            {
                [theProducts addObject:[theProduct objectForKey:@"ios_product_id"]];
                
                if ([[theProduct objectForKey:@"ios_product_id"] isEqualToString:@"ios.microphones"] && [[theProduct objectForKey:@"purchased"] intValue] == 1)
                {
                    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"Mics"];
                }
            }
            
            setProducts = [NSMutableArray arrayWithArray:[theProducts allObjects]];
            
            // Grab from Apple
            inAppHelper = [[InAppRageIAPHelper alloc] initwithProdID:theProducts];
            if (inAppHelper.products == nil)
            {
                [inAppHelper requestProducts];
                [timeoutTimer invalidate];
                timeoutTimer = nil;
                timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0
                                                                target:self
                                                              selector:@selector(timeout:)
                                                              userInfo:nil
                                                               repeats:NO];
            }
            
            isCheckingProducts = NO;
                        
            [self refreshMicrophones];
        }
    }
}

- (void)productsLoaded:(NSNotification *)notification
{
    [theHUD hide];
    [timeoutTimer invalidate];
    isCheckingProducts = NO;
    didLoadProducts = YES;
    
    [self refreshMicrophones];
}

- (void)timeout:(id)arg
{
    [theHUD hide];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"UNABLE TO VERIFY HISTORY", nil)
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"TRY_AGAIN_BUTTON_TITLE", nil) ,
                          NSLocalizedString(@"NO_THANKS_BUTTON_TITLE", nil) , nil];
    alert.tag = VERIFY_HISTORY_TIME_OUT_TAG;
    [alert show];
    
    [timeoutTimer invalidate];
    timeoutTimer = nil;
}


#pragma mark - API server methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [theHUD hide];
    [timeoutTimer invalidate];
    timeoutTimer = nil;
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    if ([ref isEqualToString:@"downloadMic"]) {
        UIImage *image = [UIImage imageWithData:response];
        NSData *dataImage = UIImagePNGRepresentation(image);
        [dataImage writeToFile:userInfo atomically:YES];
    }
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    if ([dictJSON objectForKey:@"code"])
    {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    if ([ref isEqualToString:@"getAllProducts"])
    {
        NSArray *arrProducts = [dictJSON objectForKey:@"products"];
        
        CoreDataClass *core = [[CoreDataClass alloc] init];
        [core deleteAll:@"Products" Conditions:@""];
        [core deleteAll:@"Products_content" Conditions:@""];
        
        for (int i=0; i < [arrProducts count]; i++)
        {
            NSDictionary *dict = [arrProducts objectAtIndex:i];
            
            NSString *where = [NSString stringWithFormat:@"id = %@",[dict objectForKey:@"id"]];
            BOOL exists = [core doesDataExist:@"Products" Conditions:where];
            
            if (!exists)
            {
                [core setProduct:dict forObject:nil];
            }
        }
        [core saveContext];
        [self requestProductData];
    }

}

- (void)connectionAlert:(NSString *)message {
    
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

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [arrMic count];;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Mics"]) {
        return 0;
    }
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Mics"]) {
        return nil;
    }
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(30, 10, 260, 33)];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setBackgroundImage:[[UIImage imageNamed:@"bttn_add"] stretchableImageWithLeftCapWidth:30 topCapHeight:0] forState:UIControlStateNormal];
    [button setTitle:NSLocalizedString(@"GET MORE MICROPHONES", nil) forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openExtras) forControlEvents:UIControlEventTouchUpInside];
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    [view addSubview:button];
    
    return view;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = @"Mics";
    
    UILabel *mainLabel;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        
        // main label
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 230, 20)];
        mainLabel.font = [UIFont boldSystemFontOfSize:18];
        mainLabel.textColor = [UIColor blackColor];//[UIColor colorWithWhite:0.46 alpha:1];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4000;
        [cell.contentView addSubview:mainLabel];
    } else {
        mainLabel = (UILabel *)[cell viewWithTag:4000];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [arrMic objectAtIndex:indexPath.row];
    
    if ([[dict objectForKey:@"id"] intValue] == [defaults integerForKey:@"MicID"]) {
        UIImageView *checkImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bttn_add_done"]];
        checkImage.frame = CGRectMake(0, 0, 30, 23);
        cell.accessoryView = checkImage;
        currentThemeCell = cell;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }
    
    mainLabel.text = [dict objectForKey:@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Remove the current check mark and find the new theme cell
    currentThemeCell.accessoryView = nil;
    currentThemeCell = [self.tableMics cellForRowAtIndexPath:indexPath];
    
    // Set the check mark image for the new theme
    UIImageView *checkImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bttn_add_done"]];
    checkImage.frame = CGRectMake(0, 0, 30, 23);
    currentThemeCell.accessoryView = checkImage;
    
    // get the data for this cell
    NSDictionary *dict = [arrMic objectAtIndex:indexPath.row];

    [defaults setInteger:[[dict objectForKey:@"id"] intValue] forKey:@"MicID"];
    [defaults setObject:[dict objectForKey:@"name"] forKey:@"MicName"];
    if (![defaults integerForKey:@"MicID"] == 0) {
        [defaults setObject:[dict objectForKey:@"path"] forKey:@"MicPath"];
    }
    [defaults synchronize];
    
    [self.tableMics deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)openExtras {
    ExtrasView *extras = [[ExtrasView alloc] initWithNibName:@"ExtrasView" bundle:nil];
    [self.navigationController pushViewController:extras animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIAlerView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == VERIFY_HISTORY_TIME_OUT_TAG)
    {
        if (buttonIndex == 0)
        {
            [theHUD setTheText:NSLocalizedString(@"CHECKING_PURCHASES_MESSAGE", nil)];
            [theHUD show];
            [timeoutTimer invalidate];
            timeoutTimer = nil;
            timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0
                                                            target:self
                                                          selector:@selector(timeout:)
                                                          userInfo:nil
                                                           repeats:NO];
            [self requestProductData];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

@end
