//
//  CMAJournal.h
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/9/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMAEntry.h"
#import "CMAConstants.h"
#import "CMAUserDefine.h"

@interface CMAJournal : NSObject <NSCoding>

@property (strong, nonatomic)NSMutableArray *entries;
@property (strong, nonatomic)NSMutableDictionary *userDefines;
@property (nonatomic)CMAMeasuringSystemType measurementSystem;
@property (nonatomic)CMAEntrySortMethod entrySortMethod;
@property (nonatomic)CMASortOrder entrySortOrder;

// initializing
- (void)validateUserDefines;

// archiving
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (void)archive;

// editing
- (BOOL)addEntry: (CMAEntry *)anEntry;
- (void)removeEntryDated: (NSDate *)aDate;
- (void)editEntryDated: (NSDate *)aDate newProperties: (CMAEntry *)aNewEntry;

- (void)addUserDefine: (NSString *)aDefineName objectToAdd: (id)anObject;
- (void)removeUserDefine: (NSString *)aDefineName objectNamed: (NSString *)anObjectName;
- (void)editUserDefine: (NSString *)aDefineName objectNamed: (id)aName newProperties: (id)aNewObject;

// accessing
- (CMAUserDefine *)userDefineNamed: (NSString *)aName;
- (NSInteger)entryCount;
- (CMAEntry *)entryDated: (NSDate *)aDate;
- (NSString *)lengthUnitsAsString: (BOOL)shorthand;
- (NSString *)weightUnitsAsString: (BOOL)shorthand;
- (NSString *)depthUnitsAsString: (BOOL)shorthand;
- (NSString *)temperatureUnitsAsString: (BOOL)shorthand;
- (NSString *)speedUnitsAsString: (BOOL)shorthand;

// sorting
- (void)sortEntriesBy: (CMAEntrySortMethod)aSortMethod order: (CMASortOrder)aSortOrder;

@end