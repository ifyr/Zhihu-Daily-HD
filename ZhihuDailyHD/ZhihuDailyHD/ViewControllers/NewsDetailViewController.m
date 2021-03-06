//
//  NewsDetailViewController.m
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import "NewsDetailViewController.h"
#import <BlocksKit/BlocksKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <ShareSDK/ShareSDK.h>
#import "Constants.h"
#import "ModelUtils.h"
#import "Emoji.h"

#define kViewPortScale  1.3

static char *keySharingRetryed;

@interface NewsDetailViewController () <UIWebViewDelegate>

@property (nonatomic, strong) MODailyNews *dailyNews;
@property (nonatomic, strong) MONewsItem *news;

@property (nonatomic, strong) NSArray *emojiArray;

@property (nonatomic, weak) id<ISSShareActionSheet> shareActionSheet;

- (void)refreshTheNews;

- (void)shareTheNews;

- (void)switchToPreArticle;
- (void)switchToNextArticle;
- (void)startSwipeAnimationWithDirection:(BOOL)fromRightToLeft;

@end

@implementation NewsDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithNewsItem:(MONewsItem *)news inDailyNews:(MODailyNews *)dailyNews {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.dailyNews = dailyNews;
        self.news = news;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.emojiArray = [Emoji allEmoji];
	
    self.hidesBottomBarWhenPushed = NO;
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.scalesPageToFit = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    
    self.webView.delegate = self;
    
    __weak NewsDetailViewController *blockSelf = self;
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                  handler:^(id sender) {
                                                                                      if ( ! [blockSelf.webView isLoading]) {
                                                                                          [blockSelf refreshTheNews];
                                                                                      }
                                                                                  }];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                handler:^(id sender) {
                                                                                    [blockSelf shareTheNews];
                                                                                }];
    self.navigationItem.rightBarButtonItems = @[refreshButton, shareButton];

    //Gestures
    UISwipeGestureRecognizer *swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (blockSelf.webView.isLoading) {
            return;
        }
        [blockSelf switchToNextArticle];
    }];
    swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeftGesture];
    
    UISwipeGestureRecognizer *swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (blockSelf.webView.isLoading) {
            return;
        }
        [blockSelf switchToPreArticle];
    }];
    swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRightGesture];
    
    [self refreshTheNews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:NSStringFromClass([self class])];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.shareActionSheet dismiss];
    [MobClick endLogPageView:NSStringFromClass([self class])];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTheNews {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES].removeFromSuperViewOnHide = YES;
    __weak NewsDetailViewController *weakSelf = self;
    [[DailyNewsDataCenter sharedInstance] exposeTheNewsDetail:self.news
                                                   usingCache:YES
                                                       result:^(BOOL success, MONewsItem *newsItem, BOOL cached) {
                                                           if (success) {
                                                               weakSelf.news = newsItem;
                                                               NSString *newsHtml = [ModelUtils htmlForNewsItem:newsItem];
                                                               [weakSelf.webView loadHTMLString:newsHtml baseURL:nil];
                                                           }
                                                           else {
                                                               
                                                           }
                                                           [MBProgressHUD hideAllHUDsForView:weakSelf.view
                                                                                    animated:YES];
                                                       }];
}

- (void)shareTheNews {
    MONewsItem *newsItem = self.news;
    NSString *content = newsItem.title;
    if ( ! [content length]) {
        content = self.title;
    }
    content = [content stringByAppendingFormat:@" %@ (来自【知乎日报HD】%@)", newsItem.share_url, AppStoreShortUrl];
    
    id<ISSContent> publishContent = [ShareSDK content:content
                                       defaultContent:[@"知乎日报HD " stringByAppendingString:AppStoreUrl]
                                                image:[ShareSDK imageWithUrl:newsItem.share_image]
                                                title:@"知乎日报"
                                                  url:newsItem.share_url
                                          description:content
                                            mediaType:SSPublishContentMediaTypeText];
    
    id<ISSAuthOptions> authOptions = [ShareSDK authOptionsWithAutoAuth:YES
                                                         allowCallback:NO
                                                         authViewStyle:SSAuthViewStylePopup
                                                          viewDelegate:nil
                                               authManagerViewDelegate:nil];
    [authOptions setPowerByHidden:YES];
    
    NSArray *shareList = [ShareSDK getShareListWithType:
                          ShareTypeSinaWeibo,
                          ShareTypeTencentWeibo,
                          ShareTypeWeixiTimeline,
                          ShareTypeWeixiSession,
                          ShareTypePocket,
                          ShareTypeEvernote,
                          ShareTypeYouDaoNote,
                          ShareTypeMail,
                          ShareTypeCopy,
                          ShareTypeAirPrint,
                          ShareTypeQQSpace,
                          ShareTypeQQ,
                          nil];
    id<ISSShareOptions> shareOptions = [ShareSDK defaultShareOptionsWithTitle:@"分享好内容"
                                                              oneKeyShareList:shareList
                                                               qqButtonHidden:NO
                                                        wxSessionButtonHidden:NO
                                                       wxTimelineButtonHidden:NO
                                                         showKeyboardOnAppear:NO
                                                            shareViewDelegate:nil
                                                          friendsViewDelegate:nil
                                                        picViewerViewDelegate:nil];
    
    id<ISSContainer> container = [ShareSDK container];
    [container setIPadContainerWithBarButtonItem:[self.navigationItem.rightBarButtonItems lastObject]
                                     arrowDirect:UIPopoverArrowDirectionUp];
    
    self.shareActionSheet =
    [ShareSDK showShareActionSheet:container
                         shareList:shareList
                           content:publishContent
                     statusBarTips:YES
                       authOptions:authOptions
                      shareOptions:shareOptions
                            result:^(ShareType type, SSPublishContentState state, id<ISSStatusInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                                if (state == SSResponseStateSuccess) {
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.removeFromSuperViewOnHide = YES;
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"分享成功";
                                    [hud hide:YES afterDelay:1.0f];
                                }
                                else if (state == SSResponseStateFail) {
                                    //Fix for sina weibo image url sharing
                                    if (type == ShareTypeSinaWeibo) {
                                        BOOL retryed = [[(NSObject *)publishContent associatedValueForKey:keySharingRetryed] boolValue];
                                        if ( ! retryed) {
                                            [(NSObject *)publishContent atomicallyAssociateCopyOfValue:@(YES) withKey:keySharingRetryed];
                                            id<ISSContent> weiboContent = [ShareSDK content:content
                                                                             defaultContent:[@"知乎日报HD " stringByAppendingString:AppStoreUrl]
                                                                                      image:nil
                                                                                      title:nil
                                                                                        url:nil
                                                                                description:content
                                                                                  mediaType:SSPublishContentMediaTypeText];
                                            [ShareSDK shareContent:weiboContent
                                                              type:ShareTypeSinaWeibo
                                                       authOptions:authOptions
                                                     statusBarTips:YES
                                                            result:^(ShareType type, SSPublishContentState state, id<ISSStatusInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                                                                
                                                            }];
                                        }
                                    }
                                }
                            }];
}

- (void)switchToPreArticle {
    NSArray *newsArray = [self.dailyNews news];
    NSInteger currentIndex = [newsArray indexOfObject:self.news];
    
    if (currentIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        MONewsItem *preNews = newsArray[currentIndex - 1];
        self.news = preNews;
        self.title = [NSString stringWithFormat:@"[%d/%d] %@ %@", currentIndex, [newsArray count], self.emojiArray[arc4random() % [self.emojiArray count]], [preNews title]];
        
        [self refreshTheNews];
        
        [self startSwipeAnimationWithDirection:NO];
    }
}

- (void)switchToNextArticle {
    NSArray *newsArray = [self.dailyNews news];
    NSInteger currentIndex = [newsArray indexOfObject:self.news];
    
    if (currentIndex == [newsArray count] - 1) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"后面没有了";
        [hud hide:YES afterDelay:1.0f];
    }
    else {
        MONewsItem *nextNews = newsArray[currentIndex + 1];
        self.news = nextNews;
        self.title = [NSString stringWithFormat:@"%d/%d %@ %@", currentIndex + 2, [newsArray count], self.emojiArray[arc4random() % [self.emojiArray count]], [nextNews title]];
        
        [self refreshTheNews];
        
        [self startSwipeAnimationWithDirection:YES];
    }
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

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES].removeFromSuperViewOnHide = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([[webView.request.URL absoluteString] isEqualToString:@"about:blank"]) {
        [webView.scrollView setContentOffset:CGPointMake(0, UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 150 * kViewPortScale : 100 * kViewPortScale) animated:NO];
    }
    [[MBProgressHUD HUDForView:self.view] hide:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[MBProgressHUD HUDForView:self.view] hide:YES];
}

@end
