//
//  MONewsItem.m
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import "MONewsItem.h"

@implementation MONewsItem

+ (RKObjectMapping *)commonMapping {
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[self class]];
    [objectMapping addAttributeMappingsFromArray:@[@"id", @"body", @"image_source", @"title", @"url", @"image", @"share_url", @"thumbnail", @"ga_prefix", @"share_image"]];
    [objectMapping addAttributeMappingsFromArray:@[@"js", @"css"]];
    return objectMapping;
}

@end
