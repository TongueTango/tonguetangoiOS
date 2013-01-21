//
//  FriendsListView.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/9/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "DeepMutableCopy.h"
#import "SquareAndMask.h"
#import "HomeView.h"

@class AddContactsToGroupView;
@class AddFriendsView;
@class RemoveFromGroupView;

@interface FriendsListView : UIViewController
{
    BOOL processCall;
    BOOL callInProgress;
    float refreshAngle;
    NSTimer *callTimer;
    NSTimer *requestTimer;
    NSTimer *refreshTimer;
    
    UIImage *defaultImage;
    UIImage *defaultGroup;
    
    NSMutableArray *arrFriends;
    NSMutableArray *arrGroups;
    NSMutableArray *arrCellData;
    NSMutableArray *arrSectionTitles;
    NSMutableDictionary *dictActivity;
    NSMutableDictionary *dictDownloadImages;
    
    int currentTable;
    BOOL isSearchResults;
}

@property (assign) BOOL showBackButton;
@property (strong, nonatomic) NSMutableArray *arrFriends;
@property (strong, nonatomic) NSMutableArray *arrGroups;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableArray *arrSectionTitles;
@property (strong, nonatomic) NSMutableDictionary *dictActivity;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong, nonatomic) NSMutableDictionary *dictSelectedGroup;

@property (strong, nonatomic) NSString *groupFriend;

@property (strong, nonatomic) IBOutlet UIButton *bttnRefresh;
@property (strong, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (strong, nonatomic) IBOutlet UITableView *tableFriends;

@property (strong, nonatomic) AddContactsToGroupView *addContactsToGroupView;
@property (strong, nonatomic) AddFriendsView *addFriendsView;
@property (strong, nonatomic) HomeView *homeView;
@property (strong, nonatomic) ServerConnection *serverConnection;

- (void)pushNotificationReceived:(NSNotification *)notification;

// Download table images
- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType;

- (void)requestData;
- (void)populateTableCellData;
- (void)switchTables:(id)sender;
- (void)handleSearchForTerm:(NSString *)searchText;
- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people;

- (IBAction)toggleMove;
- (IBAction)moveRight;
- (IBAction)moveLeft;

- (IBAction)refreshTapped;
- (void)rotateRefresh;
- (void)hadleTimer:(NSTimer *)timer;
- (void)reloadTable;

@end
