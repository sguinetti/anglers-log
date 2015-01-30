//
//  CMALocation.m
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/3/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMALocation.h"
#import "CMAConstants.h"
#import "CMAAppDelegate.h"
#import "CMAStorageManager.h"

@implementation CMALocation

@dynamic entries;
@dynamic userDefine;

@dynamic fishingSpots;

#pragma mark - Global Accessing

- (CMAJournal *)journal {
    return [[CMAStorageManager sharedManager] sharedJournal];
}

#pragma mark - Initialization

- (CMALocation *)initWithName:(NSString *)aName andUserDefine:(CMAUserDefine *)aUserDefine {
    self.name = [NSMutableString stringWithString:[aName capitalizedString]];
    self.fishingSpots = [NSMutableOrderedSet orderedSet];
    self.entries = [NSMutableSet set];
    self.userDefine = aUserDefine;
    
    return self;
}

// Used to initialize objects created from an archive. For compatibility purposes.
- (void)validateProperties {
    if (!self.name)
        self.name = [NSMutableString string];
    
    if (!self.fishingSpots)
        self.fishingSpots = [NSMutableOrderedSet orderedSet];
    
    for (CMAFishingSpot *f in self.fishingSpots)
        [f validateProperties];
}

#pragma mark - Archiving
/*
- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _name = [aDecoder decodeObjectForKey:@"CMALocationName"];
        _fishingSpots = [aDecoder decodeObjectForKey:@"CMALocationFishingSpots"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"CMALocationName"];
    [aCoder encodeObject:self.fishingSpots forKey:@"CMALocationFishingSpots"];
}
*/
#pragma mark - Editing

- (BOOL)addFishingSpot: (CMAFishingSpot *)aFishingSpot {
    if ([self fishingSpotNamed:aFishingSpot.name] != nil) {
        NSLog(@"Fishing spot with name %@ already exists", aFishingSpot.name);
        return NO;
    }

    [self.fishingSpots addObject:aFishingSpot];
    [self sortFishingSpotsByName];
    
    return YES;
}

- (void)removeFishingSpotNamed: (NSString *)aName {
    CMAFishingSpot *spot = [self fishingSpotNamed:aName];
    
    // remove from core data
    [[CMAStorageManager sharedManager] deleteManagedObject:spot];
    
    [self.fishingSpots removeObject:spot];
}

- (void)editFishingSpotNamed: (NSString *)aName newProperties: (CMAFishingSpot *)aNewFishingSpot; {
    [[self fishingSpotNamed:aName] edit:aNewFishingSpot];
}

// updates self's properties with aNewLocation's properties
- (void)edit:(CMALocation *)aNewLocation {
    [self setName:[aNewLocation.name capitalizedString]];
    [self setFishingSpots:aNewLocation.fishingSpots];
}

- (void)addEntry:(CMAEntry *)anEntry {
    [self.entries addObject:anEntry];
}

#pragma mark - Accessing

- (NSInteger)fishingSpotCount {
    return [self.fishingSpots count];
}

// returns nil if a fishing spot with aName does not exist, otherwise returns a pointer to the existing fishing spot
- (CMAFishingSpot *)fishingSpotNamed: (NSString *)aName {
    for (CMAFishingSpot *spot in self.fishingSpots)
        if ([spot.name isEqualToString:[aName capitalizedString]])
            return spot;
    
    return nil;
}

// Returns a MKCoordinateRegion for this location. Used for display on a MKMapView.
- (MKCoordinateRegion)mapRegion {
    MKCoordinateRegion result;

    if ([self fishingSpotCount] > 0) {
        CMAFishingSpot *fishingSpot = [[self fishingSpots] objectAtIndex:0];
        
        CLLocationDegrees maxLatitude = fishingSpot.coordinate.latitude;
        CLLocationDegrees minLatitude = fishingSpot.coordinate.latitude;
        CLLocationDegrees maxLongitude = fishingSpot.coordinate.longitude;
        CLLocationDegrees minLongitude = fishingSpot.coordinate.longitude;
        
        for (CMAFishingSpot *p in [self fishingSpots]) {
            if (p.coordinate.latitude < minLatitude)
                minLatitude = p.coordinate.latitude;
            
            if (p.coordinate.latitude > maxLatitude)
                maxLatitude = p.coordinate.latitude;
            
            if (p.coordinate.longitude < minLongitude)
                minLongitude = p.coordinate.longitude;
            
            if (p.coordinate.longitude > maxLongitude)
                maxLongitude = p.coordinate.longitude;
        }
        
        result.center.latitude = minLatitude + ((maxLatitude - minLatitude) / 2);
        result.center.longitude = minLongitude + ((maxLongitude - minLongitude) / 2);
        
        // add some padding to the region
        result.span.latitudeDelta = (maxLatitude - minLatitude) * 2.0;
        result.span.longitudeDelta = (maxLongitude - minLongitude) * 2.0;
        
        if (result.span.latitudeDelta < 0.001220)
            result.span.latitudeDelta = 0.001220;
        
        if (result.span.longitudeDelta < 0.001120)
            result.span.longitudeDelta = 0.001120;
    }

    return result;
}

#pragma mark - Sorting

- (void)sortFishingSpotsByName {
    NSArray *sortedArray = [self.fishingSpots sortedArrayUsingComparator:^NSComparisonResult(CMAFishingSpot *s1, CMAFishingSpot *s2){
        return [s1.name compare:s2.name];
    }];
    
    self.fishingSpots = [NSMutableOrderedSet orderedSetWithArray:sortedArray];
}

@end
