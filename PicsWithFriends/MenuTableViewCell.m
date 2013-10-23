//
//  MenuTableViewCell.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/17/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "MenuTableViewCell.h"

@implementation MenuTableViewCell
@synthesize labelDealer, labelOtherPlayers, imageView;

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
