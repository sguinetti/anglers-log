//
//  CMAEditSettingsViewController.h
//  AnglersLog
//
//  Created by Cohen Adair on 10/19/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMAJournal.h"
#import "CMATableViewController.h"
#import "CMAUserDefine.h"

@interface CMAUserDefinesViewController : CMATableViewController

// a pointer to the journal's userDefine object for the cell clicked in the previous view
@property (strong, nonatomic)CMAUserDefine *userDefine;
@property (nonatomic)CMAViewControllerID previousViewID;

// used for communication to the Add Entry view
@property (strong, nonatomic)NSString *selectedCellLabelText;

// used to check off cells when editing
@property (strong, nonatomic)NSMutableArray<NSString *> *selectedCellsArray;

@end
