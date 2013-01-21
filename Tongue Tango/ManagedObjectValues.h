//
//  ManagedObjectValues.h
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/8/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSManagedObject (ManagedObjectValues)

- (void)setDateValue:(id)value forKey:(NSString *)key;
- (void)setNumberValue:(id)value forKey:(NSString *)key;
- (void)setStringValue:(id)value forKey:(NSString *)key;

@end

