//
//  SquareAndMask.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/18/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SquareAndMask : NSObject
{
    BOOL saveLocally;
    id delegate;
    id userInfo;
    NSMutableData *responseData;
    NSNumber *personId;
    NSString *fileURL;
    UIImage *cachedImage;
    UIImage *imageMask;
}

@property (assign) BOOL saveLocally;
@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) id userInfo;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) NSNumber *personId;
@property (strong, nonatomic) NSString *fileURL;
@property (strong, nonatomic) UIImage *cachedImage;
@property (strong, nonatomic) UIImage *imageMask;

+ (UIImage *)squareImage:(UIImage *)image;
+ (UIImage *)scaleImage:(UIImage *)image;
+ (UIImage *)scaleImageRect:(UIImage *)image;
+ (UIImage *)maskImage:(UIImage *)image;
- (UIImage *)maskImage:(UIImage *)image;
+ (NSData *)maskImage:(UIImage *)image withImage:(UIImage *)imgMask;
+ (UIImage *)imageFromDevice:(NSString *)strURL;
- (void)imageFromURL:(NSString *)strURL;

@end

@protocol DownloadImage <NSObject>
@optional
- (void)imageDidFail;
- (void)imageDidFinishLoading:(NSNumber *)personId image:(UIImage *)image userInfo:(id)userInfo;
@end