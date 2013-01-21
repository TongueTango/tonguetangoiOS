//
//  SPDeepCopy.h
//
//  Created by Sherm Pendley on 3/15/09.
//
// Deep -copy and -mutableCopy methods for NSArray and NSDictionary

@interface NSArray (SPDeepCopy)

- (NSArray*) deepCopy;
- (NSMutableArray*) mutableDeepCopy;

@end

@interface NSDictionary (SPDeepCopy)

- (NSDictionary*) deepCopy;
- (NSMutableDictionary*) mutableDeepCopy;

@end