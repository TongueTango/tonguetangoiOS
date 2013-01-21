//
//  Utils.m
//  Tongue Tango
//
//  Created by Johana Moccetti on 7/20/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "Utils.h"
#import "SquareAndMask.h"
#import "Constants.h"

@implementation Utils

/**
 **     Check if app is currently running on an iPhone 5
 **/
+ (BOOL)isiPhone5
{
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) && ([[UIScreen mainScreen] bounds].size.height * [[UIScreen mainScreen] scale] >= 1136);
}

+ (void)saveUserImage:(UIImage *)aImage {

    NSData *imageData = UIImagePNGRepresentation(aImage);
    
    if (imageData.length > 0)
    {
        SquareAndMask *squareAndMask = [[SquareAndMask alloc] init];
        UIImage *maskedImage = [squareAndMask maskImage:aImage];
        NSData *dataImage = UIImagePNGRepresentation(maskedImage);
        
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"UserImage"];
        [dataImage writeToFile:filePath atomically:YES];
        [[NSUserDefaults standardUserDefaults] setObject:filePath forKey:@"UserImage"];
    }
}

+ (void)customizeNavigationBarTitle:(UINavigationItem *)navItem title:(NSString *)title {    
    
    UILabel *tmpTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 0.0, 150, 44)];
    tmpTitleLabel.text = [title uppercaseString];
    tmpTitleLabel.backgroundColor = [UIColor clearColor];
    tmpTitleLabel.textColor = [UIColor whiteColor];
    [tmpTitleLabel setFont:[UIFont fontWithName:@"BebasNeue" size:32.0]];
    //[tmpTitleLabel setFont:[UIFont fontWithName:@"Bell Gothic Bold BT" size:32.0]];
    tmpTitleLabel.textAlignment = UITextAlignmentCenter;
    
    CGRect applicationFrame = CGRectMake(0.0, 0.0, 172.0, 44.0);
    UIView * newView = [[UIView alloc] initWithFrame:applicationFrame];
    [newView setBackgroundColor:[UIColor clearColor]];
    [newView addSubview:tmpTitleLabel];
    navItem.titleView = newView;
    
}


+(void) createImagesAndAudioDirectory
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [libraryDirectory stringByAppendingPathComponent:kImageDirectory];
    NSString *audioPath = [libraryDirectory stringByAppendingPathComponent:kAudioDirectory];
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath])
        [[NSFileManager defaultManager] createDirectoryAtPath:imagePath withIntermediateDirectories:NO attributes:nil error:&error];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:audioPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:audioPath withIntermediateDirectories:NO attributes:nil error:&error];

}
@end
