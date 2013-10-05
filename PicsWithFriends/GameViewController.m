//
//  GameViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "GameViewController.h"
#import "Constants.h"

@interface GameViewController ()

@end

@implementation GameViewController
@synthesize game;
@synthesize buttonWordOne, buttonWordTwo, buttonWordThree, buttonWordFour, buttonWordFive;
@synthesize buttonAction;

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
    
    [self queryRound];
}

- (void) queryRound {
    
    PFQuery *queryRound = [PFQuery queryWithClassName:kParseClassRound];
    [queryRound whereKey:@"game" equalTo:self.game];
    [queryRound orderByDescending:@"createdAt"];
    [queryRound setLimit:1];
    
    [queryRound findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        NSLog(@"round: %@", objects);
        
    }];
    
}

- (IBAction) wordButtonTouchedHandler:(id)sender {
    
    
    
}

- (IBAction) actionButtonTouchedHandler:(id)sender {
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
