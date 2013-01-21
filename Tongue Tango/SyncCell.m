//
//  SyncCell.m
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "SyncCell.h"

@implementation SyncCell

@synthesize lblTitle=_lblTitle;
@synthesize delegate=_delegate;
@synthesize syncType=_syncType;
@synthesize btnSync=_btnSync;

+(SyncCell*)createCell:(NSString*)text forType:(SyncType)syncType
{
    SyncCell *cell = [[[NSBundle mainBundle] loadNibNamed:@"SyncCell" owner:self options:nil] objectAtIndex:0];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (SyncTypeFacebook == syncType)
    {
        if (YES == [defaults boolForKey:@"fb_sync"])
        {
            [cell.btnSync setBackgroundImage:[UIImage imageNamed:@"check_mark_btn"] forState:UIControlStateNormal];
            cell.btnSync.enabled = NO;
        }
    }
    if (SyncTypeContacts == syncType)
    {
        if (YES == [defaults boolForKey:@"ab_sync"])
        {
            [cell.btnSync setBackgroundImage:[UIImage imageNamed:@"check_mark_btn"] forState:UIControlStateNormal];
            cell.btnSync.enabled = NO;
        }
    }
    
    cell.syncType = syncType;
    cell.lblTitle.text = text;
    return cell;
}

-(IBAction)syncPressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    [button setBackgroundImage:[UIImage imageNamed:@"check_mark_btn"] forState:UIControlStateNormal];
    
    if (self.delegate)
    {
        [self.delegate shouldSyncFor:self.syncType];
    }
}

@end
