//
//  TwitterHelper.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/14/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SA_OAuthTwitterController.h"
#import "UA_SBJSON.h"

typedef enum twApiCall {
    kTWTextMessage,
    kTWAudioMessage,
} twApiCall;

@class SA_OAuthTwitterEngine;

@interface TwitterHelper : NSObject <SA_OAuthTwitterControllerDelegate>
{
    SA_OAuthTwitterEngine *twitterEngine;
    
    id delegate;
    id userInfo;
}

@property (nonatomic, assign) int currentAPICall;
@property(readonly) SA_OAuthTwitterEngine *twitterEngine;
@property(strong) id delegate;
@property(strong) id userInfo;

+ (TwitterHelper *) sharedInstance;

#pragma mark - Public Methods

- (BOOL)isLoggedIn;
- (void)login;
- (void)logout;

- (void)postTextMessage:(NSString *)message;
- (void)postAudioMessage:(NSString *)message audioLink:(NSString *)link;

- (NSArray *)getFollwerIDs:(NSString *)username;
- (NSArray *)getMyFollowers:(NSArray *)followerIDs;

- (void)requestFailed:(NSString *)error;
@end

@protocol TwitterHelper <NSObject>
@optional
- (void)twDidReturnLogin:(BOOL)success;
- (void)twDidReturnLogout:(BOOL)success;
- (void)twDidReturnRequest:(BOOL)success;
@end