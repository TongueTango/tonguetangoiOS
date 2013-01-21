//
//  ServerConnection.h
//  Checklyst Pro
//
//  Created by Ryan Bigger on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UA_SBJSON.h"
#import "CoreDataClass.h"

@interface ServerConnection : NSObject
{
    BOOL isQueueRunning;
    id delegate;
    id userInfo;
    NSString *reference;
    NSMutableData *responseData;
    NSMutableArray *arrRequests;
    NSTimer *refreshTimer;
    
    NSInteger retryCount;
}

@property(nonatomic, retain) id delegate;
@property(nonatomic, retain) id userInfo;
@property(nonatomic, retain) NSString *reference;
@property(nonatomic, retain) NSTimer *refreshTimer;
@property(nonatomic, retain) NSMutableData *responseData;
@property(nonatomic, retain) NSMutableArray *arrRequests;

- (void)startQueue;
- (void)apiCall:(NSData *)json Method:(NSString *)method URL:(NSString *)urlString;
- (void)apiCallForPairing:(NSData *)json Method:(NSString *)method URL:(NSString *)urlString;
- (void)sendFile:(NSString *)filePath URL:(NSString *)urlString JSON:(NSData *)jsonBody;
- (void)sendFileWithData:(NSData *)dataFile Method:(NSString *)method URL:(NSString *)urlString JSON:(NSData *)jsonBody fileName:(NSString *)filename;
- (void)getImage:(NSString *)urlString;
- (void)connectionAlert:(NSString *)message;
- (void)processFriends:(NSDictionary *)dictJSON essentialOnly:(BOOL)essential;
- (void)updateUserImage:(NSDictionary *)dict;

+ (ServerConnection *)sharedInstance;

@end

@protocol ServerResponse <NSObject>
@optional
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFailWithError:(NSError *)error reference:(NSString *)ref userInfo:(id)userInfo;
- (void)connectionDidFinishLoading:(NSMutableData*)response reference:(NSString *)ref userInfo:(id)userInfo;

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error; // remove when done updating all views
@end