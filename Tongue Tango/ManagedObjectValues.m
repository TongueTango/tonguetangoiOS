//
//  ManagedObjectValues.m
//  Tongue Tango
//
//  Created by Ryan Bigger on 3/8/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "ManagedObjectValues.h"

static NSDateFormatter *sUserVisibleDateFormatter;

@implementation NSManagedObject (ManagedObjectValues)

- (void)setNumberValue:(id)value forKey:(NSString *)key
{
    if ([value isKindOfClass:[NSNumber class]])
    {
        [self setValue:value forKey:key];
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber *numberFromString = [numberFormatter numberFromString:value];
        
        [self setValue:numberFromString forKey:key];
    }
    
    if ([value isKindOfClass:[NSNull class]]) {
        [self setValue:nil forKey:key];
    }
}

- (void)setDateValue:(id)value forKey:(NSString *)key
{
    if ([value isKindOfClass:[NSDate class]])
    {
        [self setValue:value forKey:key];
    }
    else
    {
        if (sUserVisibleDateFormatter == nil)
        {
            sUserVisibleDateFormatter = [[NSDateFormatter alloc] init];
            [sUserVisibleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            [sUserVisibleDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        }
        
        if ([value isKindOfClass:[NSString class]])
        {
            NSString *strValue = value;
            NSDate *dateFromString = [sUserVisibleDateFormatter dateFromString:strValue];
            [self setValue:dateFromString forKey:key];
        }
        else
        {
            [self setValue:nil forKey:key];
        }
    }
}

- (void)setStringValue:(id)value forKey:(NSString *)key
{
    if ([value isKindOfClass:[NSString class]]) {
        [self setValue:value forKey:key];
    }
    
    if ([value isKindOfClass:[NSNumber class]]) {
        NSString *stringFromNumber = [NSString stringWithFormat:@"%@", value];
        [self setValue:stringFromNumber forKey:key];
    }
    
    if ([value isKindOfClass:[NSNull class]]) {
        [self setValue:nil forKey:key];
    }
}

@end

