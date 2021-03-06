//
//  CMASideMenuViewController.m
//  AnglersLog
//
//  Created by Cohen Adair on 11/12/14.
//  Copyright (c) 2014 Cohen Adair. All rights reserved.
//

#import "CMASideMenuViewController.h"
#import "CMAUserDefinesViewController.h"
#import "CMAAppDelegate.h"
#import "SWRevealViewController.h"
#import "CMAStorageManager.h"
#import "CMAAlerts.h"
#import "CMAUtilities.h"
#import "UIColor+CMA.h"

@interface CMASideMenuViewController ()

@property (weak, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UITableViewCell *instagramCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *twitterCell;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (strong, nonatomic)UIView *statusBar;

@end

#define kBannerCell 9
#define kInstagramCell 9
#define kTwitterCell 10

#define kInstagram 1
#define kTwitter 2

@implementation CMASideMenuViewController

#pragma mark - Global Accessing

- (CMAJournal *)journal {
    return [[CMAStorageManager sharedManager] sharedJournal];
}

#pragma mark - View Management

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    CGFloat statusBarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
    self.statusBar = [[UIView alloc] initWithFrame:CGRectMake(0, -statusBarHeight, self.view.frame.size.width, statusBarHeight)];
    [self.statusBar setBackgroundColor:UIColor.anglersLogLight];
    [self.view addSubview:self.statusBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Initializing

- (CMAUserDefine *)userDefineFromSelectedCell {
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
    return [[self journal] userDefineNamed:[(UILabel *)[selectedCell viewWithTag:100] text]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView cellForRowAtIndexPath:indexPath] == self.instagramCell) {
        NSString *instagramString = [NSString stringWithFormat:@"instagram://tag?name=%@", HASHTAG_TEXT];
        
        if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:instagramString]])
            [CMAAlerts showError:@"Please install the Instagram app to use this feature." inVc:self];

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if ([tableView cellForRowAtIndexPath:indexPath] == self.twitterCell) {
        NSString *appText = [@"twitter://search?query=%23" stringByAppendingString:HASHTAG_TEXT];
        NSString *webText = [@"https://twitter.com/search?f=realtime&q=%23" stringByAppendingString:HASHTAG_TEXT];
        webText = [webText stringByAppendingString:@"&src=typd&lang=en"];
        
        if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:appText]])
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:webText]];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect fixedFrame = self.statusBar.frame;
    fixedFrame.origin.y = 0 + scrollView.contentOffset.y;
    self.statusBar.frame = fixedFrame;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"fromSideMenuSpeciesToEditSettings"] ||
        [segue.identifier isEqualToString:@"fromSideMenuLocationsToEditSettings"] ||
        [segue.identifier isEqualToString:@"fromSideMenuFishingMethodsToEditSettings"] ||
        [segue.identifier isEqualToString:@"fromSideMenuWaterClaritiesToEditSettings"])
    {
        CMAUserDefinesViewController *destination = segue.destinationViewController;
        destination.userDefine = [self userDefineFromSelectedCell];
    }
    
    // Manage the view transition and tell SWRevealViewController the new front view controller for display. We reuse the navigation controller and replace the view controller with destination view controller.
    if ([segue isKindOfClass: [SWRevealViewControllerSegue class]]) {
        [self.revealViewController toggleOverlay];
        
        SWRevealViewControllerSegue *swSegue = (SWRevealViewControllerSegue*)segue;

        swSegue.performBlock = ^(SWRevealViewControllerSegue *rvc_segue, UIViewController *svc, UIViewController *dvc) {
            UINavigationController *navController = (UINavigationController *)self.revealViewController.frontViewController;
            [navController setViewControllers: @[dvc] animated: NO];
            [self.revealViewController setFrontViewPosition: FrontViewPositionLeft animated: YES];
        };
    }
}

@end
