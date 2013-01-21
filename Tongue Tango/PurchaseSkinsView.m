//
//  PurchaseSkinsView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "PurchaseSkinsView.h"
#import "Constants.h"

@implementation PurchaseSkinsView

@synthesize strPreviewFilePath = _strPreviewFilePath;
@synthesize tableThemes;
@synthesize viewPreview;
@synthesize imagePreview;
@synthesize labelRetreive;
@synthesize activityRetrieve;
@synthesize bttnClose;
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
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Purchase Theme View."];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:kProductPurchasedNotification object:nil];
    
    // Set the backbround image for this view
    self.tableThemes.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"SKIN MY APP", nil)];
    
    coreDataClass = [CoreDataClass sharedInstance];
    
    isCheckingProducts = YES;
    
    self.theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"LOADING THEMES", nil) willAnimate:YES addToView:self.view];
    [self.theHUD create];
    [self.theHUD show];
    [self requestProductData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsLoaded:) name:kProductsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(productPurchaseFailed:) name:kProductPurchaseFailedNotification object: nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductPurchaseFailedNotification object:nil];
}

- (void)viewDidUnload
{
    self.tableThemes = nil;
    [self setViewPreview:nil];
    [self setImagePreview:nil];
    [self setLabelRetreive:nil];
    [self setActivityRetrieve:nil];
    [self setBttnClose:nil];
    theHUD = nil;
    [super viewDidUnload];
}

#pragma mark - API server methods

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"%@", [error description]);
    [theHUD hide];
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    // NSLog(@"%@---%@",dictJSON,ref);
    if ([dictJSON objectForKey:@"code"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REQUEST ERROR" , nil)
                                                        message:[dictJSON objectForKey:@"message"]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    else
        if ([ref isEqualToString:@"getAllProducts"])
        {
            NSArray *arrProducts = [dictJSON objectForKey:@"products"];
            
            [coreDataClass deleteAll:@"Products" Conditions:@""];
            [coreDataClass deleteAll:@"Products_content" Conditions:@""];
            for (int i=0; i < [arrProducts count]; i++)
            {
                NSDictionary *dict = [arrProducts objectAtIndex:i];
                
                NSString *where = [NSString stringWithFormat:@"id = %@",[dict objectForKey:@"id"]];
                BOOL exists = [coreDataClass doesDataExist:@"Products" Conditions:where];
                
                if (!exists)
                {
                    [coreDataClass setProduct:dict forObject:nil];
                }
            }
            [self requestProductData];
        }
        else
            if ([ref isEqualToString:@"loadingPreview"])
            {
                //>---------------------------------------------------------------------------------------------------
                //>     We need to save preview files locally, so that we won't request them everytime from server
                //>---------------------------------------------------------------------------------------------------
                DLog(@"Saved local image.");
                UIImage *image          = [UIImage imageWithData:response];
                NSData *dataImage       = UIImagePNGRepresentation(image);
                [dataImage writeToFile:_strPreviewFilePath atomically:YES];
                
                [self.theHUD hide];
                
                self.viewPreview.alpha = 1;
                [self showPreviewImage:image];
            }
            else
                if ([ref isEqualToString:@"downloadBG"])
                {
                    DLog(@"Saved local image.");
                    UIImage *image = [UIImage imageWithData:response];
                    NSData *dataImage = UIImagePNGRepresentation(image);
                    [dataImage writeToFile:filePath atomically:YES];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:filePath forKey:@"ThemeBG"];
                }
                else
                {
                    [self requestProducts];
                }
}

#pragma mark - In-App Purchases

- (void)requestProducts
{
    // Make the API request
    NSString *url = [NSString stringWithFormat:@"%@product",kAPIURL];
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"getAllProducts"];
    [APIrequest apiCall:nil Method:@"GET" URL:url];
}

- (void)requestProductData
{
    if (isCheckingProducts) {
        // Grab from Core Data
        NSString *where = @"ios_product_id CONTAINS[cd] '.skin.'";
        NSArray *results = [coreDataClass getData:@"Products" Conditions:where Sort:@"descript" Ascending:YES];
        NSMutableArray *savedProducts  = [coreDataClass convertToDict:results];
        
        if ([savedProducts count] == 0) {
            [self requestProducts];
        } else {
            // Create Set of products
            NSMutableSet *theProducts = [NSMutableSet setWithObjects:nil,nil];
            for (NSDictionary *theProduct in savedProducts) {
                [theProducts addObject:[theProduct objectForKey:@"ios_product_id"]];
            }
            
            // Grab from Apple
            inAppHelper = [[InAppRageIAPHelper alloc] initwithProdID:theProducts];
            if (inAppHelper.products == nil) {
                [inAppHelper requestProducts];
                [self performSelector:@selector(timeout:) withObject:nil afterDelay:30.0];
            }
            isCheckingProducts = NO;
        }
    }
}

- (void)productsLoaded:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [theHUD hide];
    [self.tableThemes reloadData];
}

- (IBAction)buyButtonTapped:(id)sender {
    UIButton *buyButton = (UIButton *)sender;
    
    SKProduct *product = [inAppHelper.products objectAtIndex:buyButton.tag];
    
    DLog(@"Purchasing %@...", product.productIdentifier);
    [inAppHelper buyProductIdentifier:product.productIdentifier];
    
    [theHUD setTheText: [NSString stringWithFormat:@"Purchasing %@...",product.localizedTitle]];
    [theHUD show];
    
    NSDictionary *flurryParams =
    [NSDictionary dictionaryWithObjectsAndKeys:
     product.localizedTitle, @"Product",
     nil];
    
    [FlurryAnalytics logEvent:@"Purchasing Product" withParameters:flurryParams timed:YES];
    
    [self performSelector:@selector(timeout:) withObject:nil afterDelay:60*5];
}

- (void)productPurchased:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [theHUD hide];
    DLog(@"TEST");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"THEME PURCHASED", nil) 
                                                    message:NSLocalizedString(@"SET YOUR THEME IN SETTINGS", nil) 
                                                   delegate:nil 
                                          cancelButtonTitle:nil 
                                          otherButtonTitles:@"Ok", nil];
    
    [alert show];
    
    NSString *productIdentifier = (NSString *) notification.object;
    DLog(@"Purchased: %@", productIdentifier);
    NSString *where = [NSString stringWithFormat:@"ios_product_id = '%@'",productIdentifier];
    NSArray *results = [coreDataClass getData:@"Products" Conditions:where Sort:@"" Ascending:YES];
    NSManagedObject *currentProduct = [results objectAtIndex:0];
    
    NSString *url = [NSString stringWithFormat:@"%@product/create/%@", kAPIURL, [currentProduct valueForKey:@"id"]];
    
    ServerConnection *APIrequest = [[ServerConnection alloc] init];
    [APIrequest setDelegate:self];
    [APIrequest setReference:@"requestSetAsPurchased"];
    [APIrequest apiCall:nil Method:@"POST" URL:url];
    
    where = [NSString stringWithFormat:@"product_id = %@ AND content_type_id = 2",[currentProduct valueForKey:@"id"]];
    
    NSArray *cdProductContent = [coreDataClass getData:@"Products_content" Conditions:where Sort:@"" Ascending:YES];
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
    filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Theme%@", [currentProduct valueForKey:@"id"]]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if ([cdProductContent count] > 0)
        {
            url = [[cdProductContent objectAtIndex:0] valueForKey:@"data"];
            DLog(@"BG IMG URL: %@",url);
            DLog(@"BG IMG PATH: %@",filePath);
            
            ServerConnection *Imgrequest = [[ServerConnection alloc] init];
            [Imgrequest setDelegate:self];
            [Imgrequest setReference:@"downloadBG"];
            [Imgrequest getImage:url];
        }
    }
    
    where = [NSString stringWithFormat:@"product_id = %@ AND content_type_id = 3",[currentProduct valueForKey:@"id"]];
    
    NSArray *cdColor = [coreDataClass getData:@"Products_content" Conditions:where Sort:@"" Ascending:YES];
    
    NSArray *colors = [[[cdColor objectAtIndex:0] valueForKey:@"data"] componentsSeparatedByString: @","];
    [[NSUserDefaults standardUserDefaults] setInteger:[[colors objectAtIndex:0] intValue] forKey:@"ThemeRed"];
    [[NSUserDefaults standardUserDefaults] setInteger:[[colors objectAtIndex:1] intValue] forKey:@"ThemeGreen"];
    [[NSUserDefaults standardUserDefaults] setInteger:[[colors objectAtIndex:2] intValue] forKey:@"ThemeBlue"];
    [[NSUserDefaults standardUserDefaults] setInteger:[[currentProduct valueForKey:@"id"] intValue] forKey:@"ThemeID"];
    [[NSUserDefaults standardUserDefaults] setObject:[currentProduct valueForKey:@"name"] forKey:@"ThemeName"];
    
    NSDictionary *flurryParams =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [currentProduct valueForKey:@"name"], @"Product",
     nil];
    
    [FlurryAnalytics endTimedEvent:@"Purchased Product" withParameters:flurryParams];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.tintColor = [UIColor colorWithRed:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeRed"]/255.0) 
                                              green:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeGreen"]/255.0) 
                                               blue:([[NSUserDefaults standardUserDefaults] integerForKey:@"ThemeBlue"]/255.0) alpha:1];

    
    isCheckingProducts = YES;
    [self requestProductData];
}

- (void)productPurchaseFailed:(NSNotification *)notification {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [theHUD hide];
    
    SKPaymentTransaction * transaction = (SKPaymentTransaction *) notification.object;    
    if (transaction.error.code != SKErrorPaymentCancelled) {    
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" 
                                                        message:transaction.error.localizedDescription 
                                                       delegate:nil 
                                              cancelButtonTitle:nil 
                                              otherButtonTitles:@"OK", nil];
        
        [alert show];
    }
}

- (void)dismissHUD:(id)arg {
    [theHUD hide];
}

- (void)timeout:(id)arg {
    [theHUD hide];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
                                                    message:NSLocalizedString(@"UNABLE TO PURCHASE" , nil) 
                                                   delegate:self 
                                          cancelButtonTitle:nil 
                                          otherButtonTitles:@"OK", nil];
    alert.tag = 30;
    [alert show];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [inAppHelper.products count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = @"Skins";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    SKProduct *product = [inAppHelper.products objectAtIndex:indexPath.row];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    
    cell.textLabel.text = product.localizedTitle;
    cell.detailTextLabel.text = NSLocalizedString(@"TAP TO PREVIEW", nil);
    

if ([[NSUserDefaults standardUserDefaults] boolForKey:product.productIdentifier]) {

        UIImageView *checkImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bttn_add_done_ws"]];
        checkImage.frame = CGRectMake(260, 17, 60, 24);

//        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = checkImage;
    } else {
        UIButton *buyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        buyButton.frame = CGRectMake(249, 17, 65, 33);
        buyButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [buyButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [buyButton setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
        [buyButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
		[buyButton setBackgroundColor:[UIColor clearColor]];
        [buyButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
        [buyButton addTarget:self action:@selector(buyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        buyButton.tag = indexPath.row;
        [buyButton setTitle:formattedString forState:UIControlStateNormal];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = buyButton;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = [inAppHelper.products objectAtIndex:indexPath.row];
    
    NSString *where = [NSString stringWithFormat:@"ios_product_id = '%@'",product.productIdentifier];
    NSArray *cdProduct = [coreDataClass getData:@"Products" Conditions:where Sort:@"" Ascending:YES];
    
    if ([cdProduct count] > 0)
    {
        NSInteger product_id = [[[cdProduct objectAtIndex:0] valueForKey:@"id"] intValue];
        where = [NSString stringWithFormat:@"product_id = %i AND content_type_id = 5",product_id];
        
        NSArray *cdProductContent = [coreDataClass getData:@"Products_content" Conditions:where Sort:@"" Ascending:YES];
        
        NSString *url = [[cdProductContent objectAtIndex:0] valueForKey:@"data"];
        
        //>---------------------------------------------------------------------------------------------------
        //>     Always check if we have the file saved locally. If not, go on and download it from server
        //>---------------------------------------------------------------------------------------------------
        NSString *strFileName       = [url lastPathComponent];
        NSArray *paths              = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath     = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *strFilePath       = [documentsPath stringByAppendingPathComponent:strFileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:strFilePath])
        {
            // Show the spinner and message while retreiving the preview
            self.viewPreview.alpha = 1;
            
            UIImage *previewImage   = [UIImage imageWithData:[NSData dataWithContentsOfFile:strFilePath]];
            [self showPreviewImage:previewImage];
        }
        else
        {
            self.theHUD = nil;
            self.theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"Loading...", nil) willAnimate:YES addToView:self.view];
            [self.theHUD create];
            [self.theHUD show];
            
            self.strPreviewFilePath        = strFilePath;
            
            ServerConnection *APIrequest    = [[ServerConnection alloc] init];
            [APIrequest setDelegate:self];
            [APIrequest setReference:@"loadingPreview"];
            [APIrequest getImage:url];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)showPreviewImage:(UIImage *)image
{
    self.imagePreview.image = image;
    self.labelRetreive.hidden = YES;
    [self.activityRetrieve stopAnimating];
    [UIView animateWithDuration :.4
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          self.imagePreview.alpha = 1;
                          self.bttnClose.alpha = 1;
                      }
                      completion:^(BOOL finished){
                      }];
}

- (IBAction)closePreview:(id)sender
{
    [UIView animateWithDuration :.4
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          self.imagePreview.alpha = 0;
                          self.bttnClose.alpha = 0;
                          self.viewPreview.alpha = 0;
                      }
                      completion:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
