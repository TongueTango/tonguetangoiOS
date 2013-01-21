//
//  AppDelegate.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 1/19/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppRageIAPHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SyncFriendsView.h"

@class HomeView;
@class CoreDataClass;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    InAppRageIAPHelper *inAppHelper;
    UIImage *imageNotification;
    NSUserDefaults *defaults;
    SystemSoundID pushSound;
    BOOL isAlerted;
    BOOL isExternalPush;
    
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HomeView *homeViewController;
@property (strong, nonatomic) CoreDataClass *coreDataClass;
@property (strong, nonatomic) NSMutableArray *pendingGroups;

- (void)resetUserDefaults;
- (void)updateUnreadMessages:(NSInteger)newValue;
- (void)updatePendingFriends:(NSInteger)newValue;
    
@end