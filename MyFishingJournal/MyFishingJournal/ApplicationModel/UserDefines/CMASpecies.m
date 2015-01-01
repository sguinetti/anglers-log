//
//  CMASpecies.m
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/27/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMASpecies.h"
#import "CMAConstants.h"

@implementation CMASpecies

#pragma mark - Instance Creation

+ (CMASpecies *)withName: (NSString *)aName {
    return [[self alloc] initWithName:[aName capitalizedString]];
}

#pragma mark - Initialization

- (id)initWithName: (NSString *)aName {
    if (self = [super init]) {
        _name = aName;
        _numberCaught = [NSNumber numberWithInteger:0];
        _weightCaught = [NSNumber numberWithInteger:0];
        _ouncesCaught = [NSNumber numberWithInteger:0];
    }
    
    return self;
}

// Used to initialize objects created from an archive. For compatibility purposes.
- (void)validateProperties {
    if (!self.name)
        self.name = [NSMutableString string];
    
    if (!self.numberCaught)
        self.numberCaught = [NSNumber numberWithInteger:0];
    
    if (!self.weightCaught)
        self.weightCaught = [NSNumber numberWithInteger:0];
    
    if (!self.ouncesCaught)
        self.ouncesCaught = [NSNumber numberWithInteger:0];
}

#pragma mark - Archiving

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _name = [aDecoder decodeObjectForKey:@"CMASpeciesName"];
        _numberCaught = [aDecoder decodeObjectForKey:@"CMASpeciesNumberCaught"];
        _weightCaught = [aDecoder decodeObjectForKey:@"CMASpeciesWeightCaught"];
        _ouncesCaught = [aDecoder decodeObjectForKey:@"CMASpeciesOuncesCaught"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"CMASpeciesName"];
    [aCoder encodeObject:self.numberCaught forKey:@"CMASpeciesNumberCaught"];
    [aCoder encodeObject:self.weightCaught forKey:@"CMASpeciesWeightCaught"];
    [aCoder encodeObject:self.ouncesCaught forKey:@"CMASpeciesOuncesCaught"];
}

#pragma mark - Editing

- (void)edit: (CMASpecies *)aNewSpecies {
    [self setName:[aNewSpecies.name capitalizedString]];
}

- (void)incNumberCaught: (NSInteger)incBy {
    NSInteger count = [self.numberCaught integerValue];
    count += incBy;
    
    [self setNumberCaught:[NSNumber numberWithInteger:count]];
}

- (void)decNumberCaught: (NSInteger)decBy {
    NSInteger count = [self.numberCaught integerValue];
    count -= decBy;
    
    [self setNumberCaught:[NSNumber numberWithInteger:count]];
}

- (void)incWeightCaught: (NSInteger)incBy {
    NSInteger count = [self.weightCaught integerValue];
    count += incBy;
    
    [self setWeightCaught:[NSNumber numberWithInteger:count]];
}

- (void)decWeightCaught: (NSInteger)decBy {
    NSInteger count = [self.weightCaught integerValue];
    count -= decBy;
    
    [self setWeightCaught:[NSNumber numberWithInteger:count]];
}

- (void)incOuncesCaught: (NSInteger)incBy {
    NSInteger count = [self.ouncesCaught integerValue];
    count += incBy;
    
    [self setOuncesCaught:[NSNumber numberWithInteger:count]];
}

- (void)decOuncesCaught: (NSInteger)decBy {
    NSInteger count = [self.ouncesCaught integerValue];
    count -= decBy;
    
    [self setOuncesCaught:[NSNumber numberWithInteger:count]];
}

#pragma mark - Other

// other
- (BOOL)removedFromUserDefines {
    return [self.name isEqualToString:REMOVED_TEXT];
}

@end
