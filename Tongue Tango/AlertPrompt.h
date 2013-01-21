//
//  AlertPrompt.h
//  Tongue Tango
//
//  Created by Chris Serra on 3/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlertPrompt : UIAlertView 
{
    UITextField *textField;
}

@property (nonatomic, strong) UITextField *textField;
@property (readonly, strong) NSString *enteredText;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle preFilledWith:(NSString *)preFilledText;

@end