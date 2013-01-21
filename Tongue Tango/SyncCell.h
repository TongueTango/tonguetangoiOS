//
//  SyncCell.h
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SyncType.h"
#import "SyncCellDelegate.h"

@interface SyncCell : UITableViewCell

@property (nonatomic,retain) IBOutlet UILabel *lblTitle;
@property (nonatomic,retain) IBOutlet UIButton *btnSync;
@property (nonatomic,retain) id<SyncCellDelegate> delegate;
@property (nonatomic) SyncType syncType;

+(SyncCell*)createCell:(NSString*)text forType:(SyncType)syncType;
-(IBAction)syncPressed:(id)sender;

@end
