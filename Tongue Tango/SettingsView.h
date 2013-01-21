//
//  SettingsView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PickThemeView;
@class PickMicrophoneView;

@interface SettingsView : UIViewController {
    UIColor *themeColor;
    NSUserDefaults *defaults;
}

//constants
FOUNDATION_EXPORT double const DEFAUL_RED_COLOUR;
FOUNDATION_EXPORT double const DEFAUL_GREEN_COLOUR;
FOUNDATION_EXPORT double const DEFAUL_BLUE_COLOUR;
FOUNDATION_EXPORT int const TAG_CELL_MAIN_TITLE;
FOUNDATION_EXPORT int const TAG_CELL_SWITCH;

@property (strong, nonatomic) PickThemeView *pickThemeView;
@property (strong, nonatomic) PickMicrophoneView *pickMicrophoneView;
@property (strong, nonatomic) IBOutlet UITableView *tableSettings;
@property (strong, nonatomic) NSArray *arrGeneral;
@property (strong, nonatomic) NSArray *arrTheme;
@property (strong, nonatomic) NSArray *arrMics;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) IBOutlet UIButton *buttonFAQ;
@property (strong, nonatomic) IBOutlet UIButton *buttonAbout;


- (IBAction)actionFAQ:(UIButton*)sender;
- (IBAction)actionAbout:(UIButton*)sender;

- (void)reviewChanged:(id)sender;
- (void)speakerChanged:(id)sender;

@end
