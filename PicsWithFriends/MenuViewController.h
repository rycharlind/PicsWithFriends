//
//  MenuViewController.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MenuViewController : UITableViewController

@property (strong, nonatomic) NSArray *games;

@property BOOL isLoading;

@property int invitedFriendsCounter;


- (IBAction)optionsButtonTouched:(id)sender;

@end
