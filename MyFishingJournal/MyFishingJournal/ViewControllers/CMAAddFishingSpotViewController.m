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

@interface CMAAddFishingSpotViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *fishingSpotNameTextField;
@property (weak, nonatomic)IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic)IBOutlet MKMapView *mapView;
@property (weak, nonatomic)IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic)IBOutlet UILabel *longitudeLabel;

@property (strong, nonatomic)CLLocationManager *locationManager;

@end

NSInteger const INDEX_TITLE = 0;
NSInteger const INDEX_MAP = 1;
NSInteger const INDEX_COORDINATES = 2;

@implementation CMAAddFishingSpotViewController

#pragma mark - View Initializing

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [CLLocationManager new];
    [self.locationManager setDelegate:self];
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    
    if (!self.fishingSpot) {
        self.fishingSpot = [CMAFishingSpot new];
        self.isEditingFishingSpot = NO;
    } else {
        self.fishingSpotNameTextField.text = self.fishingSpot.name;
        self.isEditingFishingSpot = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Initializing

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return TABLE_SECTION_SPACING;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // only set a footer for the last cell in the table
    if (section == ([self numberOfSectionsInTableView:tableView] - 1))
        return TABLE_SECTION_SPACING;
    
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == INDEX_MAP) {
        return tableView.frame.size.width * 0.75;
    }
    
    // using the super class's implementation gets the height set in storyboard
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - Events
- (IBAction)clickDoneButton:(UIBarButtonItem *)sender {
    // validate fishing spot name
    if ([[self.fishingSpotNameTextField text] isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a fishing spot name." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    // make sure the fishing spot doesn't already exist
    if (!self.isEditingFishingSpot)
        if ([self.locationFromAddLocation fishingSpotNamed:self.fishingSpotNameTextField.text] != nil) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"A fishing spot by that name already exists. Please choose a new name or edit the existing spot." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }

    CLLocationCoordinate2D mapCenter = [self.mapView centerCoordinate];
    
    [self.fishingSpot setName:[[self.fishingSpotNameTextField text] mutableCopy]];
    [self.fishingSpot setLocation:[[CLLocation alloc] initWithLatitude:mapCenter.latitude longitude:mapCenter.longitude]];
    
    [self performSegueWithIdentifier:@"unwindToAddLocation" sender:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Map Initializing

// Update Lat and Long text fields when the user moves the map.
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D center = [mapView centerCoordinate];
    [self.latitudeLabel setText:[NSString stringWithFormat:@"%f", center.latitude]];
    [self.longitudeLabel setText:[NSString stringWithFormat:@"%f", center.longitude]];
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
    if (![self.fishingSpot.name isEqualToString:@""]) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.fishingSpot.coordinate, 800, 800);
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:NO];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if ([self.fishingSpot.name isEqualToString:@""]) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    }
}

@end
