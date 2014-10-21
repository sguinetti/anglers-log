//
//  CMAUserDefine.m
//  MyFishingJournal
//
//  Created by Cohen Adair on 10/9/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMAUserDefine.h"
#import "CMALocation.h"

@implementation CMAUserDefine

#pragma mark - Initialization

- (CMAUserDefine *)init {
    _objects = [NSMutableSet set];
    return self;
}

#pragma Editing

- (void)addObject: (id)anObject {
    [self.objects addObject:anObject];
}

- (void)removeObjectNamed: (NSString *)aName {
    NSAssert(NO, @"Subclass needs to overwrite this method");
}

- (void)editObjectNamed: (NSString *)aName newObject: (id)aNewObject {
    NSAssert(NO, @"Subclass needs to overwrite this method");
}

#pragma mark - Accessing

- (NSInteger)count {
    return [self.objects count];
}

- (NSString *)nameAtIndex: (NSInteger)anIndex {
    NSAssert(NO, @"Subclass needs to overwrite this method");
    return nil;
}

@end
