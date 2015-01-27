//
//  CMAConstants.h
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/19/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#ifndef MyFishingJournal_CMAConstants_h
#define MyFishingJournal_CMAConstants_h

typedef enum cvID_e : int16_t {
    CMAViewControllerIDNil = -1,
    CMAViewControllerIDViewEntries = 0,
    CMAViewControllerIDEditSettings = 1,
    CMAViewControllerIDAddEntry = 2,
    CMAViewControllerIDSingleEntry = 3,
    CMAViewControllerIDSingleLocation = 4,
    CMAViewControllerIDSingleBait = 5,
    CMAViewControllerIDViewBaits = 6,
    CMAViewControllerIDStatistics = 7,
    CMAViewControllerIDSelectFishingSpot = 8
} CMAViewControllerID;

// Each value represents the index for an item in a UISegmentedControlView.
typedef enum msID_e : int16_t {
    CMAMeasuringSystemTypeImperial = 0,
    CMAMeasuringSystemTypeMetric = 1
} CMAMeasuringSystemType;

// Each value represents the index for an item in a UISegmentedControlView.
typedef enum soID_e : int16_t {
    CMASortOrderAscending = 0,
    CMASortOrderDescending = 1
} CMASortOrder;

// Each value represents the index for an item in a UISegmentedControlView.
typedef enum btID_e : int16_t {
    CMABaitTypeArtificial = 0,
    CMABaitTypeLive = 1
} CMABaitType;

// Each value >= 0 represents an index for a row in a UITableView.
typedef enum smID_e : int16_t {
    CMAEntrySortMethodNil = -1,
    CMAEntrySortMethodDate = 0,
    CMAEntrySortMethodSpecies = 1,
    CMAEntrySortMethodLocation = 2,
    CMAEntrySortMethodLength = 3,
    CMAEntrySortMethodWeight = 4,
    CMAEntrySortMethodBaitUsed = 5
} CMAEntrySortMethod;

#pragma mark - User Define Name (UDN)

extern NSString *const UDN_SPECIES;
extern NSString *const UDN_BAITS;
extern NSString *const UDN_LOCATIONS;
extern NSString *const UDN_FISHING_METHODS;
extern NSString *const UDN_WATER_CLARITIES;

#pragma mark - Core Data Entities (CDE)

extern NSString *const CDE_JOURNAL;
extern NSString *const CDE_ENTRY;
extern NSString *const CDE_USER_DEFINE;
extern NSString *const CDE_SPECIES;
extern NSString *const CDE_BAIT;
extern NSString *const CDE_LOCATION;
extern NSString *const CDE_FISHING_METHOD;
extern NSString *const CDE_WATER_CLARITY;
extern NSString *const CDE_WEATHER_DATA;
extern NSString *const CDE_FISHING_SPOT;

extern NSString *const APP_NAME;

// Used for splitting up NSStrings.
extern NSString *const TOKEN_FISHING_METHODS;
extern NSString *const TOKEN_LOCATION;

// User data file name.
extern NSString *const ARCHIVE_FILE_NAME;

extern NSString *const SHARE_MESSAGE;
extern NSString *const REMOVED_TEXT; // text displayed in an entry when a user define has been removed

// measurement units
extern NSString *const UNIT_IMPERIAL_LENGTH;
extern NSString *const UNIT_IMPERIAL_LENGTH_SHORTHAND;
extern NSString *const UNIT_IMPERIAL_WEIGHT;
extern NSString *const UNIT_IMPERIAL_WEIGHT_SHORTHAND;
extern NSString *const UNIT_IMPERIAL_WEIGHT_SMALL;
extern NSString *const UNIT_IMPERIAL_WEIGHT_SMALL_SHORTHAND;
extern NSString *const UNIT_IMPERIAL_DEPTH;
extern NSString *const UNIT_IMPERIAL_DEPTH_SHORTHAND;
extern NSString *const UNIT_IMPERIAL_TEMPERATURE;
extern NSString *const UNIT_IMPERIAL_TEMPERATURE_SHORTHAND;
extern NSString *const UNIT_IMPERIAL_SPEED;
extern NSString *const UNIT_IMPERIAL_SPEED_SHORTHAND;

extern NSString *const UNIT_METRIC_LENGTH;
extern NSString *const UNIT_METRIC_LENGTH_SHORTHAND;
extern NSString *const UNIT_METRIC_WEIGHT;
extern NSString *const UNIT_METRIC_WEIGHT_SHORTHAND;
extern NSString *const UNIT_METRIC_DEPTH;
extern NSString *const UNIT_METRIC_DEPTH_SHORTHAND;
extern NSString *const UNIT_METRIC_TEMPERATURE;
extern NSString *const UNIT_METRIC_TEMPERATURE_SHORTHAND;
extern NSString *const UNIT_METRIC_SPEED;
extern NSString *const UNIT_METRIC_SPEED_SHORTHAND;

// notifications
extern NSString *const NOTIFICATION_CHANGE_JOURNAL;

extern NSString *const GLOBAL_FONT;

extern CGFloat const TABLE_SECTION_SPACING;

UIColor *CELL_COLOR_DARK; // initialized in AppDelegate.m
UIColor *CELL_COLOR_LIGHT; // initialized in AppDelegate.m

#define kTableSectionHeaderHeight 40
#define kTableFooterHeight 25

#define kWeatherCellHeightExpanded 90

#define kOuncesInAPound 16

#endif
