//
//  PickThemeView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/11/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "PickThemeView.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "ExtrasView.h"

#define VERIFY_HISTORY_TIME_OUT_TAG 30

@implementation PickThemeView

@synthesize strCallReference = _strCallReference;
@synthesize arrExtras;
@synthesize tableThemes;
@synthesize arrTheme;
@synthesize labelSubtitle;
@synthesize theHUD;
@synthesize progressBar;

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
    [FlurryAnalytics logEvent:@"Visited Theme Settings View."];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Set the backbround image for this view
    self.tableThemes.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    //theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"APPLYING THEME", nil) willAnimate:YES addToView:self.view];
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"CHECKING PURCHASES", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
    
    didLoadProducts = NO;
    
    // Set the view title
    self.labelSubtitle.text = NSLocalizedString(@"SKINS", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsLoaded:) name:kProductsLoadedNotification object:nil];
}

- (void)viewDidUnload
{
    [self setLabelSubtitle:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!didLoadProducts)
    {
        isCheckingProducts = YES;
        
        self.theHUD = nil;
        theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"CHECKING PURCHASES", nil) willAnimate:YES addToView:self.view];
        [theHUD create];
        [theHUD show];
        
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0
                                                        target:self
                                                      selector:@selector(timeout:)
                                                      userInfo:nil
                                                       repeats:NO];
        [self requestProductData];
    }
    
    // Add custom nav bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"THEMES", nil)];
    
    [self reloadAllThemes];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductsLoadedNotification object:nil];
}

- (void)reloadAllThemes
{
    [self.arrTheme removeAllObjects];
    
    CoreDataClass *core = [[CoreDataClass alloc] init];
    self.arrTheme = [NSMutableArray arrayWithArray:[core getData:@"Products"
                                                      Conditions:@"purchased = 1 AND ios_product_id CONTAINS[cd] '.skin.'"
                                                            Sort:@"name"
                                                       Ascending:YES]];
    self.arrTheme = [core convertToDict:arrTheme];
    [self.arrTheme insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Default", @"name",
                                 @"0", @"id",
                                 nil] atIndex:0];
    [self.tableThemes reloadData];
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
            
            self.arrExtras = [NSArray arrayWithObjects:
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               NSLocalizedString(@"MICROPHONE PACK", nil), @"product",
                               NSLocalizedString(@"MICROPHONE DESCRIPTION", nil), @"description",
                               @"icon_extras_mic", @"icon", nil],
                              [NSDictionary dictionaryWithObjectsAndKeys:
                               NSLocalizedString(@"SKIN MY APP", nil), @"product",
                               NSLocalizedString(@"SKIN DESCRIPTION", nil), @"description",
                               @"2", @"row",
                               @"icon_extras_skin", @"icon", nil],
                              nil];
            
            //[tableExtras reloadData];
            
            [self reloadAllThemes];
        }
    }
}

- (void)productsLoaded:(NSNotification *)notification
{
    [theHUD hide];
    [timeoutTimer invalidate];
    isCheckingProducts = NO;
    didLoadProducts = YES;
    
    [self reloadAllThemes];
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([_strCallReference isEqualToString:@"downloadBG"])
    {
        NSInteger totalFileSize = response.expectedContentLength;
        [theHUD hideSpinner];
        progressBar = [[ProgressBar alloc] initWithTotal:totalFileSize addToView:self.view];
        [progressBar createProgressBar];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([_strCallReference isEqualToString:@"downloadBG"])
    {
        [progressBar increaseProgress:[data length]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([_strCallReference isEqualToString:@"downloadBG"])
    {
        DLog(@"Connection failed: %@", [error description]);
        [progressBar removeProgressBar];
        [theHUD showSpinner];
    }
    
    [theHUD hide];
    [timeoutTimer invalidate];
    timeoutTimer = nil;
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo {
    [progressBar removeProgressBar];
    DLog(@"connectionDidFinishLoading");
    
    if ([ref isEqualToString:@"downloadBG"])
    {
        UIImage *image = [UIImage imageWithData:response];
        NSData *dataImage = UIImagePNGRepresentation(image);
        [dataImage writeToFile:filePath atomically:YES];
        
        [theHUD hide];
        
        [self.navigationController popViewControllerAnimated:YES];
        
        return;
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

- (void)connectionAlert:(NSString *)message
{    
    if (!message)
    {
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
    return [arrTheme count];;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(30, 10, 260, 33)];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setBackgroundImage:[[UIImage imageNamed:@"bttn_add"] stretchableImageWithLeftCapWidth:30 topCapHeight:0] forState:UIControlStateNormal];
    [button setTitle:NSLocalizedString(@"GET MORE THEMES", nil) forState:UIControlStateNormal];
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
    
    NSString *CellIdentifier = @"Themes";
    
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
    NSDictionary *dict = [arrTheme objectAtIndex:indexPath.row];
    
    if ([[dict objectForKey:@"id"] intValue] == [defaults integerForKey:@"ThemeID"]) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove the current check mark and find the new theme cell
    currentThemeCell.accessoryView = nil;
    currentThemeCell = [self.tableThemes cellForRowAtIndexPath:indexPath];
    
    // Set the check mark image for the new theme
    UIImageView *checkImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bttn_add_done"]];
    checkImage.frame = CGRectMake(0, 0, 30, 23);
    currentThemeCell.accessoryView = checkImage;
    
    // get the data for this cell
    NSDictionary *dict = [arrTheme objectAtIndex:indexPath.row];
    
    [defaults setInteger:[[dict objectForKey:@"id"] intValue] forKey:@"ThemeID"];
    [defaults setObject:[dict objectForKey:@"name"] forKey:@"ThemeName"];
    
    NSDictionary *flurryParams = [NSDictionary dictionaryWithObject:[dict objectForKey:@"name"] forKey:@"Product"];
    [FlurryAnalytics logEvent:@"Set Theme" withParameters:flurryParams timed:YES];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if ([defaults integerForKey:@"ThemeID"] == 0) {
        [defaults setInteger:0 forKey:@"ThemeRed"];
        [defaults setInteger:0 forKey:@"ThemeGreen"];
        [defaults setInteger:0 forKey:@"ThemeBlue"];
        navigationBar.tintColor = DEFAULT_THEME_COLOR;
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        CoreDataClass *core = [[CoreDataClass alloc] init];
        
        NSString *where = [NSString stringWithFormat:@"product_id = %@ AND content_type_id = 2",[dict objectForKey:@"id"]];
        NSArray *cdProductContent = [core getData:@"Products_content" Conditions:where Sort:@"" Ascending:YES];
        
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Theme%@", [dict objectForKey:@"id"]]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            if ([cdProductContent count] > 0)
            {
                NSString *url = [[cdProductContent objectAtIndex:0] valueForKey:@"data"];
                DLog(@"BG IMG URL: %@",url);
                DLog(@"BG IMG PATH: %@",filePath);
                
                ServerConnection *Imgrequest = [[ServerConnection alloc] init];
                [Imgrequest setDelegate:self];
                [Imgrequest setReference:@"downloadBG"];
                self.strCallReference   = @"downloadBG";
                [Imgrequest getImage:url];
                
                self.theHUD = nil;
                theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"APPLYING THEME", nil) willAnimate:YES addToView:self.view];
                [theHUD create];
                [theHUD show];
            }
        }
        
        where = [NSString stringWithFormat:@"product_id = %@ AND content_type_id = 3",[dict objectForKey:@"id"]];
        NSArray *cdColor = [core getData:@"Products_content" Conditions:where Sort:@"" Ascending:YES];
        
        NSArray *colors = [[[cdColor objectAtIndex:0] valueForKey:@"data"] componentsSeparatedByString: @","];
        [defaults setInteger:[[colors objectAtIndex:0] intValue] forKey:@"ThemeRed"];
        [defaults setInteger:[[colors objectAtIndex:1] intValue] forKey:@"ThemeGreen"];
        [defaults setInteger:[[colors objectAtIndex:2] intValue] forKey:@"ThemeBlue"];
        
        [defaults setObject:filePath forKey:@"ThemeBG"];
        
        navigationBar.tintColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                                  green:([defaults integerForKey:@"ThemeGreen"]/255.0) 
                                                   blue:([defaults integerForKey:@"ThemeBlue"]/255.0) alpha:1];
    }
    
    [defaults synchronize];
    [self.tableThemes deselectRowAtIndexPath:indexPath animated:YES];
    if (![theHUD shown])
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)openExtras {
    ExtrasView *extras = [[ExtrasView alloc] initWithNibName:@"ExtrasView" bundle:nil];
    [self.navigationController pushViewController:extras animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
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
