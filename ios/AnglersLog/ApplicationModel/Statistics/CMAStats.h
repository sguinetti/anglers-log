//
//  CMABaitStats.h
//  AnglersLog
//
//  Created by Cohen Adair on 11/25/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMAStatsObject.h"
#import "CMAJournal.h"

@interface CMAStats : NSObject

#define kHighCatchEntryLength 0
#define kHighCatchEntryWeight 1

typedef NS_ENUM(NSInteger, CMAPieChartDataType) {
    CMAPieChartDataTypeCaught = 0,
    CMAPieChartDataTypeWeight = 1,
    CMAPieChartDataTypeBait = 2,
    CMAPieChartDataTypeLocation = 3
};

@property (strong, nonatomic)CMAJournal *journal;
@property (strong, nonatomic)NSArray *sliceObjects;
@property (strong, nonatomic)NSString *totalDescription;
@property (strong, nonatomic)NSString *detailDescription;
@property (strong, nonatomic)NSString *detailDescription2;
@property (strong, nonatomic)NSString *userDefineName;
@property (nonatomic)NSInteger totalValue;                  // used to calculate percentages
@property (nonatomic)NSInteger totalButtonLabelValue;       // displayed when the "Total" button is clicked
@property (nonatomic)CMAPieChartDataType pieChartDataType;

// initializing
+ (CMAStats *)forCaughtWithJournal:(CMAJournal *)aJournal;
+ (CMAStats *)forWeightWithJournal:(CMAJournal *)aJournal;
+ (CMAStats *)forBaitWithJournal:(CMAJournal *)aJournal;
+ (CMAStats *)forLocationWithJournal:(CMAJournal *)aJournal;

// accessing
- (NSInteger)sliceObjectCount;
- (NSDate *)earliestEntryDate;
- (CMAEntry *)highCatchEntryFor:(NSInteger)lengthOrWeight;

- (NSInteger)highestValueIndex;
- (NSInteger)indexForName:(NSString *)aName;
- (NSInteger)valueForSliceAtIndex:(NSInteger)anIndex;
- (NSInteger)valueForPercentAtIndex:(NSInteger)anIndex;
- (NSString *)stringForPercentAtIndex:(NSInteger)anIndex;
- (NSString *)nameAtIndex:(NSInteger)anIndex;
- (NSString *)detailTextAtIndex:(NSInteger)anIndex;

@end
