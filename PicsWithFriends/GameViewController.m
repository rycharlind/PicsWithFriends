//
//  GameViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "GameViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UzysSlideMenu.h"

#define IS_IOS7 [[[UIDevice currentDevice] systemVersion] floatValue] >= 7

@interface GameViewController () <UIImagePickerControllerDelegate>

@property (nonatomic,strong) UzysSlideMenu *uzysSMenu;

@end

@implementation GameViewController
@synthesize nextAction;
@synthesize game, gameUsers, currentRound, currentGameUserWords, currentRoundWordsSubmitted, roundWordsCounter, selectedWord, currentGameUser, currentGameUserWinner;
@synthesize buttonAction;
@synthesize uzysSMenu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)refresh:(id)sender {
    
    [self getGameStatus];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.navigationController.navigationBar setBackgroundColor:[UIColor clearColor]];
    
    [self getGameStatus];
}

- (void) getGameStatus {
    
    NSLog(@"getGameStatusForGame: %@", self.game);
    
    [self queryGameUsers];
    
}

- (void) queryGameUsers {
    
    PFQuery *queryGameUsers = [PFQuery queryWithClassName:kParseClassGameUser];
    [queryGameUsers whereKey:@"game" equalTo:self.game];
    
    [queryGameUsers findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        self.gameUsers = objects;
        
        // Set the current GameUser
        for (PFObject *gameUser in self.gameUsers) {
            
            PFUser *user = [gameUser objectForKey:@"user"];
            
            if ([user.objectId isEqualToString:[[PFUser currentUser] objectId]]) {
                
                self.currentGameUser = gameUser;
                
                NSLog(@"currentGameUser: %@", self.currentGameUser);
            }
            
        }
        
        [self queryCurrentRound];
        
    }];
    
    
}

- (void) queryCurrentRound {
    
    PFQuery *queryRound = [PFQuery queryWithClassName:kParseClassRound];
    [queryRound whereKey:@"game" equalTo:self.game];
    [queryRound includeKey:@"dealer"];
    [queryRound orderByDescending:@"createdAt"];
    [queryRound setLimit:1];
    
    [queryRound findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count) {
        
            self.currentRound = [objects objectAtIndex:0];
            
            NSLog(@"currentRound: %@", self.currentRound);
            
            [self queryCurrentRoundWordsSubmitted];
        
        } else {
            
            NSLog(@"No round returned");
        
        }
        
    }];
    
}

- (void) queryCurrentRoundWordsSubmitted {
    
    PFQuery *queryRoundWords = [PFQuery queryWithClassName:kParseClassRoundWordSubmitted];
    [queryRoundWords whereKey:@"round" equalTo:self.currentRound];
    [queryRoundWords includeKey:@"gameUser"];
    [queryRoundWords includeKey:@"word"];
    
    [queryRoundWords findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSLog(@"currentRoundWordsSubmitted: %@", objects);
        
        if (objects.count) {
            
            self.currentRoundWordsSubmitted = objects;
        
        }
        
        [self updateViewForCurrentStatus];
        
    }];

}

- (void) queryWordsForCurrentGameUser {
    
    NSLog(@"queryWordsForCurrentUser");
    
    PFQuery *queryRoundWords = [PFQuery queryWithClassName:kParseClassRoundWords];
    [queryRoundWords whereKey:@"gameUser" equalTo:self.currentGameUser];
    
    [queryRoundWords findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        if (objects.count) {
            
            PFObject *roundWords = [objects objectAtIndex:0];
            
            PFRelation *wordsRelation = [roundWords relationforKey:@"words"];
            
            PFQuery *queryWords = [wordsRelation query];
            
            [queryWords findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
               
                NSLog(@"currentGameUserWords: %@", objects);
                
                if (objects.count) {
                    
                    self.currentGameUserWords = objects;
                    
                    [self addWordsMenu];
                    
                }
                
            }];
        }
        
    }];
    
    
}

- (void) updateViewForCurrentStatus {
    
    PFFile *image = [self.currentRound objectForKey:@"pic"];
    PFUser *dealerUser = [self.currentRound objectForKey:@"dealer"];
    
    NSString *currentUserId = [[PFUser currentUser] objectId];
    NSString *dealerUserId = dealerUser.objectId;
    
    
    if ([currentUserId isEqualToString:dealerUserId]) { // Current user is dealer
        
        if (image != NULL) {
            
            [self getImage:image];
            
            if (self.currentRoundWordsSubmitted.count == (self.gameUsers.count - 1)) { // Have a -1 since the dealer does not submit a word
                
                [self addAnswersToMenu];
                
                self.nextAction = SUBMITANSWER;
            
            } else {
                
                self.nextAction = WAITING;
                
            }
            
        
        } else {
            
            self.nextAction = CHOOSEPHOTO;
            
        }
    
    } else { // Current user is NOT dealer
        
        if (image != NULL) {
            
            [self getImage:image];
            
            // Check if current gameUser has submitted a word
            if (self.currentRoundWordsSubmitted.count) { // Check if any words are submitted
            
                BOOL hasWordSubmitted = NO;
                for (PFObject *wordSubmitted in self.currentRoundWordsSubmitted) {
                    
                    PFObject *gameUserWordSubmitted = [wordSubmitted objectForKey:@"gameUser"];
                    
                    if ([self.currentGameUser.objectId isEqualToString:gameUserWordSubmitted.objectId]) { // Word was submitted
                        
                        hasWordSubmitted = YES;
                    }
                    
                }
                
                if (hasWordSubmitted) {
                 
                    self.nextAction = WAITING;
                    
                } else {
                    
                    [self queryWordsForCurrentGameUser];
                    
                    self.nextAction = SUBMITWORD;
                    
                }
                
            } else { // No users have submitted any words.  Query for new words.
                
                [self queryWordsForCurrentGameUser];
                
                self.nextAction = SUBMITWORD;
                
            }
            
            
        } else {
            
            self.nextAction = WAITING;
            
        }
        
    }
    
    [self updateActionButton];
    
}

- (void) getImage:(PFFile*)image {
    
    [image getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        
        UIImage *pic = [UIImage imageWithData:data];
        [self.imageView setImage:pic];
        
    } progressBlock:^(int progress) {
        
        NSLog(@"Image Progress: %d", progress);
        
    }];
    
}

- (void) updateActionButton {
    
    switch (self.nextAction) {
        case WAITING:
            [self.buttonAction setTitle:kActionWaiting];
            break;
            
        case CHOOSEPHOTO:
            [self.buttonAction setTitle:kActionChoosePhoto];
            break;
            
        case SUBMITPHOTO:
            [self.buttonAction setTitle:kActionSubmitPhoto];
            break;
            
        case SUBMITANSWER:
            [self.buttonAction setTitle:kActionSubmitAnswer];
            break;
            
        case SUBMITWORD:
            [self.buttonAction setTitle:kActionSubmitWord];
            break;
    }
    
}

- (IBAction) actionButtonTouchedHandler:(id)sender {

    switch (self.nextAction) {
        case WAITING:
            
            break;
            
        case CHOOSEPHOTO:
            [self choosePhoto];
            break;
            
        case SUBMITPHOTO:
            [self submitPhoto];
            break;
            
        case SUBMITANSWER:
            [self submitSelectedAnswer];
            break;
            
        case SUBMITWORD:
            [self submitSelectedWord];
            break;
    
    }
    
}

#define NUMBEROFWORDS 5
- (void) createNewRound {
    
    PFQuery *gameUser = [PFQuery queryWithClassName:kParseClassGameUser];
    [gameUser whereKey:@"game" equalTo:self.game];
    [gameUser includeKey:@"user"];
    
    [gameUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        self.gameUsers = objects;
        
        // (New) Round - Game
        PFObject *round = [PFObject objectWithClassName:kParseClassRound];
        [round setObject:self.game forKey:@"game"];
        
        PFUser *currentDealer = [self.currentRound objectForKey:@"dealer"];
        PFUser *nextDealer;
        
        
        // Get the current dealer's table position
        int nextDealerTablePosition;
        for (PFObject *gameUser in self.gameUsers) {
            
            PFUser *user = [gameUser objectForKey:@"user"];
            if ([user.objectId isEqualToString:currentDealer.objectId]) {
                
                NSNumber *tablePosition = [gameUser objectForKey:@"tablePosition"];
                nextDealerTablePosition = [tablePosition intValue];
                nextDealerTablePosition++;
                
                if (nextDealerTablePosition > gameUsers.count) {
                    
                    nextDealerTablePosition = 1;
                    
                }
                
            }
            
        }
        
        // Get the next dealer
        for (PFObject *gameUser in gameUsers) {
            
            PFUser *user = [gameUser objectForKey:@"user"];
            NSNumber *tablePosition = [gameUser objectForKey:@"tablePosition"];
            int userTablePosition = [tablePosition intValue];
            
            if (userTablePosition == nextDealerTablePosition) {
                
                nextDealer = [gameUser objectForKey:@"user"];
                
            }
            
        }
        
        [round setObject:nextDealer forKey:@"dealer"];
        
        
        [round saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            
            self.currentRound = round;
            
            [self createWordsForCurrentRound];
            
        }];
        
        
    }];
    
    
}

- (void) createWordsForCurrentRound {
    
    self.roundWordsCounter = 0;
    
    // Query all words set words for next round
    PFQuery *words = [PFQuery queryWithClassName:kParseClassWord];
    [words findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSMutableArray *words = [objects mutableCopy];
        
        for (PFObject *gameUser in self.gameUsers) { // iterate through each user
            
            // RoundWords - Round
            PFObject *roundWords = [PFObject objectWithClassName:kParseClassRoundWords];
            [roundWords setObject:self.currentRound forKey:@"round"];
            
            // RoundWords - Words (Relation)
            PFRelation *wordsRelatoin = [roundWords relationforKey:@"words"];
            for (int i = 0; i < NUMBEROFWORDS; i++) {
                
                NSUInteger wordCount = words.count;
                NSUInteger randomIndex = arc4random() %  wordCount;
                [wordsRelatoin addObject:[words objectAtIndex:randomIndex]];
                [words removeObjectAtIndex:randomIndex];
                
                
            }
            
            // RoundWords - GameUser
            [roundWords setObject:gameUser forKey:@"gameUser"];
            
            [roundWords saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {
                
                    self.roundWordsCounter++;
                    
                    if (self.roundWordsCounter == self.gameUsers.count) {
                        
                        // New Round Created
                        [self getGameStatus];
                    
                    }
                    
                }
                
            }];
            
        }
        
    }];
    
}

- (void) addWordsMenu {
    
    //CGRect frame = [UIScreen mainScreen].applicationFrame;
    //self.view.frame = frame;
    
    ah__block typeof(self) blockSelf = self;
    

    NSMutableArray *tmpWorsArray = [NSMutableArray array];
    
    int tag = 0;
    for (PFObject *word in self.currentGameUserWords) {
        
        NSString *theWord = [word objectForKey:@"word"];

        UzysSMMenuItem *item = [[UzysSMMenuItem alloc] initWithTitle:theWord image:nil action:^(UzysSMMenuItem *item) {
            NSLog(@"Item: %@ menuState : %d", item , blockSelf.uzysSMenu.menuState);
            self.selectedWord = [self.currentGameUserWords objectAtIndex:tag];
            NSLog(@"Selected Word: %@", [self.selectedWord objectForKey:@"word"]);
            
        }];
        
        [tmpWorsArray addObject:item];
        item.tag = tag;
        tag++;
        
    }
    
    
    NSUInteger statusbarHeight = self.navigationController.navigationBar.frame.size.height;
    if(IS_IOS7)
        statusbarHeight += 20;
    
    
    self.uzysSMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    
    self.uzysSMenu.frame = CGRectMake(self.uzysSMenu.frame.origin.x, self.uzysSMenu.frame.origin.y+ statusbarHeight, self.uzysSMenu.frame.size.width, self.uzysSMenu.frame.size.height);
    
    [self.view addSubview:self.uzysSMenu];
    
    [self.uzysSMenu toggleMenu];
    
    
}

- (void) addAnswersToMenu {
    
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    self.view.frame = frame;
    
    ah__block typeof(self) blockSelf = self;
    
    NSMutableArray *tmpWorsArray = [NSMutableArray new];
    
    int tag = 0;
    for (PFObject *wordSubmitted in self.currentRoundWordsSubmitted) {
        
        //NSString *theWord = [word objectForKey:@"word"];
        PFObject *word = [wordSubmitted objectForKey:@"word"];
        NSString *theWord = [word objectForKey:@"word"];
        
        UzysSMMenuItem *item = [[UzysSMMenuItem alloc] initWithTitle:theWord image:nil action:^(UzysSMMenuItem *item) {
            NSLog(@"Item: %@ menuState : %d", item , blockSelf.uzysSMenu.menuState);
            self.currentGameUserWinner = [[self.currentRoundWordsSubmitted objectAtIndex:tag] objectForKey:@"gameUser"];
            NSLog(@"Selected Current Game User %@", self.currentGameUserWinner);
            
        }];
        
        [tmpWorsArray addObject:item];
        item.tag = tag;
        tag++;
        
    }
    
    
    NSUInteger statusbarHeight = self.navigationController.navigationBar.frame.size.height;
    if(IS_IOS7)
        statusbarHeight += 20;
    
    self.uzysSMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    
    self.uzysSMenu.frame = CGRectMake(self.uzysSMenu.frame.origin.x, self.uzysSMenu.frame.origin.y+ statusbarHeight, self.uzysSMenu.frame.size.width, self.uzysSMenu.frame.size.height);
    
    [self.view addSubview:self.uzysSMenu];
    
    [self.uzysSMenu toggleMenu];
}

- (void) submitSelectedWord {
    
    PFObject *roundWordSubmitted = [PFObject objectWithClassName:kParseClassRoundWordSubmitted];
    [roundWordSubmitted setObject:self.selectedWord forKey:@"word"];
    [roundWordSubmitted setObject:self.currentRound forKey:@"round"];
    [roundWordSubmitted setObject:self.currentGameUser forKey:@"gameUser"];
    
    [roundWordSubmitted saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
       
        if (success) {
            
            NSLog(@"Word Submited");
            
            [self getGameStatus];
        }
        
    }];
}

- (void) submitSelectedAnswer {
    
    [self.currentRound setObject:self.currentGameUserWinner forKey:@"winner"];
    
    [self.currentRound saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
        if (success) {
            
            NSLog(@"Answer Subbmited");
            
            // Update score value for current game user winner
            NSNumber *score = [self.currentGameUserWinner objectForKey:@"score"];
            int s = [score intValue];
            s++;
            
            [self.currentGameUserWinner setObject:[NSNumber numberWithInt:s] forKey:@"score"];
            
            [self.currentGameUserWinner saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    [self createNewRound];
                    
                }
                
            }];
            

        }
        
    }];
    
}

- (void) submitPhoto {
    
    NSLog(@"Uploading Photo ... ");
    
    NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, 0.05f);
    
    PFFile *imageFile = [PFFile fileWithData:imageData];
    
    [imageFile saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
        if (success) {
            
            [self.currentRound setObject:imageFile forKey:@"pic"];
            [self.currentRound setObject:[NSDate date] forKey:@"picSubmittedDate"];
            
            [self.currentRound saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    NSLog(@"Image Uploaded Successfully");
                    [self createWordsForCurrentRound];
                
                }
                
            }];
            
        }
    
    } progressBlock:^(int percentageDone) {
        
        NSLog(@"Image:  %d", percentageDone);
        
    
    }];
    
    
}

- (void) choosePhoto {
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];

}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        [self.imageView setImage:image];
        
        self.nextAction = SUBMITPHOTO;
        
        [self updateActionButton];
    
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
