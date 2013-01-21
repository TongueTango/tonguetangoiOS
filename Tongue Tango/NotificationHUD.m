//
//  NotificationHUD.m
//  Tongue Tango
//
//  Created by Chris Air on 5/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "NotificationHUD.h"
#import "CoreDataClass.h"

@implementation NotificationHUD

@synthesize bttnAction;
@synthesize userPhoto;
@synthesize lblMessage;
@synthesize theBanner;
@synthesize controller;

- (NotificationHUD *)initWithTarget:(UIViewController *)_controller
{
    self = [super init];
    if(self) {
        self.controller = _controller;
        [self createNotification];
    }
    return(self);
}

- (void)createNotification
{
    theBanner = [[UIView alloc] initWithFrame:CGRectMake(0, 480, 320, 40)];
    
    // Set the background for the notification bar
    UIImageView *bgNotify = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    bgNotify.image = [UIImage imageNamed:@"bg_notification_bar"];
    bgNotify.alpha = 0.9;
    [theBanner addSubview:bgNotify];
    
    UIImageView *imgArrow = [[UIImageView alloc] initWithFrame:CGRectMake(300, 12, 12, 16)];
    imgArrow.backgroundColor = [UIColor clearColor];
    imgArrow.image = [UIImage imageNamed:@"arrow_notification.png"];
    [theBanner addSubview:imgArrow];
    
    userPhoto = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 25, 25)];
    userPhoto.backgroundColor = [UIColor clearColor];
    [theBanner addSubview:userPhoto];
    
    UIImageView *imgPlaceholder = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 32, 32)];
    imgPlaceholder.backgroundColor = [UIColor clearColor];
    imgPlaceholder.image = [UIImage imageNamed:@"userpic_notification.png"];
    [theBanner addSubview:imgPlaceholder];
    
    lblMessage = [[UILabel alloc] initWithFrame:CGRectMake(42, 9, 250, 21)];
    lblMessage.backgroundColor = [UIColor clearColor];
    lblMessage.font = [UIFont fontWithName:@"Helvetica Bold" size:13];
    lblMessage.text = @"Push Notification";
    lblMessage.textColor = [UIColor whiteColor];
    [theBanner addSubview:lblMessage];
    
    bttnAction = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [theBanner addSubview:bttnAction];
    
    [controller.view addSubview:theBanner];
}

- (void)toggleNotification:(int)yPoint animate:(BOOL)animate
{
    if (animate) {
        [UIView animateWithDuration :.2
                               delay:0
                             options:UIViewAnimationOptionTransitionNone
                          animations:^{
                              [theBanner setCenter:CGPointMake(160, yPoint)];
                          }
                          completion:nil];
    } else {
        [theBanner setCenter:CGPointMake(160, yPoint)];
    }
}

- (void)setWithUserInfo:(NSDictionary *)userInfo
{
    // Clear out the previous info
    userPhoto.image = nil;
    lblMessage.text = nil;
    
    NSDictionary *extras = [userInfo objectForKey:@"extra"];
    
    BOOL friendRequest = NO;
    if ([extras objectForKey:@"action"]) {
        if ([[extras objectForKey:@"action"] isEqualToString:@"group"]) {
            userPhoto.image = [UIImage imageNamed:@"userpic_placeholder_group"];
            lblMessage.text = NSLocalizedString(@"ADDED TO A GROUP", nil);
            return;
        } else if ([[extras objectForKey:@"action"] isEqualToString:@"request"]) {
            friendRequest = YES;
        }
    }
    
    CoreDataClass *core = [CoreDataClass sharedInstance];
    if ([[extras objectForKey:@"user_id"] intValue] > 0) {
        NSString *where = [NSString stringWithFormat:@"user_id = %@", [extras objectForKey:@"user_id"]];
        NSArray *result = [core searchEntity:@"People" Conditions:where Sort:@"" Ascending:YES andLimit:1];
        userPhoto.image = [self imageFromObjects:result forType:@"User" isFriendRequest:friendRequest];
    } else {
        NSString *where = [NSString stringWithFormat:@"id = %@", [extras objectForKey:@"group_id"]];
        NSArray *result = [core searchEntity:@"Groups" Conditions:where Sort:@"" Ascending:YES andLimit:1];
        userPhoto.image = [self imageFromObjects:result forType:@"Group" isFriendRequest:friendRequest];
    }
    
    if ([extras objectForKey:@"message"]) {
        lblMessage.text = [extras objectForKey:@"message"];
    } else {
        lblMessage.text = NSLocalizedString(@"HAVE A NEW MESSAGE", nil);
    }
}

- (UIImage *)imageFromObjects:(NSArray *)objects forType:(NSString *)type isFriendRequest:(BOOL)request
{
    if ([objects count] > 0) {
        NSManagedObject *object = [objects objectAtIndex:0];
        
        // Local directory
       // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //NSString *documentsPath = [paths objectAtIndex:0];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];

        
        // Full local path
        if ([object valueForKey:@"photo"]) {
            NSString *theFileName = [[[object valueForKey:@"photo"] lastPathComponent] stringByDeletingPathExtension];
            
            if ([theFileName length] > 0) {
                NSString *filePath = [documentsPath stringByAppendingPathComponent:theFileName];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) { 
                    return [UIImage imageWithContentsOfFile:filePath];
                }
            }
        }
    }
    
    if (request) {
        return [UIImage imageNamed:@"logo"];
    }
    
    if ([type isEqualToString:@"Group"]) {
        return [UIImage imageNamed:@"userpic_placeholder_group"];
    }
    return [UIImage imageNamed:@"userpic_placeholder_male"];
}

- (void)addAction:(SEL)action
{
    [bttnAction removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [bttnAction addTarget:self.controller action:action forControlEvents:UIControlEventTouchUpInside]; 
}

- (void)addAction:(SEL)action withPhoto:(UIImage *)photo andMessage:(NSString *)message
{
    userPhoto.image = photo;
    lblMessage.text = message;
    [self addAction:action];
}

- (void)setHidden:(BOOL)hide animate:(BOOL)animate
{
    if (hide) {
        if (theBanner.center.y != 480) {
            [bttnAction removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self toggleNotification:480 animate:animate];
        }
    } else {
        [controller.view bringSubviewToFront:theBanner];
        [self toggleNotification:440 animate:animate];
    }
}

@end
