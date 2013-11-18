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
                                NSString *currentDateString = [[DailyNewsDataCenter dateFormatter] stringFromDate:[NSDate date]];
                                weakSelf.dailyNews = [mappingResult firstObject];
                                weakSelf.beforeNews[currentDateString] = weakSelf.dailyNews;
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
    __weak __typeof(&*self) weakSelf = self;
    
    NSDateFormatter *dateFormatter = [DailyNewsDataCenter dateFormatter];
    if ( ! [dateFormatter dateFromString:dateString]) {
        if (loadOver) {
            loadOver(NO, nil);
        }
        return;
    }
    
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
                                }
                                
                                if (loadOver) {
                                    loadOver(success, success ? dailyNews : nil);
                                }
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (loadOver) {
                                    loadOver(NO, nil);
                                }
                            }];
}

- (void)exposeTheNewsDetail:(MONewsItem *)newsItem result:(void (^)(BOOL success, MONewsItem *newsItem))loadOver {
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
                                if (loadOver) {
                                    MONewsItem *exposedNewsItem = [mappingResult firstObject];
                                    if ([exposedNewsItem isKindOfClass:[MONewsItem class]]) {
                                        newsItem.body = exposedNewsItem.body;
                                        newsItem.css = exposedNewsItem.css;
                                        newsItem.js = exposedNewsItem.js;
                                        loadOver(YES, newsItem);
                                    }
                                    else {
                                        loadOver(YES, nil);
                                    }
                                }
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (loadOver) {
                                    loadOver(NO, nil);
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
