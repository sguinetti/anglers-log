//
//  CMAAddFishingSpotTableViewController.m
//  MyFishingJournal
//
//  Created by Cohen Adair on 11/6/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMAAddFishingSpotViewController.h"
#import "CMAAppDelegate.h"
#import "CMAConstants.h"
#import "CMAAlerts.h"

@interface CMAAddFishingSpotViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic)IBOutlet UITextField *fishingSpotNameTextField;
@property (weak, nonatomic)IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic)IBOutlet MKMapView *mapView;
@property (weak, nonatomic)IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic)IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic)IBOutlet UIImageView *rectileImage;
@property (weak, nonatomic)IBOutlet UIView *loadingMapView;

@property (strong, nonatomic)CLLocationManager *locationManager;
@property (nonatomic)BOOL userLocationAdded;
@property (nonatomic)BOOL mapHasLoaded;

@end

NSInteger const INDEX_TITLE = 0;
NSInteger const INDEX_MAP = 1;
NSInteger const INDEX_COORDINATES = 2;

@implementation CMAAddFishingSpotViewController

#pragma mark - View Initializing

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.fishingSpot) {
        self.fishingSpot = [CMAFishingSpot new];
        self.isEditingFishingSpot = NO;
    } else {
        self.fishingSpotNameTextField.text = self.fishingSpot.name;
        self.isEditingFishingSpot = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self.locationFromAddLocation fishingSpotCount] > 0)
        [self setMapRegion];
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
    if (indexPath.item == 0)
        return 44;
    
    if (indexPath.item == INDEX_MAP)
        return tableView.frame.size.width * 0.75;
    
    // using the super class's implementation gets the height set in storyboard
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - Events

- (IBAction)clickDoneButton:(UIBarButtonItem *)sender {
    // validate fishing spot name
    if ([[self.fishingSpotNameTextField text] isEqualToString:@""]) {
        [CMAAlerts errorAlert:@"Please enter a fishing spot name."];
        return;
    }
    
    // make sure the fishing spot doesn't already exist
    if (!self.isEditingFishingSpot)
        if ([self.locationFromAddLocation fishingSpotNamed:self.fishingSpotNameTextField.text] != nil) {
            [CMAAlerts errorAlert:@"A fishing spot by that name already exists. Please choose a new name or edit the existing spot."];
            return;
        }

    CLLocationCoordinate2D mapCenter = [self.mapView centerCoordinate];
    
    [self.fishingSpot setName:[[self.fishingSpotNameTextField text] mutableCopy]];
    [self.fishingSpot setLocation:[[CLLocation alloc] initWithLatitude:mapCenter.latitude longitude:mapCenter.longitude]];
    
    [self performSegueWithIdentifier:@"unwindToAddLocationFromAddFishingSpot" sender:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Map Initializing

#define AREA_X 800
#define AREA_Y 800

// Update Lat and Long text fields when the user moves the map.
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D center = [mapView centerCoordinate];
    [self.latitudeLabel setText:[NSString stringWithFormat:@"%f", center.latitude]];
    [self.longitudeLabel setText:[NSString stringWithFormat:@"%f", center.longitude]];
}

- (void)setMapRegion {
    if (!self.mapHasLoaded) {
        MKCoordinateRegion region;
        
        // display the correct are if we're editing an existing fishing spot
        if (self.isEditingFishingSpot)
            region = MKCoordinateRegionMakeWithDistance(self.fishingSpot.coordinate, AREA_X, AREA_Y);
        else {
            if ([self.locationFromAddLocation fishingSpotCount] > 0)
                region = [self.locationFromAddLocation mapRegion]; // set the correct region if there is already fishing spots for the location
        }
        
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:NO];
        self.mapHasLoaded = YES;
    }
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    [self.mapView setHidden:NO];
    [self.rectileImage setHidden:NO];
    [self.loadingMapView setHidden:YES];
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!self.isEditingFishingSpot && !self.userLocationAdded && [self.locationFromAddLocation fishingSpotCount] <= 0) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(manager.location.coordinate, AREA_X, AREA_Y);
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
        
        self.userLocationAdded = YES;
        [manager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [CMAAlerts errorAlert:[NSString stringWithFormat:@"Failed to get user location. Error: %@", error.localizedDescription]];
}

@end