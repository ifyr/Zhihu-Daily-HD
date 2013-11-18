//
//  DailyNewsDataCenter.h
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import "DataCenter.h"
#import "MODailyNews.h"

@interface DailyNewsDataCenter : DataCenter

- (MODailyNews *)latestNews;

@end
