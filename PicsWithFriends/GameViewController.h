//
//  GameViewController.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Constants.h"

@interface GameViewController : UIViewController

@property (strong, nonatomic) PFObject *game;
@property (strong, nonatomic) NSArray *gameUsers;
@property (strong, nonatomic) PFObject *currentGameUser;
@property (strong, nonatomic) NSArray *currentGameUserWords;
@property (strong, nonatomic) PFObject *currentRound;
@property (strong, nonatomic) NSArray *currentRoundWordsSubmitted;
@property (strong, nonatomic) PFObject *selectedWord;
@property (strong, nonatomic) PFObject *currentGameUserWinner;

@property int roundWordsCounter;

@property Action nextAction;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonAction;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction) actionButtonTouchedHandler:(id)sender;

- (IBAction)refresh:(id)sender;

@end
