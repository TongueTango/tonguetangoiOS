//
//  CoreDataClass.h
//  Tongue Tango
//
//  Created by Chris Serra on 2/26/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataClass : NSObject

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (NSMutableArray *)convertToDict:(NSArray *)arrManObj;
- (NSString *)getStringValue:(id)value;

- (NSArray *)getData:(NSString *)entity Conditions:(NSString *)where Sort:(NSString *)orderBy Ascending:(BOOL)sortAscending;
- (NSArray *)searchEntity:(NSString *)entity Conditions:(NSString *)_where Sort:(NSString *)_sort Ascending:(BOOL)_ascending andLimit:(NSInteger)_limit;
- (BOOL)doesDataExist:(NSString *)entity Conditions:(NSString *)where;

- (BOOL)deleteAll:(NSString *)entity Conditions:(NSString *)where;

- (BOOL)addPeople:(id)data;
- (BOOL)addBlockedPeople:(id)data;
- (BOOL)addPerson:(id)data;
- (BOOL)setPerson:(id)data forObject:(NSManagedObject *)object;

- (BOOL)addMessageThreads:(id)data;
- (BOOL)addMessageThread:(id)data;
- (BOOL)setMessageThread:(id)data forObject:(NSManagedObject *)object;

- (BOOL)addMessages:(id)data;
- (BOOL)addMessage:(id)data;
- (BOOL)setMessage:(id)data forObject:(NSManagedObject *)object;
- (BOOL)addMessageForGroup:(NSNumber *)group_id withDictionary:(id)data;
- (BOOL)setMessageForGroup:(NSNumber *)group_id withDictionary:(id)data forObject:(NSManagedObject *)object;

- (BOOL)addGroups:(id)data;
- (BOOL)addBlockedGroups:(id)data;
- (BOOL)addGroup:(id)data;
- (BOOL)setGroup:(id)data forObject:(NSManagedObject *)object;
- (BOOL)setBlockedGroup:(id)data forObject:(NSManagedObject *)object;
- (BOOL)addGroupMembers:(NSNumber *)group_id withDictionary:(id)data;
- (BOOL)addGroupMember:(NSNumber *)group_id withDictionary:(id)data;
- (BOOL)setGroupMember:(NSNumber *)group_id withDictionary:(id)data forObject:(NSManagedObject *)object;

- (BOOL)addProducts:(id)data;
- (BOOL)setProduct:(id)data forObject:(NSManagedObject *)object;

+ (CoreDataClass *)sharedInstance;

- (void)cleanDatabase;

@end
