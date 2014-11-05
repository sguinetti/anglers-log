//
//  CMASingleLocationViewController.h
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/20/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "CMALocation.h"
#import "CMAConstants.h"

@interface CMASingleLocationViewController : UITableViewController <MKMapViewDelegate>

@property (nonatomic)CMAViewControllerID previousViewID;
@property (strong, nonatomic)CMALocation *location;
@property (strong, nonatomic)CMAFishingSpot *fishingSpotFromSingleEntry;
@property (strong, nonatomic)NSIndexPath *selectedFishingSpotFromSingleEntry;

@property (strong, nonatomic)NSString *addEntryLabelText;
@property (nonatomic)BOOL isSelectingForAddEntry;

@end
