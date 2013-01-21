//
//  CoreDataClass.m
//  Tongue Tango
//
//  Created by Chris Serra on 2/26/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "CoreDataClass.h"
#import "ManagedObjectValues.h"

@implementation CoreDataClass

@synthesize fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

static CoreDataClass *singletonDelegate = nil;

#pragma mark - Singleton Methods

- (id)init
{
    return self;
}

+ (CoreDataClass *)sharedInstance
{
    if (singletonDelegate == nil) {
        singletonDelegate = [[super alloc] init];
    }
    
    return singletonDelegate;
}

#pragma mark - Convert values

- (NSMutableArray *)convertToDict:(NSArray *)arrManObj {
    NSMutableArray *convert = [[NSMutableArray alloc] init];
    
    int resultsCount = [arrManObj count];
    for (int i = 0; i < resultsCount; i++) {
        NSArray *keys = [[[[arrManObj objectAtIndex:i] entity] attributesByName] allKeys];
        NSDictionary *dict = [[arrManObj objectAtIndex:i] dictionaryWithValuesForKeys:keys];
        [convert addObject:dict];
    }
    return convert;
}

- (NSNumber *)getNumberValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber *numberFromString = [numberFormatter numberFromString:value];
        
        return numberFromString;
    }
    return [NSNumber numberWithInt:0];
}

- (NSString *)getStringValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        NSString *stringFromNumber = [value stringValue];
        return stringFromNumber;
    }
    return @"";
}

#pragma mark - General

- (BOOL)deleteAll:(NSString *)entity Conditions:(NSString *)where
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *allRecords = [[NSFetchRequest alloc] init];
    [allRecords setEntity:[NSEntityDescription entityForName:entity inManagedObjectContext:context]];
    [allRecords setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    if ([where length] > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: where];
        [allRecords setPredicate:predicate];
    }
    
    NSError *error = nil;
    NSArray *records = [context executeFetchRequest:allRecords error:&error];

    for (NSManagedObject *record in records) {
        [context deleteObject:record];
    }
    
    NSError *saveError = nil;
    [context save:&saveError];

    return YES;
}

- (NSArray *)getData:(NSString *)entity Conditions:(NSString *)where Sort:(NSString *)orderBy Ascending:(BOOL)sortAscending
{
    return [self searchEntity:entity Conditions:where Sort:orderBy Ascending:sortAscending andLimit:0];
}

- (NSArray *)searchEntity:(NSString *)entity Conditions:(NSString *)_where Sort:(NSString *)_sort Ascending:(BOOL)_ascending andLimit:(NSInteger)_limit
{
//    DLog(@"Querying %@ in core data",entity);
//    DLog(@"with the following conditions: %@",_where);
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *desc = [NSEntityDescription entityForName:entity inManagedObjectContext:context];
    [fetchRequest setEntity:desc];
    
    [fetchRequest setFetchBatchSize:20];
    
    if (_limit > 0) {
        [fetchRequest setFetchLimit:_limit];
    }
    
    if ([_where length]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:_where];
        [fetchRequest setPredicate:predicate];
    }
    
    if ([_sort length]) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:_sort ascending:_ascending];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    NSError *error = nil;
    NSArray *aFetchResults = [context executeFetchRequest:fetchRequest error:&error];
    
    if (aFetchResults == nil) {
	    DLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return aFetchResults;
}

- (BOOL)doesDataExist:(NSString *)entity Conditions:(NSString *)where
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *desc = [NSEntityDescription entityForName:entity inManagedObjectContext:context];
    [fetchRequest setEntity:desc];
    
    if ([where length]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: where];
        [fetchRequest setPredicate:predicate];
    }
        
    NSError *error;
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    
    if (!error && count > 0) {
        return YES;
    }
    return NO;
}

#pragma mark - People

- (BOOL)addPeople:(id)data
{
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrData = (NSArray *)data;
    NSInteger dataCount = [arrData count];
    for (int i = 0; i < dataCount; i++) {
        if (![self setPerson:[arrData objectAtIndex:i] forObject:nil]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)addBlockedPeople:(id)data
{
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrData = (NSArray *)data;
    NSInteger dataCount = [arrData count];
    for (int i = 0; i < dataCount; i++) {
        if (![self setBlockPerson:[arrData objectAtIndex:i] forObject:nil]) {
            return NO;
        }
    }
    return YES;
}


- (BOOL)addPerson:(id)data
{
    return [self setPerson:data forObject:nil];
}

- (BOOL)setPerson:(id)data forObject:(NSManagedObject *)object
{
    
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    [object setNumberValue:[dict objectForKey:@"person_id"] forKey:@"id"];
    [object setNumberValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
    [object setStringValue:[dict objectForKey:@"facebook_id"] forKey:@"facebook_id"];
    [object setStringValue:[dict objectForKey:@"first_name"] forKey:@"first_name"];
    [object setStringValue:[dict objectForKey:@"last_name"] forKey:@"last_name"];
    [object setStringValue:[dict objectForKey:@"photo"] forKey:@"photo"];
    [object setNumberValue:[dict objectForKey:@"on_tt"] forKey:@"on_tt"];
    [object setNumberValue:[dict objectForKey:@"accepted"] forKey:@"is_friend"];
    
    NSInteger accepted = [[self getNumberValue:[dict objectForKey:@"accepted"]] intValue];
    if (accepted > 0) {
        [object setValue:nil forKey:@"status"];
    } else {
        NSInteger initiator = [[self getNumberValue:[dict objectForKey:@"initiator_id"]] intValue];
        if (initiator > 0) {
            if ([[NSUserDefaults standardUserDefaults] integerForKey:@"UserID"] == initiator) {
                [object setValue:@"invited" forKey:@"status"];
            } else {
                [object setValue:@"invited_you" forKey:@"status"];
            }
        }
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save person: %@", [error description]);
        return NO;
    }
    return YES;
}

- (BOOL)setBlockPerson:(id)data forObject:(NSManagedObject *)object
{
    
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"BlockedPeople" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    [object setNumberValue:[dict objectForKey:@"person_id"] forKey:@"id"];
    [object setNumberValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
    [object setStringValue:[dict objectForKey:@"facebook_id"] forKey:@"facebook_id"];
    [object setStringValue:[dict objectForKey:@"first_name"] forKey:@"first_name"];
    [object setStringValue:[dict objectForKey:@"last_name"] forKey:@"last_name"];
    [object setStringValue:[dict objectForKey:@"photo"] forKey:@"photo"];
    [object setNumberValue:[dict objectForKey:@"on_tt"] forKey:@"on_tt"];
    [object setNumberValue:[dict objectForKey:@"accepted"] forKey:@"is_friend"];
    
    NSInteger accepted = [[self getNumberValue:[dict objectForKey:@"accepted"]] intValue];
    if (accepted > 0) {
        [object setValue:nil forKey:@"status"];
    } else {
        NSInteger initiator = [[self getNumberValue:[dict objectForKey:@"initiator_id"]] intValue];
        if (initiator > 0) {
            if ([[NSUserDefaults standardUserDefaults] integerForKey:@"UserID"] == initiator) {
                [object setValue:@"invited" forKey:@"status"];
            } else {
                [object setValue:@"invited_you" forKey:@"status"];
            }
        }
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save person: %@", [error description]);
        return NO;
    }
    return YES;
}


#pragma mark - Messages

- (BOOL)addMessageThreads:(id)data {
    
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrData = (NSArray *)data;
    NSInteger dataCount = [arrData count];
    for (int i = 0; i < dataCount; i++) {
        if (![self setMessageThread:[arrData objectAtIndex:i] forObject:nil]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)addMessageThread:(id)data
{
    return [self setMessageThread:data forObject:nil];
}

- (BOOL)setMessageThread:(id)data forObject:(NSManagedObject *)object
{
    if (![data isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    if (object == nil)
    {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Message_threads" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    [object setDateValue:[dict objectForKey:@"create_date"] forKey:@"create_date"];
    [object setNumberValue:[dict objectForKey:@"friend_id"] forKey:@"friend_id"];
    [object setNumberValue:[dict objectForKey:@"group_id"] forKey:@"group_id"];
    [object setStringValue:[dict objectForKey:@"thread_id"] forKey:@"id"];
    [object setNumberValue:[dict objectForKey:@"unread"] forKey:@"unread"];
    [object setNumberValue:[dict objectForKey:kCoreData_Thread_TotalNumber] forKey:kCoreData_Thread_TotalNumber];
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error])
    {
        DLog(@"Could not save thread: %@", [error localizedDescription]);
        return NO;
    }
    
    return YES;
}

- (BOOL)addMessages:(id)data
{
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrData = (NSArray *)data;
    NSInteger dataCount = [arrData count];
    for (int i = 0; i < dataCount; i++) {
        if (![self setMessage:[arrData objectAtIndex:i] forObject:nil]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)addMessage:(id)data
{
    return [self setMessage:data forObject:nil];
}

- (BOOL)setMessage:(id)data forObject:(NSManagedObject *)object
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Messages" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    [object setDateValue:[dict objectForKey:@"create_date"] forKey:@"create_date"];
    [object setNumberValue:[dict objectForKey:@"id"] forKey:@"id"];
    [object setNumberValue:[dict objectForKey:@"sender_id"] forKey:@"sender_id"];
    [object setNumberValue:[dict objectForKey:@"recipient_id"] forKey:@"recipient_id"];
    [object setStringValue:[dict objectForKey:@"message_body"] forKey:@"message_body"];
    [object setStringValue:[dict objectForKey:@"message_header"] forKey:@"message_header"];
    [object setNumberValue:[dict objectForKey:@"is_favorite"] forKey:@"is_favorite"];
    [object setStringValue:[dict objectForKey:@"message_path"] forKey:@"message_path"];
    [object setNumberValue:[NSNumber numberWithInt:0] forKey:@"group_id"];
    
    NSString *body = [self getStringValue:[dict objectForKey:@"message_body"]];
    if (![body isEqualToString:@""]) {
        [object setValue:@"text" forKey:@"message_type"];
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save message: %@", [error localizedDescription]);
        return NO;
    }
    
    return YES;
}

- (BOOL)addMessageForGroup:(NSNumber *)group_id withDictionary:(id)data
{
    return [self setMessageForGroup:group_id withDictionary:data forObject:nil];
}

- (BOOL)setMessageForGroup:(NSNumber *)group_id withDictionary:(id)data forObject:(NSManagedObject *)object
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Messages" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    
    [object setValue:group_id forKey:@"group_id"];
    [object setNumberValue:[dict objectForKey:@"id"] forKey:@"id"];
    [object setNumberValue:[dict objectForKey:@"user_id"] forKey:@"sender_id"];
    [object setStringValue:[dict objectForKey:@"message_header"] forKey:@"message_header"];
    [object setStringValue:[dict objectForKey:@"message_body"] forKey:@"message_body"];
    [object setStringValue:[dict objectForKey:@"message_path"] forKey:@"message_path"];
    [object setDateValue:[dict objectForKey:@"create_date"] forKey:@"create_date"];
    
    NSString *body = [self getStringValue:[dict objectForKey:@"message_body"]];
    if (![body isEqualToString:@""]) {
        [object setValue:@"text" forKey:@"message_type"];
    }
    
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save message for group: %@", [error localizedDescription]);
        return NO;
    }
    
    return YES;
}

#pragma mark - Groups

- (BOOL)addGroups:(id)data
{
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrData = (NSArray *)data;
    NSInteger dataCount = [arrData count];
    for (int i = 0; i < dataCount; i++) {
        if (![self setGroup:[arrData objectAtIndex:i] forObject:nil]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)addBlockedGroups:(id)data
{
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrData = (NSArray *)data;
    NSInteger dataCount = [arrData count];
    for (int i = 0; i < dataCount; i++) {
        if (![self setBlockedGroup:[arrData objectAtIndex:i] forObject:nil]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)addGroup:(id)data
{
    return [self setGroup:data forObject:nil];
}

- (BOOL)setGroup:(id)data forObject:(NSManagedObject *)object
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Groups" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    
    // Build a list of member user ids to save in groups
    NSMutableArray *memberList = [[NSMutableArray alloc] init];
    for (NSDictionary *member in [dict objectForKey:@"members"]) {
        if ([member objectForKey:@"user"]) {
            [memberList addObject:[member objectForKey:@"user"]];
        }
    }
    
    [object setDateValue:[dict objectForKey:@"create_date"] forKey:@"create_date"];
    [object setDateValue:[dict objectForKey:@"update_date"] forKey:@"update_date"];
    [object setDateValue:[dict objectForKey:@"delete_date"] forKey:@"delete_date"];
    [object setNumberValue:[dict objectForKey:@"id"] forKey:@"id"];
    [object setStringValue:[dict objectForKey:@"name"] forKey:@"name"];
    [object setStringValue:[dict objectForKey:@"photo"] forKey:@"photo"];
    [object setNumberValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
    [object setStringValue:[memberList componentsJoinedByString:@","] forKey:@"members"];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save group: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)setBlockedGroup:(id)data forObject:(NSManagedObject *)object
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"BlockedGroups" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    [object setDateValue:[dict objectForKey:@"create_date"] forKey:@"create_date"];
    [object setDateValue:[dict objectForKey:@"update_date"] forKey:@"update_date"];
    [object setDateValue:[dict objectForKey:@"delete_date"] forKey:@"delete_date"];
    [object setNumberValue:[dict objectForKey:@"id"] forKey:@"id"];
    [object setStringValue:[dict objectForKey:@"name"] forKey:@"name"];
    [object setStringValue:[dict objectForKey:@"photo"] forKey:@"photo"];
    [object setNumberValue:[dict objectForKey:@"user_id"] forKey:@"user_id"];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save group: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

- (BOOL)addGroupMembers:(NSNumber *)group_id withDictionary:(id)data
{
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrData = (NSArray *)data;
    NSInteger dataCount = [arrData count];
    for (int i = 0; i < dataCount; i++) {
        if (![self setGroupMember:group_id withDictionary:[arrData objectAtIndex:i] forObject:nil]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)addGroupMember:(NSNumber *)group_id withDictionary:(id)data
{
    return [self setGroupMember:group_id withDictionary:data forObject:nil];
}

- (BOOL)setGroupMember:(NSNumber *)group_id withDictionary:(id)data forObject:(NSManagedObject *)object
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Group_members" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dict = (NSDictionary *)data;
    [object setNumberValue:group_id forKey:@"group_id"];
    [object setStringValue:[dict objectForKey:@"photo"] forKey:@"photo"];
    [object setNumberValue:[dict objectForKey:@"user"] forKey:@"user_id"];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save member: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

#pragma mark - Products

- (BOOL)addProducts:(id)data {
    if (![data isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *arrProducts = (NSArray *)data;
    
    for (int i = 0; i < [arrProducts count]; i++) {
        NSDictionary *dictProd = [arrProducts objectAtIndex:i];
        
        NSManagedObject *objectProd = [NSEntityDescription insertNewObjectForEntityForName:@"Products" inManagedObjectContext:[self managedObjectContext]];
        
        [objectProd setDateValue:[dictProd objectForKey:@"create_date"] forKey:@"create_date"];
        [objectProd setDateValue:[dictProd objectForKey:@"update_date"] forKey:@"update_date"];
        [objectProd setNumberValue:[dictProd objectForKey:@"id"] forKey:@"id"];
        [objectProd setStringValue:[dictProd objectForKey:@"description"] forKey:@"descript"];
        [objectProd setNumberValue:[dictProd objectForKey:@"purchased"] forKey:@"purchased"];
        [objectProd setStringValue:[dictProd objectForKey:@"name"] forKey:@"name"];
        [objectProd setStringValue:[dictProd objectForKey:@"ios_product_id"] forKey:@"ios_product_id"];
        if ([[dictProd objectForKey:@"purchased"] intValue] == 1) {
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:[dictProd objectForKey:@"ios_product_id"]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        NSArray *arrContent = [dictProd objectForKey:@"content"];
        
        for (int i = 0; i < [arrContent count]; i++) {
            NSDictionary *dictCont = [arrContent objectAtIndex:i];
            
            NSManagedObject *objectCont = [NSEntityDescription insertNewObjectForEntityForName:@"Products_content" inManagedObjectContext:[self managedObjectContext]];
            
            [objectCont setDateValue:[dictCont objectForKey:@"create_date"] forKey:@"create_date"];
            [objectCont setDateValue:[dictCont objectForKey:@"update_date"] forKey:@"update_date"];
            [objectCont setNumberValue:[dictCont objectForKey:@"content_type_id"] forKey:@"content_type_id"];
            //>---------------------------------------------------------------------------------------------------
            //>     I'm doing a trick here: if user is an on iPhone 5, then save the url from "iphone_5data"
            //>     instead of the one from "data"
            //>---------------------------------------------------------------------------------------------------
            if ([Utils isiPhone5])
            {
                [objectCont setStringValue:[dictCont objectForKey:@"iphone_5data"] forKey:@"data"];
            }
            else
            {
                [objectCont setStringValue:[dictCont objectForKey:@"data"] forKey:@"data"];
            }
            //[objectCont setStringValue:[dictCont objectForKey:@"iphone_5data"] forKey:@"iphone_5data"];
            [objectCont setNumberValue:[dictCont objectForKey:@"product_id"] forKey:@"product_id"];
        }
        NSError *error;
        if (![[self managedObjectContext] save:&error]) {
            DLog(@"Could not save product: %@", [error localizedDescription]);
            return NO;
        }
    }
    return YES;
}

- (BOOL)setProduct:(id)data forObject:(NSManagedObject *)object
{
    if (![data isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (object == nil) {
        object = [NSEntityDescription insertNewObjectForEntityForName:@"Products" inManagedObjectContext:[self managedObjectContext]];
    }
    
    NSDictionary *dictProd = (NSDictionary *)data;
    
    [object setDateValue:[dictProd objectForKey:@"create_date"] forKey:@"create_date"];
    [object setDateValue:[dictProd objectForKey:@"update_date"] forKey:@"update_date"];
    [object setNumberValue:[dictProd objectForKey:@"id"] forKey:@"id"];
    [object setStringValue:[dictProd objectForKey:@"description"] forKey:@"descript"];
    [object setNumberValue:[dictProd objectForKey:@"purchased"] forKey:@"purchased"];
    [object setStringValue:[dictProd objectForKey:@"name"] forKey:@"name"];
    [object setStringValue:[dictProd objectForKey:@"ios_product_id"] forKey:@"ios_product_id"];
    if ([[dictProd objectForKey:@"purchased"] intValue] == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:[dictProd objectForKey:@"ios_product_id"]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSArray *arrContent = [dictProd objectForKey:@"content"];
    for (int i = 0; i < [arrContent count]; i++) {
        NSDictionary *dictCont = [arrContent objectAtIndex:i];
        
        NSManagedObject *objectCont = [NSEntityDescription insertNewObjectForEntityForName:@"Products_content" inManagedObjectContext:[self managedObjectContext]];
        
        [objectCont setDateValue:[dictCont objectForKey:@"create_date"] forKey:@"create_date"];
        [objectCont setDateValue:[dictCont objectForKey:@"update_date"] forKey:@"update_date"];
        [objectCont setNumberValue:[dictCont objectForKey:@"content_type_id"] forKey:@"content_type_id"];
        
        //>---------------------------------------------------------------------------------------------------
        //>     I'm doing a trick here: if user is an on iPhone 5, then save the url from "iphone_5data"
        //>     instead of the one from "data"
        //>---------------------------------------------------------------------------------------------------
        if ([Utils isiPhone5])
        {
            [objectCont setStringValue:[dictCont objectForKey:@"iphone_5data"] forKey:@"data"];
        }
        else
        {
            [objectCont setStringValue:[dictCont objectForKey:@"data"] forKey:@"data"];
        }
        [objectCont setNumberValue:[dictCont objectForKey:@"product_id"] forKey:@"product_id"];
        [objectCont setStringValue:[dictCont objectForKey:@"name"] forKey:@"name"];
        [objectCont setNumberValue:[dictCont objectForKey:@"id"] forKey:@"id"];
    }
    
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        DLog(@"Could not save product: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            DLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
        } 
    }
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    [__managedObjectContext setUndoManager:nil];
    
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TongueTango" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationLibraryDirectory] URLByAppendingPathComponent:@"TongueTango.sqlite"];
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
         [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        return [self persistentStoreCoordinator];
    }
    
    //DLog(@"Databse is at:%@", [storeURL absoluteString]);
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationLibraryDirectory
{
    
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - delete database objects

- (void)cleanDatabase
{
    [self deleteAll:@"Message_threads" Conditions:@""];
    [self deleteAll:@"Messages" Conditions:@""];
    [self deleteAll:@"Groups" Conditions:@""];
    [self deleteAll:@"People" Conditions:@""];
    [self deleteAll:@"BlockedGroups" Conditions:@""];
    [self deleteAll:@"BlockedPeople" Conditions:@""];
    
    
}

@end
