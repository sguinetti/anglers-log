//
//  CMAUserDefineProtocol.h
//  MyFishingJournal
//
//  Created by Cohen Adair on 2015-01-01.
//  Copyright (c) 2015 Cohen Adair. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CMAUserDefineProtocol <NSObject>

@required
@property (strong, nonatomic)NSString *name;
- (void)validateProperties;
- (void)edit:(id)aNewObject;

@end