//
//  AddArtworkVC.m
//  Street Art Map
//
//  Created by Alex Smith on 11/07/2015.
//  Copyright (c) 2015 Alex Smith. All rights reserved.
//

#import "AddAndViewArtworkVC.h"
#import "Artist.h"
#import "Artwork.h"
#import "ArtistsCDTVC.h"
#import "PhotoLibraryInterface.h"

@interface AddAndViewArtworkVC () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, PhotoLibraryInterfaceDelegate>

@property (strong, nonatomic) Artist *artistForArtwork;
@property (strong, nonatomic) NSString *localIdentifierForArtworkImage;
@property (strong, nonatomic) PhotoLibraryInterface *photoLibInterface;

// outlets
@property (weak, nonatomic) IBOutlet UIImageView *artworkImageView;
@property (weak, nonatomic) IBOutlet UITextField *artworkArtistTextField;
@property (weak, nonatomic) IBOutlet UITextField *artworkTitleTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@end

@implementation AddAndViewArtworkVC

#pragma mark - View Life Cycle

-(void)viewDidLoad
{
    if (self.artworkToView) {
        self.artworkTitleTextField.text = self.artworkToView.title;
        self.artistForArtwork = self.artworkToView.artist;
        
        if (self.artworkToView.imageLocation)
            self.localIdentifierForArtworkImage = self.artworkToView.imageLocation;
        
        self.title = @"View/Edit Art";
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        self.title = @"Add Art";
    }
}

#pragma mark - Helpers

-(void)showSingleButtonAlertWithMessage:(NSString *)message andTitle:(NSString *)title
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:NULL];
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - Segues

-(BOOL)updateArtworkFromView:(Artwork *)artworkToUpdate // will return YES if changes are made
{
    BOOL changesMade = NO;
    
    if (![artworkToUpdate.title isEqualToString:self.artworkTitleTextField.text]) {
        artworkToUpdate.title = self.artworkTitleTextField.text;
        changesMade = YES;
    }
    
    if (artworkToUpdate.artist != self.artistForArtwork) {
        artworkToUpdate.artist = self.artistForArtwork;
        changesMade = YES;
    }
    
    if (![artworkToUpdate.imageLocation isEqualToString:self.localIdentifierForArtworkImage]) {
        artworkToUpdate.imageLocation = self.localIdentifierForArtworkImage;
        changesMade = YES;
    }
    
    return changesMade;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Add Photo Unwind"]) {
        Artwork *artworkToUpdate;
        
        if (!self.artworkToView) {
            artworkToUpdate = [NSEntityDescription insertNewObjectForEntityForName:@"Artwork"
                                                                inManagedObjectContext:self.context];
        } else {
            artworkToUpdate = self.artworkToView;
        }
        
        if ([self updateArtworkFromView:artworkToUpdate]) {
            artworkToUpdate.uploadDate = [NSDate date];
        }
    
    } else if ([segue.identifier isEqualToString:@"Select Artist"]) {
        if ([segue.destinationViewController isMemberOfClass:[UINavigationController class]]) {
            UINavigationController *navController = (UINavigationController *)segue
            .destinationViewController;
            if ([[navController.viewControllers firstObject] isMemberOfClass:[ArtistsCDTVC class]]) {
                ArtistsCDTVC *artistSelection = (ArtistsCDTVC *)[navController.viewControllers firstObject];
                artistSelection.context = self.context;
                artistSelection.screenMode = SelectionMode;
            }
        }
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"Add Photo Unwind"]) {
        if (!self.artworkTitleTextField.text || !self.artworkImageView.image) {
            [self showSingleButtonAlertWithMessage:@"Photo title or image not set" andTitle:nil];
            return NO;
        }
    }
    
    return YES;
}

-(IBAction)done:(UIStoryboardSegue *)segue
{
    if ([segue.identifier isEqualToString:@"Select Artist Unwind"]) {
        if ([segue.sourceViewController isMemberOfClass:[ArtistsCDTVC class]]) {
            ArtistsCDTVC *artistSelection = (ArtistsCDTVC *)segue.sourceViewController;
            self.artistForArtwork = artistSelection.selectedArtist;
        }
    }
}

#pragma mark - Properties

-(PhotoLibraryInterface *)photoLibInterface
{
    if (!_photoLibInterface) {
        _photoLibInterface = [[PhotoLibraryInterface alloc] init];
        _photoLibInterface.delegate = self;
    }
    
    return _photoLibInterface;
}

-(void)setArtistForArtwork:(Artist *)artistForArtwork
{
    _artistForArtwork = artistForArtwork;
    self.artworkArtistTextField.text = _artistForArtwork.name;
}

-(void)setLocalIdentifierForArtworkImage:(NSString *)localIdentifierForArtworkImage
{
    _localIdentifierForArtworkImage = localIdentifierForArtworkImage;
    
    // SET UP A TEST FOR A DELETED IMAGE
    
    [self.photoLibInterface getImageForLocalIdentifier:_localIdentifierForArtworkImage
                                              withSize:self.artworkImageView.bounds.size];
    
    /*
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.localIdentifierForArtworkImage] options:nil];
    PHAsset *assetForArtworkImage = [result firstObject];
    
    // PHImageRequestOptions *options - consider implementing this if performance is bad? run against instruments to determine this
    
    [[PHImageManager defaultManager] requestImageForAsset:assetForArtworkImage
                                               targetSize:self.artworkImageView.bounds.size
                                              contentMode:PHImageContentModeAspectFit
                                                  options:nil
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                if (info[PHImageErrorKey]) {
                    // error handling
                } else {
                    self.artworkImageView.image = result;
                }
    }];*/
}

#pragma mark - Actions

-(void)selectImageWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = sourceType;
        imagePicker.delegate = self;
        
        [self presentViewController:imagePicker animated:YES completion:NULL];
    } else {
        [self showSingleButtonAlertWithMessage:@"Sorry, that option is not available on your device"
                                      andTitle:nil];
    }
}

- (IBAction)addPhotoToArtwork:(UIBarButtonItem *)sender
{
    UIAlertController *addPhotoAlert =
            [UIAlertController alertControllerWithTitle:nil
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:NULL];
    [addPhotoAlert addAction:cancelButton];
    
    UIAlertAction *fromCameraButton = [UIAlertAction actionWithTitle:@"Take photo"
                                                               style:UIAlertActionStyleDefault handler:
                                       ^(UIAlertAction *action) {
        [self selectImageWithSourceType:UIImagePickerControllerSourceTypeCamera];
    }];
    [addPhotoAlert addAction:fromCameraButton];
    
    UIAlertAction *fromExistingButton = [UIAlertAction actionWithTitle:@"Choose photo"
                                                                 style:UIAlertActionStyleDefault handler:
                                         ^(UIAlertAction *action) {
        [self selectImageWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    [addPhotoAlert addAction:fromExistingButton];
    
    [self presentViewController:addPhotoAlert animated:YES completion:NULL];
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (info[UIImagePickerControllerReferenceURL]) {
        /*PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[info[UIImagePickerControllerReferenceURL]] options:nil];
        PHAsset *assetForArtworkImage = [result firstObject];
        self.localIdentifierForArtworkImage = assetForArtworkImage.localIdentifier;*/
        
        self.localIdentifierForArtworkImage = [self.photoLibInterface localIdentifierForALAssetURL:info[UIImagePickerControllerReferenceURL]];
    } else {
        UIImage *artworkImage = info[UIImagePickerControllerOriginalImage];
        
        [self.photoLibInterface getLocalIdentifierForImage:artworkImage];
        
        /*__block NSString *localIdentifier;
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            PHAssetChangeRequest *addArtworkRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:artworkImage];
            PHObjectPlaceholder *addedArtworkPlaceholder = addArtworkRequest.placeholderForCreatedAsset;
             localIdentifier = addedArtworkPlaceholder.localIdentifier;
            
        } completionHandler:^(BOOL success, NSError *error) {
            self.localIdentifierForArtworkImage = localIdentifier;
        }];*/
        
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - PhotoLibraryInterfaceDelegate

-(void)image:(UIImage *)image forProvidedLocalIdentifier:(NSString *)identifier
{
    self.artworkImageView.image = image;\
    // WHY IS THIS CALLED TWICE?
    NSLog(@"setting image woohoo");
}

-(void)localIdentifier:(NSString *)identifier forProvidedImage:(UIImage *)image
{
    self.localIdentifierForArtworkImage = identifier;
    NSLog(@"identifer set as = %@", identifier);
}

@end