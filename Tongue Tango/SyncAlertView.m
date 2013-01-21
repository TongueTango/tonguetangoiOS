//
//  SyncAlertView.m
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "SyncAlertView.h"

@interface SyncAlertView ()

@end

@implementation SyncAlertView

@synthesize delegate=_delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(IBAction)allowPressed:(id)sender
{
    [self.view removeFromSuperview];
    if (self.delegate)
    {
        [self.delegate allow];
    }
}

-(IBAction)cancelPressed:(id)sender
{
    [self.view removeFromSuperview];
    if (self.delegate)
    {
        [self.delegate cancel];
    }
}

@end
