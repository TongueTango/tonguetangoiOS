//
//  SquareAndMask.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/18/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "SquareAndMask.h"
#import "Constants.h"

@implementation SquareAndMask

@synthesize saveLocally;
@synthesize delegate;
@synthesize userInfo;
@synthesize responseData;
@synthesize personId;
@synthesize fileURL;
@synthesize cachedImage;
@synthesize imageMask;

- (SquareAndMask *) init
{
    self = [super init];
    return self;
}

#pragma mark - Modify image

// Used for squaring an image without masking (e.g. registration)
+ (UIImage *)squareImage:(UIImage *)image
{
    CGImageRef  imageRef;
    CGSize      imageSize = image.size;
    UIImage     *outputImage = nil;
    CGRect      cropRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    if (imageSize.width > imageSize.height) {
        cropRect.origin.x = roundf((imageSize.width - imageSize.height) / 2);
        cropRect.size.width = imageSize.height;
    } else {
        cropRect.origin.y = roundf((imageSize.height - imageSize.width) / 2);
        cropRect.size.height = imageSize.width;
    }
    
    // Crop the image
    if ((imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect))) {
        outputImage = [[UIImage alloc] initWithCGImage: imageRef];
        CGImageRelease(imageRef);
    } else {
        outputImage = image;
    }
    
    return outputImage;
}

// Used for masking only one image (e.g. default image)
+ (UIImage *)maskImage:(UIImage *)image
{
    UIImage *mask = [UIImage imageNamed:@"mask.png"];
    NSData *dataImage = [SquareAndMask maskImage:image withImage:mask];
    UIImage *returnImage = [UIImage imageWithData:dataImage];
    return returnImage;
}

+ (UIImage *)scaleImage:(UIImage *)image
{
    CGSize size = CGSizeMake(174, 174);
    UIGraphicsBeginImageContext(size);
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality (ctxt, kCGInterpolationHigh);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

+ (UIImage *)scaleImageRect:(UIImage *)image
{
    CGSize size = CGSizeMake(320, 480);
    UIGraphicsBeginImageContext(size);
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality (ctxt, kCGInterpolationHigh);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

// Used for masking multiple images with one object (e.g. address book)
- (UIImage *)maskImage:(UIImage *)image
{
    if (!self.imageMask) {
        self.imageMask = [UIImage imageNamed:@"mask.png"];
    }
    NSData *dataImage = [SquareAndMask maskImage:image withImage:self.imageMask];
    UIImage *returnImage = [UIImage imageWithData:dataImage];
    return returnImage;
}

+ (NSData *)maskImage:(UIImage *)image withImage:(UIImage *)imgMask
{
    CGSize      imageSize = image.size;
    UIImage     *outputImage = nil;
    
    // Check if the image is square
    if (imageSize.width != imageSize.height) {
        outputImage = [SquareAndMask squareImage:image];
    } else {
        outputImage = image;
    }
    
    if (imageSize.width > 174) {
        outputImage = [SquareAndMask scaleImage:outputImage];
    }
    
    // Apply the mask
    CGImageRef maskRef = imgMask.CGImage; 
    
    CGImageRef newMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask(outputImage.CGImage, newMask);
    CGImageRelease(newMask);
    
    outputImage = [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);
    NSData *dataImage = UIImagePNGRepresentation(outputImage);
    
    return dataImage;
}

#pragma mark - Retrieve image

+ (UIImage *)imageFromDevice:(NSString *)strURL
{
    NSString *theFilePath = [SquareAndMask getImageFilePath:strURL];
    if (theFilePath)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:theFilePath])
        {
            return [UIImage imageWithContentsOfFile:theFilePath];
        }
    }
    
    return nil;
}

+ (NSString *)getImageFilePath:(NSString *)strURL
{
    // Local directory
   // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    documentsPath = [documentsPath stringByAppendingPathComponent:kImageDirectory]; //New added

    NSString *theFileName = [[strURL lastPathComponent] stringByDeletingPathExtension];
    
    if ([theFileName length] > 0)
    {
        if ([theFileName isEqualToString:@"picture"])
        {
            NSArray *pathParts = [strURL componentsSeparatedByString:@"/"];
            theFileName = [NSString stringWithFormat:@"%@-userimage", [pathParts objectAtIndex:([pathParts count] - 2)]];
        }
        
        return [documentsPath stringByAppendingPathComponent:theFileName];
    }
    
    return nil;
}

- (void)imageFromURL:(NSString *)strURL
{
//    TFLog(@"Downloading user image: %@", strURL);
    self.fileURL = strURL;
    self.responseData = [NSMutableData data];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strURL]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:44];
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    NSLog(@"didReceiveResponse");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DLog(@"SquareAndMask->didFailWithError: %@", [error description]);
    if ([delegate respondsToSelector:@selector(imageDidFail)] ) {
        [delegate imageDidFail];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    if (responseData.length > 0)
    {
        // Mask the image
        UIImage *mask = [UIImage imageNamed:@"mask.png"];
        NSData *dataImage = [SquareAndMask maskImage:[UIImage imageWithData:responseData] withImage:mask];
        
        if (dataImage.length > 0) {
            UIImage *image = [UIImage imageWithData:dataImage];
            
            // Save the image to the device
            if (saveLocally)
            {
                NSData *dataImage = UIImagePNGRepresentation(image);
                NSString *theFilePath = [SquareAndMask getImageFilePath:self.fileURL];
                [dataImage writeToFile:theFilePath atomically:YES];
            }
            self.cachedImage = image;
            
            // Return the image to the delegate
            if ([delegate respondsToSelector:@selector(imageDidFinishLoading:image:userInfo:)] )
            {
                [delegate imageDidFinishLoading:self.personId image:image userInfo:self.userInfo];
                self.delegate = nil;
                self.responseData = nil;
                return;
            }
        }
    }
    
    if ([delegate respondsToSelector:@selector(imageDidFail)] )
    {
        [delegate imageDidFail];
    }
}

@end
