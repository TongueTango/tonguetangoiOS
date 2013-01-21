//
//  Constants.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 1/19/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#ifndef Tongue_Tango_Constants_h
#define Tongue_Tango_Constants_h

// Twitter OAuth Credentials
#define kOAuthConsumerKey     @"MQOfe7NTpw51nNh6EtPB5Q"
#define kOAuthConsumerSecret  @"7scn2m6vhRKAUjdSrmXnJpFW6jKYWn4vK2OPFxiKAmc"

// API Server following 2 lines - commented by Ash
//#define kAPIURL @"http://prod.tonguetango.com/api/" // LIVE - 108.166.96.160
//#define kROOTURL @"http://prod.tonguetango.com/" // DEV - 50.57.98.17

//#define kAPIURL @"http://uat.tonguetango.com/api/" // UAT - 50.57.80.69

//#define kAPIURL @"http://dev.tonguetango.com/api/" // DEV - 50.57.98.17
//#define kROOTURL @"http://dev.tonguetango.com/" // DEV - 50.57.98.17

//#define kAPIURL @"http://localhost/api/" // local dev - 50.57.98.17


#define kAPIURL @"http://apiv2.tonguetango.com/"
#define kROOTURL @"http://apiv2.tonguetango.com/"

// Invite Video and Audio
#define kInviteVideo @"http://youtu.be/CGFlmQ5ruTM"
#define kInviteVideoPreview @"http://www.youtube.com/watch?v=CGFlmQ5ruTM&feature=youtu.be"
#define kInviteAudio @"http://c10691910.r10.cf2.rackcdn.com/TongueTangoAd.mp4"
#define kInviteFBAudio @"http://c10691910.r10.cf2.rackcdn.com/TongueTangoAd.avi"
#define kTTDownload @"http://TongueTango.com/download"
#define kTTDownloadStore @"www.itunes.com/apps/tonguetango"

// login types
typedef enum LoginMode {
    LoginModeNone = 0,
    LoginModeTongueTango,
    LoginModeFacebook,
    LoginModeTwitter
} LoginMode;

// View Controllers
#define kViewWelcome     0
#define kViewAddFriends  1
#define kViewHome        2
#define kViewMessages    3
#define kViewFriends     4
#define kViewGroups      5
#define kViewFavorites   6
#define kViewProfile     7
#define kViewSettings    8
#define kViewExtras      9
#define kViewFAQs        10
#define kViewAbout       11
#define kThreadDetail    12

// Used to specify type of contact for AddFriends and AddFromContacts
typedef enum showFriendView {
    kShowContacts,
    kShowFacebook,
    kShowInvite
} showFriendView;

// Used to specify tables for FriendsList and SelectMessageContact
typedef enum viewTableList {
    kListFriends,
    kListGroups
} viewTableList;

#define kSendText   1000
#define kSendAudio  1001
#define kSendImage  1002

// Image types
#define kGroupImage 0
#define kUserImage  1

#define DEFAULT_THEME_COLOR [UIColor colorWithRed:0.745 green:0.058 blue:0.050 alpha:1]
#define PROFILE_CELL_DISABLED_BACKGROUND_COLOR [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1]

// Messages
#define kFriendKey @"user_id"
#define kCoreData_Thread_TotalNumber        @"thread_total_number"

// Colors
#define SEPARATOR_LINE_COLOR [UIColor colorWithRed:0.87 green:0.86 blue:0.85 alpha:1]

#endif


#define kImageDirectory @"/Images"
#define kAudioDirectory @"/Audio"

#define k_UIImage_BackgroundImageName                   @"bg_generic"
#define k_UIImage_BackgroundImageNamePNG                @"bg_generic.png"

#define k_UIImage_BackgroundImageNamePNG_iPhone5        @"bg_generic_iPhone5.png"


#define FRIEND_REQUEST_ACCEPTED_NOTIFICATION @"requestAccepted"
#define FRIEND_REQUEST_NOTIFICATION @"request"
#define NEW_MESSAGE_NOTIFICATION @"message"
#define ADDED_TO_GROUP_NOTIFICATION @"group"
#define FRIEND_ADDED @"friend"
