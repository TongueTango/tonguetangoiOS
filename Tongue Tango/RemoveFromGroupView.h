//
//  AddGroupView.h
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

@class AddContactsToGroupView;

@interface RemoveFromGroupView : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate>
{
    UIActionSheet *imageActionSheet;
    BOOL doSaveChanges;
    BOOL isGroupCreator;
    UIButton *photoButton;
    UIImage *defaultImage;
    UIImage *defaultGroup;
    UIImageView *groupImageView;
    
    NSInteger groupCreatorID;
    NSMutableDictionary *dictGroup;
    NSMutableArray *arrMemberList;
    NSMutableArray *arrCellData;
    NSMutableDictionary *dictDownloadImages;
}

@property (strong) NSMutableDictionary *dictGroup;
@property (strong, nonatomic) NSMutableArray *arrMemberList;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;
@property (strong, nonatomic) UIImagePickerController* imagePickerController;

@property (strong, nonatomic) IBOutlet UITableView *tableFriends;
@property (strong, nonatomic) IBOutlet UITextField *fieldGroupTitle;

@property (strong, nonatomic) AddContactsToGroupView *addContactsToGroupView;
@property (strong) ProgressHUD *theHUD;

- (void)saveGroupChanges:(BOOL)save andExit:(BOOL)exit action:(NSString *)action;
- (void)saveGroupImage:(UIImage *)newImage;
- (void)populateTableCellData;
- (IBAction)selectPhoto:(id)sender;

// Download table images
- (UIImage *)downloadCellImage:(NSDictionary *)cellData forIndexPath:(NSIndexPath *)indexPath imageType:(NSInteger)imageType;

@end
