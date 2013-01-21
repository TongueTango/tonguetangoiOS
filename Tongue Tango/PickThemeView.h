//
//  PickThemeView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/11/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "InAppRageIAPHelper.h"
#import "ProgressBar.h"
#import "ProgressHUD.h"

@interface PickThemeView : UIViewController
{
    NSUserDefaults *defaults;
    NSString *filePath;
    
    BOOL didLoadProducts;
    BOOL isCheckingProducts;
    
    UITableViewCell *currentThemeCell;
    NSTimer *timeoutTimer;
    NSMutableArray *setProducts;
    
    InAppRageIAPHelper *inAppHelper;
}

@property (nonatomic, strong) NSString *strCallReference;
@property (strong, nonatomic) NSArray *arrExtras;
@property (strong, nonatomic) NSMutableArray *arrTheme;
@property (strong, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (strong, nonatomic) IBOutlet UITableView *tableThemes;
@property (strong) ProgressHUD *theHUD;
@property (strong) ProgressBar *progressBar;

- (void)openExtras;

@end
