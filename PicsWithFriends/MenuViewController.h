//
//  MenuViewController.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MenuViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *games;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property BOOL isLoading;

@property int invitedFriendsCounter;
@property int gamesCounter;

- (IBAction)optionsButtonTouched:(id)sender;
- (IBAction) createGameButtonHandler:(id)sender;

@end
