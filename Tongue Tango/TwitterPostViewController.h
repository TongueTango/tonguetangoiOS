//
//  TwitterPostViewController.h
//  Tongue Tango
//
//  Created by Gap User on 7/31/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterHelper.h"

@interface TwitterPostViewController : UIViewController<UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *labelCount;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) NSString *link;

@property (strong, nonatomic) TwitterHelper *twHelper;

@end
