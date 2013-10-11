//
//  MenuViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "MenuViewController.h"
#import "GameViewController.h"
#import "Constants.h"

@interface MenuViewController () <UIActionSheetDelegate, FBFriendPickerDelegate, FBViewControllerDelegate>

@end

@implementation MenuViewController
@synthesize games, invitedFriendsCounter;
@synthesize isLoading;


// Ideas
// Display who invited you to the game (or basically who created it) - this way the user knows who sent the invite even if they did not receive it from facebook

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void) viewDidAppear:(BOOL)animated {
    
    [self queryGames];
    
}

- (void) queryGames {
    
    self.isLoading = YES;
    
    self.games = [NSMutableArray new];
    
    PFQuery *queryByUser = [PFQuery queryWithClassName:kParseClassGameUser]; // Query by Current User
    [queryByUser whereKey:@"user" equalTo:[PFUser currentUser]];
    
    PFQuery *queryByFacebookId = [PFQuery queryWithClassName:kParseClassGameUser];
    [queryByFacebookId whereKey:@"facebookId" equalTo:[[PFUser currentUser] objectForKey:@"facebookId"]]; // Query by FacebookId is current user is not set yet
     
    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryByUser, queryByFacebookId, nil]];
    [query includeKey:@"game"];
    [query orderByDescending:@"createdAt"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        self.games = objects;
        
        [self.tableView reloadData];
        
        self.isLoading = NO;
        
    }];

}

- (IBAction)optionsButtonTouched:(id)sender {
    
    [self displayOptionsActionSheet];
    
}

- (void) displayOptionsActionSheet {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Logout", @"Create Game", nil];
    [actionSheet showInView:self.view];
    
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        
        case 0: // Logut
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;

        case 1:
            [self showFacebookFriendsSelector];
        default:
            break;
    }
    
}

#pragma mark - Table view data sourc

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        
        return 1;
    }
    
    return self.games.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        
        cell.textLabel.text = @"Create Game";
    
    } else {
        
        PFObject *gameUser = [self.games objectAtIndex:indexPath.row];
        PFObject *game = [gameUser objectForKey:@"game"];
        
        cell.textLabel.text = [NSString stringWithFormat:@"Game: %@", game.objectId];
    
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.isLoading) {
    
        if (indexPath.section == 0) {
            
            [self showFacebookFriendsSelector]; // Callback method from the Facebook Friend picker will call the createGameWithFriends method
            
        } else {
            
            PFObject *gameUser = [self.games objectAtIndex:indexPath.row];
            PFObject *game = [gameUser objectForKey:@"game"];
            
            [self pushToGameView:game];
            
        }
        
    }

}

- (void) pushToGameView:(PFObject*)game {
    
    GameViewController *gameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"game"];
    gameViewController.game = game;
    [self.navigationController pushViewController:gameViewController animated:YES];

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
                                [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:@"You have been invited to play"];
                                
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
    
    [self createGameWtihFriends:friendPicker.selection];
    
    [self dismissViewControllerAnimated:YES completion:nil];

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
