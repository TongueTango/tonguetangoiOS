//
//  ExtrasView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "ExtrasView.h"
#import "PurchaseSkinsView.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "SquareAndMask.h"

#define BUY_MICROPHONE_PACK_ALERT_VIEW_TAG  10
#define VERIFY_HISTORY_TIME_OUT_TAG 30


@implementation ExtrasView

@synthesize arrExtras;
@synthesize tableExtras;
@synthesize purchaseSkinsView;
@synthesize imagePreview;
@synthesize viewPreview;
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
    [FlurryAnalytics logEvent:@"Visited Extras View."];
    
    // Set the backbround image for this view
    self.tableExtras.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"EXTRAS", nil)];
    
    coreDataClass = [CoreDataClass sharedInstance];
    
    theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"CHECKING PURCHASES", nil) willAnimate:YES addToView:self.view];
    [theHUD create];
    
    didLoadProducts = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:kProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsLoaded:) name:kProductsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:kProductPurchaseFailedNotification object: nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!didLoadProducts) {
        isCheckingProducts = YES;
        [theHUD show];
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0
                                                        target:self
                                                      selector:@selector(timeout:)
                                                      userInfo:nil
                                                       repeats:NO];
        [self requestProductData];
    }
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
    [self setImagePreview:nil];
    [self setBttnClose:nil];
    [self setTheHUD:nil];
    [self setViewPreview:nil];
    [self setTableExtras:nil];
    [self setPurchaseSkinsView:nil];
    [super viewDidUnload];
}

#pragma mark - API server methods

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

- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo {
    DLog(@"%@", [error description]);
    [theHUD hide];
    [timeoutTimer invalidate];
    timeoutTimer = nil;
}

- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo
{
    DLog(@"connectionDidFinishLoading");
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    if ([dictJSON objectForKey:@"code"])
    {
        [self connectionAlert:[dictJSON objectForKey:@"message"]];
    }
    
    // NSLog(@"%@",dictJSON);
    if ([ref isEqualToString:@"getAllProducts"])
    {
        NSArray *arrProducts = [dictJSON objectForKey:@"products"];
        
        CoreDataClass *core = [[CoreDataClass alloc] init];
        [core deleteAll:@"Products" Conditions:@""];
        [core deleteAll:@"Products_content" Conditions:@""];
        for (int i=0; i < [arrProducts count]; i++) {
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
    else
        if ([ref isEqualToString:@"downloadMic"])
        {
            DLog(@"Saved local image.");
            UIImage *image = [UIImage imageWithData:response];
            NSData *dataImage = UIImagePNGRepresentation(image);
            [dataImage writeToFile:userInfo atomically:YES];
        }
        else
            if ([ref isEqualToString:@"loadingPreview"])
            {
                NSInteger tag   = [[userInfo objectForKey:@"tag"] intValue];
                
                UIButton *button = (UIButton *)[viewPreview viewWithTag:tag];
                UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[viewPreview viewWithTag:tag+100];
                UIImage *image = [SquareAndMask scaleImageRect:[UIImage imageWithData:response]];
                [button setImage:image forState:UIControlStateNormal];
                [activity stopAnimating];
                
                //>---------------------------------------------------------------------------------------------------
                //>     We need to save preview files locally, so that we won't request them everytime from server
                //>---------------------------------------------------------------------------------------------------
                NSString *strFileName   = (NSString *)[userInfo objectForKey:@"filePath"];
                NSData *dataImage       = UIImagePNGRepresentation(image);
                [dataImage writeToFile:strFileName atomically:YES];
            }
            else
            {
                [self requestProductData];
            }
}

#pragma mark - In-App Purchases

- (void)requestProducts
{
    if (bStopRequest) {
        return;
    }
    
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
        CoreDataClass *core = [[CoreDataClass alloc] init];
        NSArray *results = [core getData:@"Products" Conditions:@"NOT ios_product_id CONTAINS[cd] '.skin.'" Sort:@"descript" Ascending:YES];
        NSMutableArray *savedProducts  = [core convertToDict:results];
        
        if ([savedProducts count] == 0) {
            [self requestProducts];
        } else {
            // Create Set of products
            NSMutableSet *theProducts = [NSMutableSet setWithObjects:nil,nil];
            for (NSDictionary *theProduct in savedProducts) {
                [theProducts addObject:[theProduct objectForKey:@"ios_product_id"]];
                
                if ([[theProduct objectForKey:@"ios_product_id"] isEqualToString:@"ios.microphones"] && [[theProduct objectForKey:@"purchased"] intValue] == 1) {
                    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"Mics"];
                }
            }
            setProducts = [NSMutableArray arrayWithArray:[theProducts allObjects]];
            
            // Grab from Apple
            inAppHelper = [[InAppRageIAPHelper alloc] initwithProdID:theProducts];
            if (inAppHelper.products == nil) {
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
            
            [tableExtras reloadData];
        }
    }
}

- (void)productsLoaded:(NSNotification *)notification {
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [theHUD hide];
    [timeoutTimer invalidate];
    isCheckingProducts = NO;
    didLoadProducts = YES;
}

- (IBAction)buyProduct:(NSInteger)row {
    DLog(@"");
    SKProduct *product = [inAppHelper.products objectAtIndex:row];
    
    [inAppHelper buyProductIdentifier:product.productIdentifier];
    
    [theHUD setTheText:[NSString stringWithFormat:NSLocalizedString(@"PURCHASING_PROGRESS_MESSAGE DESCRIPTION", nil) , 
                        product.localizedTitle]];
    [theHUD show];
    
    NSDictionary *flurryParams = [NSDictionary dictionaryWithObjectsAndKeys:product.localizedTitle, @"Product", nil];
    
    [FlurryAnalytics logEvent:@"Purchasing Product" withParameters:flurryParams timed:YES];
    [timeoutTimer invalidate];
    timeoutTimer = nil;
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 * 5
                                                    target:self
                                                  selector:@selector(timeout:)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)productPurchased:(NSNotification *)notification
{
    DLog(@"");
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [theHUD hide];
    [timeoutTimer invalidate];
    timeoutTimer = nil;
    
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
    
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:productIdentifier];
    
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"Mics"];
    
    NSDictionary *flurryParams =
    [NSDictionary dictionaryWithObjectsAndKeys:
     @"Microphone Pack", @"Product",
     nil];
    
    [FlurryAnalytics endTimedEvent:@"Purchased Product" withParameters:flurryParams];
    
    UIImageView *soldImage = (UIImageView *)[tableExtras viewWithTag:1001];
    soldImage.hidden = NO;
    
    NSArray *cdMics = [coreDataClass getData:@"Products_content" Conditions:@"content_type_id = 4" Sort:@"name" Ascending:YES];
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
    
    for (int i = 0; i < [cdMics count]; i++) {
        NSDictionary *dict = [cdMics objectAtIndex:i];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Mic%@", [dict valueForKey:@"id"]]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            url = [dict valueForKey:@"data"];
            DLog(@"MIC IMG URL: %@",url);
            DLog(@"MIC IMG PATH: %@",filePath);
            
            ServerConnection *Imgrequest = [[ServerConnection alloc] init];
            [Imgrequest setDelegate:self];
            [Imgrequest setUserInfo:filePath];
            [Imgrequest setReference:@"downloadMic"];
            [Imgrequest getImage:url];
        }
    }
    
    isCheckingProducts = YES;
    [self requestProductData];
}

- (void)productPurchaseFailed:(NSNotification *)notification
{
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [theHUD hide];
    [timeoutTimer invalidate];
    timeoutTimer = nil;
    
    SKPaymentTransaction * transaction = (SKPaymentTransaction *) notification.object;    
    if (transaction.error.code != SKErrorPaymentCancelled) {   
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PRODUCT_PURCHASED_FAILED_ERROR_TITLE", nil) 
                                                        message:transaction.error.localizedDescription 
                                                       delegate:nil 
                                              cancelButtonTitle:nil 
                                              otherButtonTitles:NSLocalizedString(@"OK_BUTTON_TITLE", nil), nil];
        [alert show];
    }
    
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
    alert.tag = 30;
    [alert show];

    [timeoutTimer invalidate];
    timeoutTimer = nil;
}

#pragma mark - Table View

- (CGFloat)labelHeight:(NSString *)text
{
    CGSize constraint = CGSizeMake(212, 20000.0f);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    CGFloat height = MAX(size.height, 44.0f);
    
    return height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.arrExtras count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSDictionary *dict = [self.arrExtras objectAtIndex:indexPath.section];
    
    NSString *text = [dict objectForKey:@"description"];
    CGFloat height = [self labelHeight:text] + 10;
    
    if (height < 60) {
        height = 60;
    }
    
    return height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = [self.arrExtras objectAtIndex:section];
    
    return [dict objectForKey:@"product"];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
    // Create label with section title
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 290, 20)];
    label.font = [UIFont boldSystemFontOfSize:18];
    label.textColor = [UIColor colorWithWhite:0.37 alpha:1];
    label.backgroundColor = [UIColor clearColor];
    label.text = sectionTitle;
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 28)];
    [view addSubview:label];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 28;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UILabel *descLabel;
    UIImageView *soldImage;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        cell.imageView.frame = CGRectMake(0, 0, 50, 50);
        
        descLabel = [[UILabel alloc] init];
        descLabel.font = [UIFont systemFontOfSize:15];
        descLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        descLabel.numberOfLines = 0;
        descLabel.backgroundColor = [UIColor clearColor];
        descLabel.lineBreakMode = UILineBreakModeWordWrap;
        descLabel.tag = 4001;
        [cell.contentView addSubview:descLabel];
        
        soldImage = [[UIImageView alloc] init];
        soldImage.contentMode = UIViewContentModeScaleAspectFill;
        soldImage.frame = CGRectMake(0, 0, 50, 50);
        soldImage.image = [UIImage imageNamed:@"sold.png"];
        soldImage.tag = 4002;
        [cell.contentView addSubview:soldImage];
        
    } else {
        descLabel = (UILabel *)[cell viewWithTag:4001];
        soldImage = (UIImageView *)[cell viewWithTag:4002];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [self.arrExtras objectAtIndex:indexPath.section];
    
    soldImage.hidden = YES;
    // sold image
    if (indexPath.section < 1 && [setProducts count] == 1) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:[setProducts objectAtIndex:indexPath.section]]) {
            soldImage.hidden = NO;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    // Set the cell height and message text
    NSString *text = [dict objectForKey:@"description"];
    CGFloat textHeight = [self labelHeight:text];
    
    cell.imageView.image = [UIImage imageNamed:[dict objectForKey:@"icon"]];
    
    descLabel.text = text;
    descLabel.frame = CGRectMake(70, 0, 220, textHeight + 8);
    descLabel.tag = indexPath.section+1000;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:[setProducts objectAtIndex:indexPath.section]])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"BUY_MICROPHONES_PACKAGE_QUESTION", nil) 
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"CANCEL_BUTTON_TITLE", nil)  
                                                  otherButtonTitles:NSLocalizedString(@"YES_BUTTON_TITLE", nil),
                                  NSLocalizedString(@"PREVIEW_BUTTON_TITLE", nil), nil];
            alert.tag = BUY_MICROPHONE_PACK_ALERT_VIEW_TAG;
            
            [alert show];
        }
        else
        {
            [self displayPreviews];
        }
    }
    else
    {
        if (purchaseSkinsView == nil)
        {
            purchaseSkinsView = [[PurchaseSkinsView alloc] initWithNibName:@"PurchaseSkinsView" bundle:nil];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductPurchasedNotification object:nil];
        [self.navigationController pushViewController:purchaseSkinsView animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)displayPreviews {
    // Show the spinner and message while retreiving the preview
    NSString *where = [NSString stringWithFormat:@"ios_product_id = 'ios.microphones'"];
    NSArray *cdProduct = [coreDataClass getData:@"Products" Conditions:where Sort:@"" Ascending:YES];
    
    if ([cdProduct count] > 0)
    {
        self.viewPreview.alpha = 1;
        UIButton *previewImage;
        NSInteger product_id = [[[cdProduct objectAtIndex:0] valueForKey:@"id"] intValue];
        where = [NSString stringWithFormat:@"product_id = %i AND content_type_id = 6",product_id];
        
        NSArray *cdProductContent = [coreDataClass getData:@"Products_content" Conditions:where Sort:@"" Ascending:YES];
        
        CGRect deviceFrame          = [[UIScreen mainScreen] bounds];
        float middleScreen          = deviceFrame.size.height/2;
        
        NSInteger previewX = 118;
        NSInteger previewY = middleScreen - 60;
        NSInteger previewCol = 1;
        NSInteger previewRow = 1;
        
        for (int i = 0; i < [cdProductContent count]; i++)
        {
            UIButton *button = (UIButton *)[viewPreview viewWithTag:i+200];
            UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[viewPreview viewWithTag:i+300];
            [button removeFromSuperview];
            [activity removeFromSuperview];
            
            previewImage = [[UIButton alloc] initWithFrame:CGRectMake(40, 0, 80, 120)];
            previewImage.center = CGPointMake(previewX, previewY);
            previewImage.tag = i+200;
            [previewImage setBackgroundColor:[UIColor darkGrayColor]];
            [previewImage addTarget:self action:@selector(resizePreview:) forControlEvents:UIControlEventTouchUpInside];
            [viewPreview addSubview:previewImage];
            
            activity = [[UIActivityIndicatorView alloc] init];
            activity.center = CGPointMake(previewX, previewY);
            [activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
            activity.hidesWhenStopped = YES;
            activity.tag = i+300;
            [viewPreview addSubview:activity];
            [activity startAnimating];
            
            previewX += 82;
            previewCol += 1;
            if ((previewRow == 1 && previewCol == 3) || (previewRow > 1 && previewCol == 4))
            {
                previewY = previewY+122;
                previewX = 78;
                previewCol = 1;
                previewRow += 1;
            }
            
            NSString *url = [[cdProductContent objectAtIndex:i] valueForKey:@"data"];
            
            //>---------------------------------------------------------------------------------------------------
            //>     Always check if we have the file saved locally. If not, go on and download it from server
            //>---------------------------------------------------------------------------------------------------
            NSString *strFileName       = [url lastPathComponent];
            NSArray *paths              = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString *documentsPath     = [paths objectAtIndex:0];
            NSString *strFilePath       = [documentsPath stringByAppendingPathComponent:strFileName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:strFilePath])
            {
                NSInteger tag           = i + 200;
                UIButton *button        = (UIButton *)[viewPreview viewWithTag:tag];
                UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[viewPreview viewWithTag:tag+100];
                UIImage *image          = [UIImage imageWithData:[NSData dataWithContentsOfFile:strFilePath]];
                [button setImage:image forState:UIControlStateNormal];
                [activity stopAnimating];
            }
            else
            {
                //>     Build a dict for userInfo
                NSMutableDictionary *dictUserInfo   = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                       [NSNumber numberWithInt:i+200], @"tag",
                                                       strFilePath, @"filePath", nil];
                
                ServerConnection *APIrequest = [[ServerConnection alloc] init];
                [APIrequest setDelegate:self];
                [APIrequest setReference:@"loadingPreview"];
                [APIrequest setUserInfo:dictUserInfo];
                [APIrequest getImage:url];
            }
        }
    }
}

#pragma mark - Alert View

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == BUY_MICROPHONE_PACK_ALERT_VIEW_TAG) {
        if (buttonIndex == 2) {
            [self displayPreviews];
        } else if (buttonIndex == 1) {
            self.viewPreview.alpha = 0;
            [self buyProduct:0];
        }
    } else if (alertView.tag == VERIFY_HISTORY_TIME_OUT_TAG) {
        if (buttonIndex == 0) {
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
        } else {
            // TODO JMR validate this step is ok
            bStopRequest = YES;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (IBAction)closePreview:(id)sender
{
    previewPoint = CGPointZero;
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

- (IBAction)resizePreview:(id)sender
{
    if (!animating)
    {
        animating = YES;
        UIButton *button = (UIButton *)[viewPreview viewWithTag:[sender tag]];
        CGPoint newPoint;
        CGAffineTransform transform;
        [viewPreview bringSubviewToFront:button];
        
        CGRect deviceFrame  = [[UIScreen mainScreen] bounds];
        
        if ((previewPoint.x > 0.0)&&(previewPoint.y > 0.0))
        {
            transform = CGAffineTransformMakeScale(1, 1);
            newPoint = previewPoint;
            previewPoint = CGPointZero;
        }
        else
        {
            transform = CGAffineTransformMakeScale(3.1, 3.1);
            //newPoint = CGPointMake(160, 260);
            newPoint = CGPointMake(160, deviceFrame.size.height/2);
            previewPoint = button.center;
        }
        
        [UIView animateWithDuration :.2
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              button.center = newPoint;
                              button.transform = transform;
                          }
                          completion:^(BOOL finished){
                              animating = NO;
                          }];
    }
}

@end