//
//  ProgressBar.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 5/8/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProgressBar : NSObject

@property (nonatomic) NSInteger total;
@property (nonatomic) CGFloat totalProgress;
@property (strong, nonatomic) UIView *theView;
@property (strong, nonatomic) UIImageView *progressFill;
@property (strong, nonatomic) UIImageView *progressBorder;

- (ProgressBar *)initWithTotal:(NSInteger)_total addToView:(UIView *)theCurrentView;

- (void)createProgressBar;
- (void)removeProgressBar;
- (void)setBarColor:(UIColor *)color;
- (void)increaseProgress:(CGFloat)progress;

@end
