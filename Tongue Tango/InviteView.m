//
//  InviteView.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 2/7/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "InviteView.h"
#import "AlertPrompt.h"
#import "Constants.h"
#import "HomeView.h"

@implementation InviteView

@synthesize delegate;
@synthesize dictPerson;
@synthesize sentIndexPath;
@synthesize responseData;
@synthesize arrCellData;
@synthesize tableInvites;
@synthesize labelSubtitle;
@synthesize fbHelper;
@synthesize bttnClose;
@synthesize bttnTapAway;
@synthesize audioURL;

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
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FlurryAnalytics logEvent:@"Visited Invite View."];
    
    defaults = [NSUserDefaults standardUserDefaults];
    fbHelper = [FacebookHelper sharedInstance];
    
    // Set the backbround image for this view
    self.tableInvites.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    // Add the logo to the navigation bar
    [Utils customizeNavigationBarTitle:self.navigationItem title:NSLocalizedString(@"Tongue tango", nil)];
    
    // Disable the selection of rows
    self.tableInvites.allowsSelection = NO;
    
    // Set the audio player
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    audioIsPlaying = NO;
}

- (void)viewDidUnload
{
    [self setTableInvites:nil];
    [self setLabelSubtitle:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([self.dictPerson objectForKey:@"facebook_id"]) {
        // set the property that will be used to output the table
        self.arrCellData = [NSArray arrayWithObjects:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"RECORD VOICE", nil), @"title",
                             NSLocalizedString(@"RECORD SUBTITLE", nil), @"description",
                             @"icon_type_record.png", @"image", nil],
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"TEXT", nil), @"title",
                             NSLocalizedString(@"TEXT SUBTITLE", nil), @"description",
                             @"icon_type_text.png", @"image", nil],
                            nil];
        strFullName = [NSString stringWithFormat:@"%@ %@", [self.dictPerson objectForKey:@"first_name"], [self.dictPerson objectForKey:@"last_name"]];
        strPhone = @"";
        strEmail = @"";
    } else {
        // set the property that will be used to output the table
        self.arrCellData = [NSArray arrayWithObjects:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"VIDEO DEMO", nil), @"title",
                             NSLocalizedString(@"VIDEO SUBTITLE", nil), @"description",
                             @"icon_type_video.png", @"image", nil],
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"VOICE NOTE", nil), @"title",
                             NSLocalizedString(@"VOICE SUBTITLE", nil), @"description",
                             @"icon_type_audio.png", @"image", nil],
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"RECORD VOICE", nil), @"title",
                             NSLocalizedString(@"RECORD SUBTITLE", nil), @"description",
                             @"icon_type_record.png", @"image", nil],
                            [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"TEXT", nil), @"title",
                             NSLocalizedString(@"TEXT SUBTITLE", nil), @"description",
                             @"icon_type_text.png", @"image", nil],
                            nil];
        strFullName = [NSString stringWithFormat:@"%@ %@", [self.dictPerson objectForKey:@"first_name"], [self.dictPerson objectForKey:@"last_name"]];
        
        if (!strEmail) {
            NSArray *emails = [self.dictPerson objectForKey:@"email"];
            if (emails) {
                if ([emails count] > 0) {
                    strEmail = [emails objectAtIndex:0];
                } else {
                    strEmail = @"";
                }
            } else {
                strEmail = @"";
            }
        }
        
        NSArray *phones = [self.dictPerson objectForKey:@"phone"];
        if (phones) {
            if ([phones count] > 0) {
                strPhone = [phones objectAtIndex:0];
            } else {
                strPhone = @"";
            }
        } else {
            strPhone = @"";
        }
    }
    
    self.labelSubtitle.text = [NSString stringWithFormat:NSLocalizedString(@"INVITE TITLE", nil), strFullName];
    
    if (!avPlayer) {
        self.responseData = [NSMutableData data];
        NSString *strURL = kInviteAudio;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strURL]];
        (void)[[NSURLConnection alloc]initWithRequest:request delegate:self];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (audioURL) {
        rowNumber = 2;
        [self sendEmail];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [avPlayer stop];
    NSDictionary *animate = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideNotification" object:nil userInfo:animate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)sendEmailWithURL:(NSString *)_audioURL
{
    audioURL = _audioURL;
}

- (BOOL)checkForPhone
{
    if ([strPhone isEqualToString:@""]) {
        AlertPrompt *prompt = [[AlertPrompt alloc] initWithTitle:@"Phone Number Required" message:@"Phone Number" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" preFilledWith:@""];
        prompt.tag = 20;
        
        [prompt show];
        return NO;
    }
    return YES;
}

- (BOOL)checkForEmail
{
    if ([strEmail isEqualToString:@""]) {
        AlertPrompt *prompt = [[AlertPrompt alloc] initWithTitle:@"Email Required" message:@"Email" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" preFilledWith:@""];
        prompt.tag = 10;
        
        [prompt show];
        return NO;
    }
    return YES;
}

- (void)openHomeForInviteType:(NSInteger)sendTo
{
    // Open the Home view
    HomeView *homeView = [[HomeView alloc] initWithNibName:@"HomeView" bundle:nil];
    
    [homeView setSendTo:sendTo];
    [homeView setSendType:@"AudioInvite"];
    [homeView setSendPerson:dictPerson];
    [homeView setInviteView:self];
    [homeView setDisableMenu:YES];
    [self.navigationController pushViewController:homeView animated:YES];
}

- (IBAction)buttonTapped:(id)sender
{
    // drill down to find the buttons parent view
    UIButton *button = (UIButton *)sender;
    UIView *parentView = (UIView *)button.superview;
    
    // find the table cell view to get the users information
    UITableViewCell *tableCell = (UITableViewCell *)parentView.superview;
    NSIndexPath *indexPath = [self.tableInvites indexPathForCell:tableCell];
    rowNumber = indexPath.row;
    
    if (button.tag == 4003) {
        if (rowNumber == 3 || ([self.dictPerson objectForKey:@"facebook_id"] && rowNumber == 1)) {
            // Check if this device can send an SMS
            if ([MFMessageComposeViewController canSendText]) {
                if ([self checkForPhone]) {
                    [self sendSMS];
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"OPTION UNAVAILABLE" , nil)
                                                                message:NSLocalizedString(@"SMS NOT AVAILABLE" , nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                                      otherButtonTitles:nil];
                [alert show];
            }
        } else if (![self.dictPerson objectForKey:@"facebook_id"]) {
            // Check if this device can send an email
            if ([MFMailComposeViewController canSendMail]) {
                if (rowNumber < 3 && [self checkForEmail]) {
                    if (rowNumber == 2) {
                        [self openHomeForInviteType:0];
                    } else {
                        [self sendEmail];
                    }
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"OPTION UNAVAILABLE" , nil)
                                                                message:NSLocalizedString(@"EMAIL NOT AVAILABLE" , nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
            [self openHomeForInviteType:0];
        }
    } else {
        if (rowNumber == 0) {
            [self playVideo];
        } else {
            if (audioIsPlaying) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
                [avPlayer stop];
                audioIsPlaying = NO;
            } else {
                // Proximity Sensor
                UIDevice *device = [UIDevice currentDevice];
                device.proximityMonitoringEnabled = YES;
                if (device.proximityMonitoringEnabled == YES)
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityChanged:) name:@"UIDeviceProximityStateDidChangeNotification" object:device];
                
                [avPlayer setDelegate:self];
                [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
                
                if ([defaults boolForKey:@"Speaker"]) {
                    UInt32 doChangeDefaultRoute = 1;
                    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
                }
                
                UInt32 allowBluetoothInput = 1;
                AudioSessionSetProperty(
                                        kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                        sizeof (allowBluetoothInput),
                                        &allowBluetoothInput);
                
                [avPlayer prepareToPlay];
                
                [avPlayer play];
                audioIsPlaying = YES;
            }
        }
    }
}

- (void)proximityChanged:(NSNotification *)notification {
	UIDevice *device = [notification object];
    if (device.proximityState == 1) {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        if ([defaults boolForKey:@"Speaker"]) {
            [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        } else {
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        }
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
}

#pragma mark - Validate Forms

- (void)resetEmail {
    strEmail = nil;
}

- (BOOL)isValidEmail:(NSString *)checkString
{
    NSString *emailRegex = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (BOOL)isValidPhone:(NSString *)checkString
{
    if ([checkString intValue] > 1000000) {
        return true;
    }
    return false;
//    NSString *phoneRegex = @"[235689][0-9]{6}([0-9]{3})?";
//    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
//    return [phoneTest evaluateWithObject:checkString];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1000) {
        [self closeView];
        return;
    }
    if (buttonIndex == 1) {
        NSString *entered = [(AlertPrompt *)alertView enteredText];
        
        if (alertView.tag == 10) {
            if (![self isValidEmail:entered]) {
                AlertPrompt *prompt = [[AlertPrompt alloc] initWithTitle:@"Invalid Email" message:@"Email" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" preFilledWith:entered];
                prompt.tag = 10;
                [prompt show];
            } else {
                strEmail = entered;
                if (rowNumber == 2) {
                    [self openHomeForInviteType:0];
                } else {
                    [self sendEmail];
                }
            }
        }
        if (alertView.tag == 20) {
            if (![self isValidPhone:entered]) {
                AlertPrompt *prompt = [[AlertPrompt alloc] initWithTitle:@"Invalid Phone Number" message:@"Phone Number" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" preFilledWith:entered];
                prompt.tag = 20;
                [prompt show];
            } else {
                strPhone = entered;
                [self sendSMS];
            }
        }
    }
}

#pragma mark - Play Video

- (IBAction)playVideo
{
	[self performSelector:@selector(buttonPressed) withObject:nil afterDelay:2];
}

- (void)buttonPressed
{
    [self embedYouTube:kInviteVideoPreview frame:CGRectMake(6, 60, 307, 220)];
}

- (void)embedYouTube:(NSString *)urlString frame:(CGRect)frame
{
    bttnTapAway = [UIButton buttonWithType:UIButtonTypeCustom];
    bttnTapAway.frame = CGRectMake(0, 0, 320, 480);
    bttnTapAway.backgroundColor = [UIColor clearColor];
    [bttnTapAway addTarget:self action:@selector(removeVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bttnTapAway];
    
    loadedWeb = YES;
    NSString *embedHTML = @"\
    <html><head>\
    <style type=\"text/css\">\
    body {\
    background-color: transparent;\
    color: white;\
    }\
    </style>\
    </head><body style=\"margin:0\">\
    <embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
    width=\"%0.0f\" height=\"%0.0f\"></embed>\
    </body></html>";
    NSString *html = [NSString stringWithFormat:embedHTML, urlString, frame.size.width, frame.size.height];
    videoView = [[UIWebView alloc] initWithFrame:frame];
    [videoView loadHTMLString:html baseURL:[NSURL URLWithString:nil]];
    videoView.delegate = self;
    [self.view addSubview:videoView];
    
    bttnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    bttnClose.frame = CGRectMake(284, 40, 40, 40);
    bttnClose.backgroundColor = [UIColor clearColor];
    [bttnClose setBackgroundImage:[UIImage imageNamed:@"bttn_close_preview"] forState:UIControlStateNormal];
    [bttnClose addTarget:self action:@selector(removeVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bttnClose];
}

- (void)removeVideo:(id)sender
{
    [videoView removeFromSuperview];
    [bttnClose removeFromSuperview];
    [bttnTapAway removeFromSuperview];
}

- (BOOL)webView:(UIWebView*)aWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    if (!loadedWeb) {
        [videoView removeFromSuperview];
    }
    loadedWeb = NO;
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
    DLog(@"didReceiveData");
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    DLog(@"Succeeded! Received %d bytes of data",[responseData length]);
    if (connection) {
        avPlayer = [[AVAudioPlayer alloc] initWithData:responseData error:NULL];
    }
}

#pragma mark - Send Invites

- (void)sendEmail {
    [self openEmailComposer];
}

- (void)sendSMS {
    [self openSMSComposer];
}

- (void)openEmailComposer
{
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    
    if ([MFMailComposeViewController canSendMail]) {
        mailViewController.mailComposeDelegate = self;
        
        // Change the color of the mailViewController navigation bar.
        UINavigationBar *navigationBar = mailViewController.navigationBar;
        if ([defaults integerForKey:@"ThemeID"] == 0) {
            navigationBar.tintColor = DEFAULT_THEME_COLOR;
        } else {
            navigationBar.tintColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) green:([defaults integerForKey:@"ThemeGreen"]/255.0) blue:([defaults integerForKey:@"ThemeBlue"]/255.0) alpha:1];
        }
        
        NSString *theMessage;
        if (rowNumber == 0) {
            theMessage = [NSString stringWithFormat:@"%@\n\n%@",[NSString stringWithFormat:NSLocalizedString(@"INVITE TEXT MESSAGE", nil),[[NSUserDefaults standardUserDefaults] objectForKey:@"UserFirstName"] ,[[NSUserDefaults standardUserDefaults] objectForKey:@"UserLastName"],kTTDownload],kInviteVideo];
        } else if (rowNumber == 1 || rowNumber == 2) {
            if (!audioURL) {
                audioURL = kInviteAudio;
            }
            theMessage = [NSString stringWithFormat:@"%@\n\n%@",[NSString stringWithFormat:NSLocalizedString(@"INVITE TEXT MESSAGE", nil),[[NSUserDefaults standardUserDefaults] objectForKey:@"UserFirstName"] ,[[NSUserDefaults standardUserDefaults] objectForKey:@"UserLastName"],kTTDownload],audioURL];
        } else {
            theMessage = [NSString stringWithFormat:@"%@\n\n%@",[NSString stringWithFormat:NSLocalizedString(@"INVITE TEXT MESSAGE", nil),[[NSUserDefaults standardUserDefaults] objectForKey:@"UserFirstName"] ,[[NSUserDefaults standardUserDefaults] objectForKey:@"UserLastName"],kTTDownload],kInviteAudio];
        }
        
        // Set the email subject and recipient.
        [mailViewController setSubject:@"You've been invited to Tongue Tango!"];
        [mailViewController setToRecipients:[NSArray arrayWithObjects:strEmail, nil]];
        [mailViewController setMessageBody:theMessage isHTML:NO];
        
        // Open the Mail app
        [self presentModalViewController:mailViewController animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL UNAVAILABLE", nil)
                                                        message:NSLocalizedString(@"EMAIL NOT SETUP", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)openSMSComposer
{
    MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
    
    if ([MFMailComposeViewController canSendMail]) {
        messageViewController.messageComposeDelegate = self;
        
        // Change the color of the mailViewController navigation bar.
        UINavigationBar *navigationBar = messageViewController.navigationBar;
        if ([defaults integerForKey:@"ThemeID"] == 0) {
            navigationBar.tintColor = DEFAULT_THEME_COLOR;
        } else {
            navigationBar.tintColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) green:([defaults integerForKey:@"ThemeGreen"]/255.0) blue:([defaults integerForKey:@"ThemeBlue"]/255.0) alpha:1];
        }
        
        NSString *theMessage = [NSString stringWithFormat:NSLocalizedString(@"INVITE SMS MESSAGE", nil),[[NSUserDefaults standardUserDefaults] objectForKey:@"UserFirstName"],kTTDownload];
        NSArray *recipients = [NSArray arrayWithObject:strPhone];
        
        // Set the SMS body and recipient.
        [messageViewController setBody:theMessage];
        [messageViewController setRecipients:recipients];
        [self presentModalViewController:messageViewController animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL UNAVAILABLE", nil)
                                                        message:NSLocalizedString(@"EMAIL NOT SETUP", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

	
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {    
    [self dismissModalViewControllerAnimated:YES];
    if (result == MessageComposeResultSent) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INVITE SENT" , nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil, nil];
        alert.tag = 1000;
        [alert show];
    }
}

// Bug US17
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
    // Reset email
    [self resetEmail];    
    // This prevents the MailCompose Viewer to show again after pressing Cancel or Send
    audioURL = nil;
    
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //NSLog(@"Result: canceled");
            break;
        case MFMailComposeResultSaved:
            //NSLog(@"Result: saved");
            break;
        case MFMailComposeResultSent:
            //NSLog(@"Result: sent");
            break;
        case MFMailComposeResultFailed: {
            //NSLog(@"Result: failed");
            break;
        }
        default:
            //NSLog(@"Result: not sent");
            break;
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)fbDidReturnRequest:(BOOL)success:(NSMutableArray *)result
{
    if (success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INVITE SENT" , nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil, nil];
        alert.tag = 1000;
        [alert show];
    }
}

- (void)didSendAudioToFacebook
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INVITE SENT" , nil)
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil, nil];
    alert.tag = 1000;
    [alert show];
}

- (void)closeView {
    if (delegate) {
        [delegate makeFriend:self.dictPerson indexPath:self.sentIndexPath];
        // AddFromContactsView isn't part anymore of the navigation controller' view controllers
        //[self.navigationController popToViewController:delegate animated:YES];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        int count = [self.navigationController.viewControllers count];
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:count-3] animated:YES];
    }
}

#pragma mark - Table View Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.arrCellData count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 67;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UIImageView *rowIcon;
    UILabel *mainLabel, *subLabel;
    UIButton *actionButton, *sendButton;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_separators"]];
        
        // row icon
        rowIcon = [[UIImageView alloc] initWithFrame:CGRectMake(10, 9, 49, 49)];
        rowIcon.contentMode = UIViewContentModeCenter;
        rowIcon.tag = 4000;
        [cell.contentView addSubview:rowIcon];
        
        // main label
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 16, 195, 20)];
        mainLabel.font = [UIFont boldSystemFontOfSize:19];
        mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.tag = 4001;
        [cell.contentView addSubview:mainLabel];
        
        // detail label
        subLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 35, 250, 19)];
        subLabel.font = [UIFont systemFontOfSize:14];
        subLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        subLabel.backgroundColor = [UIColor clearColor];
        subLabel.tag = 4002;
        [cell.contentView addSubview:subLabel];
        
        // send button
        sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sendButton.frame = CGRectMake(249, 17, 65, 33);
        sendButton.tag = 4003;
        sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [sendButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [sendButton setTitle:NSLocalizedString(@"SEND", nil) forState:UIControlStateNormal];
        [sendButton setTitleShadowColor:[UIColor colorWithWhite:0.87 alpha:1] forState:UIControlStateNormal];
        [sendButton setTitleColor:[UIColor colorWithWhite:0.51 alpha:1] forState:UIControlStateNormal];
        [sendButton setBackgroundImage:[UIImage imageNamed:@"bttn_add"] forState:UIControlStateNormal];
		[sendButton setBackgroundColor:[UIColor clearColor]];
        [sendButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:sendButton];

        // action button
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        actionButton.frame = CGRectMake(208, 17, 39, 33);
        actionButton.tag = 4004;
        [actionButton setBackgroundImage:[UIImage imageNamed:@"bttn_preview"] forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
        
    } else {
        rowIcon = (UIImageView *)[cell viewWithTag:4000];
        mainLabel = (UILabel *)[cell viewWithTag:4001];
        subLabel = (UILabel *)[cell viewWithTag:4002];
        sendButton = (UIButton *)[cell viewWithTag:4003];
        actionButton = (UIButton *)[cell viewWithTag:4004];
    }

    // Get the data for this cell
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];

    // set the row icon
    rowIcon = (UIImageView *)[cell viewWithTag:4000];
    rowIcon.image = [UIImage imageNamed:[dict objectForKey:@"image"]];
    
    // set the main label
    mainLabel = (UILabel *)[cell viewWithTag:4001];
    mainLabel.text = [dict objectForKey:@"title"];
    
    // set the sub label
    subLabel = (UILabel *)[cell viewWithTag:4002];
    subLabel.text = [dict objectForKey:@"description"];
    
    if (indexPath.row < 2 && ![self.dictPerson objectForKey:@"facebook_id"]) {
        actionButton.hidden = NO;
    } else {
        actionButton.hidden = YES;
    }
    
    return cell;
}

@end
