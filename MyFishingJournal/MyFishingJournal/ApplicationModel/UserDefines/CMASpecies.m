//
//  CMASpecies.m
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/27/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMASpecies.h"

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
    }
    
    return self;
}

#pragma mark - Archiving

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _name = [aDecoder decodeObjectForKey:@"CMASpeciesName"];
        _numberCaught = [aDecoder decodeObjectForKey:@"CMASpeciesNumberCaught"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"CMASpeciesName"];
    [aCoder encodeObject:self.numberCaught forKey:@"CMASpeciesNumberCaught"];
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

@end
