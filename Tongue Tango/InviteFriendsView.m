//
//  InviteFriendsView.m
//  Tongue Tango
//
//  Created by Aftab Baig on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "InviteFriendsView.h"
#import "SquareAndMask.h"

#define k_UIAlertView_Tag_NoContactsInAddressBook   1

@class Recipients;

@implementation Recipients

-(void)getMailRecipients:(NSMutableArray*)allRecipients
{
    NSMutableArray *recipients = [[NSMutableArray alloc] init];
    for (NSDictionary *dictionary in allRecipients)
    {
        NSString *selected = [dictionary objectForKey:@"selected"];
        NSArray *emails = [dictionary objectForKey:@"email"];
        if (emails.count > 0 && [selected isEqualToString:@"YES"])
        {
            [recipients addObject:[emails objectAtIndex:0]];
        }
    }
    if (self.delegate)
    {
        [self.delegate mailRecipientsAdded:recipients];
    }
}

-(void)getSMSRecipients:(NSMutableArray*)allRecipients
{
    NSMutableArray *recipients = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dictionary in allRecipients)
    {
        NSString *selected = [dictionary objectForKey:@"selected"];
        NSArray *phones = [dictionary objectForKey:@"phone"];
        if (phones.count > 0 && [selected isEqualToString:@"YES"])
        {
            [recipients addObject:[phones objectAtIndex:0]];
        }
    }

    if (self.delegate)
    {
        [self.delegate smsRecipientsAdded:recipients];
    }
}

@end

@interface InviteFriendsView ()
{
    UIImage *defaultImage;
    BOOL isSearchResults;
    NSMutableDictionary *_alphabets;
    NSArray *_alphabetsArray;
    UISegmentedControl *btnSend;
    BOOL _searching;
    NSInteger nItemSort;
    NSInteger _lastSearchSelected;
}
@end

@implementation InviteFriendsView

@synthesize tblFriends=_tblFriends;
@synthesize people=_people;
@synthesize temp=_temp;
@synthesize theHUD=_theHUD;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        btnSend = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"SMS",@"Email",nil]];
        [btnSend addTarget:self action:@selector(segmentSwitch:) forControlEvents:UIControlEventValueChanged];
        btnSend.frame = CGRectMake(160,0,226,30);
        [btnSend setSelectedSegmentIndex:0];
        btnSend.segmentedControlStyle = UISegmentedControlStyleBar;
        self.navigationItem.titleView = btnSend;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (UIView *searchBarSubview in [self.searchDisplayController.searchBar subviews]) {
        
        if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {
            
            @try {
                
                [(UITextField *)searchBarSubview setReturnKeyType:UIReturnKeyDone];
                [(UITextField *)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
            }
            @catch (NSException * e) {
                
                // ignore exception
            }
        }
    }
    
    _searching = NO;
    
    nItemSort = 0;
    
    defaultImage = [UIImage imageNamed:@"userpic_placeholder_male"];
    
    self.theHUD = [[ProgressHUD alloc] initWithText:NSLocalizedString(@"LOADING", nil) willAnimate:YES addToView:self.view];
    [self.theHUD create];
    
    [self.theHUD show];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            self.people = [self getAllAddressBookPeople];
            
            if (self.people.count == 0)
            {
                //>---------------------------------------------------------------------------------------------------
                //>     Ben 10/03/2012
                //>
                //>     I commented this out. User should never get here, in iOS 6, because I am stopping him when
                //>     pressing "Invite Your Friends!!" button. See "inviteFriends" method in SyncFriendsView.m
                //>
                //>     Update:
                //>
                //>     We need to treat the case when there is no contact in address book. So we will show an alert
                //>---------------------------------------------------------------------------------------------------
                /*[NSThread sleepForTimeInterval:2.0f];
                self.people = [self getAllAddressBookPeople];
                if (self.people.count == 0)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Address Book"
                                                                    message:@"You need to give permission from Settings>Privacy>Contacts to access your contacts"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    [self.theHUD hide];
                    return;
                }*/
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Address Book"
                                                                message:@"You have no contacts to invite."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                alert.tag   = k_UIAlertView_Tag_NoContactsInAddressBook;
                [alert show];
                [self.theHUD hide];
                return;
            }
            
            self.temp = [[NSMutableArray alloc] init];
            self.temp = [self.people mutableCopy];
            
            _alphabets = [[NSMutableDictionary alloc] init];
            for (NSDictionary *dictionary in self.people)
            {
                NSString *firstName = [dictionary objectForKey:@"first_name"];
                NSString *alphabet = [firstName substringToIndex:1];
                NSNumber *count = [_alphabets objectForKey:alphabet];
                if (count == nil)
                {
                    [_alphabets setValue:[NSNumber numberWithInteger:1] forKey:alphabet];
                }
                else
                {
                    [_alphabets setValue:[NSNumber numberWithInteger:[count integerValue]+1] forKey:alphabet];
                }
            }
            _alphabetsArray = [_alphabets allKeys];
            _alphabetsArray = [_alphabetsArray sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2)
                               {
                                   NSString *name1 = (NSString*)obj1;
                                   NSString *name2 = (NSString*)obj2;
                                   return [name1 caseInsensitiveCompare:name2];
                               }];
            
            [self.tblFriends reloadData];
            [self.theHUD hide];
        });
    });
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - tableview delegate & datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    if (!isSearchResults)
    {
        return [self numberOfSections];
    }
    else
    {
        return 1;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!isSearchResults)
    {
        NSString *alphabet = [_alphabetsArray objectAtIndex:section];
        NSNumber *count = [_alphabets objectForKey:alphabet];
        return [count intValue];
    }
    else
    {
        return self.temp.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!isSearchResults)
    {
        return [_alphabetsArray objectAtIndex:section];
    }
    else
    {
        return @"";
    }
}

-(UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    int index=0;
    
    if (!isSearchResults)
    {
        int range=0;
        for (int i=0; i<indexPath.section; i++)
        {
            NSString *alphabet = [_alphabetsArray objectAtIndex:i];
            NSNumber *count = [_alphabets objectForKey:alphabet];
            range += [count integerValue];
        }
        index=range+indexPath.row;
    }
    else
    {
        index=indexPath.row;
    }
    
    NSDictionary *dictionary = [self.temp objectAtIndex:index];
    NSString *title = [NSString stringWithFormat:@"%@ %@",[dictionary objectForKey:@"first_name"],[dictionary objectForKey:@"last_name"]];
    NSString *phone = @"";
    NSArray *phones = [dictionary objectForKey:@"phone"];
    NSArray *emails = [dictionary objectForKey:@"email"];
    if (nItemSort == 0)
    {
        phone = [phones objectAtIndex:0];
    }
    else if (nItemSort == 1)
    {
        phone = [emails objectAtIndex:0];
    }
    
    int entry_id = [[dictionary objectForKey:@"entry_id"] intValue];
    NSLog(@"Count = %d", _people.count);
    NSDictionary *p_dictionary;
    for (NSInteger i = 0; i < _people.count; i++)
    {
        p_dictionary = [_people objectAtIndex:i];
        if ( [[p_dictionary objectForKey:@"entry_id"] intValue] == entry_id )
            break;
    }
    BOOL isSelected = [[p_dictionary objectForKey:@"selected"] isEqualToString:@"YES"]?YES:NO;
    
    AddressBookEntryCell *cell = [AddressBookEntryCell createCellWithId:index title:title
                                                                  phone:phone isSelected:isSelected];
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    return 52.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AddressBookEntryCell *cell  = (AddressBookEntryCell*)[self.tblFriends cellForRowAtIndexPath:indexPath];
    [cell toggleSelect:cell.btnSelected];
    
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    if (!isSearchResults)
    {
        return _alphabetsArray;
    }
    else
    {
        return nil;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

-(NSInteger)numberOfSections
{
    return _alphabetsArray.count;
}

#pragma mark - Get All Address Book Entries
// Create an array of people data from the Address Book
- (NSMutableArray *)getAllAddressBookPeople
{
    // create the address book (AB) array
    ABAddressBookRef addressBook = ABAddressBookCreate();

    NSArray *arrAllPeople = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSMutableArray *arrReturn = [NSMutableArray array];
    
    SquareAndMask *objImage = [[SquareAndMask alloc] init];
    
    if (arrAllPeople != nil) {
        
        // build an array containing dictionaries for each person
        NSInteger peopleCount = [arrAllPeople count];
        for (int i = 0; i < peopleCount; i++) {
            ABRecordRef thisPerson = (__bridge ABRecordRef)[arrAllPeople objectAtIndex:i];
            
            // get this persons name
            NSString *strFirstName = (__bridge_transfer NSString *)ABRecordCopyValue(thisPerson, kABPersonFirstNameProperty);
            NSString *strLastName = (__bridge_transfer NSString *)ABRecordCopyValue(thisPerson, kABPersonLastNameProperty);
            
            // get this persons email addresses
            ABMultiValueRef multi1 = ABRecordCopyValue(thisPerson, kABPersonEmailProperty);
            NSArray *arrAllEmailAddresses = (__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(multi1);
            if (!arrAllEmailAddresses) {
                arrAllEmailAddresses = [[NSArray alloc] init];
            }
            CFRelease(multi1);
            
            // get this persons phone numbers
            ABMultiValueRef multi2 = ABRecordCopyValue(thisPerson, kABPersonPhoneProperty);
            NSArray *arrAllPhoneNumbers = (__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(multi2);
            if (!arrAllPhoneNumbers) {
                arrAllPhoneNumbers = [[NSArray alloc] init];
            }
            CFRelease(multi2);
            
            // get this persons id
            int intPersonId = (int)ABRecordGetRecordID(thisPerson);
            NSNumber *personId = [NSNumber numberWithInt:intPersonId];
            
            // get this persons image data
            UIImage *image;
            if(ABPersonHasImageData(thisPerson)){
                UIImage *tmpImage = [UIImage imageWithData:(__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(thisPerson, 0)];
                image = [objImage maskImage:tmpImage];
            } else {
                image = defaultImage;
            }
            
            // skip this person if both first and last names are not available
            if (strFirstName || strLastName) {
                
                // make sure both first and last names have values since we'll be sorting by them
                if (!strFirstName) {
                    strFirstName = strLastName;
                    strLastName = @" ";
                }
                if (!strLastName) {
                    strLastName = @" ";
                }
                
                // save the data to a dictionary and save the dictionary into an array
                NSMutableDictionary *dict =
                [[NSMutableDictionary alloc] initWithDictionary:
                        [NSDictionary dictionaryWithObjectsAndKeys:
                                             personId,@"addressbookid", [NSString stringWithFormat:@"AB%@", personId ], @"id", image, @"photo",
                                             strFirstName, @"first_name", strLastName, @"last_name",
                                             arrAllEmailAddresses, @"email", arrAllPhoneNumbers, @"phone",
                                             @"NO",@"selected",
                  [NSString stringWithFormat:@"%d",i],@"entry_id",
                                             nil]];
                NSString *phone = @"";
                NSArray *phones = [dict objectForKey:@"phone"];
                NSArray *emails = [dict objectForKey:@"email"];
                if ( nItemSort == 0 )
                {
                    if (phones.count > 0)
                    {
                        phone = [phones objectAtIndex:0];
                        [arrReturn addObject:dict];
                    }
                }
                else if ( nItemSort == 1 )
                {
                    if (emails.count > 0)
                    {
                        phone = [emails objectAtIndex:0];
                        [arrReturn addObject:dict];
                    }
                }
            }
        }
    }
    CFRelease(addressBook);
    
    return [self sortPeopleByFirstName:arrReturn];
}

- (NSMutableArray *)sortPeopleByFirstName:(NSMutableArray *)people
{
    NSSortDescriptor *firstDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"first_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSSortDescriptor *lastDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"last_name"
                                ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSArray *descriptors = [NSArray arrayWithObjects:firstDescriptor, lastDescriptor, nil];
    NSArray *arrSorted = [people sortedArrayUsingDescriptors:descriptors];
    
    return [NSMutableArray arrayWithArray:arrSorted];
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
    [self.temp removeAllObjects];
    [self.temp addObjectsFromArray:self.people];
    [self.tblFriends reloadData];
    isSearchResults = NO;
}

- (void)handleSearchForTerm:(NSString *)searchText
{
    NSMutableArray *arrSearch = [self.people mutableCopy];
    NSMutableIndexSet *rowsToRemove = [[NSMutableIndexSet alloc] init];
    int searchCount = [arrSearch count];
    
    for (int i = 0; i < searchCount; i++) {
        NSDictionary *dict = [arrSearch objectAtIndex:i];
        NSString *fullname;
            fullname = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"first_name"],[dict objectForKey:@"last_name"]];
        if ([fullname rangeOfString:searchText options:NSCaseInsensitiveSearch].location == NSNotFound) {
            [rowsToRemove addIndex:i];
        }
    }

    if (rowsToRemove.count > 0) {
        [arrSearch removeObjectsAtIndexes:rowsToRemove];
    }

    [self.temp removeAllObjects];
    [self.temp addObjectsFromArray:arrSearch];
    isSearchResults = YES;
    [self.tblFriends reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        [self resetSearch];
        [self.tblFriends reloadData];
        return;
    }
    [self handleSearchForTerm:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchBarCancelButtonClicked:searchBar];
    [self.searchDisplayController setActive:NO animated:YES];
    
    int range=0;
    int sections = [self numberOfSections];
    int selected_section = 0;
    int selected_row = 0;
    for (int i=0; i<sections; i++)
    {
        NSString *alphabet = [_alphabetsArray objectAtIndex:i];
        NSNumber *count = [_alphabets objectForKey:alphabet];
        range += [count integerValue];
        if (range > _lastSearchSelected)
        {
            selected_section = i;
            selected_row = _lastSearchSelected-(range-[count integerValue]);
            break;
        }
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selected_row inSection:selected_section];
    [self.tblFriends scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    _lastSearchSelected = 0;
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    isSearchResults = NO;
    self.searchDisplayController.searchBar.text = @"";
    [self resetSearch];
    [self.tblFriends reloadData];
    [searchBar resignFirstResponder];
}

#pragma mark - AddressBook Cell Delegate

-(void)shouldSelectEntry:(int)entryId
{
    NSDictionary *entry = [self.temp objectAtIndex:entryId];
    int originalId = [[entry objectForKey:@"entry_id"] intValue];
    NSDictionary *p_entry;
    NSInteger i = 0;
    for (i = 0; i < _people.count; i++)
    {
        p_entry = [_people objectAtIndex:i];
        if ( [[p_entry objectForKey:@"entry_id"] intValue] == originalId )
            break;
    }
    _lastSearchSelected = i;
    
    [p_entry setValue:@"YES" forKey:@"selected"];
    [self.people replaceObjectAtIndex:i withObject:p_entry];
}

-(void)shouldDeselectEntry:(int)entryId
{
    NSDictionary *entry = [self.temp objectAtIndex:entryId];
    int originalId = [[entry objectForKey:@"entry_id"] intValue];
    
    NSDictionary *p_entry;
    NSInteger i;
    for (i = 0; i < _people.count; i++)
    {
        p_entry = [_people objectAtIndex:i];
        if ( [[p_entry objectForKey:@"entry_id"] intValue] == originalId )
            break;
    }
    
    if (i == _lastSearchSelected)
    {
        _lastSearchSelected = 0;
    }
    
    [p_entry setValue:@"NO" forKey:@"selected"];
    [self.people replaceObjectAtIndex:i withObject:p_entry];
}

-(IBAction)selectAll:(id)sender
{
    if (self.people.count == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Address Book"
                                                        message:@"No contacts available to select"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    UIButton *button = (UIButton*)sender;
    button.selected = !button.selected;
    
    for (int i=0; i<self.people.count; i++)
    {
        NSDictionary *dictionary = [self.people objectAtIndex:i];
        if (button.selected)
        {
            [dictionary setValue:@"YES" forKey:@"selected"];
        }
        else
        {
            [dictionary setValue:@"NO" forKey:@"selected"];
        }
    }
    [self.tblFriends reloadData];
}



#pragma mark - Send SMS/Email
- (void)openEmailComposer
{
    [self.theHUD show];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(buildEmailRecipients) userInfo:nil repeats:NO];
}

- (void)buildEmailRecipients
{
    Recipients *recipients = [[Recipients alloc] init];
    recipients.delegate = self;
    [recipients getMailRecipients:self.people];
}

- (void)openSMSComposer
{
    [self.theHUD show];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(buildSMSRecipients) userInfo:nil repeats:NO];
}

- (void)buildSMSRecipients
{
    Recipients *recipients = [[Recipients alloc] init];
    recipients.delegate = self;
    [recipients getSMSRecipients:self.people];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissModalViewControllerAnimated:YES];
    
    [self.theHUD hide];
    
    if (result == MessageComposeResultSent)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INVITE SENT" , nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil, nil];
        alert.tag = 1000;
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Reset email
    //[self resetEmail];
    // This prevents the MailCompose Viewer to show again after pressing Cancel or Send
    //audioURL = nil;
    
    [self.theHUD hide];
    
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

-(IBAction)preview:(id)sender
{
    if (btnSend.selectedSegmentIndex == 0)
    {
        [self openSMSComposer];
    }
    else
    {
        [self openEmailComposer];
    }
}

- (IBAction)segmentSwitch:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    nItemSort = selectedSegment;
    
    [self.theHUD show];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        self.people = [self getAllAddressBookPeople];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            self.people = [self getAllAddressBookPeople];
            self.temp = [[NSMutableArray alloc] init];
            self.temp = [self.people mutableCopy];
            
            _alphabets = [[NSMutableDictionary alloc] init];
            for (NSDictionary *dictionary in self.people)
            {
                NSString *firstName = [dictionary objectForKey:@"first_name"];
                NSString *alphabet = [firstName substringToIndex:1];
                NSNumber *count = [_alphabets objectForKey:alphabet];
                if (count == nil)
                {
                    [_alphabets setValue:[NSNumber numberWithInteger:1] forKey:alphabet];
                }
                else
                {
                    [_alphabets setValue:[NSNumber numberWithInteger:[count integerValue]+1] forKey:alphabet];
                }
            }
            _alphabetsArray = [_alphabets allKeys];
            _alphabetsArray = [_alphabetsArray sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2)
                               {
                                   NSString *name1 = (NSString*)obj1;
                                   NSString *name2 = (NSString*)obj2;
                                   return [name1 caseInsensitiveCompare:name2];
                               }];
            
            [self.theHUD hide];
            [self.tblFriends reloadData];
        });
    });
}

-(void)mailRecipientsAdded:(NSMutableArray *)recipients
{
    
    //[self.theHUD hide];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    
    if ([MFMailComposeViewController canSendMail])
    {
        mailViewController.mailComposeDelegate = self;
        
        // Change the color of the mailViewController navigation bar.
        UINavigationBar *navigationBar = mailViewController.navigationBar;
        if ([defaults integerForKey:@"ThemeID"] == 0) {
            navigationBar.tintColor = DEFAULT_THEME_COLOR;
        } else {
            navigationBar.tintColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) green:([defaults integerForKey:@"ThemeGreen"]/255.0) blue:([defaults integerForKey:@"ThemeBlue"]/255.0) alpha:1];
        }
        
        NSString *theMessage;
        theMessage = [NSString stringWithFormat:NSLocalizedString(@"INVITE TEXT MESSAGE", nil),[[NSUserDefaults standardUserDefaults] objectForKey:@"UserFirstName"],
                      [[NSUserDefaults standardUserDefaults] objectForKey:@"UserLastName"],
                      kTTDownloadStore,
                      kTTDownloadStore];
        
        
        // Set the email subject and recipient.
        [mailViewController setSubject:@"You've been invited to Tongue Tango!"];
        [mailViewController setToRecipients:recipients];
        [mailViewController setMessageBody:theMessage isHTML:NO];
        
        // Open the Mail app
        [self presentModalViewController:mailViewController animated:YES];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL UNAVAILABLE", nil)
                                                        message:NSLocalizedString(@"EMAIL NOT SETUP", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }

}

-(void)smsRecipientsAdded:(NSMutableArray *)recipients
{
    
    //[self.theHUD hide];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
    
    if ([MFMessageComposeViewController canSendText]) {
        
        messageViewController.messageComposeDelegate = self;
        
        // Change the color of the mailViewController navigation bar.
        UINavigationBar *navigationBar = messageViewController.navigationBar;
        if ([defaults integerForKey:@"ThemeID"] == 0) {
            navigationBar.tintColor = DEFAULT_THEME_COLOR;
        } else {
            navigationBar.tintColor = [UIColor colorWithRed:([defaults integerForKey:@"ThemeRed"]/255.0) green:([defaults integerForKey:@"ThemeGreen"]/255.0) blue:([defaults integerForKey:@"ThemeBlue"]/255.0) alpha:1];
        }
        
        NSString *theMessage = [NSString stringWithFormat:NSLocalizedString(@"INVITE SMS MESSAGE2", nil),kTTDownloadStore];
        
        // Set the SMS body and recipient.
        [messageViewController setBody:theMessage];
        [messageViewController setRecipients:recipients];
        [self presentModalViewController:messageViewController animated:YES];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Sent Message"
                                                        message:NSLocalizedString(@"SMS NOT AVAILABLE", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }

}

#pragma mark - UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == k_UIAlertView_Tag_NoContactsInAddressBook)
    {
        //>     Address Book is empty, so pop back to previous screen
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
