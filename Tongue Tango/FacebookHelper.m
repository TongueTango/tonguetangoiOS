//
//  FacebookHelper.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/18/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "FacebookHelper.h"

@implementation FacebookHelper

@synthesize facebook = facebook;
@synthesize delegate;
@synthesize userInfo, currentAPICall;

static FacebookHelper *singletonDelegate = nil;

#pragma mark - Singleton Methods

- (id)init
{
    return self;
}

+ (FacebookHelper *)sharedInstance
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
			// assignment and return on first allocation
			return singletonDelegate;
		}
	}
	// on subsequent allocation attempts return nil
	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

#pragma mark - Public Session Methods

- (BOOL)isLoggedIn
{
    facebook = [[Facebook alloc] initWithAppId:kAppId andDelegate:self];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }

    return ([facebook isSessionValid]);
}

- (void)login
{
    NSArray *permissions = [[NSArray alloc] initWithObjects: @"publish_stream", @"email", @"offline_access", @"user_hometown", @"user_location", nil];
    [facebook authorize:permissions];
}

- (void)logout
{
    [facebook logout];
}

#pragma mark - Public Post Methods

- (void)postLinkToFriend:(NSString *)facebookId linkURL:(NSString *)link message:(NSString *)message
{
    self.currentAPICall = kPostLink;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    /*[params setObject:@"status" forKey:@"type"];
    //>     This is a logo photo to be posted on FB
    [params setObject:@"https://s3.amazonaws.com/TongueTangoScreens_Static/video_placeholder.png" forKey:@"picture"];
    [params setObject:message forKey:@"message"];
    [params setObject:link forKey:@"link"];
    [params setObject:@"Tongue Tango" forKey:@"name"];
    //[params setObject:NSLocalizedString(@"FB VIDEO POST TITLE", nil) forKey:@"description"];
    [params setObject:link forKey:@"description"];
    [params setObject:NSLocalizedString(@"FB VIDEO POST TITLE", nil) forKey:@"caption"];*/
    
    NSString *actions = [NSString stringWithFormat:@"{\"name\":\"%@\",\"link\":\"%@\"}",
                         @"Get Tongue Tango", @"http://itunes.com/app/tonguetango"];
	[params setObject:actions forKey:@"actions"];
    
    [params setObject:@"video" forKey:@"type"];
    [params setObject:link forKey:@"link"];
    [params setObject:@"Tongue Tango" forKey:@"name"];
    [params setObject:message forKey:@"message"];
    [params setObject:@"https://s3.amazonaws.com/TongueTangoScreens_Static/Springboard.png" forKey:@"picture"];
    [params setObject:NSLocalizedString(@"FB VIDEO POST TITLE", nil) forKey:@"description"];
    
    NSString *sendTo = [NSString stringWithFormat:@"%@/feed", facebookId];
    DLog(@"Send to: %@", sendTo);
    
    [facebook requestWithGraphPath:sendTo andParams:params andHttpMethod:@"POST" andDelegate:self];
}

- (void)postVideoToFriend:(NSString *)facebookId videoURL:(NSString *)link message:(NSString *)message
{
    self.currentAPICall = kPostVideos;
    
    NSURL *url = [NSURL URLWithString:link];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   data, @"video.mov",
                                   @"video/quicktime", @"contentType",
                                   NSLocalizedString(@"FB VIDEO POST TITLE", nil), @"title",
                                   message, @"description",
								   nil];
    
    NSString *sendTo = [NSString stringWithFormat:@"%@/videos", facebookId];
    DLog(@"Send to: %@", sendTo);
    
    [facebook requestWithGraphPath:sendTo andParams:params andHttpMethod:@"POST" andDelegate:self];
}

- (void)postTextToFriend:(NSString *)facebookId message:(NSString *)message
{
    self.currentAPICall = kPostText;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSString *actions = [NSString stringWithFormat:@"{\"name\":\"%@\",\"link\":\"%@\"}",
                         @"Get Tongue Tango", @"http://itunes.com/app/tonguetango"];
	[params setObject:actions forKey:@"actions"];
    
    [params setObject:message forKey:@"message"];
    
    NSString *sendTo = [NSString stringWithFormat:@"%@/feed", facebookId];
    DLog(@"Send to: %@", sendTo);
    
    [facebook requestWithGraphPath:sendTo andParams:params andHttpMethod:@"POST" andDelegate:self];
}

- (void)postMyStatus:(NSString *)message
{
    self.currentAPICall = kPostStatus;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"status" forKey:@"type"];
    [params setObject:message forKey:@"message"];
    [params setObject:@"http://itunes.com/app/tonguetango" forKey:@"link"];
    [params setObject:@"Tongue Tango" forKey:@"name"];
    
    [facebook requestWithGraphPath:@"me/feed" andParams:params andHttpMethod:@"POST" andDelegate:self];
}

#pragma mark - Public Get Methods

- (void)getMyInfo
{
    self.currentAPICall = kMyInfo;
    [facebook requestWithGraphPath:@"me" andDelegate:self];
}

- (void)getMyFriends
{
    self.currentAPICall = kMyFriends;
    [facebook requestWithGraphPath:@"me/friends" andDelegate:self];
}

- (void)getMyAppUsers
{
    self.currentAPICall = kMyAppUsers;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"friends.getAppUsers", @"method", nil];
    [facebook requestWithParams:params andDelegate:self];
}

- (void)getProfilePic
{
    self.currentAPICall = kProfilePic;
    [facebook requestWithGraphPath:@"me/picture?type=large" andDelegate:self];
}

- (NSData *)getUsersImage:(NSString *)facebookId
{
    // Get the object image
    NSString *url = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture?type=large", facebookId];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    return data;
}

#pragma mark - FBSessionDelegate Methods

// Sent to the delegate when the user successfully logs in.
- (void)fbDidLogin
{
    DLog(@"FB TOKEN SHOULD BE ON NEXT LINE");
    DLog(@"%@",[facebook accessToken]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
    if ([delegate respondsToSelector:@selector(fbDidReturnLogin:)] ) {
        [delegate fbDidReturnLogin:YES];
    }
}

// Sent to the delegate when there is an error during authorization
// or if the user dismissed the dialog without logging in.
- (void)fbDidNotLogin:(BOOL)cancelled
{
    if ([delegate respondsToSelector:@selector(fbDidReturnLogin:)] ) {
        [delegate fbDidReturnLogin:NO];
    }
}

// Sent to the delegate when the user logged out.
- (void)fbDidLogout {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"FBAccessTokenKey"] length] > 0) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults removeObjectForKey:@"FBIdentifier"];
        [defaults synchronize];
    }
    if ([delegate respondsToSelector:@selector(fbDidReturnLogout:)] ) {
        [delegate fbDidReturnLogout:YES];
    }
}


#pragma mark - FBRequestDelegate Methods

// Sent to the delegate just before the request is sent to the server.
- (void)requestLoading:(FBRequest *)request
{
    DLog(@"Facebook helper return: %@", request);
}

// Sent to the delegate when an error prevents the request from completing successfully.
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
    if ([delegate respondsToSelector:@selector(fbDidReturnRequest::)] ) {
        [delegate fbDidReturnRequest:NO:nil];
    } else {
        DLog(@"Facebook helper return: %@", [error localizedDescription]);
    }
}

// Sent to the delegate when a request returns and its response has been parsed into an object.
- (void)request:(FBRequest *)request didLoad:(id)result
{
    NSMutableArray *arrResult = [[NSMutableArray alloc] init];
    BOOL setArrResult = NO;

    switch (currentAPICall) {
        case kMyInfo:
        {
            
            [arrResult addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [result objectForKey:@"id"], @"facebook_id",
                                  [result objectForKey:@"first_name"], @"firstname",
                                  [result objectForKey:@"last_name"], @"lastname",
                                  [result objectForKey:@"email"], @"email",
                                  nil]];
            setArrResult = YES;
            break;
        }
        case kMyFriends:
        {
            NSMutableArray *resultData = [result objectForKey:@"data"];
            int resultCount = [resultData count];
            for (int i = 0; i < resultCount; i++) {
                NSDictionary *data = [resultData objectAtIndex:i];
                [arrResult addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"fb%@",[data objectForKey:@"id"]], @"id",
                                      [data objectForKey:@"id"], @"facebook_id",
                                      [data objectForKey:@"name"], @"first_name",
                                      @"", @"last_name",
                                      nil]];
                setArrResult = YES;
            }
            break;
        }
        case kMyAppUsers:
        {
            // Many results
            if ([result isKindOfClass:[NSArray class]]) {
                [arrResult addObjectsFromArray:result];
                setArrResult = YES;
            } else if ([result isKindOfClass:[NSDecimalNumber class]]) {
                [arrResult addObject:[result stringValue]];
                setArrResult = YES;
            }
        }
        case kProfilePic:
        {
            UIImage *image = [UIImage imageWithData:result];
            
            if ([delegate respondsToSelector:@selector(fbDidReturnProfilePic:)] )
            {
                [delegate fbDidReturnProfilePic:image];
            }
            break;
        }
        case kPostLink:
        {
            setArrResult = YES;
            break;
        }
        case kPostText:
        {
            setArrResult = YES;
            break;
        }
        default:
            break;
    }
    
    if ([delegate respondsToSelector:@selector(fbDidReturnRequest::)] && setArrResult)
    {
        DLog(@"Lets see result : %@",[result description]);
        [delegate fbDidReturnRequest:YES:arrResult];
    }
    else
    {
        DLog(@"Facebook helper return: %@", result);
    }
}

@end
