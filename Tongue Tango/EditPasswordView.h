//
//  EditPasswordView.h
//  Tongue Tango
//
//  Created by Johana Moccetti on 7/27/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditPasswordView : UIViewController <UITextFieldDelegate, UIAlertViewDelegate> {
    
    NSUserDefaults *defaults;
    UIColor *themeColor;
    
    UITextField *activeField;
    UITextField *newPasswordField;
    UITextField *confirmPasswordField;
}


@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) IBOutlet UITableView *tableProfile;

@end
