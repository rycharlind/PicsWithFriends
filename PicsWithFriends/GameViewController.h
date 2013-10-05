//
//  GameViewController.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface GameViewController : UIViewController

@property (strong, nonatomic) PFObject *game;

@property (weak, nonatomic) IBOutlet UIButton *buttonWordOne;
@property (weak, nonatomic) IBOutlet UIButton *buttonWordTwo;
@property (weak, nonatomic) IBOutlet UIButton *buttonWordThree;
@property (weak, nonatomic) IBOutlet UIButton *buttonWordFour;
@property (weak, nonatomic) IBOutlet UIButton *buttonWordFive;

@property (weak, nonatomic) IBOutlet UIButton *buttonAction;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction) wordButtonTouchedHandler:(id)sender;
- (IBAction) actionButtonTouchedHandler:(id)sender;

@end
