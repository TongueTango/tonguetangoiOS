//
//  SocialFriendsList.h
//  Tongue Tango
//
//  Created by Chris Air on 3/26/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataClass.h"
#import "DeepMutableCopy.h"
#import "HomeView.h"
#import "TwitterHelper.h"
#import "Constants.h"

@interface SocialFriendsList : UIViewController <UISearchBarDelegate>
{
    NSInteger toID, selectedRow;
    NSMutableArray *arrCellData;
    NSString *socialToID;
    NSString *socialToName;
    NSUserDefaults *defaults;
    UITableView *tableFriends;
    
    HomeView *homeView;
    CoreDataClass *coreDataClass;
    TwitterHelper *twHelper;
    
    BOOL isSearchResults;
}

@property (nonatomic) NSInteger toID, selectedRow;
@property (strong, nonatomic) NSString *socialToID;
@property (strong, nonatomic) NSString *socialToName;
@property (strong, nonatomic) NSMutableArray *arrFacebook;
@property (strong, nonatomic) NSMutableArray *arrTwitter;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *moreActivity;
@property (strong, nonatomic) IBOutlet UITableView *tableFriends;

@property (strong, nonatomic) HomeView *homeView;
@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong, nonatomic) TwitterHelper *twHelper;

- (void)populateTableCellData;
- (void)handleSearchForTerm:(NSString *)searchText;
- (void)resetSearch;

- (IBAction)closeList;

@end
