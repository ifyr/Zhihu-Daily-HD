//
//  NewsDetailViewController.h
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobClick.h"
#import "DailyNewsDataCenter.h"

@interface NewsDetailViewController : UIViewController

@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, strong) MONews *news;

- (id)initWithUrl:(NSString *)urlString;

@end
