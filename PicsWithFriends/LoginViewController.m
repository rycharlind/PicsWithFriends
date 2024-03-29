//
//  LoginViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 9/30/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "MenuViewController.h"
#import "Constants.h"

@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize buttonLogin, buttonGames, gameUsersCounter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.hidden = YES;
    
    if ([self userLoggedIn]) {
        
        NSLog(@"LoginView - User Logged In");
        
        [self activeFacebookSession];
        [self pushToMenu];
        
    }

}

- (void) viewDidAppear:(BOOL)animated {
    
    
    if ([self userLoggedIn]) {
        
        [self updateUIControlsForIsLoggedIn:YES];
    
    } else {
        
        [self updateUIControlsForIsLoggedIn:NO];
        
    }

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
    NSArray *permissionsArray = @[@"user_about_me"];
    
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
            
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation setDeviceTokenFromData:appDelegate.deviceToken];
            [currentInstallation setObject:user forKey:@"user"];
            [currentInstallation saveInBackground];
            
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                
                if (!error) {
                    
                    // Store the current user's Facebook ID on the user
                    [[PFUser currentUser] setObject:[result objectForKey:@"id"] forKey:@"facebookId"];
                    [[PFUser currentUser] setObject:[result objectForKey:@"name"] forKey:@"name"];
                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                        
                        [self activeFacebookSession];
                        [self updateUIControlsForIsLoggedIn:YES];
                        [self pushToMenu];
                        
                        
                    }];
                
                } else {
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errir" message:[error localizedFailureReason] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alertView show];
                }
            
            }];
        
            
        } else {
            
            NSLog(@"User with facebook logged in!");
            
            [self activeFacebookSession];
            [self updateUIControlsForIsLoggedIn:YES];
            [self pushToMenu];
            
        }
        
    }];
    
}

- (void) updateUIControlsForIsLoggedIn:(BOOL)isLoggedIn {
    
    if (isLoggedIn) {
        
        [self.buttonLogin setTitle:@"Logout" forState:UIControlStateNormal];
        self.buttonGames.hidden = NO;
        self.imageViewProfPic.hidden = NO;
        
        [self getMeFacebookInfo];
    
    } else {
        
        [self.buttonLogin setTitle:@"Login" forState:UIControlStateNormal];
        self.buttonGames.hidden = YES;
        self.imageViewProfPic.hidden = YES;
        self.imageViewProfPic.image = nil;
        self.navigationItem.title = @"Log In with Facebook";
    
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

- (void) getMeFacebookInfo {
    
    // Send request to Facebook
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        // handle response
        if (!error) {
            
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            [self.imageViewProfPic setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]]];
            
            if (userData[@"name"]) {
                self.navigationItem.title = userData[@"name"];
            }
            
        
        }
    
    }];

}


- (void) pushToMenu {
    
    MenuViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"menu"];
    [self.navigationController pushViewController:viewController animated:YES];
    
}

- (void) logout {
    
    [PFUser logOut]; // Log out

    [self updateUIControlsForIsLoggedIn:NO];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
