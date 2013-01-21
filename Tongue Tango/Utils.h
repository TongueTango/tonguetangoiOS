//
//  Utils.h
//  Tongue Tango
//
//  Created by Johana Moccetti on 7/20/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Utils : NSObject

/**
 **     Check if app is currently running on an iPhone 5
 **/
+ (BOOL)isiPhone5;

+ (void)saveUserImage:(UIImage *)aImage;
+ (void)customizeNavigationBarTitle:(UINavigationItem *)navItem title:(NSString *)title;
+ (void) createImagesAndAudioDirectory;

@end
