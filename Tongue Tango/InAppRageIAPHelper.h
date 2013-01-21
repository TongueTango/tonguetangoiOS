//
//  InAppRageIAPHelper.h
//  InAppRage
//
//  Created by Ray Wenderlich on 2/28/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAPHelper.h"

@interface InAppRageIAPHelper : IAPHelper {

}

@property (strong, nonatomic) NSSet *productIDs;

- (id)initwithProdID:(id)prodIDs;

@end
