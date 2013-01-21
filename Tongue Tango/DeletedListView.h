//
//  DeletedListView.h
//  Tongue Tango
//
//  Created by Adnan@Sohail on 9/24/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ProgressHUD.h"
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"

@interface DeletedListView : UIViewController
{

    IBOutlet UITableView *deletedListTableView;
    
    NSMutableDictionary *dictDeletedList;
    NSMutableArray *arrDeletedList;
    NSMutableArray *arrCellData;
    NSMutableDictionary *dictDownloadImages;
}

@property (strong) NSMutableDictionary *dictDeletedList;
@property (strong, nonatomic) NSMutableArray *arrDeletedList;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong) ProgressHUD *theHUD;

- (void)populateTableCellData;
// Download table images
- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType;

@end
