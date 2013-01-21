//
//  FacebookHelper.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/18/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

#define kAppId @"130756190331765"

typedef enum apiCall {
    kLogout,
    kMyInfo,
    kMyFriends,
    kMyAppUsers,
    kPostLink,
    kPostPhotos,
    kPostStatus,
    kPostText,
    kPostVideos,
    kProfilePic
} apiCall;

@interface FacebookHelper : NSObject <FBRequestDelegate, FBSessionDelegate>
{
    int currentAPICall;
    Facebook* facebook;
    id delegate;
    id userInfo;
}

@property (nonatomic, assign) int currentAPICall;
@property(readonly) Facebook *facebook;
@property(strong) id delegate;
@property(strong) id userInfo;

+ (FacebookHelper *) sharedInstance;

#pragma mark - Public Methods

- (BOOL)isLoggedIn;
- (void)login;
- (void)logout;

- (void)postLinkToFriend:(NSString *)facebookId linkURL:(NSString *)link message:(NSString *)message;
- (void)postVideoToFriend:(NSString *)facebookId videoURL:(NSString *)link message:(NSString *)message;
- (void)postMyStatus:(NSString *)message;
- (void)postTextToFriend:(NSString *)facebookId message:(NSString *)message;

- (void)getMyInfo;
- (void)getMyFriends;
- (void)getMyAppUsers;
- (void)getProfilePic;
- (NSData *)getUsersImage:(NSString *)facebookId;

@end

@protocol FacebookHelper <NSObject>
@optional
- (void)fbDidReturnLogin:(BOOL)success;
- (void)fbDidReturnLogout:(BOOL)success;
- (void)fbDidReturnRequest:(BOOL)success:(NSMutableArray *)result;
- (void)fbDidReturnProfilePic:(UIImage*)profilePic;
@end
