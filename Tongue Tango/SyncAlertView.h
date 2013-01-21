//
//  SyncAlertView.h
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SyncAlertDelegate
-(void)allow;
-(void)cancel;
@end

@interface SyncAlertView : UIViewController

-(IBAction)allowPressed:(id)sender;
-(IBAction)cancelPressed:(id)sender;

@property (nonatomic,retain) id<SyncAlertDelegate> delegate;

@end
