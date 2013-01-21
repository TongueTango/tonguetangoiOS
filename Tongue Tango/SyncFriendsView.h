//
//  SyncFriendsView.h
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "SyncTypeCell.h"
#import "SyncAlertView.h"
#import "ServerConnection.h"
#import "AppDelegate.h"
#import "FacebookHelper.h"
#import "ProgressHUD.h"
#import "NotificationsView.h"

@interface SyncFriendsView : UIViewController <SyncCellDelegate,SyncAlertDelegate>

@property (nonatomic,retain) IBOutlet UITableView *tblType;
@property (nonatomic,retain) SyncAlertView *alertView;
@property (strong, nonatomic) FacebookHelper *fbHelper;
@property (nonatomic,retain) ProgressHUD *theHUD;

-(IBAction)inviteFriends:(id)sender;

@end
