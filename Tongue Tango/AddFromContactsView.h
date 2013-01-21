//
//  AddFromContactsView.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/7/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "FacebookHelper.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"
#import "DeepMutableCopy.h"
#import "CoreDataClass.h"

@class InviteView;

typedef enum promptForAction {
    kHidePrompt,
    kShowPromptContactsActivity,
    kShowPromptContactsError,
    kShowPromptContactsEmpty,
    kShowPromptFacebookActivity,
    kShowPromptFacebookConnect,
    kShowPromptFacebookError
} promptForAction;

@interface AddFromContactsView : UIViewController
{
    NSDate *recordStart;
    
    int viewToDisplay;
    float refreshAngle;
    UIActivityIndicatorView *activityIndicator;
    UIButton *buttonConnect;
    UIImage *defaultImage;
    UILabel *messageConnect;
    UITableView *tableContacts;
    UIView *viewMessagePrompt;
    
    NSMutableArray *arrMyContacts;
    NSMutableArray *arrFbContacts;
    NSMutableArray *arrCellData;
    NSMutableArray *arrSectionTitles;
    NSMutableDictionary *dictActivity;
    NSMutableDictionary *dictDownloadImages;
    NSUserDefaults *defaults;
    NSTimer *refreshTimer;
    
    BOOL isSearchResults;
    
    FacebookHelper *fbHelper;
    SquareAndMask *squareAndMask;
    InviteView *inviteView;
}

@property (assign) id delegate;
@property (assign) int viewToDisplay;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicateConnect;
@property (strong, nonatomic) IBOutlet UIButton *buttonConnect;
@property (strong, nonatomic) IBOutlet UIButton *bttnRefresh;
@property (strong, nonatomic) IBOutlet UILabel *messageConnect;
@property (strong, nonatomic) IBOutlet UITableView *tableContacts;
@property (strong, nonatomic) IBOutlet UIView *viewMessagePrompt;

@property (assign) NSMutableDictionary *selectedUsers;
@property (strong, nonatomic) NSMutableArray *arrMyContacts;
@property (strong, nonatomic) NSMutableArray *arrFbContacts;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableArray *arrSectionTitles;
@property (strong, nonatomic) NSMutableDictionary *dictActivity;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong, nonatomic) NSMutableArray *arrAddressBookPeople;

@property (strong, nonatomic) FacebookHelper *fbHelper;
@property (strong, nonatomic) InviteView *inviteView;
@property (strong, nonatomic) ServerConnection *serverConnection;

- (void)makeFriend:(NSDictionary *)dict indexPath:(NSIndexPath *)index;
- (void)launchFriendRequest;
- (void)reloadTable;

// Address Book
- (NSMutableArray *)getAllAddressBookPeople;
- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people;

// API Server Connection
- (void)requestContacts:(NSMutableArray *)people;
- (void)requestFriends;
- (void)switchPromptMessage:(int)status;
- (IBAction)connectToFacebook:(id)sender;
- (NSMutableArray *)removeMeAndDuplicates:(NSMutableArray *)people;

- (IBAction)refreshTapped;
- (void)rotateRefresh;
- (void)hadleTimer:(NSTimer *)timer;

// Asynchronous image loading
- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath;

- (void)populateTableCellData;
- (void)handleSearchForTerm:(NSString *)searchText;

@end

@protocol AddFriendsView <NSObject>
@optional
- (void)removeSuggestion:(NSNumber *)uniqueID;
- (void)addFriendsViewPushViewController:(UIViewController*)viewController animated:(BOOL)animated;
@end
