//
//  SocialFriendsList.m
//  Tongue Tango
//
//  Created by Chris Air on 3/26/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "SocialFriendsList.h"

@interface SocialFriendsList ()

@end

@implementation SocialFriendsList

@synthesize moreActivity;
@synthesize coreDataClass;
@synthesize toID;
@synthesize tableFriends;
@synthesize arrCellData;
@synthesize arrFacebook = _arrFacebook;
@synthesize arrTwitter = _arrTwitter;
@synthesize socialToID;
@synthesize socialToName;
@synthesize homeView;
@synthesize selectedRow;
@synthesize twHelper;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.alpha = 0;
    self.view.bounds = CGRectMake(0, 0, 320, 340);
    self.view.frame = CGRectMake(0, 0, 320, 340);
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOpacity = 0.4;
    self.view.layer.shadowRadius = 5;
    self.view.layer.shadowOffset = CGSizeMake(0, 5.0f);
    
    self.socialToID = @"";
    
    // Set the backbround image for this view
    self.tableFriends.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    
    arrCellData = [[NSMutableArray alloc] init];
    defaults = [NSUserDefaults standardUserDefaults];
    twHelper = [TwitterHelper sharedInstance];
}

- (void)viewDidUnload
{
    defaults = nil;
    [self setTableFriends:nil];
    [self setArrCellData:nil];
    [self setArrFacebook:nil];
    [self setArrTwitter:nil];
    [self setSocialToID:nil];
    [self setSocialToName:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (IBAction)closeList {
    [UIView animateWithDuration :.2
                           delay: 0
                         options: UIViewAnimationOptionTransitionNone
                      animations:^{
                          [self.view setAlpha:0];
                          homeView.viewAction.alpha = 0;
                          homeView.pickedGlow.alpha = 0;
                          homeView.bttnRefresh.alpha = .8;
                      }
                      completion:^(BOOL finished){
                      }];
}

#pragma mark - Table View methods

- (NSMutableArray *)arrFacebook
{
    if (_arrFacebook != nil) {
        return _arrFacebook;
    }
    
    coreDataClass = [CoreDataClass sharedInstance];
    NSArray *results = [coreDataClass getData:@"People" Conditions:@"facebook_id != '0'" Sort:@"" Ascending:YES];
    
    if (results.count > 0) {
        NSMutableArray *temp = [coreDataClass convertToDict:results];
        
        NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:@"first_name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *descriptors = [NSArray arrayWithObject:firstDescriptor];
        NSArray *arrSorted = [temp sortedArrayUsingDescriptors:descriptors];
        
        self.arrFacebook = [NSMutableArray arrayWithArray:arrSorted];
    } else {
        self.arrFacebook = [[NSMutableArray alloc] init];
    }
    
    return _arrFacebook;
}

- (NSMutableArray *)arrTwitter
{
    if (_arrTwitter != nil) {
        return _arrTwitter;
    }
    
    NSArray *arrFollowerIDs = [twHelper getFollwerIDs:[defaults objectForKey:@"TWUsername"]];
    
    NSInteger followersPerQuery = 100;
    NSInteger followerCount = arrFollowerIDs.count;
    NSInteger numberOfQueries = ceil(followerCount / followersPerQuery);
    
    NSMutableArray *followers = [[NSMutableArray alloc] init];
    
    if (followerCount > 0) {
        if (followerCount > followersPerQuery) {
            for (NSInteger i = 0; i < numberOfQueries; i++) {
                if (i == numberOfQueries) {
                    followersPerQuery = followerCount;
                }
                NSRange rangeForQuery = NSMakeRange(i * followersPerQuery, followersPerQuery);
                NSArray *newFollowers = [twHelper getMyFollowers:[arrFollowerIDs subarrayWithRange:rangeForQuery]];
                if (newFollowers) {
                    [followers addObjectsFromArray:newFollowers];
                }
            }
        } else if (followerCount <= followersPerQuery) {
            NSArray *newFollowers = [twHelper getMyFollowers:arrFollowerIDs];
            if (newFollowers) {
                [followers addObjectsFromArray:newFollowers];
            }
        }
        NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *descriptors = [NSArray arrayWithObject:firstDescriptor];
        NSArray *arrSorted = [followers sortedArrayUsingDescriptors:descriptors];
        self.arrTwitter = [NSMutableArray arrayWithArray:arrSorted];
    } else {
        self.arrTwitter = followers;
    }
    
    return _arrTwitter;
}

- (void)populateTableCellData
{
    arrCellData = nil;
    if (toID == 1) {
        arrCellData = [self.arrFacebook mutableDeepCopy];
    } else {
        arrCellData = [self.arrTwitter mutableDeepCopy];
    }
    
    NSDictionary *myDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            NSLocalizedString(@"MY TIMELINE", nil), @"first_name",
                            @"", @"last_name",
                            NSLocalizedString(@"MY FEED", nil), @"name",
                            @"me", @"facebook_id",
                            @"me", @"username",
                            nil];
    
    [arrCellData insertObject:myDict atIndex:0];
    [tableFriends reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.arrCellData count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *NameIdentifier = @"NameCell";
    static NSString *ButtonIdentifier = @"ButtonCell";
    
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    UITableViewCell *cell = nil;
    if ([dict objectForKey:@"button"] == nil) {
        UILabel *mainLabel;
        
        cell = [tableView dequeueReusableCellWithIdentifier:NameIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NameIdentifier];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 10, 180, 22)];
            mainLabel.font = [UIFont boldSystemFontOfSize:16];
            mainLabel.textColor = [UIColor colorWithWhite:0.46 alpha:1];
            mainLabel.backgroundColor = [UIColor clearColor];
            mainLabel.tag = 4000;
            [cell.contentView addSubview:mainLabel];
        } else {
            mainLabel = (UILabel *)[cell viewWithTag:4000];
        }
        
        // Set the main label
        if (toID == 1) {
            mainLabel.text = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
        } else {
            mainLabel.text = [dict objectForKey:@"name"];
        }
    } else {
        UILabel *moreLabel = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:ButtonIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ButtonIdentifier];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            moreLabel = [[UILabel alloc] init];
            moreLabel.backgroundColor = [UIColor clearColor];
            moreLabel.font = [UIFont boldSystemFontOfSize:19];
            moreLabel.frame = CGRectMake(0, 18, 320, 30);
            moreLabel.textAlignment = UITextAlignmentCenter;
            moreLabel.text = @"Show 20 More";
            [cell.contentView addSubview:moreLabel];
            
            moreActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            moreActivity.hidesWhenStopped = YES;
            [moreActivity setCenter:CGPointMake(294, 33)];
            [cell.contentView addSubview:moreActivity];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [self.arrCellData objectAtIndex:indexPath.row];
    
    if ([dict objectForKey:@"button"] == nil) {
        selectedRow = indexPath.row;
        if (toID == 1) {
            socialToName = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
            socialToID = [dict objectForKey:@"facebook_id"];
        } else {
            socialToName = [dict objectForKey:@"name"];
            socialToID = [dict objectForKey:@"username"];
        }
        
        [homeView socFriendSelected:socialToID withName:socialToName];
        
        [UIView animateWithDuration :.2
                               delay: 0
                             options: UIViewAnimationOptionTransitionNone
                          animations:^{
                              [self.view setAlpha:0];
                          }
                          completion:nil];
        
        if (isSearchResults) {
            self.searchDisplayController.searchBar.text = @"";
            [self resetSearch];
            [self.tableFriends reloadData];
            [self.searchDisplayController.searchBar resignFirstResponder];
            [self.searchDisplayController setActive:NO];
        }
    }
    [self.tableFriends deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Search table cell data

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    UIImageView *anImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_list_white_leather.png"]];
    controller.searchResultsTableView.backgroundView = anImage;
    controller.searchResultsTableView.separatorColor = SEPARATOR_LINE_COLOR;
}

- (void)resetSearch
{
    [self.arrCellData removeAllObjects];
    [self.arrCellData addObjectsFromArray:self.arrFacebook];
    isSearchResults = NO;
}

- (void)handleSearchForTerm:(NSString *)searchText
{
    NSMutableArray *arrSearch = [self.arrFacebook mutableDeepCopy];
    NSMutableIndexSet *rowsToRemove = [[NSMutableIndexSet alloc] init];
    int searchCount = [arrSearch count];
    
    for (int i = 0; i < searchCount; i++) {
        NSDictionary *dict = [arrSearch objectAtIndex:i];
        NSString *fullname;
        if (toID == 1) {
            fullname = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
        } else {
            fullname = [dict objectForKey:@"name"];
        }
        if ([fullname rangeOfString:searchText options:NSCaseInsensitiveSearch].location == NSNotFound) {
            [rowsToRemove addIndex:i];
        }
    }
    
    if (rowsToRemove.count > 0) {
        [arrSearch removeObjectsAtIndexes:rowsToRemove];
    }
    
    [self.arrCellData removeAllObjects];
    [self.arrCellData addObjectsFromArray:arrSearch];
    [self.tableFriends reloadData];
    isSearchResults = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        [self resetSearch];
        [self.tableFriends reloadData];
        return;
    }
    [self handleSearchForTerm:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchDisplayController.searchBar.text = @"";
    [self resetSearch];
    [self.tableFriends reloadData];
    [searchBar resignFirstResponder];
}

@end
