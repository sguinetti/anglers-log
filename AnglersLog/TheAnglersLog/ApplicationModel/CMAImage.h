//
//  CMAImage.h
//  AnglersLog
//
//  Created by Cohen Adair on 2015-01-27.
//  Copyright (c) 2015 Cohen Adair. All rights reserved.
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CMABait, CMAEntry;

@interface CMAImage : NSManagedObject

@property (strong, nonatomic)NSString *imagePath;
@property (strong, nonatomic)CMAEntry *entry;
@property (strong, nonatomic)CMABait *bait;

@property (strong, nonatomic)UIImage *image;
@property (strong, nonatomic)UIImage *tableCellImage;
@property (strong, nonatomic)UIImage *galleryCellImage;

- (void)handleModelUpdate;
- (void)initProperties;

- (void)saveWithImage:(UIImage *)anImage andFileName:(NSString *)aFileName;
- (void)saveWithIndex:(NSInteger)anIndex;

@end