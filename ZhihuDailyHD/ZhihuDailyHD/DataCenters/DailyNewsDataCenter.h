//
//  DailyNewsDataCenter.h
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import "DataCenter.h"
#import "MODailyNews.h"
#import "CDNewsItem.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@interface DailyNewsDataCenter : DataCenter

- (MODailyNews *)latestNews;
- (MODailyNews *)newsOnDate:(NSString *)dateString;
- (MODailyNews *)newsBeforeDays:(NSInteger)dateInterval;

// The dateString format must be as '20131129'
- (void)reloadNewsOnDate:(NSString *)dateString result:(void (^)(BOOL success, MODailyNews *dailyNews))loadOver;
- (void)reloadNewsOnDate:(NSString *)dateString usingCache:(BOOL)cache result:(void (^)(BOOL success, MODailyNews *dailyNews, BOOL cached))loadOver;

- (void)exposeTheNewsDetail:(MONewsItem *)newsItem result:(void (^)(BOOL success, MONewsItem *newsItem))loadOver;
- (void)exposeTheNewsDetail:(MONewsItem *)newsItem usingCache:(BOOL)cache result:(void (^)(BOOL success, MONewsItem *newsItem, BOOL cached))loadOver;

+ (NSDateFormatter *)dateFormatter;

@end
