//
//  GameViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "GameViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "GameUserTableViewCell.h"
#import "UIImageView+AFNetworking.h"

#define IS_IOS7 [[[UIDevice currentDevice] systemVersion] floatValue] >= 7

@interface GameViewController () <UIImagePickerControllerDelegate>

@property (nonatomic,strong) UzysSlideMenu *wordsMenu;


@end

@implementation GameViewController
@synthesize tableView;
@synthesize imageWrapperView;
@synthesize game, gameUsers, currentRound, currentGameUserWords, currentRoundWordsSubmitted, roundWordsCounter, selectedWord, currentGameUser, currentGameUserWinner, currentRoundDealer;
@synthesize buttonAction;
@synthesize wordsMenu;
@synthesize nextAction;
@synthesize uploadImageView, labelUploadImageStatus, progressView, imageViewCheckmark;
@synthesize isLoading;

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

- (void) showError:(NSError*)error {
    
    UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedFailureReason] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorView show];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSLog(@"viewDidLoad");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getGameStatus) name:kPostNoteGetStatus object:nil];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(getGameStatus) userInfo:nil repeats:YES];
    
    self.uploadImageView.layer.cornerRadius = 10.0;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.imageView addGestureRecognizer:tapGesture];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(imageSwiped:)];
    [self.imageView addGestureRecognizer:swipeGesture];

    self.gameUsers = [NSMutableArray new];
    
    [self getGameStatus];
}

- (void) getGameStatus {
    
    self.buttonAction.enabled = NO;
    
    self.gameUsers = nil;
    self.currentRound = nil;
    self.currentGameUserWords = nil;
    self.currentRoundWordsSubmitted = nil;
    self.currentGameUser = nil;
    self.currentGameUserWinner = nil;
    self.currentRoundDealer = nil;
    
    if (!self.isLoading) {
    
        [self queryGameUsers];
        
    }
    
    
}

- (void) queryGameUsers {
    
    self.isLoading = YES;
    
    __block NSError *gameUsersError;
    
    PFQuery *queryGameUsers = [PFQuery queryWithClassName:kParseClassGameUser];
    [queryGameUsers whereKey:@"game" equalTo:self.game];
    [queryGameUsers orderByAscending:@"tablePosition"];
    
    [queryGameUsers findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        gameUsersError = error;
        
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
        
        if (!gameUsersError) {
            
            [self queryCurrentRound];
            
        } else {
            
            [self showError:gameUsersError];
            
        }
        
    }];
    
    
}

- (void) queryCurrentRound {
    
    PFQuery *queryRound = [PFQuery queryWithClassName:kParseClassRound];
    [queryRound whereKey:@"game" equalTo:self.game];
    [queryRound includeKey:@"dealer"];
    [queryRound orderByDescending:@"createdAt"];
    [queryRound setLimit:1];
    
    [queryRound findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error) {
            
            NSLog(@"%@", [error localizedDescription]);
            
            self.isLoading = NO;
        }
        
        
        if (objects.count) {
        
            self.currentRound = [objects objectAtIndex:0];
            self.currentRoundDealer = [self.currentRound objectForKey:@"dealer"];
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
        
        if (objects.count) {
            
            self.currentRoundWordsSubmitted = objects;
        
        }
        
        [self getGameStatusesForEachUser];
        [self updateViewForCurrentStatus];
        [self.tableView reloadData];
        
        self.isLoading = NO;
        
    }];

}

- (void) queryWordsForCurrentGameUser {
    
    NSLog(@"queryWordsForCurrentUser");
    
    self.isLoading = YES;
    
    PFQuery *queryRoundWords = [PFQuery queryWithClassName:kParseClassRoundWords];
    [queryRoundWords whereKey:@"gameUser" equalTo:self.currentGameUser];
    [queryRoundWords whereKey:@"round" equalTo:self.currentRound];
    
    [queryRoundWords findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        if (objects.count) {
            
            PFObject *roundWords = [objects objectAtIndex:0];
            
            PFRelation *wordsRelation = [roundWords relationforKey:@"words"];
            
            PFQuery *queryWords = [wordsRelation query];
            
            [queryWords findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                if (objects.count) {
                    
                    self.currentGameUserWords = objects;
                    
                    [self showWordsMenu];
                    
                }
                
                self.isLoading = NO;
                
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
            
            self.imageWrapperView.hidden = YES;
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
                
                self.imageWrapperView.hidden = NO;
                self.tableView.hidden = YES;
                
                [self queryWordsForCurrentGameUser];
                
            }
            
            
        } else {
            
            self.nextAction = WAITING;
            
            self.imageWrapperView.hidden = YES;
            self.tableView.hidden = NO;
            self.wordsMenu.hidden = YES;
            
        }
        
    }
    
    [self updateActionButton];
    
}

- (void) getImage:(PFFile*)image {
    
    [self.imageView setImage:nil];
    
    [image getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        
        NSLog(@"Got Image Data");
        
        UIImage *pic = [UIImage imageWithData:data];
        [self.imageView setImage:pic];
        self.imageWrapperView.hidden = NO;
        self.tableView.hidden = YES;
        self.uploadImageView.hidden = YES;
        
    } progressBlock:^(int progress) {
        
        NSLog(@"Image Progress: %d", progress);
        
    }];
    
}

- (void) updateActionButton {
    
    self.buttonAction.enabled = YES;
    
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
    
    self.buttonAction.enabled = NO;
    
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
    
    [self.wordsMenu removeFromSuperview];
    
    self.wordsMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    self.wordsMenu.frame = CGRectMake(0, 0, self.wordsMenu.frame.size.width, self.wordsMenu.frame.size.height);
    
    self.wordsMenu.hidden = NO;
    self.imageWrapperView.hidden = NO;
    
    [self.imageWrapperView addSubview:self.wordsMenu];
    
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
    
    [self.wordsMenu removeFromSuperview];

    self.wordsMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    self.wordsMenu.frame = CGRectMake(0, 0, self.wordsMenu.frame.size.width, self.wordsMenu.frame.size.height);
    
    self.wordsMenu.hidden = NO;
    self.imageWrapperView.hidden = NO;
    
    [self.imageWrapperView addSubview:self.wordsMenu];
    
    [self.wordsMenu toggleMenu];
    
    
}

- (void) showAnswersMenu {
    
    ah__block typeof(self) blockSelf = self;
    
    NSMutableArray *tmpWorsArray = [NSMutableArray new];
    
    int tag = 0;
    for (PFObject *wordSubmitted in self.currentRoundWordsSubmitted) {
        
        PFObject *word = [wordSubmitted objectForKey:@"word"];
        NSString *theWord = [word objectForKey:@"word"];
        
        UzysSMMenuItem *item = [[UzysSMMenuItem alloc] initWithTitle:theWord image:nil action:^(UzysSMMenuItem *item) {
            
            NSLog(@"Item: %@ menuState : %d", item , blockSelf.wordsMenu.menuState);
            self.currentGameUserWinner = [[self.currentRoundWordsSubmitted objectAtIndex:tag] objectForKey:@"gameUser"];
            self.selectedWord = [[self.currentRoundWordsSubmitted objectAtIndex:tag] objectForKey:@"word"];
            NSLog(@"Selected Current Game User %@", self.currentGameUserWinner);
            
            
        }];
        
        [tmpWorsArray addObject:item];
        item.tag = tag;
        tag++;
        
    }
    
    [self.wordsMenu removeFromSuperview];
    
    self.wordsMenu = [[UzysSlideMenu alloc] initWithItems:tmpWorsArray];
    self.wordsMenu.frame = CGRectMake(0, 0, self.wordsMenu.frame.size.width, self.wordsMenu.frame.size.height);
    
    self.wordsMenu.hidden = NO;
    self.imageWrapperView.hidden = NO;
    
    [self.imageWrapperView addSubview:self.wordsMenu];
    
    [self.wordsMenu toggleMenu];
     
}

- (void) submitSelectedWord {
    
    if (self.selectedWord != nil) {
    
        PFObject *roundWordSubmitted = [PFObject objectWithClassName:kParseClassRoundWordSubmitted];
        [roundWordSubmitted setObject:self.selectedWord forKey:@"word"];
        [roundWordSubmitted setObject:self.currentRound forKey:@"round"];
        [roundWordSubmitted setObject:self.currentGameUser forKey:@"gameUser"];
        
        [roundWordSubmitted saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            
            [self getGameStatus];
            
        }];
        
    }

}

- (void) submitSelectedAnswer {
    
    if (self.currentGameUserWinner != nil) {
        
        [self.currentRound setObject:self.currentGameUserWinner forKey:@"winner"];
        
        [self.currentRound saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            
            if (success) {
                
                // Update score value for current game user winner
                NSNumber *score = [self.currentGameUserWinner objectForKey:@"score"];
                int s = [score intValue];
                s++;
                
                [self.currentGameUserWinner setObject:[NSNumber numberWithInt:s] forKey:@"score"];
    
                [self.currentGameUserWinner saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                    
                    if (success) {
                        
                        /*
                        for (PFObject *gameUser in self.gameUsers) {
                            
                            PFUser *user = [gameUser objectForKey:@"user"];
                            NSString *dealer = [self.currentGameUser objectForKey:@"name"];
                            
                            if (![gameUser.objectId isEqualToString:self.currentGameUser.objectId]) {
                            
                                PFQuery *pushQuery = [PFInstallation query];
                                [pushQuery whereKey:@"user" equalTo:user];
                                NSString *message = [NSString stringWithFormat:@"%@ chose %@", dealer, [self.selectedWord objectForKey:@"word"]];
                                [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:message];
                                
                            }
                            
                            
                        }
                        */
                        self.isLoading = NO;
                        [self getGameStatus];
                        
                    }
                    
                }];
                

            }
            
        }];
        
    }
    
}

- (void) submitPhoto {
    
    self.isLoading = YES;
    
    [self showUploadImageView];
    
    NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, 0.08f);
    
    PFFile *imageFile = [PFFile fileWithData:imageData];
    
    [imageFile saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
        if (success) {
            
            [self.currentRound setObject:imageFile forKey:@"pic"];
            [self.currentRound setObject:[NSDate date] forKey:@"picSubmittedDate"];
            
            [self.currentRound saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    self.labelUploadImageStatus.text = @"Success";
                    self.progressView.hidden = YES;
                    self.imageViewCheckmark.hidden = NO;
                    
                    self.isLoading = NO;
                    [self getGameStatus];
                    
                }
                
            }];
            
        } else if (error) {
            
            NSLog(@"Image Upload Failed: %@", [error localizedDescription]);
            self.labelUploadImageStatus.text = @"Upload Failed";
            self.progressView.hidden = YES;
            
            self.isLoading = NO;
            [self getGameStatus];
            
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
        
        self.imageWrapperView.hidden = NO;
        self.wordsMenu.hidden = YES;
        self.tableView.hidden = YES;
        
        
        [self.imageView setImage:image];
        if(self.imageView.image == nil)
        {
            
            NSLog(@"image from assets");
            NSURL *imageSource = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
            self.imageView.image = [self findLargeImage:imageSource];
        
        
        }
        
        self.nextAction = SUBMITPHOTO;
        
        [self updateActionButton];
    
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self updateActionButton];
}

- (UIImage*) findLargeImage:(NSURL*)path {
    
    NSLog(@"path: %@", path);
    
    __block UIImage *largeimage = nil;
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset) {
        
        NSLog(@"set large image");
        
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        largeimage = [UIImage imageWithCGImage:[rep fullScreenImage] scale:[rep scale] orientation:0];
        
    };

    NSLog(@"in find large image4");

    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror) {
        
        NSLog(@"cant get image - %@",[myerror localizedDescription]);
    
    };

    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];

    [assetslibrary assetForURL:path resultBlock:resultblock failureBlock:failureblock];

    return largeimage;

}

- (void) imageTapped:(id)sender {
    
    NSLog(@"imageTapped");
    
    if (self.nextAction == WAITING) {
    
        self.imageWrapperView.hidden = YES;
        self.tableView.hidden = NO;
    
    }

}

- (void) imageSwiped:(id)sender {
    
    UIAlertView *reportView = [[UIAlertView alloc] initWithTitle:@"Report" message:@"Report photo as inappropriate?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Report", nil];
    [reportView show];
    
    
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        
        PFObject *report = [PFObject objectWithClassName:@"Report"];
        [report setObject:self.currentRound forKey:@"round"];
        [report saveInBackground];
    
    }
    
}

#pragma mark - Table view data source

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
    PFFile *pic = [self.currentRound objectForKey:@"pic"];
    
    if (self.nextAction == WAITING) {
        
        if ([gameUser.objectId isEqualToString:gameUserDealer.objectId]) {
        
            if (pic != NULL) {
            
                self.tableView.hidden = YES;
                self.imageWrapperView.hidden = NO;
                
                if (self.wordsMenu.pItems.count) {
                    self.wordsMenu.hidden = NO;
                }
                
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
