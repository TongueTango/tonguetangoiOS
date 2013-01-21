//
//  AddressBookEntryCell.h
//  Tongue Tango
//
//  Created by Aftab Baig on 9/23/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddressBookCellDelegate
-(void)shouldSelectEntry:(int)entryId;
-(void)shouldDeselectEntry:(int)entryId;
@end

@interface AddressBookEntryCell : UITableViewCell

@property (nonatomic,retain) IBOutlet UILabel *lblTitle;
@property (nonatomic,retain) IBOutlet UILabel *lblPhone;
@property (nonatomic,retain) IBOutlet UIButton *btnSelected;

@property (nonatomic) NSInteger entryId;
@property (nonatomic,retain) id<AddressBookCellDelegate> delegate;

+(AddressBookEntryCell*)createCellWithId:(NSInteger)entryId title:(NSString*)title phone:(NSString*)phone isSelected:(BOOL)isSelected;
-(IBAction)toggleSelect:(id)sender;

@end
