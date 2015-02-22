//
//  CMAImage.h
//  TheAnglersLog
//
//  Created by Cohen Adair on 2015-01-27.
//  Copyright (c) 2015 Cohen Adair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CMABait, CMAEntry;

@interface CMAImage : NSManagedObject

@property (strong, nonatomic)NSData *data;
@property (strong, nonatomic)NSData *tableThumbnailData;
@property (strong, nonatomic)NSData *galleryThumbnailData;
@property (strong, nonatomic)CMAEntry *entry;
@property (strong, nonatomic)CMABait *bait;

- (void)handleModelUpdate;

- (UIImage *)dataAsUIImage;
- (UIImage *)dataAsUIImage:(NSData *)data;

- (void)setDataFromUIImage:(UIImage *)anImage;
- (NSData *)dataFromUIImage:(UIImage *)anImage;

@end
