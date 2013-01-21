//
//  AddContactsToGroupView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"
#import "ProgressHUD.h"

@interface AddContactsToGroupView : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate>
{
    UIActionSheet *imageActionSheet;
    UIImage *defaultImage;
    UIImage *defaultGroup;
    UIImageView *groupImageView;
    UIView *loadingScreen;
    
    BOOL doSaveChanges;
    NSNumber *groupID;
    id removeFromGroupView;
    NSMutableDictionary *dictGroup;

    NSMutableArray *arrMemberList;
    NSMutableArray *arrCellData;
    NSMutableDictionary *dictActivity;
    NSMutableDictionary *dictDownloadImages;
}

@property (strong, nonatomic) id removeFromGroupView;
@property (strong) NSMutableDictionary *dictGroup;

@property (strong, nonatomic) NSMutableArray *arrMemberList;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableDictionary *dictActivity;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong, nonatomic) UIImagePickerController* imagePickerController;

@property (strong, nonatomic) IBOutlet UITableView *tableFriends;
@property (strong, nonatomic) IBOutlet UITextField *fieldGroupTitle;

@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong) ProgressHUD *theHUD;

- (void)saveGroupChanges:(BOOL)save andExit:(BOOL)exit;
- (void)saveGroupImage:(UIImage *)newImage;
- (void)populateTableCellData;
- (void)openActionSheetMenu;

// Download table images
- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType;

@end
