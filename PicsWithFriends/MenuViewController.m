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
@synthesize games;

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

- (void) viewDidAppear:(BOOL)animated {
    
    [self queryGames];
    
}

- (void) queryGames {
    
    self.games = [NSMutableArray new];
    
    PFQuery *queryByUser = [PFQuery queryWithClassName:kParseClassGameUser]; // Query by Current User
    [queryByUser whereKey:@"user" equalTo:[PFUser currentUser]];
    
    PFQuery *queryByFacebookId = [PFQuery queryWithClassName:kParseClassGameUser];
    [queryByFacebookId whereKey:@"facebookId" equalTo:[[PFUser currentUser] objectForKey:@"facebookId"]]; // Query by FacebookId is current user is not set yet
     
    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryByUser, queryByFacebookId, nil]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        for (PFObject *gameUser in objects) {
            
            PFRelation *gameRelation = [gameUser relationforKey:@"game"];
            PFQuery *query = [gameRelation query];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                if (objects.count) {
                    
                    NSLog(@"add game");
                    
                    [self.games addObject:[objects objectAtIndex:0]];
                    
                    [self.tableView reloadData];
                
                }
                
            }];
            
        }
        
        
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
        
        PFObject *game = [self.games objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [NSString stringWithFormat:@"Game: %@", game.objectId];
    
    }
    
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        [self showFacebookFriendsSelector]; // Callback method from the Facebook Friend picker will call the createGameWithFriends method
        
    } else {
        
        PFObject *game = [self.games objectAtIndex:indexPath.row];
        
        GameViewController *gameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"game"];
        gameViewController.game = game;
        [self.navigationController pushViewController:gameViewController animated:YES];
        
    }

}

- (void) createGameWithFriends:(NSArray*)friends {
    
    // bug - if the user who is invited is already registered, we should create the User relationship, otherwise store the facebookId and the first time they sign up it will update the gameUser table.

    NSLog(@"Creating Game ...");
    
    // Create Game object and save
    PFObject *game = [PFObject objectWithClassName:kParseClassGame];
    [game saveInBackgroundWithBlock:^(BOOL success, NSError *error) {

        if (success) {
            
            NSLog(@"Game Created");
        
            // Add current user to GameUser
            PFObject *gameUser = [PFObject objectWithClassName:kParseClassGameUser];
            [gameUser setObject:[NSNumber numberWithInt:0] forKey:@"score"];
            [gameUser setObject:[NSNumber numberWithInt:0] forKey:@"tablePosition"];
            
            PFRelation *userRelation = [gameUser relationforKey:@"user"];
            [userRelation addObject:[PFUser currentUser]];
            
            // Add game to current user's GameUser object
            PFRelation *gameRelation = [gameUser relationforKey:@"game"];
            [gameRelation addObject:game];
            
            // create Round object
            PFObject *round = [PFObject objectWithClassName:kParseClassRound];
            
            // Add current user to as the dealer
            PFRelation *roundDealerUserRelation = [round relationforKey:@"dealerUser"];
            [roundDealerUserRelation addObject:[PFUser currentUser]];
            
            //Add game relation to the round
            PFRelation *roundGameRelation = [round relationforKey:@"game"];
            [roundGameRelation addObject:game];
            
            [round saveInBackground]; // Save the initial round
            
            [gameUser saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    [self sendFacebookRequestToFriends:friends];
                    
                    NSLog(@"Dealer Added");
                
                    int tablePosition = 0;
                    // Iterate through selected friends and add them to GameUser.
                    for (NSDictionary *friend in friends) {
                        
                        tablePosition++;
                        
                        NSString *facebookId = [friend objectForKey:@"id"];
                        
                        NSLog(@"Check FacebookId: %@", facebookId);
                        
                        PFQuery *queryUser = [PFUser query]; //[PFQuery queryWithClassName:kParseClassUser];
                        [queryUser whereKey:@"facebookId" containsString:facebookId];
                        
                        [queryUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            
                            NSLog(@"User Objects: %@", objects);
                            
                            PFObject *gameUser = [PFObject objectWithClassName:kParseClassGameUser];
                        
                            if (objects.count) { // facebookId found
                                
                                NSLog(@"Found FacebookId: %@", facebookId);
                                
                                PFUser *user = [objects objectAtIndex:0];
                                PFRelation *relation = [gameUser relationforKey:@"user"];
                                [relation addObject:user];
                                
                            } else {
                                
                                NSLog(@"Did Not Find FacebookId: %@", facebookId);
                                
                                [gameUser setObject:facebookId forKey:@"facebookId"];
                                
                            }
                            
                            [gameUser setObject:[NSNumber numberWithInt:0] forKey:@"score"];
                            [gameUser setObject:[NSNumber numberWithInt:tablePosition] forKey:@"tablePosition"]; // Set friend table position
                            
                            PFRelation *relation = [gameUser relationforKey:@"game"];
                            [relation addObject:game];
                
                            [gameUser saveInBackground];
                            
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
    
    [self createGameWithFriends:friendPicker.selection];
    
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
