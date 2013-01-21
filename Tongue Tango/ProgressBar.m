//
//  ProgressBar.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 5/8/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "ProgressBar.h"

@implementation ProgressBar

@synthesize total;
@synthesize totalProgress;
@synthesize theView;
@synthesize progressFill;
@synthesize progressBorder;

- (ProgressBar *)initWithTotal:(NSInteger)_total addToView:(UIView *)theCurrentView;
{
    self = [super init];
    if (self) {
        theView = theCurrentView;
        total = _total;
        totalProgress = 0.0;
    }
    return(self);
}

- (void)createProgressBar {
    progressBorder = [[UIImageView alloc] initWithFrame:CGRectMake(266, 15, 42, 7)];
    progressBorder.image = [UIImage imageNamed:@"progress_outline"];
    [theView addSubview:progressBorder];
    
    CGPoint center = theView.center;
    center.y -= 10;
    progressBorder.center = center;
    
    
    progressFill = [[UIImageView alloc] initWithFrame:CGRectMake(progressBorder.frame.origin.x + 1, progressBorder.frame.origin.y + 1, 0, 5)];
    progressFill.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1];
    [theView addSubview:progressFill];
}

- (void)removeProgressBar
{
    [progressFill removeFromSuperview];
    [progressBorder removeFromSuperview];
}

- (void)setBarColor:(UIColor *)color
{
    progressFill.backgroundColor = color;
}

- (void)increaseProgress:(CGFloat)progress
{
    self.totalProgress += progress;

    CGFloat ratio = self.totalProgress / self.total;
    CGFloat width = 40 * ratio;
    
    CGRect rect = progressFill.frame;
    rect.size.width = width;
    progressFill.frame = rect;
}

@end
