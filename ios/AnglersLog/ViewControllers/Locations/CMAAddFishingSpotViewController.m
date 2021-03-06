//
//  CMAAddFishingSpotTableViewController.m
//  AnglersLog
//
//  Created by Cohen Adair on 11/6/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMAAddFishingSpotViewController.h"
#import "CMAAppDelegate.h"
#import "CMAConstants.h"
#import "CMAAlerts.h"
#import "CMAStorageManager.h"

@interface CMAAddFishingSpotViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic)IBOutlet UITextField *fishingSpotNameTextField;
@property (weak, nonatomic)IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic)IBOutlet MKMapView *mapView;
@property (weak, nonatomic)IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic)IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic)IBOutlet UIImageView *rectileImage;
@property (weak, nonatomic)IBOutlet UISegmentedControl *mapTypeControl;

@property (strong, nonatomic)CLLocationManager *locationManager;
@property (nonatomic)BOOL userLocationAdded;
@property (nonatomic)BOOL mapHasLoaded;
@property (nonatomic)BOOL tappedDoneButton;
@property (nonatomic)BOOL mapDidRender;
@property (nonatomic)BOOL showRenderError;

@end

#define kIndexTitle 0
#define kIndexMap 1
#define kIndexCoordinates 2

#define kHeightTitle 44
#define kHeightCoordinates 70

@implementation CMAAddFishingSpotViewController

#pragma mark - View Initializing

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.fishingSpot) {
        self.fishingSpot = [[CMAStorageManager sharedManager] managedFishingSpot];
        self.isEditingFishingSpot = NO;
    } else {
        self.fishingSpotNameTextField.text = self.fishingSpot.name;
        self.isEditingFishingSpot = YES;
    }
    
    self.mapDidRender = NO;
    self.showRenderError = YES;
    
    [self initMapView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    
    self.tappedDoneButton = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UILabel *legal = [self.mapView.subviews objectAtIndex:1];
    legal.center = CGPointMake(legal.center.x, legal.center.y - self.mapTypeControl.frame.size.height);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // if back is tapped and and we're not editing, clean up core data obejct
    if (!self.tappedDoneButton && !self.isEditingFishingSpot) {
        [[CMAStorageManager sharedManager] deleteManagedObject:self.fishingSpot saveContext:YES];
        self.fishingSpot = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Initializing

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // only set a footer for the last cell in the table
    if (section == ([self numberOfSectionsInTableView:tableView] - 1))
        return CGFLOAT_MIN;
    
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == kIndexTitle)
        return 44;
    
    CGFloat safeAreaInset = 0;
    if (@available(iOS 11.0, *)) {
        safeAreaInset = self.view.safeAreaInsets.bottom;
    }
    
    // so the map covers the remainder of the screen
    if (indexPath.row == kIndexMap)
        return tableView.frame.size.height - kHeightCoordinates - kHeightTitle - safeAreaInset;
    
    if (indexPath.row == kIndexCoordinates)
        return kHeightCoordinates + safeAreaInset;
    
    // using the super class's implementation gets the height set in storyboard
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - Events

- (IBAction)clickDoneButton:(UIBarButtonItem *)sender {
    // validate fishing spot name
    if ([[self.fishingSpotNameTextField text] isEqualToString:@""]) {
        [CMAAlerts showError:@"Please enter a fishing spot name." inVc:self];
        return;
    }

    // make sure the fishing spot doesn't already exist
    if (!self.isEditingFishingSpot)
        if ([self.locationFromAddLocation fishingSpotNamed:self.fishingSpotNameTextField.text] != nil) {
            [CMAAlerts showError:@"A fishing spot by that name already exists. Please choose a new name or edit the existing spot." inVc:self];
            return;
        }

    CLLocationCoordinate2D mapCenter = [self.mapView centerCoordinate];
    
    [self.fishingSpot setName:[[self.fishingSpotNameTextField text] mutableCopy]];
    [self.fishingSpot setLocation:[[CLLocation alloc] initWithLatitude:mapCenter.latitude longitude:mapCenter.longitude]];
    
    self.tappedDoneButton = YES;
    [self performSegueWithIdentifier:@"unwindToAddLocationFromAddFishingSpot" sender:self];
}

- (IBAction)dismissKeyboard:(UITextField *)textField {
    [textField becomeFirstResponder];
    [textField resignFirstResponder];
}

- (IBAction)mapTypeControlChange:(UISegmentedControl *)sender {
    [self.mapView setMapType:sender.selectedSegmentIndex];
    [[CMAStorageManager sharedManager] setUserMapType:sender.selectedSegmentIndex];
    self.mapDidRender = NO;
    self.showRenderError = YES;
    [self initRectileTint];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Map Initializing

#define kMapAreaX 800
#define kMapAreaY 800

- (void)initMapView {
    UIImage *image = [[UIImage imageNamed:@"crosshairs"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.rectileImage setImage:image];
    
    [self.mapTypeControl.layer setCornerRadius:5.0f];
    [self.mapTypeControl setSelectedSegmentIndex:[[CMAStorageManager sharedManager] getUserMapType]];
    [self.mapView setMapType:self.mapTypeControl.selectedSegmentIndex];
    [self initRectileTint];
    
    [self.mapTypeControl.superview bringSubviewToFront:self.mapTypeControl];
    [self.mapTypeControl.superview bringSubviewToFront:self.rectileImage];
    
    if ([self.locationFromAddLocation fishingSpotCount] > 0)
        [self setMapRegion];
    
    // added existing fishing spots
    for (CMAFishingSpot *spot in self.locationFromAddLocation.fishingSpots) {
        MKPointAnnotation *p = [MKPointAnnotation new];
        [p setCoordinate:spot.coordinate];
        [p setTitle:spot.name];
        
        [self.mapView addAnnotation:p];
    }
}

- (void)initRectileTint {
    self.rectileImage.tintColor = self.mapTypeControl.selectedSegmentIndex == MKMapTypeStandard
            ? UIColor.blackColor : UIColor.whiteColor;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    // dismiss keyboard if the map changes
    [self.view endEditing:YES];
}

// Update Lat and Long text fields when the user moves the map.
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D center = [mapView centerCoordinate];
    [self.latitudeLabel setText:[NSString stringWithFormat:@"%f", center.latitude]];
    [self.longitudeLabel setText:[NSString stringWithFormat:@"%f", center.longitude]];
}

- (void)setMapRegion {
    if (!self.mapHasLoaded) {
        MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));
        
        // display the correct are if we're editing an existing fishing spot
        if (self.isEditingFishingSpot)
            region = MKCoordinateRegionMakeWithDistance(self.fishingSpot.coordinate, kMapAreaX, kMapAreaY);
        else {
            if ([self.locationFromAddLocation fishingSpotCount] > 0)
                region = [self.locationFromAddLocation mapRegion]; // set the correct region if there is already fishing spots for the location
        }
        
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:NO];
        self.mapHasLoaded = YES;
    }
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    self.mapDidRender = YES;
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
    NSLog(@"Failed to load map: %@.", error.localizedDescription);
    
    if (!self.mapDidRender && self.showRenderError) {
        [CMAAlerts showError:@"Failed to render map. Please try again later, zoom out, or select a different map type." inVc:self];
        self.showRenderError = NO;
    }
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!self.isEditingFishingSpot && !self.userLocationAdded && [self.locationFromAddLocation fishingSpotCount] <= 0) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(manager.location.coordinate, kMapAreaX, kMapAreaY);
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
        
        self.userLocationAdded = YES;
        [manager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [CMAAlerts showError:@"Failed to get location. Try again later or manually drag the map to your location." inVc:self];
    NSLog(@"Failed to get user location. Error: %@", error.localizedDescription);
}

@end
