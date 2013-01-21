//
//  FirstSyncView.h
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "SyncCell.h"
#import "SyncAlertView.h"
#import "ServerConnection.h"
#import "FacebookHelper.h"
#import "AppDelegate.h"
#import "ProgressHUD.h"

@interface FirstSyncView : UIViewController <SyncCellDelegate,SyncAlertDelegate>

@property (nonatomic,retain) IBOutlet UITableView *tblType;
@property (nonatomic,retain) IBOutlet UIButton *btnType;
@property (nonatomic,retain) SyncAlertView *alertView;
@property (strong, nonatomic) FacebookHelper *fbHelper;
@property (nonatomic,retain) ProgressHUD *theHUD;

@end
