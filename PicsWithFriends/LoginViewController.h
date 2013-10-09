//
//  LoginViewController.h
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 9/30/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewProfPic;
@property (weak, nonatomic) IBOutlet UILabel *labelName;

@property int gameUsersCounter;


- (IBAction) loginButtonTouchHandler:(id)sender;
- (IBAction) gamesButtonTouchHandler:(id)sender;

@end
