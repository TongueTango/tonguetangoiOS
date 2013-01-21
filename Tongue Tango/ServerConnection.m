    //
//  ServerConnection.m
//  Checklyst Pro
//
//  Created by Ryan Bigger on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "ServerConnection.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "HomeView.h"

static ServerConnection *serverConnectionDelegate = nil;

@implementation ServerConnection

@synthesize delegate;
@synthesize userInfo;
@synthesize reference;
@synthesize responseData;
@synthesize arrRequests;
@synthesize refreshTimer;

#pragma mark - Public methods

+ (ServerConnection *)sharedInstance
{
    if (serverConnectionDelegate == nil)
    {
        serverConnectionDelegate = [[super alloc] init];
    }
    
    return serverConnectionDelegate;
}

- (id)init
{
    if (self) {
    }
    responseData = [[NSMutableData alloc] init];
    arrRequests = [[NSMutableArray alloc] init];
    retryCount = 0;
    isQueueRunning = NO;
    return self;
}

#pragma mark - Control queue

- (void)startQueue
{
    if (!isQueueRunning && [arrRequests count] > 0)
    {
        isQueueRunning = YES;
        retryCount = 0;
        [self beginNextRequest];
    }
}

- (void)stopQueue
{
    isQueueRunning = NO;
    if (refreshTimer)
    {
        [refreshTimer invalidate];
        refreshTimer = nil;
    }
}

- (void)beginNextRequest
{
    NSDictionary *dictTask = [arrRequests objectAtIndex:0];
    
    TFLog(@"Running %@ API Calls",[dictTask objectForKey:@"selector"]);
    // TFLog(@"Sending the following data: %@",dictTask);
    
    NSData* jsonData = [[dictTask objectForKey:@"json_string"] dataUsingEncoding:NSUTF8StringEncoding];
    if ([[dictTask objectForKey:@"file_path"] isEqualToString:@""])
    {
        [self apiCall:jsonData
               Method:[dictTask objectForKey:@"method"]
                  URL:[dictTask objectForKey:@"url"]
         ];
    }
    else
    {
        NSData *dataFile = [NSData dataWithContentsOfFile:[dictTask objectForKey:@"file_path"]];
        [self sendFileWithData:dataFile
                        Method:[dictTask objectForKey:@"method"]
                           URL:[dictTask objectForKey:@"url"]
                          JSON:jsonData
                      fileName:[dictTask objectForKey:@"file_name"]];
    }
}

#pragma mark - Make API requests

- (void)sendFile:(NSString *)filePath URL:(NSString *)urlString JSON:(NSData *)jsonBody
{
    NSData *dataFile = [NSData dataWithContentsOfFile:filePath];
    [self sendFileWithData:dataFile Method:@"POST" URL:urlString JSON:jsonBody fileName:@"recording.mp4"];
}

- (void)sendFileWithData:(NSData *)dataFile Method:(NSString *)method URL:(NSString *)urlString JSON:(NSData *)jsonBody fileName:(NSString *)filename
{
    responseData = nil;
    responseData = [[NSMutableData alloc] init];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonBody encoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:method];
    
    NSString *strUserToken  = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserToken"];
    
    if (strUserToken)
    {
        // add the header to the request.
        [request addValue:strUserToken forHTTPHeaderField:@"token"];
    }
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"body\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/json\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", jsonString] dataUsingEncoding:NSUTF8StringEncoding]];
    
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:dataFile];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // set request body
    [request setHTTPBody:body];
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)apiCall:(NSData *)json Method:(NSString *)method URL:(NSString *)urlString
{
    
    responseData = nil;
    responseData = [[NSMutableData alloc] init];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString *strUserToken  = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserToken"];
    NSLog(@"SERVER TOKEN: %@", strUserToken);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:44];
    [request setHTTPMethod: method];
    
    if (strUserToken)
    {
        [request addValue:strUserToken forHTTPHeaderField:@"token"];
    }
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: json];
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)apiCallForPairing:(NSData *)json Method:(NSString *)method URL:(NSString *)urlString
{
    
    responseData = nil;
    responseData = [[NSMutableData alloc] init];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString *strUserToken  = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserToken"];
    NSLog(@"SERVER TOKEN: %@", strUserToken);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:44];
    [request setHTTPMethod: method];
    
    if ([self.reference isEqualToString:@"pairContacts"])
    {
        [request addValue:@"1" forHTTPHeaderField:@"auto_pair"];
    }
    
    if (strUserToken)
    {
        [request addValue:strUserToken forHTTPHeaderField:@"token"];
    }
    
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: json];
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
    
}


- (void)getImage:(NSString *)urlString
{
    responseData = nil;
    responseData = [[NSMutableData alloc] init];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
}


#pragma mark - Return methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([delegate respondsToSelector:@selector(connection:didReceiveResponse:)] )
    {
        [delegate connection:connection didReceiveResponse:response];
    }
    else
    {
        // NSLog(@"didReceiveResponse");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
    if ([delegate respondsToSelector:@selector(connection:didReceiveData:)] )
    {
        [delegate connection:connection didReceiveData:data];
    }
}

- (void)connectionAlert:(NSString *)tile withMessage:(NSString *)message
{
    if (!message)
    {
        message = NSLocalizedString(@"REQUEST ERROR MESSAGE", nil);
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REQUEST ERROR" , nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)connectionAlert:(NSString *)message
{
    if (!message)
    {
        message = NSLocalizedString(@"REQUEST ERROR MESSAGE", nil);
    }
    
    [self connectionAlert:message withMessage:NSLocalizedString(@"REQUEST ERROR" , nil)];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSUserDefaults standardUserDefaults] setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"ErrorCount"]+1 forKey:@"ErrorCount"];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"ErrorCount"] >= 3) {
        [arrRequests removeAllObjects];
        [self stopQueue];
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayedError"]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisplayedError"];
            //[self connectionAlert:NSLocalizedString(@"UNABLE TO CONNECT", nil)];
        }
    }
    NSDictionary *dictTask;
    if ([arrRequests count] > 0) {
        dictTask = [arrRequests objectAtIndex:0];
    }
    DLog(@"ERROR%i: %@",[[NSUserDefaults standardUserDefaults] integerForKey:@"ErrorCount"],dictTask);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([delegate respondsToSelector:@selector(connectionDidFailWithError: reference: userInfo:)]) {
        [delegate connectionDidFailWithError:error reference:self.reference  userInfo:self.userInfo];
        [self stopQueue];
    } else if ([delegate respondsToSelector:@selector(connection:didFailWithError:)] ) {
        [delegate connection:connection didFailWithError:error];
        [self stopQueue];
    } else {
        if ([arrRequests count] > 0) {
            [self beginNextRequest];
        }
        TFLog(@"Following Connection Failed: %@",dictTask);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DisplayedError"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"ErrorCount"];
    
    UA_SBJsonParser *parser = [[UA_SBJsonParser alloc] init];
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    responseString = [[responseString stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"] mutableCopy];
    NSDictionary *dictJSON = [parser objectWithString:responseString];
    
    NSLog(@"===============================================================");
    NSLog(@"Response String: %@", responseString);
    NSLog(@"===============================================================");
    
    NSUInteger keyCount = [dictJSON count];
    if (keyCount > 0)
    {
        if ([delegate respondsToSelector:@selector(connectionDidFinishLoading: reference: userInfo:)])
        {
            [delegate connectionDidFinishLoading:self.responseData reference:self.reference userInfo:self.userInfo];
        }
        else
        if ([arrRequests count] > 0)
        {
            NSDictionary *dictTask;
            if ([arrRequests count] > 0)
            {
                dictTask = [arrRequests objectAtIndex:0];
            }
            
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                if ([[dictTask objectForKey:@"selector"] isEqualToString:@"reloadFriends"])
                {
                    [self processFriends:dictJSON essentialOnly:NO];
                }
                else
                if ([[dictTask objectForKey:@"selector"] isEqualToString:@"reloadFriendsOnly"])
                {
                    [self processFriends:dictJSON essentialOnly:YES];
                }
                else
                if ([[dictTask objectForKey:@"selector"] isEqualToString:@"refreshAfterDelete"])
                {
                    //=>    TO DO : delete friend
                }
                else
                if ([[dictTask objectForKey:@"selector"] isEqualToString:@"reloadGroups"])
                {
                    CoreDataClass *core = [[CoreDataClass alloc] init];
                    BOOL changed = NO;
                    
                    NSArray *arrTmpGroups = [dictJSON objectForKey:@"groups"];
                    
                    [core deleteAll:@"Groups" Conditions:@""];
                    
                    NSArray *allGroups = [core getData:@"Groups" Conditions:@"delete_date = nil" Sort:@"" Ascending:YES];
                    NSMutableDictionary *dictGroups = [[NSMutableDictionary alloc] init];
                    for (NSManagedObject *group in allGroups)
                    {
                        [dictGroups setObject:group forKey:[NSString stringWithFormat:@"%@", [group valueForKey:@"id"]]];
                    }
                    
                    for (NSMutableDictionary *group in  arrTmpGroups)
                    {
                        NSNumber *key = [group objectForKey:@"id"];                    
                        NSManagedObject *object = [dictGroups objectForKey:key];
                        // Check if this group exists in core data
                        if (object)
                        {
                            if (![[object valueForKey:@"photo"] isEqualToString:[group objectForKey:@"photo"]])
                            {
                                [self updateUserImage:[object valueForKey:@"photo"]];
                            }
                            [core setGroup:group forObject:object];
                            [dictGroups removeObjectForKey:key];
                            changed = YES;
                        }
                        else
                        {
                            if ([group objectForKey:@"delete_date"] == (id)[NSNull null])
                            {
                                [core addGroup:group];
                                changed = YES;
                            }
                        }
                    }
                    
                    for (NSNumber *key in dictGroups)
                    {
                        [core deleteAll:@"Groups" Conditions:[NSString stringWithFormat:@"id = %@", key]];
                        changed = YES;
                    }
                    
                    if (changed)
                    {
                        [core saveContext];
                    }
                    
                    //>---------------------------------------------------------------------------------------------------
                    //>     Call queryFriends in HomeView in order to begin downloading the new images. This is critical,
                    //>      because downloading those images will take some time
                    //>---------------------------------------------------------------------------------------------------
                    // Get groups from core data
                    /*NSArray *results = [core getData:@"Groups" Conditions:@"delete_date = nil" Sort:@"name" Ascending:YES];
                    NSMutableArray *arrFriends = [[NSMutableArray alloc] init];
                    
                    for (NSManagedObject *group in results)
                    {
                        NSDictionary *dictGroup = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"", @"id",
                                                   @"", @"user_id",
                                                   [group valueForKey:@"id"], @"group_id",
                                                   [group valueForKey:@"name"], @"first_name",
                                                   @"", @"last_name",
                                                   [group valueForKey:@"photo"], @"photo",
                                                   nil];
                        [arrFriends addObject:dictGroup];
                    }
                    
                    if (arrFriends.count > 0)
                    {
                        //NSMutableArray *arrSortedFriends = [self sortPeopleByFirstName:arrFriends];
                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        [appDelegate.homeViewController performSelectorInBackground:@selector(downloadImages:) withObject:arrFriends];
                    }*/
                }
                else
                if ([[dictTask objectForKey:@"selector"] isEqualToString:@"reloadConversations"] ||
                    [[dictTask objectForKey:@"selector"] isEqualToString:@"reloadMenu"])
                {
                    CoreDataClass *core = [[CoreDataClass alloc] init];
                    BOOL changed = NO;
                    
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    
                    appDelegate.pendingGroups = [dictJSON objectForKey:@"group_invitations"];
                    
                    NSArray *arrTmpThreads = [dictJSON objectForKey:@"threads"];
                    
                    NSArray *allThreads = [core getData:@"Message_threads" Conditions:@"" Sort:@"" Ascending:YES];
                    NSMutableDictionary *dictThreads = [[NSMutableDictionary alloc] init];
                    for (NSManagedObject *thread in allThreads)
                    {
                        [dictThreads setObject:thread forKey:[thread valueForKey:@"id"]];
                    }
                    
                    // Loop through to add threads
                    for (NSDictionary *thread in arrTmpThreads)
                    {
                        NSNumber *key = [thread objectForKey:@"thread_id"];
                        NSManagedObject *object = [dictThreads objectForKey:key];
                        if (object)
                        {
                            [core setMessageThread:thread forObject:object];
                            [dictThreads removeObjectForKey:key];
                        }
                        else
                        {
                            [core addMessageThread:thread];
                        }
                        changed = YES;
                    }
                    
                    for (NSNumber *key in dictThreads)
                    {
                        [core deleteAll:@"Message_threads" Conditions:[NSString stringWithFormat:@"id = %@", key]];
                        changed = YES;
                    }
                    
                    if (changed)
                    {
                        [core saveContext];
                    }
                }
                else
                    if ([[dictTask objectForKey:@"selector"] isEqualToString:@"reloadGroupMessages"])
                    {
                        [self processGroupMessages:dictJSON groupID:[dictTask objectForKey:@"id"] shouldApplyDelete:YES];
                    }
                    else
                        if ([[dictTask objectForKey:@"selector"] isEqualToString:@"reloadFriendMessages"])
                        {
                            [self processFriendMessages:dictJSON friendID:[dictTask objectForKey:@"id"] shouldApplyDelete:YES];
                        }
                        else
                            if ([[dictTask objectForKey:@"selector"] isEqualToString:@"reloadProducts"])
                            {
                                CoreDataClass *core = [[CoreDataClass alloc] init];
                                BOOL changed = NO;
                                
                                NSArray *arrProducts = [dictJSON objectForKey:@"products"];
                                
                                [core deleteAll:@"Products" Conditions:@""];
                                [core deleteAll:@"Products_content" Conditions:@""];
                                changed = YES;
                                for (int i=0; i < [arrProducts count]; i++)
                                {
                                    NSDictionary *dict = [arrProducts objectAtIndex:i];
                                    
                                    NSString *where = [NSString stringWithFormat:@"id = %@",[dict objectForKey:@"id"]];
                                    BOOL exists = [core doesDataExist:@"Products" Conditions:where];
                                    
                                    if (!exists)
                                    {
                                        [core setProduct:dict forObject:nil];
                                        changed = YES;
                                    }
                                }
                                
                                if (changed)
                                {
                                    [core saveContext];
                                }
                            }
                            else
                                if ([[dictTask objectForKey:@"selector"] isEqualToString:@"sendText"] ||
                                    [[dictTask objectForKey:@"selector"] isEqualToString:@"sendAudio"] ||
                                    [[dictTask objectForKey:@"selector"] isEqualToString:@"deleteMessage"] ||
                                    [[dictTask objectForKey:@"selector"] isEqualToString:@"deleteGroup"])
                                {
                                    //Do Nothing
                                }
                                else
                                    if ([[dictTask objectForKey:@"selector"] isEqualToString:@"loadMoreGroupMessages"])
                                    {
                                        [self processGroupMessages:dictJSON groupID:[dictTask objectForKey:@"id"] shouldApplyDelete:NO];
                                    }
                                    else
                                        if ([[dictTask objectForKey:@"selector"] isEqualToString:@"loadMoreFriendMessages"])
                                        {
                                            [self processFriendMessages:dictJSON friendID:[dictTask objectForKey:@"id"] shouldApplyDelete:NO];
                                        }
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:[dictTask objectForKey:@"selector"] object:nil];
                    [arrRequests removeObjectAtIndex:0];
                    if ([arrRequests count] > 0)
                    {
                        [self beginNextRequest];
                    } else
                    {
                        [self stopQueue];
                    }
                });
            });
        }
    }
    else
    {
        if ([delegate respondsToSelector:@selector(connectionDidFinishLoading: reference: userInfo:)])
        {
            [delegate connectionDidFinishLoading:self.responseData reference:self.reference userInfo:self.userInfo];
        }
        else
            if ([delegate respondsToSelector:@selector(connectionDidFailWithError: reference: userInfo:)])
            {
                [delegate connectionDidFailWithError:nil reference:self.reference  userInfo:self.userInfo];
                [self stopQueue];
            }
            else
                if ([delegate respondsToSelector:@selector(connection:didFailWithError:)] )
                {
                    [delegate connection:connection didFailWithError:nil];
                    [self stopQueue];
                }  
    }
}

#pragma mark - Process API data

- (void)processGroupMessages:(NSDictionary *)dictJSON groupID:(NSNumber *)groupID shouldApplyDelete:(BOOL)shouldDelete
{
    CoreDataClass *core = [[CoreDataClass alloc] init];
    BOOL changed = NO;
    
    NSArray *arrMessages = [dictJSON objectForKey:@"messages"];
    
    if ([arrMessages count] > 0)
    {
        // Get all the messages for this conversation
        NSString *where = [NSString stringWithFormat:@"group_id = %@", groupID];
        NSArray *allMessages = [core getData:@"Messages" Conditions:where Sort:@"" Ascending:YES];
        NSMutableDictionary *dictMessages = [[NSMutableDictionary alloc] init];
        for (NSManagedObject *message in allMessages)
        {
            [dictMessages setObject:message forKey:[NSString stringWithFormat:@"%@", [message valueForKey:@"id"]]];
        }
        
        // Loop through to add or update messages
        for (NSDictionary *message in arrMessages)
        {
            NSString *key = [NSString stringWithFormat:@"%@", [message objectForKey:@"id"]];
            NSManagedObject *object = [dictMessages objectForKey:key];
            if (object)
            {
                if (![[object valueForKey:@"message_path"] isEqualToString:[message objectForKey:@"message_path"]])
                {
                    [core setMessageForGroup:groupID withDictionary:message forObject:object];
                    changed = YES;
                }
                [dictMessages removeObjectForKey:key];
            }
            else
            {
                [core addMessageForGroup:groupID withDictionary:message];
                changed = YES;
            }
        }
        
        // Delete old messages
        for (NSString *key in dictMessages)
        {
            //>---------------------------------------------------------------------------------------------------
            //>     There are some invalid messages created, withouth a propoer id, so delete them
            //>---------------------------------------------------------------------------------------------------
            if ([key isEqualToString:@"0"])
            {
                [core deleteAll:@"Messages" Conditions:[NSString stringWithFormat:@"id = %@", key]];
                DLog(@"Delete message: %@", key);
            }
            else
                if (shouldDelete)
                {
                    [core deleteAll:@"Messages" Conditions:[NSString stringWithFormat:@"id = %@", key]];
                    DLog(@"Delete message: %@", key);
                }
            
            changed = YES;
        }
        
        if (changed)
        {
            [core saveContext];
        }
    }
}

- (void)processFriendMessages:(NSDictionary *)dictJSON friendID:(NSNumber *)friendID shouldApplyDelete:(BOOL)shouldDelete
{
    CoreDataClass *core = [[CoreDataClass alloc] init];
    BOOL changed = NO;
    
    NSArray *arrMessages = [dictJSON objectForKey:@"messages"];
    
    if ([arrMessages count] > 0) {
        // Get all the messages for this conversation
        NSString *where = [NSString stringWithFormat:@"(sender_id = %@ OR recipient_id = %@) AND group_id = 0", friendID, friendID];
        NSArray *allMessages = [core getData:@"Messages" Conditions:where Sort:@"" Ascending:YES];
        NSMutableDictionary *dictMessages = [[NSMutableDictionary alloc] init];
        for (NSManagedObject *message in allMessages) {
            [dictMessages setObject:message forKey:[NSString stringWithFormat:@"%@", [message valueForKey:@"id"]]];
        }
        
        // Loop through to add or update messages
        for (NSDictionary *message in arrMessages) {
            NSString *key = [NSString stringWithFormat:@"%@", [message objectForKey:@"id"]];
            NSManagedObject *object = [dictMessages objectForKey:key];
            if (object) {
                if ([[object valueForKey:@"is_favorite"] intValue] != [[message objectForKey:@"is_favorite"] intValue] || 
                    ![[object valueForKey:@"message_path"] isEqualToString:[message objectForKey:@"message_path"]]) {
                    [core setMessage:message forObject:object];
                    changed = YES;
                }
                [dictMessages removeObjectForKey:key];
            } else {
                [core addMessage:message];
                changed = YES;
            }
        }
        
        //>---------------------------------------------------------------------------------------------------
        //>     There are some invalid messages created, withouth a propoer id, so delete them
        //>---------------------------------------------------------------------------------------------------
        // Delete old messages
        for (NSString *key in dictMessages)
        {
            if ([key isEqualToString:@"0"])
            {
                [core deleteAll:@"Messages" Conditions:[NSString stringWithFormat:@"id = %@", key]];
                DLog(@"Delete message: %@", key);
            }
            else
                if (shouldDelete)
                {
                    [core deleteAll:@"Messages" Conditions:[NSString stringWithFormat:@"id = %@", key]];
                    DLog(@"Delete message: %@", key);
                }

            changed = YES;
        }
        
        if (changed)
        {
            [core saveContext];
        }
    }
}

- (void)processFriends:(NSDictionary *)dictJSON essentialOnly:(BOOL)essential
{
    CoreDataClass *core = [[CoreDataClass alloc] init];
    BOOL changed = NO;
    
    NSArray *arrTmpFriends  = [dictJSON objectForKey:@"tt_friends"];
    NSArray *arrTmpFBPeople = [dictJSON objectForKey:@"fb_friends"];
    NSArray *arrTmpPending  = [dictJSON objectForKey:@"pending_friends"];
    
    [core deleteAll:@"People" Conditions:@""];
    
    NSArray *allFriends = [core getData:@"People" Conditions:@"" Sort:@"" Ascending:YES];
    NSMutableDictionary *dictFriends = [[NSMutableDictionary alloc] init];
    for (NSManagedObject *friend in allFriends)
    {
        [dictFriends setObject:friend forKey:[friend valueForKey:@"id"]];
    }
    
    // Loop through to add or update friends
    for (NSDictionary *friend in arrTmpFriends)
    {
        NSNumber *key = [friend objectForKey:@"person_id"];
        NSManagedObject *object = [dictFriends objectForKey:key];
        if (object)
        {
            if (![[object valueForKey:@"photo"] isEqualToString:[friend objectForKey:@"photo"]])
            {
                [self updateUserImage:[object valueForKey:@"photo"]];
            }
            [core setPerson:friend forObject:object];
            [dictFriends removeObjectForKey:key];
        }
        else
        {
            [core addPerson:friend];
        }
        changed = YES;
    }
    if (essential)
    {
        for (NSDictionary *friend in arrTmpFBPeople)
        {
            NSNumber *key = [friend objectForKey:@"person_id"];
            NSManagedObject *object = [dictFriends objectForKey:key];
            if (object)
            {
                [dictFriends removeObjectForKey:key];
            }
        }
    }
    else
    {
        for (NSDictionary *friend in arrTmpFBPeople)
        {
            NSNumber *key = [friend objectForKey:@"person_id"];
            NSManagedObject *object = [dictFriends objectForKey:key];
            if (object)
            {
                [core setPerson:friend forObject:object];
                [dictFriends removeObjectForKey:key];
            }
            else
            {
                [core addPerson:friend];
            }
            changed = YES;
        }
    }
    
    for (NSDictionary *friend in arrTmpPending)
    {
        NSNumber *key = [friend objectForKey:@"person_id"];
        NSManagedObject *object = [dictFriends objectForKey:key];
        if (object)
        {
            [core setPerson:friend forObject:object];
            [dictFriends removeObjectForKey:key];
        }
        else
        {
            [core addPerson:friend];
        }
        changed = YES;
    }
    
    for (NSNumber *key in dictFriends)
    {
        [core deleteAll:@"People" Conditions:[NSString stringWithFormat:@"id = %@", key]];
        changed = YES;
    }
    
    if (changed)
    {
        [core saveContext];
    }
}

- (void)updateUserImage:(NSString *)photo
{
    if ([photo isKindOfClass:[NSString class]])
    {
        NSString *strURL = (NSString *)photo;
        
        // Find the image on the device
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *fileName = [[strURL lastPathComponent] stringByDeletingPathExtension];
        
        if ([fileName length] > 0)
        {
            if ([fileName isEqualToString:@"picture"])
            {
                NSArray *pathParts = [strURL componentsSeparatedByString:@"/"];
                fileName = [NSString stringWithFormat:@"%@-userimage", [pathParts objectAtIndex:([pathParts count] - 2)]];
            }
            
            // Build the full path
            NSString *imagePath = [documentsPath stringByAppendingPathComponent:fileName];
            TFLog(@"Deleting image: %@", imagePath);
            
            // Delete the image file from the device.
            NSError *error = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            BOOL isDir;
            if ([fileManager fileExistsAtPath:imagePath isDirectory:&isDir] && !isDir) {
                [fileManager removeItemAtPath:imagePath error:&error];        
                if (error) {
                    DLog("An error occurred while deleting the file.");
                }
            }
        }
    }
}

@end
