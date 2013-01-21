//
//  TwitterHelper.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/14/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "TwitterHelper.h"
#import "SA_OAuthTwitterEngine.h"
#import "Constants.h"

@implementation TwitterHelper

@synthesize twitterEngine;
@synthesize delegate;
@synthesize userInfo;
@synthesize currentAPICall;

static TwitterHelper *singletonDelegate = nil;

#pragma mark - Singleton Methods

- (id)init
{
    self = [super init];

    if(!twitterEngine){
        twitterEngine = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
        twitterEngine.consumerKey    = kOAuthConsumerKey;
        twitterEngine.consumerSecret = kOAuthConsumerSecret;
    }
    return self;
}

+ (TwitterHelper *)sharedInstance
{
    if (singletonDelegate == nil) {
        singletonDelegate = [[super allocWithZone:NULL] init];
    }
    
    return singletonDelegate;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if (singletonDelegate == nil) {
			singletonDelegate = [super allocWithZone:zone];
			return singletonDelegate;
		}
	}
	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

#pragma mark - Public Session Methods

- (BOOL)isLoggedIn
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:@"TWAuthData"] length] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)login
{
    if(!twitterEngine){
        twitterEngine = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
        twitterEngine.consumerKey    = kOAuthConsumerKey;
        twitterEngine.consumerSecret = kOAuthConsumerSecret;
    }
    
    UIViewController *controller = [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine:twitterEngine delegate:self];
    
    if (controller) {
        [delegate presentModalViewController:controller animated: YES];
    }
}

- (void)logout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:@"TWAuthData"] length] > 0) {
        [defaults removeObjectForKey:@"TWAuthData"];
        [defaults removeObjectForKey:@"TWUsername"];
        [defaults synchronize];
        twitterEngine = nil;
    }
    if ([delegate respondsToSelector:@selector(twDidReturnLogout:)] ) {
        [delegate twDidReturnLogout:YES];
    }
}

- (void)storeCachedTwitterOAuthData:(NSString *)data forUsername:(NSString *)username
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:data forKey:@"TWAuthData"];
    [defaults setObject:username forKey:@"TWUsername"];
    [defaults synchronize];
    
    if ([delegate respondsToSelector:@selector(twDidReturnLogin:)] ) {
        [delegate twDidReturnLogin:YES];
    }
}

- (NSString *)cachedTwitterOAuthDataForUsername:(NSString *)username
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"TWAuthData"];
}

- (void)OAuthTwitterControllerFailed:(SA_OAuthTwitterController *)controller
{
    [self requestFailed:@"Twitter Controller failed."];
}

- (void)OAuthTwitterControllerCanceled:(SA_OAuthTwitterController *)controller
{
    [self requestFailed:@"Twitter Controller canceled."];
}


#pragma mark - Public Post Methods

- (void)postTextMessage:(NSString *)message
{
    if([twitterEngine isAuthorized])
    {
        self.currentAPICall = kTWTextMessage;
        [twitterEngine sendUpdate:message];
    }
}

- (void)postAudioMessage:(NSString *)message audioLink:(NSString *)link
{
	NSString *strMessage = [NSString stringWithFormat:@"%@ %@", message, link];
    if([twitterEngine isAuthorized])
    {
        self.currentAPICall = kTWAudioMessage;
        [twitterEngine sendUpdate:strMessage];
    }
}

- (NSArray *)getFollwerIDs:(NSString *)username
{
    NSString *sURL = [[NSString alloc] initWithFormat:@"https://api.twitter.com/1/followers/ids.json?cursor=-1&screen_name=%@", username];
    NSData *dataUserIDs = [NSData dataWithContentsOfURL:[NSURL URLWithString:sURL]];
    
    NSDictionary *dictUserIDs;
    if ([dataUserIDs length] > 0) {
        UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
        NSString *responseString = [[NSString alloc] initWithData:dataUserIDs encoding:NSUTF8StringEncoding];
        dictUserIDs = [parser objectWithString:responseString];
        
        if ([dictUserIDs objectForKey:@"error"]) {
            DLog(@"Twitter error: %@", [dictUserIDs objectForKey:@"error"]);
            return nil;
        }
    } else {
        return nil;
    }
    
    return [dictUserIDs objectForKey:@"ids"];
}

- (NSArray *)getMyFollowers:(NSArray *)followerIDs
{
    NSString *strUserIDs = [followerIDs componentsJoinedByString:@","];
    
    NSString *sURL = @"https://api.twitter.com/1/users/lookup.json";
    NSString *postBody = [NSString stringWithFormat:@"user_id=%@,twitter&include_entities=no", strUserIDs];
    NSData *postData = [postBody dataUsingEncoding:NSASCIIStringEncoding];
    
    NSError *error = nil;
    NSURLResponse *response;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:sURL]];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:postData];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"]; 
    
    NSData *dataReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    id followerData;
    if ([dataReply length] > 0) {
        UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
        NSString *responseString = [[NSString alloc] initWithData:dataReply encoding:NSUTF8StringEncoding];
        followerData = [parser objectWithString:responseString];
        
        if (![followerData isKindOfClass:[NSArray class]]) {
            DLog(@"Twitter error: No followers");
            return nil;
        }
        
    } else {
        return nil;
    }
    NSArray *arrFollowerData = (NSArray *)followerData;
    
    NSMutableArray *arrFollowers = [[NSMutableArray alloc] init];
    for (NSDictionary *follower in arrFollowerData) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [follower objectForKey:@"id"], @"id",
                              [follower objectForKey:@"name"], @"name",
                              [follower objectForKey:@"screen_name"], @"username",
                              nil];
        
        [arrFollowers addObject:dict];
    }
    return arrFollowers;
}

#pragma mark - Response Methods

- (void)requestSucceeded:(NSString *)requestIdentifier
{
    if ([delegate respondsToSelector:@selector(twDidReturnRequest:)] ) {
        [delegate twDidReturnRequest:YES];
    } else {
        DLog(@"Request %@ succeeded", requestIdentifier);
    }
}

- (void)requestFailed:(NSString *)error
{
    if ([delegate respondsToSelector:@selector(twDidReturnRequest:)] ) {
        [delegate twDidReturnRequest:NO];
    } else {
        DLog(@"Request failed with error: %@", error);
    }
}

@end
