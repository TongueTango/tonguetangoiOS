//
//  ProgressHUD.h
//  Tongue Tango
//
//  Created by Chris Air on 3/28/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressHUD : UIView

@property (strong, nonatomic) NSString *theText;
@property (nonatomic) BOOL animate;
@property (strong, nonatomic) UIView *theHUD;
@property (strong, nonatomic) UIView *theView;
@property (nonatomic) BOOL shown;

- (ProgressHUD *)initWithText:(NSString *)text willAnimate:(BOOL)willanimate addToView:(UIView *)theCurrentView;

- (void)create;
- (void)createWithY:(float)Ycoord;
- (void)showHUD:(float)show;
- (void)show;
- (void)hide;

- (void)showSpinner;
- (void)hideSpinner;

@end