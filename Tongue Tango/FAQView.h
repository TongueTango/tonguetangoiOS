//
//  FAQView.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressHUD.h"

@interface FAQView : UIViewController <UIWebViewDelegate>

@property (strong) ProgressHUD *theHUD;

- (IBAction)toggleMove;
- (IBAction)moveRight;
- (IBAction)moveLeft;

@end
