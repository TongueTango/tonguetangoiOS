//
//  NotificationsView.h
//  Tongue Tango
//
//  Created by Johana Moccetti on 7/24/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EGORefreshTableHeaderView.h"

@class ServerConnection;
@class MessageThreadDetailView;

@interface NotificationsView : UIViewController <EGORefreshTableHeaderDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    NSMutableDictionary *dictDownloadImages;
    NSMutableDictionary *dictActivity;
    BOOL callInProgress;
    
    NSTimer *refreshMessagesTimer;
    float angleMessages;
    
    NSTimer *refreshInvitationsTimer;
    float angleInvitations;
    
    UIColor *themeColor;
    NSUserDefaults *defaults;
    
    BOOL showPendingFriends;
    BOOL loadInvitations;
    
    int selectedIndex;
    BOOL isGroupInvitationArrived;
    BOOL isFriendPushNotify;
    BOOL isExternalPush;
    BOOL isExternalPushFrnd;
    
    IBOutlet UIView *notifyView;
    IBOutlet UILabel *lblNotifyMessage;
    NSString *notifyMessage;
    BOOL isLoading;
    int collapsSection;
    BOOL isDeleted;
    
    EGORefreshTableHeaderView *_refreshHeaderView;
}
@property (assign, nonatomic) BOOL isExternalPushFrnd;
@property (assign, nonatomic) BOOL isExternalPush;
@property (assign, nonatomic) BOOL isFriendPushNotify;
@property (assign, nonatomic) BOOL isGroupInvitationArrived;
@property (strong, nonatomic) IBOutlet UIButton *bttnRefreshMessages;
@property (strong, nonatomic) IBOutlet UIButton *bttnRefreshFriends;
@property (strong, nonatomic) IBOutlet UIView *notifyView;
@property (strong, nonatomic) IBOutlet UILabel *lblNotifyMessage;
@property (strong, nonatomic) NSString *notifyMessage;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *typeSegmentedControl;

@property (strong, nonatomic) ServerConnection *serverConnection;
@property (strong, nonatomic) NSMutableArray *arrPendingFriends;
@property (strong, nonatomic) NSMutableArray *arrMessages;
@property (strong, nonatomic) NSMutableArray *arrPendingGroups;

@property (strong, nonatomic) NSMutableArray *arrPendingFriendsTemp;
@property (strong, nonatomic) NSMutableArray *arrMessagesTemp;
@property (strong, nonatomic) NSMutableArray *arrPendingGroupsTemp;

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) NSMutableDictionary *dictCollapse;

//@property (strong, nonatomic) IBOutlet UIView *segmentedControlView;

- (IBAction)changeNotificationsType:(id)sender;
- (IBAction)refreshTapped:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil showPendingFriends:(BOOL)show;

- (void)pushNotificationReceived:(NSDictionary *)userInfo;

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@end
