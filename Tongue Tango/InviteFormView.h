//
//  InviteFormView.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InviteView;

@interface InviteFormView : UIViewController <UITextFieldDelegate>
{
    UINavigationController *controller;
}

@property (strong, nonatomic) InviteView *inviteView;

@property (strong, nonatomic) IBOutlet UIToolbar *toolBar;
@property (strong, nonatomic) IBOutlet UITextField *fieldFirst;
@property (strong, nonatomic) IBOutlet UITextField *fieldLast;
@property (strong, nonatomic) IBOutlet UITextField *fieldEmail;
@property (strong, nonatomic) IBOutlet UITextField *fieldPhone;
@property (strong, nonatomic) IBOutlet UILabel *labelInstructions;
@property (strong, nonatomic) IBOutlet UILabel *labelOr;

-(BOOL)textFieldShouldReturn:(UITextField*)textField;

@end