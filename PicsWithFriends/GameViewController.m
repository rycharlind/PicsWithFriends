//
//  GameViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "GameViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import "GameUserTableViewCell.h"
#import "UIImageView+AFNetworking.h"

#define IS_IOS7 [[[UIDevice currentDevice] systemVersion] floatValue] >= 7

@interface GameViewController () <UIImagePickerControllerDelegate>

@property (nonatomic,strong) UzysSlideMenu *wordsMenu;


@end

@implementation GameViewController
@synthesize tableView;
@synthesize game, gameUsers, currentRound, currentGameUserWords, currentRoundWordsSubmitted, roundWordsCounter, selectedWord, currentGameUser, currentGameUserWinner, currentRoundDealer;
@synthesize buttonAction;
@synthesize wordsMenu;
@synthesize nextAction;
@synthesize uploadImageView, labelUploadImageStatus, progressView, imageViewCheckmark;

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
    
    self.uploadImageView.layer.cornerRadius = 10.0;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.imageView addGestureRecognizer:tapGesture];
    
    self.gameUsers = [NSMutableArray new];
    
    self.wordsMenu.hidden = YES;
    
    [self getGameStatus];
}

- (void) getGameStatus {
    
    NSLog(@"getGameStatusForGame: %@", self.game);
    
    [self queryGameUsers];
    
}

- (void) queryGameUsers {
    
    PFQuery *queryGameUsers = [PFQuery queryWithClassName:kParseClassGameUser];
    [queryGameUsers whereKey:@"game" equalTo:self.game];
    [queryGameUsers orderByAscending:@"tablePosition"];
    
    [queryGameUsers findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        self.gameUsers = [objects mutableCopy];
        
        NSLog(@"gameUsers: %@", self.gameUsers);
        
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
            self.currentRoundDealer = [self.currentRound objectForKey:@"dealer"];
            
            NSLog(@"currentRound: %@", self.currentRound);
            
            
            // If current round has a winner, then it is time to create a new round (This should never happen becuase after an answer is submitted a new round is created.
            // This is just in case something goes wrong.
            PFObject *gameUserWinner = [self.currentRound objectForKey:@"winner"];
            if (gameUserWinner != NULL) {
                
                NSLog(@"Current Round has a winner - Create new round");
                [self createNewRound];
            
            } else {
                
                [self queryCurrentRoundWordsSubmitted];
                
            }
            
            
        
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
        
        
        [self getGameStatusesForEachUser];
        [self.tableView reloadData];
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
                    
                    [self showWordsMenu];
                    
                }
                
            }];
        }
        
    }];
    
}

- (void) getGameStatusesForEachUser {
    
    PFFile *image = [self.currentRound objectForKey:@"pic"];
    
    PFObject *dealer = [self.currentRound objectForKey:@"dealer"];
    
    // Iterate through each Game User
    for (int i = 0; i < self.gameUsers.count; i++) {
        
        PFObject *gameUser = [self.gameUsers objectAtIndex:i];
        NSString *status;
        
        if ([gameUser.objectId isEqualToString:dealer.objectId]) { // User is dealer
            
            if (image != NULL) { // Image is submitted
                
                if (self.currentRoundWordsSubmitted.count == (self.gameUsers.count - 1)) {
                    
                    status = @"Needs to submit an answer";
                    
                } else {
                    
                    status = @"Photo submitted";
                    
                }
            
            } else {
                
                status = @"Needs to submit a photo";
                
            }
            
        
        } else { // User is NOT dealer
            
            if (image != NULL) { // Image submitted
                
                // Check if current gameUser has submitted a word
                if (self.currentRoundWordsSubmitted.count) { // Check if any words are submitted
                    
                    BOOL hasWordSubmitted = NO;
                    for (PFObject *wordSubmitted in self.currentRoundWordsSubmitted) {
                        
                        PFObject *gameUserWordSubmitted = [wordSubmitted objectForKey:@"gameUser"];
                        
                        if ([gameUser.objectId isEqualToString:gameUserWordSubmitted.objectId]) {
                            
                            hasWordSubmitted = YES;
                        }
                        
                    }
                    
                    if (hasWordSubmitted) { // Word is submitted
                        
                        status = @"Word Submitted";
                        
                    } else { // Word is NOT submitted

                        status = @"Needs to submit a word";
                        
                    }
                    
                } else {
                    
                    status = @"Needs to submit a word";
                }
                
                
            } else { // Image NOT submitted
                
                status = @"Waiting on dealer";
                
            }

            
        }
        
        
        if (status != nil) {
            
            NSLog(@"add status");
        
            [[self.gameUsers objectAtIndex:i] setObject:status forKey:@"status"]; // Set the status for user
        
        }
        
    }
}

- (void) updateViewForCurrentStatus {
    
    PFFile *image = [self.currentRound objectForKey:@"pic"];
    PFObject *dealer = [self.currentRound objectForKey:@"dealer"];
    
    
    if ([self.currentGameUser.objectId isEqualToString:dealer.objectId]) { // Current user is dealer
        
        if (image != NULL) {
            
            [self getImage:image];
            
            if (self.currentRoundWordsSubmitted.count == (self.gameUsers.count - 1)) { // Have a -1 since the dealer does not submit a word
                
                self.nextAction = SUBMITANSWER;
                
                [self showAnswersMenu];
            
            } else {
                
                self.nextAction = WAITING;
                
            }
            
        
        } else {
            
            self.nextAction = CHOOSEPHOTO;
            
            self.imageView.hidden = YES;
            self.tableView.hidden = NO;
            
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
                    
                    [self showSelectedWord];
                    
                    
                    
                } else {
                    
                    self.nextAction = SUBMITWORD;
                    
                    [self queryWordsForCurrentGameUser];
                    
                }
                
            } else { // No users have submitted any words.  Query for new words.
                
                self.nextAction = SUBMITWORD;
                
                self.imageView.hidden = NO;
                self.tableView.hidden = YES;
                
                [self queryWordsForCurrentGameUser];
                
            }
            
            
        } else {
            
            self.nextAction = WAITING;
            
            self.imageView.hidden = YES;
            self.tableView.hidden = NO;
            self.wordsMenu.hidden = YES;
            
        }
        
    }
    
    [self updateActionButton];
    
}

- (void) getImage:(PFFile*)image {
    
    [image getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        
        NSLog(@"Got Image Data");
        
        UIImage *pic = [UIImage imageWithData:data];
        [self.imageView setImage:pic];
        self.imageView.hidden = NO;
        self.tableView.hidden = YES;
        self.uploadImageView.hidden = YES;
        
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
            [self getGameStatus];
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
        
    // (New) Round - Game
    PFObject *round = [PFObject objectWithClassName:kParseClassRound];
    [round setObject:self.game forKey:@"game"];
    
    PFObject *currentDealer = [self.currentRound objectForKey:@"dealer"];
    PFObject  *nextDealer;
    
    
    // Get the current dealer's table position
    int nextDealerTablePosition;
    for (PFObject *gameUser in self.gameUsers) {
        
        //PFUser *user = [gameUser objectForKey:@"user"];
        if ([gameUser.objectId isEqualToString:currentDealer.objectId]) {
            
            NSNumber *tablePosition = [gameUser objectForKey:@"tablePosition"];
            nextDealerTablePosition = [tablePosition intValue];
            nextDealerTablePosition++;
            
            if (nextDealerTablePosition > gameUsers.count) {
                
                nextDealerTablePosition = 1;
                
            }
            
        }
        
    }
    
    // Get the next dealer
    for (PFObject *gameUser in self.gameUsers) {
        
        //PFUser *user = [gameUser objectForKey:@"user"];
        NSNumber *tablePosition = [gameUser objectForKey:@"tablePosition"];
        int userTablePosition = [tablePosition intValue];
        
        if (userTablePosition == nextDealerTablePosition) {
            
            nextDealer = gameUser;
            
        }
        
    }
    
    [round setObject:nextDealer forKey:@"dealer"];
    
    [round saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
        self.currentRound = round;
        
        [self createWordsForCurrentRound];
        
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

- (void) showSelectedWord {
    
    ah__block typeof(self) blockSelf = self;
    
    NSMutableArray *tmpWorsArray = [NSMutableArray array];
    
    UzysSMMenuItem *item;
    
    for (PFObject *wordSubmitted in self.currentRoundWordsSubmitted) {
        
        PFObject *gameUesrWordSubmitted = [wordSubmitted objectForKey:@"gameUser"];
        
        if ([gameUesrWordSubmitted.objectId isEqualToString:self.currentGameUser.objectId]) {
            
            PFObject *word = [wordSubmitted objectForKey:@"word"];
            NSString *theWord = [word objectForKey:@"word"];
            
            item = [[UzysSMMenuItem alloc] initWithTitle:theWord image:[UIImage imageNamed:@"888-checkmark"] action:^(UzysSMMenuItem *item) {
                NSLog(@"Item: %@ menuState : %d", item , blockSelf.wordsMenu.menuState);
                
            }];
            
        }
        
    }
    
    [tmpWorsArray addObject:item];
    
    
    NSUInteger statusbarHeight = self.navigationController.navigationBar.frame.size.height;
    if(IS_IOS7)
        statusbarHeight += 20;
    
    
    self.wordsMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    
    self.wordsMenu.frame = CGRectMake(self.wordsMenu.frame.origin.x, self.wordsMenu.frame.origin.y+ statusbarHeight, self.wordsMenu.frame.size.width, self.wordsMenu.frame.size.height);
    
    self.wordsMenu.hidden = NO;
    
    [self.view addSubview:self.wordsMenu];
    
    [self.wordsMenu toggleMenu];
    [self.wordsMenu toggleMenu];
    
}

- (void) showWordsMenu {
    
    ah__block typeof(self) blockSelf = self;

    NSMutableArray *tmpWorsArray = [NSMutableArray array];
    
    int tag = 0;
    for (PFObject *word in self.currentGameUserWords) {
        
        NSString *theWord = [word objectForKey:@"word"];

        UzysSMMenuItem *item1 = [[UzysSMMenuItem alloc] initWithTitle:theWord image:nil action:^(UzysSMMenuItem *item) {
            NSLog(@"Item: %@ menuState : %d", item , blockSelf.wordsMenu.menuState);
            self.selectedWord = [self.currentGameUserWords objectAtIndex:tag];
            NSLog(@"Selected Word: %@", [self.selectedWord objectForKey:@"word"]);
            
        }];
        
        [tmpWorsArray addObject:item1];
        item1.tag = tag;
        tag++;
        
    }
    
    
    NSUInteger statusbarHeight = self.navigationController.navigationBar.frame.size.height;
    if(IS_IOS7)
        statusbarHeight += 20;
    
    
    self.wordsMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    
    self.wordsMenu.frame = CGRectMake(self.wordsMenu.frame.origin.x, self.wordsMenu.frame.origin.y+ statusbarHeight, self.wordsMenu.frame.size.width, self.wordsMenu.frame.size.height);
    
    self.wordsMenu.hidden = NO;
    
    [self.view addSubview:self.wordsMenu];
    
    [self.wordsMenu toggleMenu];
    
    
}

- (void) showAnswersMenu {
    
    ah__block typeof(self) blockSelf = self;
    
    NSMutableArray *tmpWorsArray = [NSMutableArray new];
    
    int tag = 0;
    for (PFObject *wordSubmitted in self.currentRoundWordsSubmitted) {
        
        //NSString *theWord = [word objectForKey:@"word"];
        PFObject *word = [wordSubmitted objectForKey:@"word"];
        NSString *theWord = [word objectForKey:@"word"];
        
        UzysSMMenuItem *item = [[UzysSMMenuItem alloc] initWithTitle:theWord image:nil action:^(UzysSMMenuItem *item) {
            NSLog(@"Item: %@ menuState : %d", item , blockSelf.wordsMenu.menuState);
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
    
    self.wordsMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    
    self.wordsMenu.frame = CGRectMake(self.wordsMenu.frame.origin.x, self.wordsMenu.frame.origin.y+ statusbarHeight, self.wordsMenu.frame.size.width, self.wordsMenu.frame.size.height);
    
    self.wordsMenu.hidden = NO;
    
    [self.view addSubview:self.wordsMenu];
    
    [self.wordsMenu toggleMenu];
}

- (void) submitSelectedWord {
    
    PFObject *roundWordSubmitted = [PFObject objectWithClassName:kParseClassRoundWordSubmitted];
    [roundWordSubmitted setObject:self.selectedWord forKey:@"word"];
    [roundWordSubmitted setObject:self.currentRound forKey:@"round"];
    [roundWordSubmitted setObject:self.currentGameUser forKey:@"gameUser"];
    
    [roundWordSubmitted saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
       
        if (success) {
            
            NSLog(@"Word Submited");
            
            [self.wordsMenu removeFromSuperview];
            
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
    
    [self showUploadImageView];
    
    NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, 0.08f);
    
    PFFile *imageFile = [PFFile fileWithData:imageData];
    
    [imageFile saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
        if (success) {
            
            [self.currentRound setObject:imageFile forKey:@"pic"];
            [self.currentRound setObject:[NSDate date] forKey:@"picSubmittedDate"];
            
            [self.currentRound saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {

                    NSLog(@"Image Uploaded Successfully");
                    self.labelUploadImageStatus.text = @"Success";
                    self.progressView.hidden = YES;
                    self.imageViewCheckmark.hidden = NO;
                    [self createWordsForCurrentRound];
                    
                }
                
            }];
            
        }
    
    } progressBlock:^(int percentageDone) {
        
        NSLog(@"Image:  %d", percentageDone);
        self.progressView.progress = percentageDone / 100;
        
    
    }];
    
}

- (void) showUploadImageView {

    self.progressView.hidden = NO;
    self.imageViewCheckmark.hidden = YES;
    self.progressView.progress = 0.0;
    self.labelUploadImageStatus.text = @"Sending Photo ...";
    self.uploadImageView.hidden = NO;

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
        
        self.imageView.hidden = NO;
        self.tableView.hidden = YES;
        [self.imageView setImage:image];
        
        self.nextAction = SUBMITPHOTO;
        
        [self updateActionButton];
    
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (void) imageTapped:(id)sender {
    
    NSLog(@"imageTapped");
    
    if (self.nextAction == WAITING) {
    
        self.imageView.hidden = YES;
        self.wordsMenu.hidden = YES;
        self.tableView.hidden = NO;
    
    }
}

#pragma mark - Table view data sourc

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.gameUsers.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    GameUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFObject *gameUser = [self.gameUsers objectAtIndex:indexPath.row];
    
    NSString *name = [gameUser objectForKey:@"name"];
    NSString *status = [gameUser objectForKey:@"status"];
    NSString *facebookId = [gameUser objectForKey:@"facebookId"];
    NSNumber *score = [gameUser objectForKey:@"score"];
    
    NSString *profilePictureUrl = [NSString stringWithFormat:@"%@/%@/picture?%@", kFacebookGraph, facebookId, kFacebookGraphPictureSize100x100];
    [cell.imageViewProfilePicture setImageWithURL:[NSURL URLWithString:profilePictureUrl] placeholderImage:[UIImage imageNamed:@"facebook_profile"]];
    
    cell.labelStatus.text = status;
    cell.labelScore.text = [score stringValue];

    
    if ([gameUser.objectId isEqualToString:self.currentRoundDealer.objectId]) { // User is dealer
        
        NSString *dealerName = [NSString stringWithFormat:@"%@ %@", name, @"(D)"];
        cell.labelName.text = dealerName;

        
    } else {
        
        cell.labelName.text = name;
        
        
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject *gameUser = [self.gameUsers objectAtIndex:indexPath.row];
    PFObject *gameUserDealer = [self.currentRound objectForKey:@"dealer"];
    
    if (self.nextAction == WAITING) {
        
        if ([gameUser.objectId isEqualToString:gameUserDealer.objectId]) {
        
            self.tableView.hidden = YES;
            self.imageView.hidden = NO;
            
            if (self.wordsMenu.pItems.count) {
                self.wordsMenu.hidden = NO;
            }
            
        }
        
    }

    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
