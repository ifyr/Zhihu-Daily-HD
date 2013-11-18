//
//  MODailyNews.m
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import "MODailyNews.h"

@implementation MODailyNews

+ (RKObjectMapping *)commonMapping {
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[self class]];
    [objectMapping addAttributeMappingsFromArray:@[@"date", @"is_today", @"display_date"]];
    [objectMapping addRelationshipMappingWithSourceKeyPath:@"news" mapping:[MONewsItem commonMapping]];
    [objectMapping addRelationshipMappingWithSourceKeyPath:@"top_stories" mapping:[MONewsItem commonMapping]];
    return objectMapping;
}

@end
