//
//  ModelUtils.h
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 11/18/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MONewsItem.h"

@interface ModelUtils : NSObject

+ (NSString *)htmlForNewsItem:(MONewsItem *)news;

@end
