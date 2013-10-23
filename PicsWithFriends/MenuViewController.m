//
//  MenuViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "MenuViewController.h"
#import "GameViewController.h"
#import "MenuTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "Constants.h"

@interface MenuViewController () <UIActionSheetDelegate, FBFriendPickerDelegate, FBViewControllerDelegate>

@end

@implementation MenuViewController
@synthesize tableView;
@synthesize games, invitedFriendsCounter, gamesCounter;
@synthesize isLoading;


// Ideas
// Display who invited you to the game (or basically who created it) - this way the user knows who sent the invite even if they did not receive it from facebook

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES animated:NO];
    self.navigationController.navigationBar.hidden = NO;
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(queryGames) userInfo:nil repeats:YES];

}

- (void) viewDidAppear:(BOOL)animated {

    self.isLoading = NO;
    [self queryGames];

    
}

- (void) queryGames {
    
    NSLog(@"queryGames");
    
    if (!self.isLoading) {
        
        self.isLoading = YES;
    
        PFQuery *queryByUser = [PFQuery queryWithClassName:kParseClassGameUser]; // Query by Current User
        [queryByUser whereKey:@"user" equalTo:[PFUser currentUser]];
        
        PFQuery *queryByFacebookId = [PFQuery queryWithClassName:kParseClassGameUser];
        [queryByFacebookId whereKey:@"facebookId" equalTo:[[PFUser currentUser] objectForKey:@"facebookId"]]; // Query by FacebookId is current user is not set yet
         
        PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryByUser, queryByFacebookId, nil]];
        [query includeKey:@"game"];
        [query orderByDescending:@"createdAt"];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) { //Query GameUsers for Current User
            
            if (error) {
                
                NSLog(@"%@", [error localizedDescription]);
                
                self.isLoading = NO;
            }
            
            self.games = [objects mutableCopy];
            self.gamesCounter = 0;
            
            for (PFObject *gameUser in self.games) {
                
                PFObject *game = [gameUser objectForKey:@"game"];
                
                PFQuery *query = [PFQuery queryWithClassName:kParseClassGameUser];
                [query whereKey:@"game" equalTo:game];
                
                // Query Game Users for the game
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) { //Query GameUser for each Game
                    
                    if (error) {
                        
                        NSLog(@"%@", [error localizedDescription]);
                        
                        self.isLoading = NO;
                    }
                   
                    NSArray *gameUsers = objects;
                    
                    if (gameUsers.count) {
                        
                        // Iterate through each game object, check the id
                        for (int i = 0; i < self.games.count; i++) {
                            
                            PFObject *tmpGameUser = [self.games objectAtIndex:i];
                            PFObject *tmpGame = [tmpGameUser objectForKey:@"game"];
                            
                            if ([tmpGame.objectId isEqualToString:game.objectId]) {
                                
                                [[self.games objectAtIndex:i] setValue:gameUsers forKey:@"players"];
                            
                            }
                            
                        }
                        
                        
                            
                        self.gamesCounter = 0;
                        // Query the current round to get the current dealer
                        PFQuery *queryRound = [PFQuery queryWithClassName:kParseClassRound];
                        [queryRound whereKey:@"game" equalTo:game];
                        [queryRound includeKey:@"dealer"];
                        [queryRound orderByDescending:@"createdAt"];
                        [queryRound setLimit:1];
                        
                        [queryRound findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *errror) { // Query current round for each Game
                            
                            if (error) {
                                
                                NSLog(@"%@", [error localizedDescription]);
                                
                                self.isLoading = NO;
                            }
                            
                            if (objects.count) {
                                
                                PFObject *currentRound = [objects objectAtIndex:0];
                                PFObject *currentRoundDealer = [currentRound objectForKey:@"dealer"];
                                
                                // Iterate through each game object, check the id
                                for (int i = 0; i < self.games.count; i++) {
                                    
                                    PFObject *tmpGameUser = [self.games objectAtIndex:i];
                                    PFObject *tmpGame = [tmpGameUser objectForKey:@"game"];
                                    
                                    if ([tmpGame.objectId isEqualToString:game.objectId]) {
                                        
                                        [[self.games objectAtIndex:i] setValue:currentRoundDealer forKey:@"dealer"];
                                        
                                    }
                                    
                                }
                                
                                self.gamesCounter++;
                                if (self.gamesCounter == self.games.count) {
                                 
                                    NSLog(@"%@", self.games);
                                    self.isLoading = NO;
                                    [self.tableView reloadData];
                                    
                                    
                                }
                                
                                
                                
                            }
                            
                            
                            
                        }];
                        
                    }
                        
                        
                    
                    
                    
                }];
                
            }
            
        }];
        
    }


}

- (IBAction)optionsButtonTouched:(id)sender {
    
    [self displayOptionsActionSheet];
    
}

- (void) displayOptionsActionSheet {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Logout", @"Refresh", nil];
    [actionSheet showInView:self.view];
    
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        
        case 0: // Logut
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        
        case 1:
            [self queryGames];
            break;
            
        default:
            break;
    }
    
}

#pragma mark - Table view data sourc

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.games.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    MenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFObject *gameUser = [self.games objectAtIndex:indexPath.row];
    PFObject *game = [gameUser objectForKey:@"game"];
    PFObject *gameDealer = [[self.games objectAtIndex:indexPath.row] objectForKey:@"dealer"];
    NSString *facebookId = [gameDealer objectForKey:@"facebookId"];
    
    NSArray *players = [[self.games objectAtIndex:indexPath.row] objectForKey:@"players"];
    
    cell.labelDealer.text = [NSString stringWithFormat:@"%@ (D)", [gameDealer objectForKey:@"name"]];
    cell.labelOtherPlayers.text = [self getPlayersStringFromPlayers:players];
    
    NSString *profilePictureUrl = [NSString stringWithFormat:@"%@/%@/picture?%@", kFacebookGraph, facebookId, kFacebookGraphPictureSize100x100];
    [cell.imageView setImageWithURL:[NSURL URLWithString:profilePictureUrl] placeholderImage:[UIImage imageNamed:@"facebook_profile"]];
    
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.isLoading) {
            
        PFObject *gameUser = [self.games objectAtIndex:indexPath.row];
        PFObject *game = [gameUser objectForKey:@"game"];
        
        [self pushToGameView:game];
        
        
    }

}

- (NSString*) getPlayersStringFromPlayers:(NSArray*)players {
    
    return [NSString stringWithFormat:@"%d other players", (players.count - 1)];
    
}

- (void) pushToGameView:(PFObject*)game {
    
    GameViewController *gameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"game"];
    gameViewController.game = game;
    [self.navigationController pushViewController:gameViewController animated:YES];

}

- (IBAction) createGameButtonHandler:(id)sender {
    
    [self showFacebookFriendsSelector];
    
}

- (void) createGameWtihFriends:(NSArray*)friends {

    NSLog(@"Creating Game ...");
    
    self.invitedFriendsCounter = 0;
    
    // Create Game object and save
    PFObject *game = [PFObject objectWithClassName:kParseClassGame];
    [game saveInBackgroundWithBlock:^(BOOL success, NSError *error) {

        if (success) {
            
            NSLog(@"Game Created");
            
            //self.createdGame = game;
        
            // Add current user to GameUser
            PFObject *gameUser = [PFObject objectWithClassName:kParseClassGameUser];
            [gameUser setObject:[NSNumber numberWithInt:0] forKey:@"score"];
            [gameUser setObject:[NSNumber numberWithInt:1] forKey:@"tablePosition"];
            [gameUser setObject:game forKey:@"game"];
            [gameUser setObject:[PFUser currentUser] forKey:@"user"];
            [gameUser setObject:[[PFUser currentUser] objectForKey:@"name"] forKey:@"name"];
            [gameUser setObject:[[PFUser currentUser] objectForKey:@"facebookId"] forKey:@"facebookId"];
            
            // create Round object
            PFObject *round = [PFObject objectWithClassName:kParseClassRound];
            
            // Add current user to as the dealer
            [round setObject:gameUser forKey:@"dealer"];
            [round setObject:game forKey:@"game"];
            [round saveInBackground]; // Save the initial round
            
            [gameUser saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    [self sendFacebookRequestToFriends:friends];
                    
                    NSLog(@"Dealer Added");
                
                    int tablePosition = 1;
                    // Iterate through selected friends and add them to GameUser.
                    for (NSDictionary *friend in friends) {
                        
                        tablePosition++;
                        
                        PFObject *invitedGameUser = [PFObject objectWithClassName:kParseClassGameUser];
                        
                        [invitedGameUser setObject:[NSNumber numberWithInt:0] forKey:@"score"];
                        [invitedGameUser setObject:[NSNumber numberWithInt:tablePosition] forKey:@"tablePosition"]; // Set friend table position
                        [invitedGameUser setObject:game forKey:@"game"];
                        
                        NSString *facebookId = [friend objectForKey:@"id"];
                        NSString *facebookName = [friend objectForKey:@"name"];
                        
                        [invitedGameUser setObject:facebookId forKey:@"facebookId"];
                        [invitedGameUser setObject:facebookName forKey:@"name"];
                        
                        NSLog(@"Check FacebookId: %@", facebookId);
                        
                        PFQuery *queryUser = [PFUser query];
                        [queryUser whereKey:@"facebookId" containsString:facebookId];
                        
                        [queryUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            
                            NSLog(@"User Objects: %@", objects);
                        
                            if (objects.count) { // facebookId found
                                
                                NSLog(@"Found FacebookId: %@", facebookId);
                                
                                PFUser *user = [objects objectAtIndex:0];
                                [invitedGameUser setObject:user forKey:@"user"];
                                
                                PFQuery *pushQuery = [PFInstallation query];
                                [pushQuery whereKey:@"user" equalTo:user];
                                NSString *message = [NSString stringWithFormat:@"%@ invited you to a game", facebookName];
                                [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:message];
                                
                            }
                
                            [invitedGameUser saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                               
                                if (success) {
                                    
                                    self.invitedFriendsCounter++;
                                    
                                    NSLog(@"invitedFriendsCount: %d", self.invitedFriendsCounter);
                                    
                                    if (self.invitedFriendsCounter == friends.count) {
                                        
                                        NSLog(@"pushing game id %@", game.objectId);
                                        
                                        [self pushToGameView:game];
                                    
                                    }
                                    
                                }
                                
                            }];
                            
                        }];
                        
                    }
                
                } else {
                    
                    if (error) {
                        
                        NSLog(@"%@", [error localizedDescription]);
                    
                    }
                
                }
                
                
            }];

        
        } else {
            
            if (error) {
                
                NSLog(@"%@", [error localizedDescription]);
            }
            
        }
        
    }];

}

- (void) showFacebookFriendsSelector {
    
    FBFriendPickerViewController *friendsPicker = [[FBFriendPickerViewController alloc] init];
    friendsPicker.delegate = self;
    [friendsPicker loadData];
    [self presentViewController:friendsPicker animated:YES completion:nil];

}

- (void) friendPickerViewController:(FBFriendPickerViewController *)friendPicker handleError:(NSError *)error {
    
    if (error) {
        
        NSLog(@"%@", [error localizedDescription]);
    
    }

}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    
    FBFriendPickerViewController *friendPicker = (FBFriendPickerViewController*)sender;
    
    NSLog(@"%@", friendPicker.selection);
    
    if (friendPicker.selection.count > 1 && friendPicker.selection.count < 8) {
        
        [self createGameWtihFriends:friendPicker.selection];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else if (friendPicker.selection.count < 2) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Need more people" message:@"You must have at least 3 people in a game" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
    } else if (friendPicker.selection.count > 7) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Too many people" message:@"You cannot have more than 8 people in a game" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
    }
    

}

- (void) facebookViewControllerCancelWasPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void) sendFacebookRequestToFriends:(NSArray*)friends {
    
    NSMutableArray *arrayFbIds = [NSMutableArray new];
    for (NSDictionary *friend in friends) {
        
        NSString *fbId = [friend objectForKey:@"id"];
        [arrayFbIds addObject:fbId];
        
    }
    
    NSString *friendIds = [arrayFbIds componentsJoinedByString:@","];
    
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:friendIds, @"to", nil];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:@"Please join my game."
                                                    title:nil
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          // Case A: Error launching the dialog or sending request.
                                                          NSLog(@"Error sending request.");
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // Case B: User clicked the "x" icon
                                                              NSLog(@"User canceled request.");
                                                          } else {
                                                              NSLog(@"Request Sent.");
                                                          }
                                                      }}];
    
    
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
