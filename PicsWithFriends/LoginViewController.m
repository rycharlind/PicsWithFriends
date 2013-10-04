//
//  LoginViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 9/30/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "MenuViewController.h"
#import "Constants.h"

@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize buttonLogin;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
    if ([self userLoggedIn]) {
        
        [self activeFacebookSession];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    
    [self toggleLoginButtonTitle];

}

- (IBAction) gamesButtonTouchHandler:(id)sender {
    
    if ([self userLoggedIn]) {
        
        [self pushToMenu];
    
    }
}

- (IBAction)loginButtonTouchHandler:(id)sender {
    
    if ([self userLoggedIn]) {
    
        [self logout];
        
    } else {
        
        [self login];
    }

}

- (void) login {
    
    // The permissions requested from the user
    NSArray *permissionsArray = @[@"publish_actions"];
    
    [PFFacebookUtils initializeFacebook];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        //[_activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        
        } else if (user.isNew) {
            
            NSLog(@"User with facebook signed up and logged in!");
            
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                
                if (!error) {
                    
                    // Store the current user's Facebook ID on the user
                    [[PFUser currentUser] setObject:[result objectForKey:@"id"] forKey:@"facebookId"];
                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                        
                        [self updateGameFacebookIdsWithUser];
                        
                    }];
                
                }
            
            }];
            
            
            
            [self activeFacebookSession];
            
            [self pushToMenu];
        
            
        } else {
            
            NSLog(@"User with facebook logged in!");
            
            [self activeFacebookSession];
            
            [self pushToMenu];
        }
        
    }];
    
}

- (void) updateGameFacebookIdsWithUser {
    
    NSLog(@"update fbIDs");
    
    PFQuery *queryGameUser = [PFQuery queryWithClassName:kParseClassGameUser];
    
    [queryGameUser whereKey:@"facebookId" equalTo:[[PFUser currentUser] objectForKey:@"facebookId"]];
    
    [queryGameUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        for (PFObject *gameUser in objects) {
            
            PFRelation *userRelation = [gameUser relationforKey:@"user"];
            [userRelation addObject:[PFUser currentUser]];
            
            //[gameUser setObject:userRelation forKey:@"user"];
            [gameUser saveInBackground];
            
        }
        
    }];
    
}

- (void) toggleLoginButtonTitle {
    
    if ([self userLoggedIn]) {
        
        [self.buttonLogin setTitle:@"Logout" forState:UIControlStateNormal];
    
    } else {
        
        [self.buttonLogin setTitle:@"Login" forState:UIControlStateNormal];
    
    }
    
}

- (BOOL) userLoggedIn {
    
    if ([PFUser currentUser] && // Check if a user is cached
        [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) // Check if user is linked to Facebook
    {
        NSLog(@"User is logged in.");
        return YES;
    }
    
    return NO;
}

- (void) activeFacebookSession {
    
    if (!FBSession.activeSession.isOpen) {
        // if the session is closed, then we open it here, and establish a handler for state changes
        [FBSession.activeSession openWithCompletionHandler:^(FBSession *session,
                                                             FBSessionState state,
                                                             NSError *error) {
            switch (state) {
                case FBSessionStateClosedLoginFailed:
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:error.localizedDescription
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
                    break;
                default:
                    break;
            }
        }];
    }
}


- (void) pushToMenu {
    
    MenuViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"menu"];
    [self.navigationController pushViewController:viewController animated:YES];
    
}

- (void) logout {
    
    [PFUser logOut]; // Log out
    
    [self toggleLoginButtonTitle];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
