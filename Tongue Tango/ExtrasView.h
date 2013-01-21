//
//  ExtrasView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "InAppRageIAPHelper.h"
#import "ProgressHUD.h"

@class PurchaseSkinsView;

@interface ExtrasView : UIViewController <UIAlertViewDelegate>
{
    BOOL bStopRequest;
    BOOL animating;
    BOOL didLoadProducts;
    BOOL isCheckingProducts;
    CGPoint previewPoint;
    NSMutableArray *setProducts;
    NSTimer *timeoutTimer;
    
    InAppRageIAPHelper *inAppHelper;
}

@property (strong, nonatomic) NSArray *arrExtras;
@property (strong, nonatomic) IBOutlet UIButton *bttnClose;
@property (strong, nonatomic) IBOutlet UIImageView *imagePreview;
@property (strong, nonatomic) IBOutlet UITableView *tableExtras;
@property (strong, nonatomic) IBOutlet UIView *viewPreview;
@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong, nonatomic) PurchaseSkinsView *purchaseSkinsView;
@property (strong) ProgressHUD *theHUD;

- (IBAction)closePreview:(id)sender;
- (IBAction)resizePreview:(id)sender;

- (IBAction)buyProduct:(NSInteger)row;
- (void)requestProducts;
- (void)requestProductData;
- (void)productPurchased:(NSNotification *)notification;
- (void)productPurchaseFailed:(NSNotification *)notification;
- (void)productsLoaded:(NSNotification *)notification;
- (void)timeout:(id)arg;

@end