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

@end

@implementation DailyNewsDataCenter

- (void)reloadData:(void (^)(BOOL success))loadOver {
    __weak DailyNewsDataCenter *blockSelf = self;
    
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
                                blockSelf.dailyNews = [mappingResult firstObject];
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
    
    __weak __typeof(&*self) weakSelf = self;
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

- (MODailyNews *)latestNews {
    return self.dailyNews;
}

@end
