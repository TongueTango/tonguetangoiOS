//
//  PickMicrophoneView.h
//  Tongue Tango
//
//  Created by Chris Serra on 3/12/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "InAppRageIAPHelper.h"
#import "ProgressHUD.h"

@interface PickMicrophoneView : UIViewController
{    
    NSUserDefaults *defaults;
    UITableViewCell *currentThemeCell;
    
    BOOL didLoadProducts;
    BOOL isCheckingProducts;
    
    NSTimer *timeoutTimer;
    NSMutableArray *setProducts;
    
    InAppRageIAPHelper *inAppHelper;
}

@property (nonatomic, strong) NSString *strCallReference;
@property (strong, nonatomic) NSMutableArray *arrMic;
@property (strong, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (strong, nonatomic) IBOutlet UITableView *tableMics;
@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong) ProgressHUD *theHUD;

- (void)openExtras;

@end
