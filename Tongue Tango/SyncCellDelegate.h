//
//  SyncCellDelegate.h
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SyncCellDelegate
-(void)shouldSyncFor:(SyncType)type;
@end