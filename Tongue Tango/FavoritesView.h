//
//  FavoritesView.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/3/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CoreDataClass.h"
#import "ServerConnection.h"
#import "SquareAndMask.h"

@interface FavoritesView : UIViewController <AVAudioPlayerDelegate, AVAudioSessionDelegate> {
    UIImage *myUserImage;
    UIImage *defaultImage;
    
    AVAudioPlayer *avPlayer;
    AVAudioSession *audioSession;
    NSArray *arrMessages;
    NSMutableArray *arrCellData;
    NSMutableDictionary *dictDownloadImages;
    NSMutableDictionary *dictPeople;
    
    NSUserDefaults *defaults;
}

@property (strong, nonatomic) UIButton *currentButton;
@property (strong, nonatomic) NSMutableArray *arrCellData;
@property (strong, nonatomic) NSMutableDictionary *dictDownloadImages;

@property (strong, nonatomic) IBOutlet UITableView *tableFavorites;

@property (strong, nonatomic) CoreDataClass *coreDataClass;

- (void)populateTableCellData;

// Download table images
- (UIImage *)downloadCellImage:(NSString *)photo withID:(NSNumber *)personId forIndexPath:(NSIndexPath *)indexPath;

- (IBAction)toggleMove;
- (IBAction)moveRight;
- (IBAction)moveLeft;

- (void)proximityChanged:(NSNotification *)notification;

@end
