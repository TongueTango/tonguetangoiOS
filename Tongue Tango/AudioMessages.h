//
//  AudioMessages.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/2/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioMessages : NSObject
{
    id delegate;
    UILabel *notifyLabel;
    NSInteger retryCount;
    NSMutableData *responseData;
    NSNumber *messageID;
    NSString *filePath;
    NSString *messageBody;
    NSString *strURL;
    NSURLConnection *apiConnection;
    CGFloat fileSize;
}

@property(nonatomic, retain) id delegate;
@property(nonatomic, retain) UILabel *notifyLabel;
@property(nonatomic, retain) NSMutableData *responseData;
@property(nonatomic, retain) NSString *filePath;

- (void)audioFromURL:(NSString *)url withID:(NSNumber *)msgID andBody:(NSString *)body;

@end

@protocol DownloadAudio <NSObject>
@optional
- (void)audioDidDownload:(BOOL)success statusLabel:(UILabel *)label messageBody:(NSString *)body messageID:(NSNumber *)messageID;
@end