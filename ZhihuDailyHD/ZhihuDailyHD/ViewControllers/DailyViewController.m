//
//  DailyViewController.m
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 11/14/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/BlocksKit.h>
#import <Reachability/Reachability.h>
#import <Appirater/Appirater.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "UMFeedback.h"

#import "Constants.h"
#import "DailyViewController.h"
#import "DailyNewsDataCenter.h"
#import "NewsDetailViewController.h"
#import "OptionsViewController.h"
#import "AboutViewController.h"

@interface DailyViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPopoverControllerDelegate, OptionsDelegate> {
    CGFloat cellWidthPortrait;
    CGFloat cellWidthLandscape;
}

@property (nonatomic, strong) MODailyNews *dailyNews;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) Reachability *reachability;

@property (nonatomic, strong) OptionsViewController *optionsViewController;
@property (nonatomic, strong) UIPopoverController *popover;

- (IBAction)showMoreOptions:(id)sender;

- (void)switchToPreDay;
- (void)switchToNextDay;
- (void)startSwipeAnimationWithDirection:(BOOL)fromRightToLeft;

- (void)reloadCollectionViewWithDailyNews:(MODailyNews *)dailyNews;

@end

@implementation DailyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cellWidthPortrait = self.view.bounds.size.width / 2 - 1;
    cellWidthLandscape = self.view.bounds.size.height / 3 - 1;
	
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                          collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.backgroundColor = [UIColor whiteColor];
    [collectionView registerClass:[NewsCollectionCell class] forCellWithReuseIdentifier:@"NewsCell"];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    
    self.title = @"知乎日报";
    
    self.hidesBottomBarWhenPushed = YES;
    
    self.reachability = [Reachability reachabilityWithHostname:@"zhihu.com"];
    
    __block BOOL isLoading = NO;
    __weak __typeof(&*self) weakSelf = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                          handler:^(id sender) {
                                                                                              if (isLoading) {
                                                                                                  return;
                                                                                              }
                                                                                              isLoading = YES;
                                                                                              [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                                                                                              MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
                                                                                              hud.removeFromSuperViewOnHide = YES;
                                                                                              [hud hide:YES afterDelay:5.0f];
                                                                                              [[DailyNewsDataCenter sharedInstance] reloadData:^(BOOL success) {
                                                                                                  isLoading = NO;
                                                                                                  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                                                                  [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
                                                                                                  if (success) {
                                                                                                      [weakSelf reloadCollectionViewWithDailyNews:[[DailyNewsDataCenter sharedInstance] latestNews]];
                                                                                                  }
                                                                                              }];
                                                                                          }];
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [leftButton addTarget:self action:@selector(showMoreOptions:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    
    //Gestures
    UISwipeGestureRecognizer *swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if ([MBProgressHUD HUDForView:weakSelf.view]) {
            return;
        }
        [weakSelf switchToNextDay];
    }];
    swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeftGesture];
    
    UISwipeGestureRecognizer *swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if ([MBProgressHUD HUDForView:weakSelf.view]) {
            return;
        }
        [weakSelf switchToPreDay];
    }];
    swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRightGesture];
    
    self.dailyNews = [[DailyNewsDataCenter sharedInstance] latestNews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [[SDImageCache sharedImageCache] clearMemory];
    [[DailyNewsDataCenter sharedInstance] didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:NSStringFromClass([self class])];
}

- (void)viewWillDisappear:(BOOL)animated {
    [MobClick endLogPageView:NSStringFromClass([self class])];
    [super viewWillDisappear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (IBAction)showMoreOptions:(id)sender {
    if ( ! self.optionsViewController) {
        self.optionsViewController = [[OptionsViewController alloc] initWithStyle:UITableViewStylePlain];
        self.optionsViewController.delegate = self;
    }
    
    if ( ! self.popover) {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:self.optionsViewController];
        popoverController.delegate = self;
        self.popover = popoverController;
    }
    
    if ([self.popover isPopoverVisible]) {
        [self.popover dismissPopoverAnimated:YES];
    }
    else {
        self.popover.popoverContentSize = CGSizeMake(240, 320);
        [self.popover presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
    }
}

- (void)switchToPreDay {
    NSLog(@"latest:%@ current:%@", [[DailyNewsDataCenter sharedInstance] latestNews], self.dailyNews);
    if ([[DailyNewsDataCenter sharedInstance] latestNews] != self.dailyNews) {
        NSDateFormatter *dateFormatter = [DailyNewsDataCenter dateFormatter];
        
        NSDate *currentDate = [dateFormatter dateFromString:self.dailyNews.date];
        NSString *preDateString = [dateFormatter stringFromDate:[currentDate dateByAddingTimeInterval:2 * 24 * 3600]];
        
        MODailyNews *preDailyNews = [[DailyNewsDataCenter sharedInstance] newsOnDate:preDateString];
        if (preDailyNews) {
            [self reloadCollectionViewWithDailyNews:preDailyNews];
        }
        else {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES].removeFromSuperViewOnHide = YES;
            __weak __typeof(&*self) weakSelf = self;
            [[DailyNewsDataCenter sharedInstance] reloadNewsOnDate:preDateString
                                                            result:^(BOOL success, MODailyNews *dailyNews) {
                                                                if (success) {
                                                                    [weakSelf reloadCollectionViewWithDailyNews:dailyNews];
                                                                }
                                                                [[MBProgressHUD HUDForView:self.view] hide:YES];
                                                            }];
        }
        
        [self startSwipeAnimationWithDirection:NO];
    }
}

- (void)switchToNextDay {
    NSString *nextDateString = self.dailyNews.date;
    
    MODailyNews *nextDailyNews = [[DailyNewsDataCenter sharedInstance] newsOnDate:nextDateString];
    if (nextDailyNews) {
        [self reloadCollectionViewWithDailyNews:nextDailyNews];
    }
    else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES].removeFromSuperViewOnHide = YES;
        __weak __typeof(&*self) weakSelf = self;
        [[DailyNewsDataCenter sharedInstance] reloadNewsOnDate:nextDateString
                                                        result:^(BOOL success, MODailyNews *dailyNews) {
                                                            if (success) {
                                                                [weakSelf reloadCollectionViewWithDailyNews:dailyNews];
                                                            }
                                                            [[MBProgressHUD HUDForView:self.view] hide:YES];
                                                        }];
    }
    
    [self startSwipeAnimationWithDirection:YES];
}

- (void)startSwipeAnimationWithDirection:(BOOL)fromRightToLeft {
    [self.view.layer removeAllAnimations];
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3f;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.fillMode = kCAFillModeForwards;
    animation.type = kCATransitionPush;
    animation.subtype = (fromRightToLeft ? kCATransitionFromRight : kCATransitionFromLeft);
    [self.view.layer addAnimation:animation forKey:kCATransition];
}

- (void)reloadCollectionViewWithDailyNews:(MODailyNews *)dailyNews {
    self.dailyNews = dailyNews;
    [self.collectionView reloadData];
    
    if (dailyNews == [[DailyNewsDataCenter sharedInstance] latestNews]) {
        self.title = @"知乎日报";
    }
    else {
        NSDateFormatter *dateFormatter = [DailyNewsDataCenter dateFormatter];
        NSDate *newsDate = [dateFormatter dateFromString:dailyNews.date];
        self.title = [NSString stringWithFormat:@"知乎日报 @ %@", [dateFormatter stringFromDate:[newsDate dateByAddingTimeInterval:24 * 3600]]];
    }
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
}

#pragma mark - OptionsDelegate

- (void)optionsSelectAtIndex:(NSInteger)index {
    [self.popover dismissPopoverAnimated:YES];
    switch (index) {
        case 0: {
            [UMFeedback showFeedback:self withAppkey:UmengAppKey];
        }
            break;
            
        case 1: {
            [Appirater rateApp];
        }
            break;
            
        case 2: {
            AboutViewController *aboutViewController = [[AboutViewController alloc] init];
            [self.navigationController pushViewController:aboutViewController animated:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.dailyNews news] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseId = @"NewsCell";
    NewsCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId forIndexPath:indexPath];
    if ( ! cell) {
        cell = [[NewsCollectionCell alloc] initWithFrame:CGRectMake(0, 0, 384, 384)];
    }
    
    MONewsItem *news = [self.dailyNews news][indexPath.row];
    
    NSString *url;
    if ([self.reachability isReachableViaWiFi]) {
        url = news.image;
    }
    if ( ! [url length]) {
        url = news.thumbnail;
    }
    [cell.imageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    cell.titleLabel.text = [news title];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (UIDeviceOrientationIsPortrait(self.interfaceOrientation)) {
        return CGSizeMake(cellWidthPortrait, cellWidthPortrait);
    }
    else {
        return CGSizeMake(cellWidthLandscape, cellWidthLandscape);
    }
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 1;
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    MONewsItem *newsItem = [self.dailyNews news][indexPath.row];
    NewsDetailViewController *webViewController = [[NewsDetailViewController alloc] initWithNewsItem:newsItem inDailyNews:self.dailyNews];
    webViewController.title = newsItem.title;
    [self.navigationController pushViewController:webViewController animated:YES];
}


-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end


@implementation NewsCollectionCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:imageView];
        self.imageView = imageView;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height - 50, frame.size.width, 50)];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        titleLabel.numberOfLines = 0;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
        [self addSubview:titleLabel];
        self.titleLabel = titleLabel;
    }
    return self;
}

@end