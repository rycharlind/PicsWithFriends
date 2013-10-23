//
//  MenuTableViewCell.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/17/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelDealer;
@property (weak, nonatomic) IBOutlet UILabel *labelOtherPlayers;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
