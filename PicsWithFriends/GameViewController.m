//
//  GameViewController.m
//  PicsWithFriends
//
//  Created by Ryan Lindbeck on 10/1/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "GameViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface GameViewController () <UIImagePickerControllerDelegate>

@end

@implementation GameViewController
@synthesize nextAction;
@synthesize game, currentRound;
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
    
    [self queryCurrentRound];
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
            
            [self determineStatusFromCurrentRound];
        
        } else {
            
            NSLog(@"No round returned");
        
        }
        
    }];
    
}

- (void) determineStatusFromCurrentRound {
    
    PFFile *image = [self.currentRound objectForKey:@"pic"];
    PFUser *dealerUser = [self.currentRound objectForKey:@"dealer"];
    
    NSString *currentUserId = [[PFUser currentUser] objectId];
    NSString *dealerUserId = dealerUser.objectId;
    
    if ([currentUserId isEqualToString:dealerUserId]) {
        
        NSLog(@"Current User is dealer");
        if (image) {
            
            NSLog(@"Dealer waiting on words");
            self.nextAction = WAITING;
        
        } else {
            
            NSLog(@"Dealer needs to submit photo");
            self.nextAction = CHOOSEPHOTO;
            
        }
    
    } else {
        
        NSLog(@"Curent User is not dealer");
    
    }
    
    [self updateActionButton];
    

}

- (void) updateActionButton {
    
    switch (self.nextAction) {
        case WAITING:
            [self.buttonAction setTitle:kActionWaiting forState:UIControlStateNormal];
            break;
            
        case CHOOSEPHOTO:
            [self.buttonAction setTitle:kActionChoosePhoto forState:UIControlStateNormal];
            break;
            
        case SUBMITPHOTO:
            [self.buttonAction setTitle:kActionSubmitPhoto forState:UIControlStateNormal];
            break;
            
        case SUBMITANSWER:
            [self.buttonAction setTitle:kActionSubmitAnswer forState:UIControlStateNormal];
            break;
            
        case SUBMITWORD:
            [self.buttonAction setTitle:kActionSubmitWord forState:UIControlStateNormal];
            break;
    }
    
}


- (IBAction) wordButtonTouchedHandler:(id)sender {
    
    
    
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
            
            break;
            
        case SUBMITWORD:
            
            break;
    }
    
}

- (void) submitPhoto {
    
    NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, 0.05f);
    
    PFFile *imageFile = [PFFile fileWithData:imageData];
    
    [imageFile saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
        if (success) {
            
            [self.currentRound setObject:imageFile forKey:@"pic"];
            
            [self.currentRound saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    NSLog(@"Image Uploaded Successfully");
                
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
