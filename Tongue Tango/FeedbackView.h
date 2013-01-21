//
//  FeedbackView.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/19/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FeedbackView : UIViewController
{
    BOOL openEmail;
    BOOL rateApp;
    id delegate;
}

@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) IBOutlet UIButton *bttnRateUs;
@property (strong, nonatomic) IBOutlet UIButton *bttnFeedback;
@property (strong, nonatomic) IBOutlet UILabel *partnersEmailLabel;

- (IBAction)openToRateApp:(id)sender;
- (IBAction)openFeedbackEmail:(id)sender;

@end

@protocol Parent <NSObject>
@optional
- (void)openRateThisApp;
- (void)openFeedbackEmail;
@end