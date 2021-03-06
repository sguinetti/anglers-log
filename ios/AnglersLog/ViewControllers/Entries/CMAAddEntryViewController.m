//
//  CMAAddEntryViewController.m
//  AnglersLog
//
//  Created by Cohen Adair on 10/15/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMAAddEntryViewController.h"
#import "CMAAlerts.h"
#import "CMAAppDelegate.h"
#import "CMACameraButton.h"
#import "CMADeleteActionSheet.h"
#import "CMAImage.h"
#import "CMAImagePicker.h"
#import "CMAUserDefinesViewController.h"
#import "CMASelectFishingSpotViewController.h"
#import "CMASingleLocationViewController.h"
#import "CMAStorageManager.h"
#import "CMAUtilities.h"
#import "CMAViewBaitsViewController.h"
#import "CMAWeatherDataView.h"
#import "NSString+CMA.h"

@interface CMAAddEntryViewController () <CMAImagePickerDelegate, UICollectionViewDelegate,
        UICollectionViewDataSource, UIActionSheetDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic)IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic)IBOutlet UIBarButtonItem *cancelButton;

#pragma mark - Date and Time
@property (weak, nonatomic)IBOutlet UILabel *dateTimeDetailLabel;
@property (weak, nonatomic)IBOutlet UIDatePicker *datePicker;

#pragma mark - Photos
@property (weak, nonatomic)IBOutlet UICollectionView *imageCollection;
@property (strong, nonatomic) CMAImagePicker *imagePicker;

#pragma mark - Fish Details
@property (weak, nonatomic)IBOutlet UILabel *speciesDetailLabel;
@property (weak, nonatomic)IBOutlet UITextField *quantityTextField;
@property (weak, nonatomic)IBOutlet UITextField *lengthTextField;
@property (weak, nonatomic)IBOutlet UITextField *metricWeightTextField;
@property (weak, nonatomic)IBOutlet UITextField *poundsTextField;
@property (weak, nonatomic)IBOutlet UITextField *ouncesTextField;
@property (weak, nonatomic)IBOutlet UILabel *lengthLabel;
@property (weak, nonatomic)IBOutlet UILabel *weightLabel;
@property (weak, nonatomic)IBOutlet UITableViewCell *metricWeightCell;
@property (weak, nonatomic)IBOutlet UITableViewCell *imperialWeightCell;
@property (weak, nonatomic)IBOutlet UISegmentedControl *resultSegmentedControl;

#pragma mark - Catch Details
@property (weak, nonatomic)IBOutlet UILabel *locationDetailLabel;
@property (weak, nonatomic)IBOutlet UILabel *baitUsedDetailLabel;
@property (weak, nonatomic)IBOutlet UILabel *methodsDetailLabel;

#pragma mark - Weather Conditions
@property (strong, nonatomic)CMAWeatherDataView *weatherDataView;
@property (strong, nonatomic)CMAWeatherData *weatherData;
@property (weak, nonatomic)IBOutlet UIButton *toggleWeatherButton;
@property (weak, nonatomic)IBOutlet UIActivityIndicatorView *weatherIndicator;
@property (strong, nonatomic)CLLocationManager *locationManager;

#pragma mark - Water Conditions
@property (weak, nonatomic)IBOutlet UILabel *waterClarityLabel;
@property (weak, nonatomic)IBOutlet UITextField *waterDepthTextField;
@property (weak, nonatomic)IBOutlet UITextField *waterTemperatureTextField;
@property (weak, nonatomic)IBOutlet UILabel *waterDepthLabel;
@property (weak, nonatomic)IBOutlet UILabel *waterTemperatureLabel;

#pragma mark - Notes
@property (weak, nonatomic)IBOutlet UITextView *notesTextView;

#pragma mark - Camera
@property (weak, nonatomic)IBOutlet CMACameraButton *cameraImage;
@property (strong, nonatomic)CMADeleteActionSheet *removeImageActionSheet;

@property (strong, nonatomic)CMADeleteActionSheet *deleteEntryActionSheet;

#pragma mark - Miscellaneous
@property (weak, nonatomic)IBOutlet UIButton *deleteEntryButton;

@property (strong, nonatomic)NSDateFormatter *dateFormatter;
@property (strong, nonatomic)NSIndexPath *indexPathForOptionsCell; // used after an unwind from selecting options
@property (nonatomic)BOOL isEditingDateTime;
@property (nonatomic)BOOL isEditingEntry;
@property (nonatomic)BOOL isWeatherInitialized;

@property (nonatomic)BOOL hasAttachedImages;
@property (nonatomic)NSInteger numberOfImages;
@property (strong, nonatomic)NSIndexPath *deleteImageIndexPath;
@property (strong, nonatomic)NSMutableArray *entryImages; // array of UIImage
@property (strong, nonatomic)NSMutableArray *saveEntryImagesToGallery;

@end

#define kNumberOfSectionsWithoutDelete 7

#define kDateCellSection 0
#define kDateCellRow 0

#define kPhotoCellSection 1
#define kPhotoCellRow 0

#define kDatePickerHeight 225
#define kDatePickerCellSection 0
#define kDatePickerCellRow 1

#define kImagesCellHeightExpanded 157
#define kImagesCellSection 1

#define kWeatherCellSection 4

#define kFishDetailsSection 2
#define kMetricFishWeightRow 3
#define kImperialFishWeightRow 4

#define kImageViewTag 100
#define kImageViewSize 100

NSString *const kNotSelectedString = @"Not Selected";

@implementation CMAAddEntryViewController

#pragma mark - Global Accessing

- (CMAJournal *)journal {
    return [[CMAStorageManager sharedManager] sharedJournal];
}

#pragma mark - View Management

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.weatherIndicator setHidden:YES];
    
    self.dateFormatter = [NSDateFormatter new];
    [self.dateFormatter setDateFormat:@"MMMM dd, yyyy 'at' h:mm a"];
    
    // set date detail label to the current date and time
    [self.dateTimeDetailLabel setText:[self.dateFormatter stringFromDate:[NSDate new]]];
    
    // set proper units for length, weight, depth, and temperature
    [self initUnitCells];
    
    [self.imageCollection setAllowsSelection:NO];
    [self.imageCollection setAllowsMultipleSelection:NO];
    
    self.imagePicker = [CMAImagePicker withViewController:self canSelectMultiple:YES];
    
    self.isEditingEntry = self.previousViewID == CMAViewControllerIDSingleEntry;
    self.isEditingDateTime = NO;
    self.hasAttachedImages = NO;
    self.numberOfImages = 0;
    
    // set weather data view (needs to be called before [self initializeTableForEditing], below)
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CMAWeatherDataView" owner:self options:nil];
    if ([nib count] > 0)
        self.weatherDataView = (CMAWeatherDataView *)[nib objectAtIndex:0];
    [self.weatherDataView setFrame:CGRectMake(0, 0, self.view.frame.size.width / 2, 25)];
    [self.weatherDataView setAlpha:0.0];
    
    // if we're editing rather than adding an entry
    if (self.isEditingEntry) {
        [self initializeTableForEditing];
    
        // NO IDEA why this needs to be called here (it's already called in initializeCellsForEditing)
        // After a stupid amount of debugging I couldn't figure this out so this is left here as a temporary solution
        // The species detail label will only when editing an entry that required a new species to be added
        // This only happens with species; no other properties
        // Also, this bug came out of no where (worked one day, and not the next); checked logs but found nothing that would cause this
        if (self.entry.fishSpecies)
            [self.speciesDetailLabel setText:self.entry.fishSpecies.name];
        else
            [self.speciesDetailLabel setText:kNotSelectedString];
    } else
        self.entryImages = [NSMutableArray array];
    
    // init save images array
    self.saveEntryImagesToGallery = [NSMutableArray array];
    for (int i = 0; i < [self.entryImages count]; i++)
        [self.saveEntryImagesToGallery addObject:[NSNumber numberWithBool:NO]];
    
    [self.cameraImage myInit:self action:NULL];
    
    // location manager
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    
    [self initDeleteEntryActionSheet];
    [self initRemoveImageActionSheet];
    [self.notesTextView setContentInset:UIEdgeInsetsMake(-4, -5, 4, 5)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Initializing

- (void)initUnitCells {
    [self.lengthLabel setText:[NSString stringWithFormat:@"Length (%@)", [[self journal] lengthUnitsAsString:NO]]];
    [self.waterDepthLabel setText:[NSString stringWithFormat:@"Depth (%@)", [[self journal] depthUnitsAsString:NO]]];
    [self.waterTemperatureLabel setText:[NSString stringWithFormat:@"Temperature (%@)", [[self journal] temperatureUnitsAsString:YES]]];
    
    if ([[self journal] measurementSystem] == CMAMeasuringSystemTypeImperial)
        [self.metricWeightCell setHidden:YES];
    else
        [self.imperialWeightCell setHidden:YES];
}

- (void)initializeTableForEditing {
    [self initializeCellsForEditing];
    
    self.navigationItem.title = @"Edit Entry";
    
    self.entryImages = [NSMutableArray array];
    for (CMAImage *img in self.entry.images) {
        [self.entryImages addObject:img.fullImage.copy];
    }
    
    self.numberOfImages = [self.entryImages count];
    self.hasAttachedImages = (self.numberOfImages > 0);
    
    if (self.entry.weatherData) {
        self.isWeatherInitialized = YES;
        self.weatherData = self.entry.weatherData;
    }
}

- (void)initializeCellsForEditing {
    // date
    [self.datePicker setDate:[self.entry date]];
    [self.dateTimeDetailLabel setText:[self.dateFormatter stringFromDate:[self.entry date]]];
    
    // pictures
    [self.imageCollection reloadData];
    
    // species
    if (self.entry.fishSpecies)
        [self.speciesDetailLabel setText:self.entry.fishSpecies.name];
    else
        [self.speciesDetailLabel setText:kNotSelectedString];

    // fish quantity
    if (self.entry.fishQuantity && ([self.entry.fishQuantity integerValue] != -1))
        [self.quantityTextField setText:self.entry.fishQuantity.stringValue];
    
    // fish length
    if (self.entry.fishLength && ([self.entry.fishLength floatValue] != -1))
        [self.lengthTextField setText:self.entry.fishLength.stringValue];
    
    // fish weight
    if (self.entry.fishWeight && ([self.entry.fishWeight floatValue] != -1)) {
        if ([[self journal] measurementSystem] == CMAMeasuringSystemTypeMetric)
            [self.metricWeightTextField setText:self.entry.fishWeight.stringValue];
        else {
            [self.poundsTextField setText:self.entry.fishWeight.stringValue];
            
            if (self.entry.fishOunces)
                [self.ouncesTextField setText:self.entry.fishOunces.stringValue];
            else
                [self.ouncesTextField setText:@"0"];
        }
    }
    
    // fish result
    [self.resultSegmentedControl setSelectedSegmentIndex:self.entry.fishResult];
    
    // bait used
    if (self.entry.baitUsed)
        [self.baitUsedDetailLabel setText:self.entry.baitUsed.name];
    else
        [self.baitUsedDetailLabel setText:kNotSelectedString];
    
    // fishing methods
    if ([self.entry.fishingMethods count] > 0)
        [self.methodsDetailLabel setText:[self.entry fishingMethodsAsString]];
    
    // location and fishing spot
    if (self.entry.location)
        [self.locationDetailLabel setText:[self.entry locationAsString]];
    else
        [self.locationDetailLabel setText:kNotSelectedString];
    
    // weather conditions
    if (self.entry.weatherData) {
        [self setIsWeatherInitialized:YES];
        [self initWeatherDataViewWithData:self.entry.weatherData];
        [self toggleWeatherDataCell];
    }
    
    // water temperature
    if (self.entry.waterTemperature && ([self.entry.waterTemperature integerValue] != -1))
        [self.waterTemperatureTextField setText:self.entry.waterTemperature.stringValue];
    
    // water clarity
    if (self.entry.waterClarity)
        [self.waterClarityLabel setText:self.entry.waterClarity.name];
    else
        [self.speciesDetailLabel setText:kNotSelectedString];
    
    // water depth
    if (self.entry.waterDepth && ([self.entry.waterDepth floatValue] != -1))
        [self.waterDepthTextField setText:self.entry.waterDepth.stringValue];
    
    // notes
    if (self.entry.notes)
        [self.notesTextView setText:self.entry.notes];
}

- (void)toggleDatePickerCellHidden:(UITableView *)aTableView selectedPath:(NSIndexPath *)anIndexPath {
    self.isEditingDateTime = !self.isEditingDateTime;
    
    if (self.isEditingDateTime)
        [UIView animateWithDuration:0.5 animations:^{
            [self.datePicker setAlpha:1.0f];
        }];
    else {
        [UIView animateWithDuration:0.15 animations:^{
            [self.datePicker setAlpha:0.0f];
        }];
        
        [aTableView deselectRowAtIndexPath:anIndexPath animated:NO];
    }
    
    // use begin/endUpdates to animate changes
    [aTableView beginUpdates];
    [aTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kNumberOfSectionsWithoutDelete + self.isEditingEntry;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.isEditingEntry && section == [tableView numberOfSections] - 1)
        return TABLE_HEIGHT_FOOTER; // there's no header for this cell
    
    return TABLE_HEIGHT_HEADER;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // set height of the date picker cell
    if (indexPath.section == kDatePickerCellSection && indexPath.row == kDatePickerCellRow) {
        if (self.isEditingDateTime)
            return kDatePickerHeight;
        else
            return 0;
    }
    
    // for the images collection cell
    if (indexPath.section == kImagesCellSection) {
        if (self.hasAttachedImages)
            return kImagesCellHeightExpanded;
        else
            return 44;
    }
    
    // if weather data is added
    if (indexPath.section == kWeatherCellSection) {
        if (self.isWeatherInitialized)
            return TABLE_HEIGHT_WEATHER_CELL;
        else
            return 44;
    }
    
    // fish weight cell
    if (indexPath.section == kFishDetailsSection) {
        if (indexPath.row == kMetricFishWeightRow && [[self journal] measurementSystem] == CMAMeasuringSystemTypeImperial)
            return 0;
        
        if (indexPath.row == kImperialFishWeightRow && [[self journal] measurementSystem] == CMAMeasuringSystemTypeMetric)
            return 0;
    }
    
    // using the super class's implementation gets the height set in storyboard
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // weather cell
    if (indexPath.section == kWeatherCellSection) {
        [cell addSubview:self.weatherDataView];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0 && indexPath.row == 0) ||
        (indexPath.section == kFishDetailsSection && indexPath.row == kMetricFishWeightRow && [[self journal] measurementSystem] == CMAMeasuringSystemTypeMetric)) {
        
        [cell setSeparatorInset:UIEdgeInsetsZero];
        [cell setPreservesSuperviewLayoutMargins:NO];
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // show the date picker cell when the date display cell is selected
    if (indexPath.section == kDateCellSection && indexPath.row == kDateCellRow) {
        [self toggleDatePickerCellHidden:tableView selectedPath:indexPath];
        return;
    } else {
        // hide the date picker cell when any other cell is selected
        if (self.isEditingDateTime) {
            [self toggleDatePickerCellHidden:tableView selectedPath:indexPath];
        }
    }
    
    if (indexPath.section == kPhotoCellSection && indexPath.row == kPhotoCellRow) {
        [self.imagePicker presentFromView:self.cameraImage];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    if (indexPath.section == kWeatherCellSection) {
        [self tapToggleWeatherButton:self.toggleWeatherButton];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
}

#pragma mark - Events

- (IBAction)tapDeleteEntryButton:(UIButton *)sender {
    [self.deleteEntryActionSheet showInViewController:self];
}

- (IBAction)clickedDone:(UIBarButtonItem *)sender {
    CMAEntry *entryToAdd = [[CMAStorageManager sharedManager] managedEntry];
    
    [self.journal addSceneConfirmWithObject:entryToAdd
                                  objToEdit:self.entry
                            checkInputBlock:^BOOL () { return [self checkUserInputAndSetEntry:entryToAdd]; }
                             isEditingBlock:^BOOL () { return self.isEditingEntry; }
                            editObjectBlock:^void () { [[self journal] editEntryDated:[self.entry date] newProperties:entryToAdd]; }
                             addObjectBlock:^BOOL () { return [[self journal] addEntry:entryToAdd]; }
                              errorAlertMsg:@"There was an error adding an entry. Please try again."
                             viewController:self
                                 segueBlock:^void () { [self performSegueToPreviousView]; }
                            removeObjToEdit:NO];
}

- (IBAction)clickedCancel:(UIBarButtonItem *)sender {
    if (!self.isEditingEntry) {
        if (self.weatherData) {
            [[CMAStorageManager sharedManager] deleteManagedObject:self.weatherData saveContext:YES];
            self.weatherData = nil;
        }
        
        [self setEntry:nil];
    }
    
    [self performSegueToPreviousView];
}

- (IBAction)changedDatePicker:(UIDatePicker *)sender {
    [self.dateTimeDetailLabel setText:[self.dateFormatter stringFromDate:sender.date]];
}

- (IBAction)tapToggleWeatherButton:(UIButton *)sender {
    [self toggleWeatherData];
}

- (void)longPressedImageInCollection:(UILongPressGestureRecognizer *)sender {
    // only show at the beginning of the gesture
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.deleteImageIndexPath = [self.imageCollection indexPathForItemAtPoint:[sender locationInView:self.imageCollection]];
        [self.removeImageActionSheet showInViewController:self];
    }
}

#pragma mark - Action Sheets

- (void)initDeleteEntryActionSheet {
    __weak typeof(self) weakSelf = self;
    
    self.deleteEntryActionSheet =
    [CMADeleteActionSheet alertControllerWithTitle:@"Delete Entry"
                                           message:@"Are you sure you want to delete this entry? It cannot be undone."
                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    self.deleteEntryActionSheet.deleteActionBlock = ^void(UIAlertAction *action) {
        [[weakSelf journal] removeEntryDated:weakSelf.entry.date];
        [weakSelf performSegueWithIdentifier:@"unwindToViewEntriesFromAddEntry" sender:weakSelf];
    };
    
    [self.deleteEntryActionSheet addActions];
}

- (void)initRemoveImageActionSheet {
    __weak typeof(self) weakSelf = self;
    
    self.removeImageActionSheet =
        [CMADeleteActionSheet alertControllerWithTitle:@"Remove Image"
                                               message:@"Are you sure you want to remove this image?"
                                        preferredStyle:UIAlertControllerStyleActionSheet];
    
    self.removeImageActionSheet.deleteActionBlock = ^void(UIAlertAction *action) {
        if (weakSelf.deleteImageIndexPath != nil) {
            [weakSelf deleteImageFromCollectionAtIndexPath:weakSelf.deleteImageIndexPath];
            weakSelf.deleteImageIndexPath = nil;
        }
    };
    
    [self.removeImageActionSheet addActions];
}

#pragma mark - Navigation

- (void)performSegueToPreviousView {
    switch (self.previousViewID) {
        case CMAViewControllerIDViewEntries:
            [self performSegueWithIdentifier:@"unwindToViewEntriesFromAddEntry" sender:self];
            break;
            
        case CMAViewControllerIDSingleEntry:
            [self performSegueWithIdentifier:@"unwindToSingleEntryFromAddEntry" sender:self];
            break;
            
        default:
            NSLog(@"Invalid previousViewID value");
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // bait used
    if ([segue.identifier isEqualToString:@"fromAddEntryToViewBaits"]) {
        CMAViewBaitsViewController *destination = segue.destinationViewController;
        destination.isSelectingForAddEntry = YES;
        
        self.indexPathForOptionsCell = [self.tableView indexPathForSelectedRow]; // so it knows which cell to edit after the unwind
        return;
    }
    
    BOOL isSetting = NO;
    NSString *userDefineName;
    
    // species
    if ([segue.identifier isEqualToString:@"fromAddEntrySpeciesToEditSettings"]) {
        isSetting = YES;
        userDefineName = UDN_SPECIES;
    }
    
    // location
    if ([segue.identifier isEqualToString:@"fromAddEntryLocationToEditSettings"]) {
        isSetting = YES;
        userDefineName = UDN_LOCATIONS;
    }
    
    // methods
    if ([segue.identifier isEqualToString:@"fromAddEntryMethodsToEditSettings"]) {
        isSetting = YES;
        userDefineName = UDN_FISHING_METHODS;
    }
    
    // water clarities
    if ([segue.identifier isEqualToString:@"fromAddEntryWaterClarityToEditSettings"]) {
        isSetting = YES;
        userDefineName = UDN_WATER_CLARITIES;
    }
    
    if (isSetting) {
        CMAUserDefinesViewController *destination = segue.destinationViewController;
        
        if ([destination isKindOfClass:[UINavigationController class]])
            destination = [[segue.destinationViewController viewControllers] objectAtIndex:0];

        destination.userDefine = [[self journal] userDefineNamed:userDefineName];
        destination.previousViewID = CMAViewControllerIDAddEntry;
        
        if ([destination.userDefine.name isEqualToString:UDN_FISHING_METHODS]) {
            NSMutableArray *stringArray = [NSMutableArray array];
            
            NSMutableSet *methods = [self parseMethodsDetailText];
            for (id m in methods)
                [stringArray addObject:[m name]];
            
            destination.selectedCellsArray = [stringArray mutableCopy];
        }
        
        self.indexPathForOptionsCell = [self.tableView indexPathForSelectedRow]; // so it knows which cell to edit after the unwind
    }
}

- (IBAction)unwindToAddEntry:(UIStoryboardSegue *)segue {
    // set the detail label text after selecting an option from the Edit Settings view
    if ([segue.identifier isEqualToString:@"unwindToAddEntryFromEditSettings"]) {
        CMAUserDefinesViewController *source = [segue sourceViewController];
        UITableViewCell *cellToEdit = [self.tableView cellForRowAtIndexPath:self.indexPathForOptionsCell];
        
        if ([source.selectedCellLabelText isEqualToString:@""])
            [[cellToEdit detailTextLabel] setText:kNotSelectedString];
        else
            [[cellToEdit detailTextLabel] setText:source.selectedCellLabelText];
        
        source.selectedCellLabelText = nil;
        source.previousViewID = CMAViewControllerIDNil;
    }
    
    if ([segue.identifier isEqualToString:@"unwindToAddEntryFromSelectFishingSpot"]) {
        CMASelectFishingSpotViewController *source = [segue sourceViewController];
        UITableViewCell *cellToEdit = [self.tableView cellForRowAtIndexPath:self.indexPathForOptionsCell];
        
        [[cellToEdit detailTextLabel] setText:source.selectedCellLabelText];
        
        source.location = nil;
        source.selectedCellLabelText = nil;
        source.previousViewID = CMAViewControllerIDNil;
    }
    
    if ([segue.identifier isEqualToString:@"unwindToAddEntryFromViewBaits"]) {
        CMAViewBaitsViewController *source = [segue sourceViewController];
        UITableViewCell *cellToEdit = [self.tableView cellForRowAtIndexPath:self.indexPathForOptionsCell];
        [[cellToEdit detailTextLabel] setText:source.baitForAddEntry.name];
        
        source.baitForAddEntry = nil;
    }
}

#pragma mark - Entry Creation

// Returns true if all the user input is valid. Sets anEntry's properties after validation.
- (BOOL)checkUserInputAndSetEntry:(CMAEntry *)anEntry {
    // date
    if (![[self journal] entryDated:[self.datePicker date]] || self.isEditingEntry)
        [anEntry setDate:[self.datePicker date]];
    else {
        [CMAAlerts showError:@"An entry with that date and time already exists. Please select a new date or edit the existing entry." inVc:self];
        return NO;
    }
    
    // species
    if (![[self.speciesDetailLabel text] isEqualToString:kNotSelectedString]) {
        CMASpecies *species = [[[self journal] userDefineNamed:UDN_SPECIES] objectNamed:[self.speciesDetailLabel text]];
        [anEntry setFishSpecies:species];
    } else {
        [CMAAlerts showError:@"Please select a species." inVc:self];
        return NO;
    }
    
    // photos
    
    // delete the old images as they are no longer needed
    if ([self.entry imageCount] > 0) {
        for (CMAImage *img in self.entry.images)
            [self.entry removeImage:img];
        
        self.entry.images = nil;
        self.entry.images = [NSMutableOrderedSet orderedSet];
    }

    if ([self.entryImages count] > 0) {
        for (int i = 0; i < [self.entryImages count]; i++) {
            CMAImage *img = [[CMAStorageManager sharedManager] managedImage];
            [img setFullImage:[self.entryImages objectAtIndex:i]];
            [anEntry addImage:img];
            [img saveWithIndex:i completion:nil];

            if ([[self.saveEntryImagesToGallery objectAtIndex:i] boolValue])
                UIImageWriteToSavedPhotosAlbum([img fullImage], nil, nil, nil);
        }
    } else
        [anEntry setImages:nil];
    
    // fish quantity
    if (![[self.quantityTextField text] isEqualToString:@""]) {
        NSNumber *quantity = [NSNumber numberWithInteger:[[self.quantityTextField text] integerValue]];
        [anEntry setFishQuantity:quantity];
    } else {
        [anEntry setFishQuantity:[NSNumber numberWithInteger:-1]];
    }
    
    // fish length
    if (![[self.lengthTextField text] isEqualToString:@""]) {
        [anEntry setFishLength:[self.lengthTextField text].formattedFloatValue];
    } else {
        [anEntry setFishLength:[NSNumber numberWithInteger:-1]];
    }
    
    // fish weight
    if ([[self journal] measurementSystem] == CMAMeasuringSystemTypeMetric) {
        if (![[self.metricWeightTextField text] isEqualToString:@""]) {
            [anEntry setFishWeight:[self.metricWeightTextField text].formattedFloatValue];
        } else {
            [anEntry setFishWeight:[NSNumber numberWithInteger:-1]];
        }
    } else {
        NSString *poundsStr = [self.poundsTextField text];
        NSString *ouncesStr = [self.ouncesTextField text];
        
        // if the user filled one of them out
        if (!([poundsStr isEqualToString:@""] && [ouncesStr isEqualToString:@""])) {
            if ([poundsStr isEqualToString:@""]) poundsStr = @"0";
            if ([ouncesStr isEqualToString:@""]) ouncesStr = @"0";
            
            [anEntry setFishWeight:[NSNumber numberWithInteger:poundsStr.integerValue]];
            [anEntry setFishOunces:[NSNumber numberWithInteger:ouncesStr.integerValue]];
        }
    }
    
    // fish result
    [anEntry setFishResult:[self.resultSegmentedControl selectedSegmentIndex]];
    
    // location and fishing spot
    if (![[self.locationDetailLabel text] isEqualToString:kNotSelectedString]) {
        NSArray *locationInfo = [self parseLocationDetailText];
        
        if ([locationInfo count] != 2) {
            [CMAAlerts showError:@"Selected location has been deleted. Please choose a different location." inVc:self];
            return NO;
        }
        
        [anEntry setLocation:locationInfo[0]];
        
        if ([locationInfo count] > 1) {
            [anEntry setFishingSpot:locationInfo[1]];
        }
    } else {
        [anEntry setLocation:nil];
        [anEntry setFishingSpot:nil];
    }
    
    // bait used
    if (![[self.baitUsedDetailLabel text] isEqualToString:kNotSelectedString]) {
        CMABait *bait = [[[self journal] userDefineNamed:UDN_BAITS] objectNamed:[self.baitUsedDetailLabel text]];
        [anEntry setBaitUsed:bait];
    } else {
        [anEntry setBaitUsed:nil];
    }
    
    // fishing methods
    if (![[self.methodsDetailLabel text] isEqualToString:kNotSelectedString]) {
        [anEntry setFishingMethods:[self parseMethodsDetailText]];
    } else {
        [anEntry setFishingMethods:nil];
    }
    
    // weather conditions
    if (self.isWeatherInitialized)
        [anEntry setWeatherData:self.weatherData];
    else
        [anEntry setWeatherData:nil];
    
    // water temperature
    if (![[self.waterTemperatureTextField text] isEqualToString:@""]) {
        NSNumber *temp = [NSNumber numberWithInteger:[[self.waterTemperatureTextField text] integerValue]];
        [anEntry setWaterTemperature:temp];
    } else {
        [anEntry setWaterTemperature:[NSNumber numberWithInteger:-1]];
    }
    
    // water clarity
    if (![[self.waterClarityLabel text] isEqualToString:kNotSelectedString]) {
        CMAWaterClarity *waterClarity = [[[self journal] userDefineNamed:UDN_WATER_CLARITIES] objectNamed:[self.waterClarityLabel text]];
        [anEntry setWaterClarity:waterClarity];
    } else {
        [anEntry setWaterClarity:nil];
    }
    
    // water depth
    if (![[self.waterDepthTextField text] isEqualToString:@""]) {
        [anEntry setWaterDepth:[self.waterDepthTextField text].formattedFloatValue];
    } else {
        [anEntry setWaterDepth:[NSNumber numberWithInteger:-1]];
    }
    
    // notes
    if (![[self.notesTextView text] isEqualToString:@""]) {
        [anEntry setNotes:[self.notesTextView text]];
    } else {
        [anEntry setNotes:nil];
    }
    
    return YES;
}

// Returns array of length 2 where [0] is a CMALocation and [1] is a CMAFishingSpot.
- (NSArray *)parseLocationDetailText {
    NSArray *stringLocationInfo = [[self.locationDetailLabel text] componentsSeparatedByString:TOKEN_LOCATION];
    
    CMALocation *location = [[[self journal] userDefineNamed:UDN_LOCATIONS] objectNamed:stringLocationInfo[0]];
    
    CMAFishingSpot *fishingSpot = nil;
    if ([stringLocationInfo count] > 1)
        fishingSpot = [location fishingSpotNamed:stringLocationInfo[1]];

    return [NSArray arrayWithObjects:location, fishingSpot, nil];
}

// Returns an NSSet of fishing methods from [[self journal] userDefines].
- (NSMutableSet *)parseMethodsDetailText {
    NSMutableSet *result = [NSMutableSet set];
    NSArray *fishingMethodStrings = [[self.methodsDetailLabel text] componentsSeparatedByString:TOKEN_FISHING_METHODS];
    
    for (NSString *str in fishingMethodStrings) {
        id obj = [[[self journal] userDefineNamed:UDN_FISHING_METHODS] objectNamed:str];
        
        if (obj)
            [result addObject:obj];
    }
    
    return result;
}

#pragma mark - Image Picker

- (void)processPickedImages:(NSArray<UIImage *> *)images wasTaken:(BOOL)wasTaken {
    for (UIImage *img in images) {
        [self insertImageIntoCollection:img saveToGallery:wasTaken];
    }
}

#pragma mark - Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.numberOfImages;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"thumbnailImageCell" forIndexPath:indexPath];
    
    if ([self.entryImages count] > 0) {
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:kImageViewTag];
        [imageView setImage:[self.entryImages objectAtIndex:indexPath.item]];
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedImageInCollection:)];
    [cell addGestureRecognizer:longPress];
        
    return cell;
}

- (void)insertImageIntoCollection:(UIImage *)anImage saveToGallery:(BOOL)saveToGallery {
    self.numberOfImages++;
    
    // reload table if adding the first image
    if (!self.hasAttachedImages) {
        self.hasAttachedImages = YES;
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.imageCollection insertItemsAtIndexPaths:@[indexPath]];
    
    UICollectionViewCell *insertedCell = [self.imageCollection cellForItemAtIndexPath:indexPath];
    
    UIImage *scaledImage = [CMAUtilities scaleImageToScreenWidth:anImage];
    [self.entryImages insertObject:scaledImage atIndex:0];
    
    if (saveToGallery)
        [self.saveEntryImagesToGallery insertObject:[NSNumber numberWithBool:YES] atIndex:0];
    else
        [self.saveEntryImagesToGallery insertObject:[NSNumber numberWithBool:NO] atIndex:0];
    
    // image is scaled to the size of the UICollectionViewCell
    UIImageView *imageView = (UIImageView *)[insertedCell viewWithTag:kImageViewTag];
    imageView.image = [CMAUtilities scaleImage:scaledImage toSquareSize:kImageViewSize];
}

- (void)deleteImageFromCollectionAtIndexPath:(NSIndexPath *)anIndexPath {
    self.numberOfImages--;
    
    [self.entryImages removeObjectAtIndex:anIndexPath.item];
    [self.saveEntryImagesToGallery removeObjectAtIndex:anIndexPath.item];
    [self.imageCollection deleteItemsAtIndexPaths:@[anIndexPath]];
    
    // reload table to hide collection cell if there are no more images
    if (self.numberOfImages == 0) {
        self.hasAttachedImages = NO;
        
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self initWeatherDataWithCoordinate:manager.location.coordinate];
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [CMAAlerts showError:[NSString stringWithFormat:@"Failed to get user location. Error: %@", error.localizedDescription] inVc:self];
    [self.weatherIndicator stopAnimating];
    [self.weatherIndicator setHidden:YES];
}

#pragma mark - Weather 

- (void)toggleWeatherDataCell {
    if (self.isWeatherInitialized) {
        [self.toggleWeatherButton setTitle:@"-" forState:UIControlStateNormal];
        [self.weatherIndicator stopAnimating];
        [self.weatherIndicator setHidden:YES];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.weatherDataView setAlpha:1.0f];
        }];
    } else {
        // remove weather data
        [UIView animateWithDuration:0.15 animations:^{
            [self.weatherDataView setAlpha:0.0f];
        }];
        
        [self.toggleWeatherButton setTitle:@"+" forState:UIControlStateNormal];
        
        // remove from core data
        if (self.weatherData) {
            [[CMAStorageManager sharedManager] deleteManagedObject:self.weatherData saveContext:YES];
            self.weatherData = nil;
        }
    }
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)toggleWeatherData {
    self.isWeatherInitialized = !self.isWeatherInitialized;
    
    if (self.isWeatherInitialized) {
        [self.weatherIndicator setHidden:NO];
        [self.weatherIndicator startAnimating];
        
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];
    } else
        [self toggleWeatherDataCell];
}

// Sets self.weatherData from data gathered from the OpenWeatherMapAPI.
- (void)initWeatherDataWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (![CMAUtilities validConnection]) {
        [CMAAlerts showError:@"You do not have a valid network connection. Please connect and try again." inVc:self];
        [self.weatherIndicator setHidden:YES];
        return;
    }
    
    self.weatherData = [[CMAStorageManager sharedManager] managedWeatherData];
    [self.weatherData withCoordinates:coordinate andJournal:[[self journal] measurementSystem]];
    
    [self.weatherData.weatherAPI currentWeatherByCoordinate:self.weatherData.coordinate withCallback:^(NSError *error, NSDictionary *result) {
        if (error) {
            NSLog(@"Error getting weather data: %@", error.localizedDescription);
            [CMAAlerts showError:@"There was an error getting weather data. Please try again later." inVc:self];
            [self.weatherIndicator setHidden:YES];
            [[CMAStorageManager sharedManager] deleteManagedObject:self.weatherData saveContext:YES];
            [self setWeatherData:nil];
            return;
        }
        
        NSArray *weatherArray = result[@"weather"];
        
        if ([weatherArray count] > 0) {
            [self.weatherData setSkyConditions:result[@"weather"][0][@"main"]];
        } else {
            [self.weatherData setSkyConditions:@"N/A"];
        }
        
        [self.weatherData setTemperature:(NSNumber *)result[@"main"][@"temp"]]; // [3][3]
        [self.weatherData setWindSpeed:[NSString stringWithFormat:@"%@", result[@"wind"][@"speed"]]]; // [1][0]
        
        [self initWeatherDataViewWithData:self.weatherData];
        [self toggleWeatherDataCell];
    }];
}

- (void)initWeatherDataViewWithData:(CMAWeatherData *)someWeatherData {
    [self.weatherDataView.temperatureLabel setText:[someWeatherData temperatureAsStringWithUnits:[[self journal] temperatureUnitsAsString:YES]]];
    [self.weatherDataView.windSpeedLabel setText:[someWeatherData windSpeedAsStringWithUnits:[[self journal] speedUnitsAsString:YES]]];
    [self.weatherDataView.skyConditionsLabel setText:[someWeatherData skyConditionsAsString]];
}

#pragma mark - CMAImagePickerDelegate

- (void)didTakePicture:(UIImage *)image {
    [self processPickedImages:@[image] wasTaken:YES];
}

- (void)didPickImages:(NSArray<UIImage *> *)images {
    [self processPickedImages:images wasTaken:NO];
}

@end
