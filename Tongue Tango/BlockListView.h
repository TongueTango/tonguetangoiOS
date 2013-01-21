//
//  BlockListView.h
//  Tongue Tango
//
//  Created by Adnan@Sohail on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressHUD.h"
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"

@interface BlockListView : UIViewController
{
    IBOutlet UITableView *blockListTableView;
    
    NSMutableDictionary *dictBlockList;
    NSMutableArray *arrBlockList;
    NSMutableArray *arrCellData;
    NSMutableDictionary *dictDownloadImages;
    
    NSMutableArray *arrBlockGroup;
    BOOL isAnyBlockedFriendOrGroup;
    BOOL isGroupUnBlocked;
}

@property (strong) NSMutableDictionary *dictBlockList;
@property (strong, nonatomic) NSMutableArray *arrBlockList;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong) ProgressHUD *theHUD;
@property (strong, nonatomic) ServerConnection *serverConnection;
@property (strong, nonatomic) IBOutlet UITableView *blockListTableView;
@property (strong, nonatomic) NSMutableArray *arrBlockGroup;

- (void)populateTableCellData;
// Download table images
- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType;

@end
