//
//  ModelUtils.m
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 11/18/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import "ModelUtils.h"

static NSString *newsDetailHtmlFormat;

@implementation ModelUtils

+(void)initialize {
    newsDetailHtmlFormat = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template_news_detail" ofType:@"html"]
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
}

+ (NSString *)htmlForNewsItem:(MONewsItem *)news {
    NSMutableString *cssString = [NSMutableString string];
    for (NSString *cssUrl in news.css) {
        [cssString appendFormat:@"<link rel=\"stylesheet\" href=\"%@\">", cssUrl];
    }
    return [NSString stringWithFormat:newsDetailHtmlFormat, news.title, cssString, news.body];
}

@end
