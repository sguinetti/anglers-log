//
//  CMASingleLocationViewController.h
//  AnglersLog
//
//  Created by Cohen Adair on 10/19/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import "CMAConstants.h"
#import "CMALocation.h"

@interface CMAAddLocationViewController : UITableViewController

@property (nonatomic)CMAViewControllerID previousViewID;
@property (strong, nonatomic)CMALocation *location;

@end
