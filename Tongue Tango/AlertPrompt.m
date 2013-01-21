//
//  AlertPrompt.m
//  Tongue Tango
//
//  Created by Chris Serra on 3/13/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "AlertPrompt.h"

@implementation AlertPrompt

@synthesize textField;
@synthesize enteredText;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okayButtonTitle preFilledWith:(NSString *)preFilledText
{
    
    if (self = [super initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:okayButtonTitle, nil])
    {
        UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)]; 
        [theTextField setBackgroundColor:[UIColor whiteColor]]; 
        [self addSubview:theTextField];
        self.textField = theTextField;
        self.textField.placeholder = message;
        self.textField.text = preFilledText;
        if ([message isEqualToString:@"Phone Number"]) {
            self.textField.keyboardType = UIKeyboardTypePhonePad;
        }
        CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 0.0); 
        [self setTransform:translate];
    }
    return self;
}
- (void)show
{
    [textField becomeFirstResponder];
    [super show];
}
- (NSString *)enteredText
{
    return textField.text;
}
@end