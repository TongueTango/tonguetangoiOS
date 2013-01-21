//
//  InviteFriendsView.h
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <MessageUI/MessageUI.h>
#import "AddressBookEntryCell.h"
#import "ProgressHUD.h"

@protocol RecipientsDelegate
-(void)mailRecipientsAdded:(NSMutableArray*)recipients;
-(void)smsRecipientsAdded:(NSMutableArray*)recipients;
@end

@interface InviteFriendsView : UIViewController <AddressBookCellDelegate,MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, RecipientsDelegate>

@property (nonatomic,retain) IBOutlet UITableView *tblFriends;
@property (nonatomic,retain) NSMutableArray *people;
@property (nonatomic,retain) NSMutableArray *temp;
@property (nonatomic,retain) ProgressHUD *theHUD;

-(IBAction)back:(id)sender;
-(IBAction)selectAll:(id)sender;
-(IBAction)preview:(id)sender;
-(IBAction)segmentSwitch:(id)sender;
-(NSMutableArray *)getAllAddressBookPeople;

@end

@interface Recipients : NSObject 

@property (nonatomic,retain) id<RecipientsDelegate> delegate;

@end