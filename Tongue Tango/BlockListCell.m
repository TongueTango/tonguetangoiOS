//
//  BlockListCell.m
//  Tongue Tango
//
//  Created by Adnan@Sohail on 9/22/12.
//  Copyright (c) 2012 Tongue Tango. All rights reserved.
//

#import "BlockListCell.h"

@implementation BlockListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
