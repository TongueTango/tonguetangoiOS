//
//  InAppRageIAPHelper.m
//  InAppRage
//
//  Created by Ray Wenderlich on 2/28/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "InAppRageIAPHelper.h"

@implementation InAppRageIAPHelper

@synthesize productIDs;

- (id)initwithProdID:(id)prodIDs {
    
    id arrProds = [self initWithProductIdentifiers:prodIDs];            
    
    return arrProds;
}

- (id)init {
    return self;
}

@end
