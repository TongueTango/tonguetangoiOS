//
//  SyncTypeCell.m
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "SyncTypeCell.h"

@implementation SyncTypeCell

@synthesize lblTitle=_lblTitle;
@synthesize imgIcon=_imgIcon;
@synthesize btnSync=_btnSync;
@synthesize delegate=_delegate;
@synthesize syncType=_syncType;

+(SyncTypeCell*)createCell:(NSString*)text forType:(SyncType)syncType
{
    SyncTypeCell *cell = [[[NSBundle mainBundle] loadNibNamed:@"SyncTypeCell" owner:self options:nil] objectAtIndex:0];
    
    cell.syncType = syncType;
    cell.lblTitle.text = text;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (SyncTypeContacts == cell.syncType)
    {
        cell.imgIcon.image = [UIImage imageNamed:@"address_book_icon"];
        if (YES == [defaults boolForKey:@"ab_sync"])
        {
            [cell.btnSync setBackgroundImage:[UIImage imageNamed:@"check_mark_btn@2x"] forState:UIControlStateNormal];
            cell.btnSync.enabled = NO;
        }
    }
    else
    {
        cell.imgIcon.image = [UIImage imageNamed:@"facebook_icon"];
        if (YES == [defaults boolForKey:@"fb_sync"])
        {
            [cell.btnSync setBackgroundImage:[UIImage imageNamed:@"check_mark_btn@2x"] forState:UIControlStateNormal];
            cell.btnSync.enabled = NO;
        }
    }
    
    
    
    return cell;
    
}

-(IBAction)syncPressed:(id)sender
{
    if (self.delegate)
    {
        [self.delegate shouldSyncFor:self.syncType];
    }
}

@end
