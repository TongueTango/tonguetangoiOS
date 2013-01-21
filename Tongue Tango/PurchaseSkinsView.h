//
//  PurchaseSkinsView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "InAppRageIAPHelper.h"
#import "ProgressHUD.h"

@interface PurchaseSkinsView : UIViewController {
    InAppRageIAPHelper *inAppHelper;
    BOOL isCheckingProducts;
    NSString *filePath;
}

@property (nonatomic, strong) NSString *strPreviewFilePath;
@property (strong, nonatomic) IBOutlet UITableView *tableThemes;
@property (strong, nonatomic) IBOutlet UIView *viewPreview;
@property (strong, nonatomic) IBOutlet UIImageView *imagePreview;
@property (strong, nonatomic) IBOutlet UILabel *labelRetreive;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityRetrieve;
@property (strong, nonatomic) IBOutlet UIButton *bttnClose;

@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong) ProgressHUD *theHUD;

- (void)showPreviewImage:(UIImage *)image;
- (IBAction)closePreview:(id)sender;

- (IBAction)buyButtonTapped:(id)sender;
- (void)requestProducts;
- (void)requestProductData;
- (void)productPurchased:(NSNotification *)notification;
- (void)productPurchaseFailed:(NSNotification *)notification;
- (void)dismissHUD:(id)arg;
- (void)productsLoaded:(NSNotification *)notification;
- (void)timeout:(id)arg;

@end
