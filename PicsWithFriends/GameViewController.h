//
//  GameViewController.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "UzysSlideMenu.h"
#import "Constants.h"

@interface GameViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *imageWrapperView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonAction;

@property (weak, nonatomic) IBOutlet UIView *uploadImageView;
@property (weak, nonatomic) IBOutlet UILabel *labelUploadImageStatus;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewCheckmark;

@property (strong, nonatomic) PFObject *game;
@property (strong, nonatomic) NSMutableArray *gameUsers;
@property (strong, nonatomic) PFObject *currentGameUser;
@property (strong, nonatomic) NSArray *currentGameUserWords;
@property (strong, nonatomic) PFObject *currentRound;
@property (strong, nonatomic) PFObject *currentRoundDealer;
@property (strong, nonatomic) NSArray *currentRoundWordsSubmitted;
@property (strong, nonatomic) PFObject *selectedWord;
@property (strong, nonatomic) PFObject *currentGameUserWinner;

@property BOOL isLoading;

@property int roundWordsCounter;
@property Action nextAction;

- (IBAction) actionButtonTouchedHandler:(id)sender;
- (void) imageTapped:(id)sender;

@end
