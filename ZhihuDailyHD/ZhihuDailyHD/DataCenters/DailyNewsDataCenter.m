//
//  DailyNewsDataCenter.m
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import "DailyNewsDataCenter.h"
#import <RestKit/RestKit.h>

@interface DailyNewsDataCenter ()

@property (nonatomic, strong) MODailyNews *dailyNews;

@property (nonatomic, strong) NSMutableDictionary *beforeNews;

@end

@implementation DailyNewsDataCenter

- (id)init {
    self = [super init];
    if (self) {
        self.beforeNews = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [self.beforeNews removeAllObjects];
    [super didReceiveMemoryWarning];
}

- (MODailyNews *)latestNews {
    return self.dailyNews;
}

- (MODailyNews *)newsOnDate:(NSString *)dateString {
    if ( ! [dateString length]) {
        return nil;
    }
    return self.beforeNews[dateString];
}

- (MODailyNews *)newsBeforeDays:(NSInteger)dateInterval {
    if (dateInterval < 0) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [DailyNewsDataCenter dateFormatter];
    
    NSDate *latestDate = [dateFormatter dateFromString:self.latestNews.date];
    NSString *dateString = [dateFormatter stringFromDate:[latestDate dateByAddingTimeInterval:(1 - dateInterval) * 24 * 3600]];
    
    return [self newsOnDate:dateString];
}

- (void)clearMemmory {
    [self.beforeNews removeAllObjects];
}

- (void)loadCache {
    CDNewsItem *latestItem = [CDNewsItem MR_findFirstOrderedByAttribute:@"date" ascending:NO];
    if ( ! latestItem) {
        return;
    }
    
    NSArray *cachedNews = [CDNewsItem MR_findByAttribute:@"date"
                                               withValue:latestItem.date
                                              andOrderBy:@"ga_prefix"
                                               ascending:YES];
    
    MODailyNews *lastestDailyNews = [[MODailyNews alloc] init];
    lastestDailyNews.date = latestItem.date;
    
    NSMutableArray *news = [NSMutableArray arrayWithCapacity:[cachedNews count]];
    for (CDNewsItem *cdNewsItem in cachedNews) {
        MONewsItem *newsItem = [[MONewsItem alloc] init];
        [newsItem updateFromCDNewsItem:cdNewsItem];
        [news addObject:newsItem];
    }
    lastestDailyNews.news = news;
    
    NSDateFormatter *dateFormatter = [DailyNewsDataCenter dateFormatter];
    NSDate *latestDate = [dateFormatter dateFromString:lastestDailyNews.date];
    NSString *currentDateString = [dateFormatter stringFromDate:[latestDate dateByAddingTimeInterval:24 * 3600]];
    if ( ! currentDateString) {
        currentDateString = [dateFormatter stringFromDate:[NSDate date]];
    }
    self.beforeNews[currentDateString] = lastestDailyNews;
    
    self.dailyNews = lastestDailyNews;
}

- (void)reloadData:(void (^)(BOOL success))loadOver {
    __weak __typeof(&*self) weakSelf = self;
    
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://news.at.zhihu.com/"]];
    [objectManager setAcceptHeaderWithMIMEType:RKMIMETypeJSON];
    [objectManager.HTTPClient setParameterEncoding:AFJSONParameterEncoding];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[MODailyNews commonMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:nil];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:@"/api/1.2/news/latest"
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                MODailyNews *lastestDailyNews = [mappingResult firstObject];
                                
                                NSDateFormatter *dateFormatter = [DailyNewsDataCenter dateFormatter];
                                NSDate *latestDate = [dateFormatter dateFromString:lastestDailyNews.date];
                                NSString *currentDateString = [dateFormatter stringFromDate:[latestDate dateByAddingTimeInterval:24 * 3600]];
                                if ( ! currentDateString) {
                                    currentDateString = [dateFormatter stringFromDate:[NSDate date]];
                                }
                                weakSelf.beforeNews[currentDateString] = lastestDailyNews;
                                
                                weakSelf.dailyNews = lastestDailyNews;
                                
                                for (MONewsItem *newsItem in lastestDailyNews.news) {
                                    CDNewsItem *cdNewsItem = [CDNewsItem MR_findFirstByAttribute:@"id" withValue:@(newsItem.id)];
                                    if ( ! cdNewsItem) {
                                        cdNewsItem = [CDNewsItem MR_createEntity];
                                    }
                                    cdNewsItem.date = lastestDailyNews.date;
                                    [newsItem saveToCDNewsItem:cdNewsItem];
                                }
                                [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                                    
                                }];
                                
                                if (loadOver) {
                                    loadOver(YES);
                                }
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (loadOver) {
                                    loadOver(NO);
                                }
                            }];
}

- (void)reloadNewsOnDate:(NSString *)dateString result:(void (^)(BOOL success, MODailyNews *dailyNews))loadOver {
    [self reloadNewsOnDate:dateString
                usingCache:YES
                    result:^(BOOL success, MODailyNews *dailyNews, BOOL cached) {
                        loadOver(success, dailyNews);
                    }];
}

- (void)reloadNewsOnDate:(NSString *)dateString usingCache:(BOOL)cache result:(void (^)(BOOL success, MODailyNews *dailyNews, BOOL cached))loadOver {
    NSDateFormatter *dateFormatter = [DailyNewsDataCenter dateFormatter];
    NSDate *theDate = [dateFormatter dateFromString:dateString];
    if ( ! theDate) {
        if (loadOver) {
            loadOver(NO, nil, NO);
        }
        return;
    }
    
    NSString *savedDateString = [dateFormatter stringFromDate:[theDate dateByAddingTimeInterval:-1 * 24 * 3600]];
    
    if (cache) {
        NSArray *cachedNews = [CDNewsItem MR_findByAttribute:@"date"
                                                   withValue:savedDateString
                                                  andOrderBy:@"ga_prefix"
                                                   ascending:YES];
        if ([cachedNews count]) {
            MODailyNews *cachedDailyNews = [[MODailyNews alloc] init];
            cachedDailyNews.date = savedDateString;
            
            NSMutableArray *news = [NSMutableArray arrayWithCapacity:[cachedNews count]];
            for (CDNewsItem *cdNewsItem in cachedNews) {
                MONewsItem *newsItem = [[MONewsItem alloc] init];
                [newsItem updateFromCDNewsItem:cdNewsItem];
                [news addObject:newsItem];
            }
            cachedDailyNews.news = news;
            
            loadOver(YES, cachedDailyNews, YES);
            return;
        }
    }
    
    __weak __typeof(&*self) weakSelf = self;
    
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://news.at.zhihu.com/"]];
    [objectManager setAcceptHeaderWithMIMEType:RKMIMETypeJSON];
    [objectManager.HTTPClient setParameterEncoding:AFJSONParameterEncoding];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[MODailyNews commonMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:nil];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:[@"/api/1.2/news/before/" stringByAppendingString:dateString]
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                MODailyNews *dailyNews = [mappingResult firstObject];
                                BOOL success = [dailyNews isKindOfClass:[MODailyNews class]];
                                
                                if (success) {
                                    weakSelf.beforeNews[dateString] = dailyNews;
                                    
                                    for (MONewsItem *newsItem in dailyNews.news) {
                                        CDNewsItem *cdNewsItem = [CDNewsItem MR_findFirstByAttribute:@"id" withValue:@(newsItem.id)];
                                        if ( ! cdNewsItem) {
                                            cdNewsItem = [CDNewsItem MR_createEntity];
                                        }
                                        cdNewsItem.date = dailyNews.date;
                                        [newsItem saveToCDNewsItem:cdNewsItem];
                                    }
                                    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                                        
                                    }];
                                }
                                
                                if (loadOver) {
                                    loadOver(success, success ? dailyNews : nil, NO);
                                }
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (loadOver) {
                                    loadOver(NO, nil, NO);
                                }
                            }];
}

- (void)exposeTheNewsDetail:(MONewsItem *)newsItem result:(void (^)(BOOL success, MONewsItem *newsItem))loadOver {
    [self exposeTheNewsDetail:newsItem usingCache:YES result:^(BOOL success, MONewsItem *newsItem, BOOL cached) {
        if (loadOver) {
            loadOver(success, newsItem);
        }
    }];
}

- (void)exposeTheNewsDetail:(MONewsItem *)newsItem usingCache:(BOOL)cache result:(void (^)(BOOL success, MONewsItem *newsItem, BOOL cached))loadOver {
    if (cache) {
        NSString *body = newsItem.body;
        if ( ! [body length]) {
            CDNewsItem *cdNewsItem = [CDNewsItem MR_findFirstByAttribute:@"id" withValue:@(newsItem.id)];
            [newsItem updateFromCDNewsItem:cdNewsItem];
            body = newsItem.body;
        }
        if ([body length]) {
            if (loadOver) {
                loadOver(YES, newsItem, YES);
            }
            return;
        }
    }
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://news.at.zhihu.com/"]];
    [objectManager setAcceptHeaderWithMIMEType:RKMIMETypeJSON];
    [objectManager.HTTPClient setParameterEncoding:AFJSONParameterEncoding];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[MONewsItem commonMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:nil];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:[@"/api/1.2/news/" stringByAppendingFormat:@"%d", newsItem.id]
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                MONewsItem *exposedNewsItem = [mappingResult firstObject];
                                if ([exposedNewsItem isKindOfClass:[MONewsItem class]]) {
                                    newsItem.body = exposedNewsItem.body;
                                    newsItem.css = exposedNewsItem.css;
                                    newsItem.js = exposedNewsItem.js;
                                    
                                    NSManagedObjectContext *managedObjectContext = [NSManagedObjectContext MR_contextForCurrentThread];
                                    CDNewsItem *cdNewsItem = [CDNewsItem MR_findFirstByAttribute:@"id" withValue:@(newsItem.id) inContext:managedObjectContext];
                                    [newsItem saveToCDNewsItem:cdNewsItem];
                                    [managedObjectContext MR_saveToPersistentStoreAndWait];
                                    
                                    if (loadOver) {
                                        loadOver(YES, newsItem, NO);
                                    }
                                }
                                else {
                                    if (loadOver) {
                                        loadOver(YES, nil, NO);
                                    }
                                }
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (loadOver) {
                                    loadOver(NO, nil, NO);
                                }
                            }];
}

+ (NSDateFormatter *)dateFormatter {
    static NSString *dateFormat = @"yyyyMMdd";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    return dateFormatter;
}

@end
