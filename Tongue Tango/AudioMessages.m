//
//  AudioMessages.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/2/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "AudioMessages.h"

@implementation AudioMessages

@synthesize delegate;
@synthesize notifyLabel;
@synthesize responseData;
@synthesize filePath;

- (id)init
{
    self = [super init];
    
    if (self) {
        responseData = [[NSMutableData alloc] init];        
    }
    
    return self;
}

- (void)audioFromURL:(NSString *)url withID:(NSNumber *)msgID andBody:(NSString *)body
{
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    documentsPath = [documentsPath stringByAppendingPathComponent:kAudioDirectory];
    self.filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Audio%@", msgID]];
    
    retryCount  = 0;
    strURL      = url;
    messageBody = body;
    messageID   = msgID;
    
    [self startRequest];
}

- (void)startRequest
{
    if (apiConnection) {
        [apiConnection cancel];
        apiConnection = nil;
    }
    self.responseData = nil;
    self.responseData = [NSMutableData data];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strURL] 
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                                       timeoutInterval:20];
    apiConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connectionAlert:(NSString *)message
{
    if (!message) {
        message = NSLocalizedString(@"REQUEST ERROR MESSAGE", nil);
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REQUEST ERROR" , nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    fileSize = response.expectedContentLength;
//    NSLog(@"didReceiveResponse");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
    CGFloat ratio = ((CGFloat)[responseData length]/fileSize);
    int roundedUp = ceil(ratio * 100);
    notifyLabel.text = [NSString stringWithFormat:@"Downloading message...%i%%",roundedUp];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSUserDefaults standardUserDefaults] setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"ErrorCount"]+1 forKey:@"ErrorCount"];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"ErrorCount"] >= 3) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayedError"]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisplayedError"];
            [self connectionAlert:NSLocalizedString(@"UNABLE TO CONNECT", nil)];
        }
        if ([delegate respondsToSelector:@selector(audioDidDownload: statusLabel: messageBody: messageID:)]) {
            [delegate audioDidDownload:NO statusLabel:self.notifyLabel messageBody:nil messageID:messageID];
        }
    } else {
        DLog(@"Start retry #%i", retryCount);
        [self startRequest];
        return;
    }
    
    DLog(@"AudioMessages->didFailWithError: %@", [error description]);
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DisplayedError"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"ErrorCount"];
    TFLog(@"Saving file to local path: %@",filePath);
    [responseData writeToFile:self.filePath atomically:YES];
    
    if ([delegate respondsToSelector:@selector(audioDidDownload: statusLabel: messageBody: messageID:)]) {
        [delegate audioDidDownload:YES statusLabel:self.notifyLabel messageBody:messageBody messageID:messageID];
    }
}

@end