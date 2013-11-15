//
//  AppDelegate.m
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 6/29/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import <Appirater/Appirater.h>
#import <GCOLaunchImageTransition/GCOLaunchImageTransition.h>
#import <SDWebImage/SDImageCache.h>
#import <ShareSDK/ShareSDK.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>

#import "WXApi.h"

#import "AppDelegate.h"
#import "Constants.h"
#import "MobClick.h"

#import "SloganViewController.h"

@interface AppDelegate ()

- (void)configUmeng;
- (void)configAppRating;
- (void)configShareSDK;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self configUmeng];
    
    [self configAppRating];
    
    [self configShareSDK];
    
    [[SDImageCache sharedImageCache] setMaxCacheSize:32 * 1024 * 1024]; //32MB
    
    self.window.rootViewController = [[SloganViewController alloc] init];
    
	[self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    [GCOLaunchImageTransition transitionWithDuration:0.5f style:GCOLaunchImageTransitionAnimationStyleFade];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application  handleOpenURL:(NSURL *)url {
    return [ShareSDK handleOpenURL:url
                        wxDelegate:self];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [ShareSDK handleOpenURL:url
                 sourceApplication:sourceApplication
                        annotation:annotation
                        wxDelegate:self];
}

#pragma mark - Private Metholds

- (void)configUmeng {
    [MobClick startWithAppkey:UmengAppKey];
    [MobClick setAppVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

- (void)configAppRating {
    [Appirater setAppId:AppId];
    [Appirater setDaysUntilPrompt:7];       //使用N天后跳出提示
    [Appirater setUsesUntilPrompt:21];      //使用N次后跳出提示
    [Appirater setTimeBeforeReminding:2];   //点击稍候提醒，设置N天后再提示
    [Appirater setOpenInAppStore:YES];
    [Appirater setDebug:NO];
    
    [Appirater appLaunched:YES];
}

- (void)configShareSDK {
    [ShareSDK registerApp:ShareSDKAppKey];
    
    //添加新浪微博应用
    [ShareSDK connectSinaWeiboWithAppKey:SinaWeiboAppKey
                               appSecret:SinaWeiboAppSecret
                             redirectUri:SinaWeiboCallbackUrl];
    
    //添加腾讯微博应用
    [ShareSDK connectTencentWeiboWithAppKey:TencentWeiboAppKey
                                  appSecret:TencentWeiboAppSecret
                                redirectUri:TencentWeiboCallbackUrl];
    
    //添加微信应用
    [ShareSDK connectWeChatWithAppId:WeChatAppKey
                           wechatCls:[WXApi class]];
    
    //添加QQ空间应用
    [ShareSDK connectQZoneWithAppKey:QZoneAppKey
                           appSecret:QZoneAppSecret];
    
    //添加QQ应用
    [ShareSDK connectQQWithQZoneAppKey:QZoneAppKey
                     qqApiInterfaceCls:[QQApiInterface class]
                       tencentOAuthCls:[TencentOAuth class]];
    
    //添加Pocket应用
    [ShareSDK connectPocketWithConsumerKey:PocketAppSecret
                               redirectUri:PocketCallbackUrl];
    
    //添加印象笔记应用
    [ShareSDK connectEvernoteWithType:SSEverNoteTypeSandbox
                          consumerKey:YinXiangAppKey
                       consumerSecret:YinXiangAppSecret];
}

@end
