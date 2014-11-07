//
//  CMASingleLocationViewController.m
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/19/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMAAddLocationViewController.h"
#import "CMAAddFishingSpotViewController.h"
#import "CMAAppDelegate.h"

@interface CMAAddLocationViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@end

NSInteger const SECTION_TITLE = 0;
NSInteger const SECTION_FISHING_SPOTS = 1;
NSInteger const SECTION_ADD = 2;

@implementation CMAAddLocationViewController

#pragma mark - Global Accessing

- (CMAJournal *)journal {
    return [((CMAAppDelegate *)[[UIApplication sharedApplication] delegate]) journal];
}

#pragma mark - View Management

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setEditing:YES];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]]; // removes empty cells at the end of the list
    
    self.location = [CMALocation withName:@""];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Initializing

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == SECTION_ADD && [self.location fishingSpotCount] <= 0)
        return CGFLOAT_MIN;
    
    return TABLE_SECTION_SPACING;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SECTION_FISHING_SPOTS)
        return [self.location fishingSpotCount];
    
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_FISHING_SPOTS)
        return YES;
    
    return NO;
}

// Initialize each cell.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_TITLE) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationNameCell" forIndexPath:indexPath];
        return cell;
    }
    
    if (indexPath.section == SECTION_FISHING_SPOTS) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fishingSpotCell" forIndexPath:indexPath];
        
        CMAFishingSpot *fishingSpot = [self.location.fishingSpots objectAtIndex:indexPath.item];
        NSString *coordinateText = [NSString stringWithFormat:@"Lat: %f, Long: %f", fishingSpot.location.coordinate.latitude, fishingSpot.location.coordinate.longitude];
        
        cell.textLabel.text = fishingSpot.name;
        cell.detailTextLabel.text = coordinateText;
        
        return cell;
    }
    
    if (indexPath.section == SECTION_ADD) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addFishingSpotCell" forIndexPath:indexPath];
        return cell;
    }
    
    return nil;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_TITLE)
        return UITableViewCellEditingStyleNone;
    
    if (indexPath.section == SECTION_FISHING_SPOTS)
        return UITableViewCellEditingStyleDelete;
    
    if (indexPath.section == SECTION_ADD)
        return UITableViewCellEditingStyleNone;
    
    return UITableViewCellEditingStyleDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // delete from data source
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self.location removeFishingSpotNamed:cell.textLabel.text];
        
        // delete from table
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Location Creation

- (BOOL)checkUserInputAndSetLocation: (CMALocation *)aLocation {
    return NO;
}

#pragma mark - Events

- (IBAction)clickedDone:(id)sender {
    // add new event to journal
    CMALocation *locationToAdd = [CMALocation new];
    
    if ([self checkUserInputAndSetLocation:locationToAdd]) {
        if (self.previousViewID == CMAViewControllerID_SingleLocation) {
            [[self journal] editUserDefine:SET_LOCATIONS objectNamed:self.location.name newProperties:locationToAdd];
            [self setLocation:locationToAdd];
        } else
            [[self journal] addUserDefine:SET_LOCATIONS objectToAdd:locationToAdd];
        
        [self performSegueToPreviousView];
    }
}

- (IBAction)clickedCancel:(id)sender {
    [self performSegueToPreviousView];
}

#pragma mark - Navigation

- (void)performSegueToPreviousView {
    switch (self.previousViewID) {
        case CMAViewControllerID_EditSettings:
            [self performSegueWithIdentifier:@"unwindToEditSettings" sender:self];
            break;
            
        default:
            NSLog(@"Invalid previousViewID value");
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"fromFishingSpotCellToAddFishingSpot"]) {
        CMAAddFishingSpotViewController *destination = [[segue.destinationViewController viewControllers] objectAtIndex:0];
        NSString *selectedCellText = [[[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]] textLabel] text];
        destination.fishingSpot = [self.location fishingSpotNamed:selectedCellText];
        destination.locationFromAddLocation = self.location;
    }
    
    if ([segue.identifier isEqualToString:@"fromAddFishingSpotCellToAddFishingSpot"]) {
        CMAAddFishingSpotViewController *destination = [[segue.destinationViewController viewControllers] objectAtIndex:0];
        destination.locationFromAddLocation = self.location;
    }
}

- (IBAction)unwindToAddLocation:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"unwindToAddLocation"]) {
        CMAAddFishingSpotViewController *source = [segue sourceViewController];
        
        if (!source.isEditingFishingSpot)
            [self.location addFishingSpot:source.fishingSpot];
        
        [self.tableView reloadData];
    }
}

@end
