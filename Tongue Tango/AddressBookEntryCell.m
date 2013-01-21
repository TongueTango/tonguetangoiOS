//
//  AddressBookEntryCell.m
//  Tongue Tango
//
//  Created by Aftab Baig on 9/23/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "AddressBookEntryCell.h"

@implementation AddressBookEntryCell

@synthesize lblTitle=_lblTitle;
@synthesize lblPhone=_lblPhone;
@synthesize btnSelected=_btnSelected;

@synthesize entryId=_entryId;
@synthesize delegate=_delegate;

+(AddressBookEntryCell*)createCellWithId:(NSInteger)entryId title:(NSString*)title phone:(NSString*)phone isSelected:(BOOL)isSelected
{
    AddressBookEntryCell *cell = [[[NSBundle mainBundle] loadNibNamed:@"AddressBookEntryCell" owner:self options:nil] objectAtIndex:0];
    cell.entryId = entryId;
    cell.lblTitle.text = title;
    cell.lblPhone.text = phone;
    cell.btnSelected.selected = isSelected;
    
    
    return cell;
}

-(IBAction)toggleSelect:(id)sender
{
    UIButton *button = (UIButton*)sender;
    button.selected = !button.selected;
    
    if (button.selected)
    {
        [self.delegate shouldSelectEntry:self.entryId];
    }
    else
    {
        [self.delegate shouldDeselectEntry:self.entryId];
    }
}

@end
