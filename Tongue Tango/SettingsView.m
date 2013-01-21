//
//  SettingsView.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "SettingsView.h"
#import "PickThemeView.h"
#import "PickMicrophoneView.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "AboutView.h"
@implementation SettingsView

@synthesize arrMics = _arrMics;
@synthesize arrTheme = _arrTheme;
@synthesize arrGeneral = _arrGeneral;
@synthesize arrCellData = _arrCellData;
@synthesize buttonFAQ = _buttonFAQ;
@synthesize buttonAbout = _buttonAbout;
@synthesize tableSettings = _tableSettings;

@synthesize pickThemeView;
@synthesize pickMicrophoneView;

// Constants
double const DEFAUL_RED_COLOUR = 0.745;
double const DEFAUL_GREEN_COLOUR = 0.058;
double const DEFAUL_BLUE_COLOUR = 0.050; 
int const TAG_CELL_MAIN_TITLE = 4000;
int const TAG_CELL_SWITCH = 4002;
int const TAG_VALUE_LABEL = 4001;

#define GENERAL_SECTION 0
#define THEMES_SECTION 1
#define MICS_SECTION 2

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Settings View."];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Set the backbround image for this view
    UIColor *colourBackground = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    _tableSettings.backgroundColor = colourBackground;
    _tableSettings.tableFooterView.backgroundColor = colourBackground;
    
    // Add the logo to the navigation bar
    self.title = NSLocalizedString(@"SETTINGS BTTN", nil);
}

- (void)viewDidUnload
{
    [self setTableSettings:nil];
    [self setPickThemeView:nil];
    [self setPickMicrophoneView:nil];
    [self setButtonFAQ:nil];
    [self setButtonAbout:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [Utils customizeNavigationBarTitle:self.navigationItem title:self.title];
    
    // Set the property that contains settings values
    
    NSString *review;
    NSString *speaker;
    if ([defaults boolForKey:@"ReviewRecording"]) {
        review = @"1";
    } else {
        review = @"0";
    }
    
    if ([defaults boolForKey:@"Speaker"]) {
        speaker = @"1";
    } else {
        speaker = @"0";
    }
    
    if ([defaults integerForKey:@"ThemeID"] == 0) {
        themeColor = [UIColor colorWithRed:DEFAUL_RED_COLOUR green:DEFAUL_GREEN_COLOUR blue:DEFAUL_BLUE_COLOUR alpha:1];
    } else {
        themeColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                     green:([defaults integerForKey:@"ThemeGreen"]/255.0) 
                                      blue:([defaults integerForKey:@"ThemeBlue"]/255.0) 
                                     alpha:1];
    }
    
    for(UITableViewCell *tableCell in [_tableSettings subviews]) {
        if([tableCell isKindOfClass:[UITableViewCell class]]) {
            UILabel *valueLabel = (UILabel *)[tableCell viewWithTag:TAG_VALUE_LABEL];
            
            valueLabel.textColor = themeColor;
        }
    }
    
    [_buttonFAQ setTitle:NSLocalizedString(@"FAQS" , nil) forState:UIControlStateNormal];
    [_buttonAbout setTitle:NSLocalizedString(@"ABOUT" , nil) forState:UIControlStateNormal];    

    
    self.arrGeneral = [NSArray arrayWithObjects:
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        NSLocalizedString(@"REVIEW AUDIO" , nil), @"title",
                        review, @"value",
                        nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:
                        NSLocalizedString(@"DEFAULT TO SPEAKER" , nil), @"title",
                        speaker, @"value",
                        nil],
                       nil];
    
    // Set the property that contains settings values
    self.arrTheme = [NSArray arrayWithObjects:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      NSLocalizedString(@"SKINS" , nil), @"title",
                      [defaults objectForKey:@"ThemeID"], @"value",
                      [defaults objectForKey:@"ThemeName"], @"value_text",
                      nil],
                     nil];
    
    // Set the property that contains settings values
    self.arrMics = [NSArray arrayWithObjects:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                     NSLocalizedString(@"MICROPHONES" , nil), @"title",
                     [defaults objectForKey:@"MicID"], @"value",
                     [defaults objectForKey:@"MicName"], @"value_text",
                     nil],
                    nil];
    
    // set the property that will be used to output the table
    //self.arrCellData = [NSMutableArray arrayWithObjects:_arrGeneral, _arrTheme, _arrMics, nil];
    self.arrCellData = [NSMutableArray arrayWithObjects:_arrGeneral, nil];
    
    [_tableSettings reloadData];
}

//Will be deleted ?
- (void)viewWillDisappear:(BOOL)animated
{
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_arrCellData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[_arrCellData objectAtIndex:section] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Settings";
    
    UILabel *mainLabel;
    UILabel *valueLabel;
    UISwitch *valueSwitch;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor whiteColor];
        
        // main label
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 230, 20)];
        mainLabel.font = [UIFont boldSystemFontOfSize:18];
        mainLabel.textColor = [UIColor blackColor];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = TAG_CELL_MAIN_TITLE;
        [cell.contentView addSubview:mainLabel];
        
        // value label
        valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 12, 160, 20)];
        valueLabel.font = [UIFont systemFontOfSize:16];
        valueLabel.textAlignment = UITextAlignmentRight;
        valueLabel.textColor = themeColor;
        valueLabel.backgroundColor = [UIColor clearColor];
        valueLabel.tag = TAG_VALUE_LABEL;
        [cell.contentView addSubview:valueLabel];
        
        // value switch
        valueSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        
        if (indexPath.section == 0) {
            
            if (indexPath.row == 0) {
                [valueSwitch addTarget:self action:@selector(reviewChanged:) forControlEvents:UIControlEventValueChanged];
            } 
            else {
                [valueSwitch addTarget:self action:@selector(speakerChanged:) forControlEvents:UIControlEventValueChanged];
            }
        }
        
        valueSwitch.tag = TAG_CELL_SWITCH;
        
    } else {
        mainLabel = (UILabel *)[cell viewWithTag:TAG_CELL_MAIN_TITLE];
        valueLabel = (UILabel *)[cell viewWithTag:TAG_VALUE_LABEL];
        valueSwitch = (UISwitch *)[cell viewWithTag:TAG_CELL_SWITCH];
    }
    
    // Get the data for this cell
    NSDictionary *dict = [[self.arrCellData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    mainLabel.text = [dict objectForKey:@"title"];
    
    if (indexPath.section == 0) {
        // value switch
        valueLabel.hidden = YES;
        valueSwitch.hidden = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = valueSwitch;
        
        if ([dict objectForKey:@"value"] == @"1") {
            [valueSwitch setOn:YES animated:NO];
        } else {
            [valueSwitch setOn:NO animated:NO];
        }
        
    } else {
        // value label
        valueLabel.hidden = NO;
        valueSwitch.hidden = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        valueLabel.text = [dict objectForKey:@"value_text"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (pickThemeView == nil) {
            pickThemeView = [[PickThemeView alloc] initWithNibName:@"PickThemeView" bundle:nil];
        }
        [self.navigationController pushViewController:pickThemeView animated:YES];
    } else if (indexPath.section == 2) {
        if (pickMicrophoneView == nil) {
            pickMicrophoneView = [[PickMicrophoneView alloc] initWithNibName:@"PickMicrophoneView" bundle:nil];
        }
        [self.navigationController pushViewController:pickMicrophoneView animated:YES];
    }
    
    [self.tableSettings deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)reviewChanged:(id)sender {
    UISwitch *thisSwitch = (UISwitch *)sender;
    [defaults setBool:thisSwitch.on forKey:@"ReviewRecording"];
    [defaults synchronize];
}

- (void)speakerChanged:(id)sender {
    UISwitch *thisSwitch = (UISwitch *)sender;
    [defaults setBool:thisSwitch.on forKey:@"Speaker"];
    [defaults synchronize];
}

#pragma mark - IBActions

- (IBAction)actionFAQ:(UIButton*)sender {
    NSURL *url = [[NSURL alloc] initWithString: @"http://www.tonguetango.com/faqs/"];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)setupBackButton {
    // change back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BACK", nil) 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:nil 
                                                                  action:nil]; 
    [[self navigationItem] setBackBarButtonItem:backButton]; 
}

- (IBAction)actionAbout:(UIButton*)sender {
    [self setupBackButton];
    AboutView *about = [[AboutView alloc] initWithNibName:@"AboutView" bundle:nil];
    [self.navigationController pushViewController:about animated:YES];
}

@end
