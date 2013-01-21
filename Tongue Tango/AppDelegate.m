//
//  AppDelegate.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 1/19/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "AppDelegate.h"
#import "CoreDataClass.h"
#import "FacebookHelper.h"
#import "UAirship.h"
#import "FlurryAnalytics.h"
#import "Constants.h"
#import "SquareAndMask.h"
#import "UAPush.h"
#import "HomeView.h"
#import "ProfileView.h"
#import "WelcomeLandingView.h"
#import "NotificationsView.h"
#import "MessageThreadDetailView.h"
#import "Appirater.h"
#import "FacebookHelper.h"
#import "Utils.h"
#import "FriendsListView.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize homeViewController;
@synthesize coreDataClass;
@synthesize pendingGroups;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DLog(@"");
    inAppHelper = [[InAppRageIAPHelper alloc] init];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:inAppHelper];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    
    pendingGroups = [[NSMutableArray alloc] init];
    [defaults setBool:NO forKey:@"DisplayedError"];
    [defaults setInteger:0 forKey:@"ErrorCount"];
	
	// Register for notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound |
                                                                           UIRemoteNotificationTypeAlert)];
	
	// Init Airship launch options
	NSMutableDictionary *takeOffOptions = [[NSMutableDictionary alloc] init];
	[takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
	
    NSMutableDictionary *takeOffFromClosed = [[NSMutableDictionary alloc] init];
	[takeOffFromClosed setValue:launchOptions forKey:UIApplicationLaunchOptionsURLKey];
	
	// Create Airship singleton that's used to talk to Urban Airship servers.
	// Please populate AirshipConfig.plist with your info from http://go.urbanairship.com
	[UAirship takeOff:takeOffOptions];
    
	// Flurry Analytics Setup
	[FlurryAnalytics startSession:@"M44HHC4KIP9J5IA7UGKU"];
	
    // Team Token
#if TARGET_IPHONE_SIMULATOR
    // Do nothing
#else
    [TestFlight takeOff:@"a5565e75e7c067e96450ea62de6a9c3f_MTI4MTI0MjAxMi0wOS0wMyAxNzoyNzoyOS41NDAxMDc"];
#endif
    
    NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"plist"];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    
    [defaults registerDefaults:appDefaults];
    
    if (![defaults objectForKey:@"ThemeID"]) {
        [defaults setInteger:0 forKey:@"ThemeID"];
        [defaults setObject:@"Default" forKey:@"ThemeName"];
    }
    
    if (![defaults objectForKey:@"MicID"]) {
        [defaults setInteger:0 forKey:@"MicID"];
        [defaults setObject:@"Default" forKey:@"MicName"];
    }
    
    [[UAPush shared] enableAutobadge:YES];
    
    coreDataClass = [CoreDataClass sharedInstance];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    
    [defaults setInteger:0 forKey:@"PushedGroup"];
    [defaults setInteger:0 forKey:@"PushedUser"];
        
    HomeView *home = [[HomeView alloc] initWithNibName:@"HomeView" bundle:nil];
    self.homeViewController = home;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:home];
    
    UINavigationBar *navigationBar = nav.navigationBar;
    if ([defaults integerForKey:@"ThemeID"] == 0)
    {
        navigationBar.tintColor = DEFAULT_THEME_COLOR;
    } 
    else
    {
        navigationBar.tintColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) 
                                                  green:([defaults integerForKey:@"ThemeGreen"]/255.0)
                                                   blue:([defaults integerForKey:@"ThemeBlue"]/255.0) 
                                                  alpha:1];
    }
    
    self.window.rootViewController = nav;
                                
    [self.window makeKeyAndVisible];
    
    if (takeOffFromClosed)
    {
        if ([takeOffFromClosed objectForKey:@"UIApplicationLaunchOptionsURLKey"])
        {
            if ([[takeOffFromClosed objectForKey:@"UIApplicationLaunchOptionsURLKey"] objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"])
            {
                NSDictionary *dict = [[takeOffFromClosed objectForKey:@"UIApplicationLaunchOptionsURLKey"] objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
                
                if ([defaults objectForKey:@"UserToken"])
                {
                    [self processExternalPushNotification:dict];;
                }
            }

        }
    }
    
    // Path for our sound:
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty (kAudioSessionProperty_AudioCategory,
                             sizeof (sessionCategory),
                             &sessionCategory);
    
    CFURLRef soundFileURLRef = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("sound"), CFSTR("caf"), NULL);
    AudioServicesCreateSystemSoundID(soundFileURLRef, &pushSound);
    CFRelease(soundFileURLRef);
    
    [[UAPush shared] resetBadge];
    
    isAlerted = NO;
    
    //Rating
    [Appirater appLaunched:YES];
    
    //Fire event that will check count and display rating screen
    [Appirater userDidSignificantEvent:YES];
    
    
    //Create Directory if not exist
    
    [Utils createImagesAndAudioDirectory];
    
    return YES;
}

- (void)processExternalPushNotification:(NSDictionary *)pushDictionary {
    NSDictionary *extras = [pushDictionary objectForKey:@"extra"];
    
    NSString *action = [extras objectForKey:@"action"];
    
    // if a new message (from person or group) was received
    if ([action isEqualToString:NEW_MESSAGE_NOTIFICATION])
    {
        [defaults setInteger:[[extras objectForKey:@"user_id"] intValue] forKey:@"PushedUser"];
        [defaults setInteger:[[extras objectForKey:@"group_id"] intValue] forKey:@"PushedGroup"];
        [defaults synchronize];
        
        [homeViewController openMessageThreadDetail];
    }
    else
        if ([action isEqualToString:ADDED_TO_GROUP_NOTIFICATION])
        {
            // user added to group
            //>---------------------------------------------------------------------------------------------------
            //>     First you need to check if Group screen is not already opened. Don't push another one
            //>     if current screen is Group screen.
            //>---------------------------------------------------------------------------------------------------
            NSArray *arrVC      = [homeViewController.navigationController viewControllers];
            if (![[arrVC objectAtIndex:0] isKindOfClass:[FriendsListView class]])
            {
                [homeViewController openGroups];
            }
        }
        else
            if ([action isEqualToString:FRIEND_REQUEST_NOTIFICATION])
            {
                //>---------------------------------------------------------------------------------------------------
                //>     First you need to check if Notification screen is not already opened. Don't push another one
                //>     if current screen is Notification screen.
                //>---------------------------------------------------------------------------------------------------
                NSArray *arrVC      = [homeViewController.navigationController viewControllers];
                if (![[arrVC objectAtIndex:0] isKindOfClass:[NotificationsView class]])
                {
                    [homeViewController openPendingFriends];
                }
            }
            else
            {
                // if someone accepted you, nothing to do yet
            }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    DLog(@"");
    
    // add validation to process login with FB
    UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
    
    BOOL processLogin = NO;
    
    if (([nav.topViewController isKindOfClass:[ProfileView class]]))
    {
        // TODO if is in profile view and no previous FB login
        
        FacebookHelper *fbHelper = [FacebookHelper sharedInstance];
        
        if ([fbHelper isLoggedIn]) {
         
            DLog(@"already logged in FB")
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FACEBOOK ALREADY LOGGED IN ERROR" , nil)  
                                                                message:NSLocalizedString(@"FACEBOOK ALREADY LOGGED IN ERROR MESSAGE", nil) 
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)  
                                                      otherButtonTitles:nil];
            [alertView show];
            processLogin = YES;
        }
        else {
            processLogin = YES;
        }
        
    }
    else if ([nav.topViewController isKindOfClass:[HomeView class]]) {
        
        if (nav.topViewController.modalViewController) {
            UINavigationController *modalNavCont = (UINavigationController *)nav.topViewController.modalViewController;
            
            if ([modalNavCont.topViewController isKindOfClass:[WelcomeLandingView class]]) {
                processLogin = YES;
            }
        }
        else {
            if (![[FacebookHelper sharedInstance] isLoggedIn]) {
                processLogin = YES;     
            }
        }
    }
    else if ([nav.topViewController isKindOfClass:[FirstSyncView class]] ||
             [nav.topViewController isKindOfClass:[SyncFriendsView class]])
    {
        processLogin = YES;
    }
    
    BOOL result = NO;
    if (processLogin) {
        result = [[[FacebookHelper sharedInstance] facebook] handleOpenURL:url];
    }         
    
    return result;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //[[UAPush shared] resetBadge];
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //[[UAPush shared] resetBadge];//zero badge
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //[[UAPush shared] resetBadge];//zero badge
    if ([defaults objectForKey:@"UserToken"])
    {
        NSLog(@"token::::::%@",[defaults objectForKey:@"UserToken"]);
        [self.homeViewController getUnreadCount];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
	[UAirship land];
}

/**
 * Fetch and Format Device Token and Register Important Information to Remote Server
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
#if !TARGET_IPHONE_SIMULATOR
    // Updates the device token and registers the token with UA
    [[UAirship shared] registerDeviceToken:deviceToken];
    
    NSString *devTok;
    if ([deviceToken description] == nil) {
        devTok = @"";
    } else {
        devTok = [deviceToken description];
    }
    
    DLog("%@", devTok);
    
	NSString *devToken = [[[devTok
                               stringByReplacingOccurrencesOfString:@"<"withString:@""]
                              stringByReplacingOccurrencesOfString:@">" withString:@""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    DLog(@"DEVICE TOKEN: %@",devToken);
    [defaults setObject:devToken forKey:@"DeviceToken"];

#endif	
}

- (UIViewController *)getViewOfClass:(Class)class navigationController:(UINavigationController *)navController {
    if ([navController.viewControllers count] > 1) {
        for (UIViewController *view in navController.viewControllers) {
            if ([view isKindOfClass:class]) {
                return view;
            }
        }
    }
    return nil;
}

- (void)processNotificationWhenAppIsRunning:(NSDictionary *)userInfo playSound:(BOOL)play {
    DLog(@"%@", userInfo);
    if ([defaults objectForKey:@"UserToken"]) {
        
        if (play) {
           
          
            AudioServicesPlaySystemSound(pushSound);
        }
        
        UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
        NSDictionary *extras = [userInfo objectForKey:@"extra"];
        NSString *action = [extras objectForKey:@"action"];
        
        // if a new message (from person or group) was received
        if ([action isEqualToString:NEW_MESSAGE_NOTIFICATION]) {
            
            // update the unread count
            
            if(isExternalPush )
            {
                isExternalPush = NO;
                DLog(@"Found External push and go to message detail view")
               
                [self.homeViewController pushNotificationReceivedExternal:userInfo];
            }
            else{
                [self.homeViewController pushNotificationReceived:userInfo];
            }
            
            if ([nav.topViewController isKindOfClass:[NotificationsView class]]) {
                NotificationsView *currentView = (NotificationsView *)nav.topViewController;
                [currentView pushNotificationReceived:userInfo];
            }
            else {
                
                MessageThreadDetailView *messageView = nil;
                
                if ([nav.topViewController isKindOfClass:[MessageThreadDetailView class]]) {
                    messageView = (MessageThreadDetailView *)nav.topViewController;
                }
                else {
                    messageView = (MessageThreadDetailView *)[self getViewOfClass:[MessageThreadDetailView class] navigationController:nav];
                }
                
                if (messageView) {
                    [messageView pushNotificationReceived:userInfo];
                }
            }
            
        }
        else if ([action isEqualToString:ADDED_TO_GROUP_NOTIFICATION])
        {
            // update list of friends/groups
           // [self.homeViewController pushNotificationReceived:userInfo];
            if(isExternalPush )
            {
                isExternalPush = NO;
                DLog(@"Found External push and go to message detail view ADDED_TO_GROUP_NOTIFICATION")
                
                [self.homeViewController pushNotificationReceivedExternal:userInfo];
            }
            else{
                [self.homeViewController pushNotificationReceived:userInfo];
            }


        }
        else if ([action isEqualToString:FRIEND_REQUEST_NOTIFICATION])
        {
            // to update the unread count
            [self.homeViewController pushNotificationReceived:userInfo];
            
            if ([nav.topViewController isKindOfClass:[NotificationsView class]])
            {
                NotificationsView *currentView = (NotificationsView *)nav.topViewController;
                [currentView pushNotificationReceived:userInfo];
            }
        }
        else  if ([action isEqualToString:FRIEND_REQUEST_ACCEPTED_NOTIFICATION])
        {
            // update list of friends/groups
            [self.homeViewController pushNotificationReceived:userInfo];
        }
        else if ([action isEqualToString:FRIEND_ADDED])
        {
            if(isExternalPush )
            {
                isExternalPush = NO;
                DLog(@"Found External push and go to message detail view FRIEND_ADDED")
                
                [self.homeViewController pushNotificationReceivedExternal:userInfo];
            }
            else{
                [self.homeViewController pushNotificationReceived:userInfo];
            }

        }
    }
    else
    {
        // if no logged in and notification arrives, nothing to do
        return;
    }
    
}

- (void)processNotificationWhenAppIsNotActive {

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    DLog(@"Notificatoin by Server : %@", [userInfo description]);
    // zero badge
    //[[UAPush shared] resetBadge];
    
    if (application.applicationState == UIApplicationStateActive) {
        DLog(@"application is active");
        [self processNotificationWhenAppIsRunning:userInfo playSound:YES];
    }
    else
    {
        DLog(@"application NOT active");
        isExternalPush = YES;
        [self processNotificationWhenAppIsRunning:userInfo playSound:YES];
    }
    
   // [self.homeViewController pushNotificationReceived:userInfo];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    TFLog(@"Application did receive memory warning.");
}

- (void)resetUserDefaults {
    [defaults setBool:YES forKey:@"ReviewRecording"];
    [defaults setBool:YES forKey:@"Speaker"];
    [defaults setObject:nil forKey:@"FBAccessTokenKey"];
    [defaults setObject:nil forKey:@"FBExpirationDateKey"];
    [defaults setObject:nil forKey:@"FBIdentifier"];
    [defaults setObject:nil forKey:@"TWAuthData"];
    [defaults setObject:nil forKey:@"TWUsername"];
    [defaults setObject:nil forKey:@"UserID"];
    [defaults setObject:nil forKey:@"UserFirstName"];
    [defaults setObject:nil forKey:@"UserLastName"];
    [defaults setObject:nil forKey:@"UserEmail"];
    [defaults setObject:nil forKey:@"UserImage"];
    [defaults setObject:nil forKey:@"UserUsername"];
    [defaults setObject:nil forKey:@"UserPassword"];
    [defaults setObject:nil forKey:@"UserPhone"];
    [defaults setObject:nil forKey:@"UserToken"];
    [defaults setBool:NO forKey:@"DidAskPermission"]; // *
    [defaults setBool:NO forKey:@"ABAccess"]; // *
    [defaults setObject:nil forKey:@"Requests"]; // *
    [defaults setInteger:0 forKey:@"ThemeID"]; // *
    [defaults setInteger:0 forKey:@"ThemeRed"]; // *
    [defaults setInteger:0 forKey:@"ThemeGreen"]; // *
    [defaults setInteger:0 forKey:@"ThemeBlue"]; // *
    [defaults setObject:@"Default" forKey:@"ThemeName"]; // *
    [defaults setInteger:0 forKey:@"ThemeID"];
    [defaults setObject:@"Default" forKey:@"ThemeName"];
    [defaults setInteger:0 forKey:@"MicID"];
    [defaults setObject:@"Default" forKey:@"MicName"];
    [defaults setBool:NO forKey:@"showFriendNotification"];
    [defaults setBool:NO forKey:@"DisplayedError"];
    [defaults setInteger:0 forKey:@"ErrorCount"];
    [defaults setInteger:0 forKey:@"pendingInvitations"];
    [defaults setInteger:0 forKey:@"UnreadMessages"];
    
    // new value for login type
    [defaults setInteger:LoginModeNone forKey:@"LoginMode"];
    
    [defaults setBool:NO forKey:@"fb_sync"];
    [defaults setBool:NO forKey:@"ab_sync"];
    
    [defaults synchronize];
    
    // reset badge number too
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)updateUnreadMessages:(NSInteger)newValue {
    [defaults setInteger:newValue forKey:@"UnreadMessages"];
    [defaults synchronize];
    NSInteger badgeValue = newValue +  [defaults integerForKey:@"pendingInvitations"];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:(badgeValue < 0) ? 0 : badgeValue];
}

- (void)updatePendingFriends:(NSInteger)newValue {
    [defaults setInteger:newValue forKey:@"pendingInvitations"];
    [defaults synchronize];
    NSInteger badgeValue = [defaults integerForKey:@"UnreadMessages"] +  newValue;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:(badgeValue < 0) ? 0 : badgeValue];
}

- (NSData *)getUsersImage:(NSString *)facebookId {
    // Get the object image
    NSString *url = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture?type=large", facebookId];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    return data;
}


@end
