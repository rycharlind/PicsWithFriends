//
//  GameUserTableViewCell.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/10/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameUserTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageViewProfilePicture;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelScore;

@end
