//
//  NotificationHUD.h
//  Tongue Tango
//
//  Created by Chris Air on 5/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationHUD : NSObject

@property (strong, nonatomic) UIButton *bttnAction;
@property (strong, nonatomic) UIImageView *userPhoto;
@property (strong, nonatomic) UILabel *lblMessage;
@property (strong, nonatomic) UIView *theBanner;
@property (strong, nonatomic) UIViewController *controller;

- (NotificationHUD *)initWithTarget:(UIViewController *)_controller;

- (void)createNotification;
- (void)toggleNotification:(int)yPoint animate:(BOOL)animate;
- (void)setWithUserInfo:(NSDictionary *)userInfo;
- (UIImage *)imageFromObjects:(NSArray *)objects forType:(NSString *)type isFriendRequest:(BOOL)request;
- (void)addAction:(SEL)action;
- (void)addAction:(SEL)action withPhoto:(UIImage *)photo andMessage:(NSString *)message;
- (void)setHidden:(BOOL)hide animate:(BOOL)animate;

@end
