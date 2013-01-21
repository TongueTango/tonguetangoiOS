//
//  ProgressHUD.m
//  Tongue Tango
//
//  Created by Chris Air on 3/28/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "ProgressHUD.h"
#import <QuartzCore/QuartzCore.h>


#define ACTIVITY_INDICATOR_TAG      1000

#define k_MessageBoxView_Height     70
#define k_MessageBoxView_Offset     30

@implementation ProgressHUD

@synthesize theText;
@synthesize animate;
@synthesize theHUD;
@synthesize theView;
@synthesize shown;

- (ProgressHUD *)initWithText:(NSString *)text willAnimate:(BOOL)willanimate addToView:(UIView *)theCurrentView
{
    self = [super init];
    if(self) {
        theView = theCurrentView;
        theText = text;
        animate = willanimate;
    }
    return(self);
}

- (void)create
{
    CGRect deviceFrame     = [[UIScreen mainScreen] bounds];
    [self createWithY:deviceFrame.size.height/2 - k_MessageBoxView_Height - k_MessageBoxView_Offset];
}

- (void)createWithY:(float)Ycoord
{
    CGRect deviceFrame     = [[UIScreen mainScreen] bounds];
    theHUD = [[UIView alloc] initWithFrame:CGRectMake(0, 0, deviceFrame.size.width, deviceFrame.size.height)];
    theHUD.alpha = 0;
    
    UIView *cover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, deviceFrame.size.width, deviceFrame.size.height)];
    cover.alpha = 0.4;
    cover.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    [theHUD addSubview:cover];
    
    UIView *msgBox = [[UIView alloc] initWithFrame:CGRectMake(60, Ycoord, 200, k_MessageBoxView_Height)];
    msgBox.alpha = 0.9;
    msgBox.backgroundColor = [UIColor blackColor];
    [msgBox.layer setCornerRadius:8];
    [theHUD addSubview:msgBox];
    
    UILabel *loading = [[UILabel alloc] initWithFrame:CGRectMake(60, Ycoord + 4, 200, 26)];
    loading.backgroundColor = [UIColor clearColor];
    loading.textColor = [UIColor whiteColor];
    loading.textAlignment = UITextAlignmentCenter;
    loading.text = theText;
    [loading setShadowOffset:CGSizeMake(0, -1)];
    loading.shadowColor = [UIColor blackColor];
    [theHUD addSubview:loading];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity.center = CGPointMake(160, Ycoord + 50);
    [activity startAnimating];
    activity.tag = ACTIVITY_INDICATOR_TAG;
    [theHUD addSubview:activity];
    
    [theView addSubview:theHUD];
}

- (void)showHUD:(float)show {
    if (animate)
    {
        [UIView animateWithDuration :.2
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{ theHUD.alpha = show; }
                          completion:nil];
    }
    else
    {
        self.alpha = show;
    }
}

- (void)show
{
    shown = YES;
    [self showHUD:1];
}

- (void)hide
{
    shown = NO;
    [self showHUD:0];
}

- (void)showSpinner
{
    UIView *spinner = [theHUD viewWithTag:ACTIVITY_INDICATOR_TAG];
    [spinner setHidden:NO];
}

- (void)hideSpinner
{
    UIView *spinner = [theHUD viewWithTag:ACTIVITY_INDICATOR_TAG];
    [spinner setHidden:YES];
}

@end
