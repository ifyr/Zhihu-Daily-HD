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

static char *keySharingRetryed;

@interface NewsDetailViewController () <UIWebViewDelegate>

@property (nonatomic, copy) NSString *url;

@property (nonatomic, weak) id<ISSShareActionSheet> shareActionSheet;

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

- (id)initWithUrl:(NSString *)urlString {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.url = urlString;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
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
                                                                                          [blockSelf.webView reload];
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
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
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

- (void)shareTheNews {
    MONewsItem *newsItem = [[self.news items] lastObject];
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
                                    NSLog(@"分享失败,错误码:%d,错误描述:%@", [error errorCode], [error errorDescription]);
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
    NSArray *newsArray = [[[DailyNewsDataCenter sharedInstance] latestNews] news];
    NSInteger currentIndex = [newsArray indexOfObject:self.news];
    
    if (currentIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        MONews *preNews = newsArray[currentIndex - 1];
        self.news = preNews;
        self.url = [(MONewsItem *)[[preNews items] lastObject] url];
        self.title = [(MONewsItem *)[[preNews items] lastObject] title];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
        
        [self startSwipeAnimationWithDirection:NO];
    }
}

- (void)switchToNextArticle {
    NSArray *newsArray = [[[DailyNewsDataCenter sharedInstance] latestNews] news];
    NSInteger currentIndex = [newsArray indexOfObject:self.news];
    
    if (currentIndex == [newsArray count] - 1) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"后面没有了";
        [hud hide:YES afterDelay:1.0f];
    }
    else {
        MONews *nextNews = newsArray[currentIndex + 1];
        self.news = nextNews;
        self.url = [(MONewsItem *)[[nextNews items] lastObject] url];
        self.title = [(MONewsItem *)[[nextNews items] lastObject] title];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
        
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
    if ([[webView.request.URL absoluteString] isEqualToString:self.url]) {
        [webView.scrollView setContentOffset:CGPointMake(0, UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 210 : 150) animated:NO];
    }
    [[MBProgressHUD HUDForView:self.view] hide:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[MBProgressHUD HUDForView:self.view] hide:YES];
}

@end
