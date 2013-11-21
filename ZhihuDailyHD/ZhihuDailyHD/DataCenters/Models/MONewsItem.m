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

- (CDNewsItem *)saveToCDNewsItem:(CDNewsItem *)cdNewsItem {
    cdNewsItem.id = @(self.id);
    cdNewsItem.body = self.body;
    cdNewsItem.image_source = self.image_source;
    cdNewsItem.title = self.title;
    cdNewsItem.url = self.url;
    cdNewsItem.image = self.image;
    cdNewsItem.share_url = self.share_url;
    cdNewsItem.ga_prefix = self.ga_prefix;
    cdNewsItem.share_image = self.share_image;
    cdNewsItem.thumbnail = self.thumbnail;
    
    NSMutableString *string = [NSMutableString string];
    for (NSString *css in self.css) {
        [string appendFormat:@",%@", css];
    }
    if ([string length]) {
        [string replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        
        cdNewsItem.css = [NSString stringWithString:string];
    }
    
    [string setString:@""];
    for (NSString *js in self.js) {
        [string appendFormat:@",%@", js];
    }
    if ([string length]) {
        [string replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        cdNewsItem.js = [NSString stringWithString:string];
    }
    
    return cdNewsItem;
}

- (void)updateFromCDNewsItem:(CDNewsItem *)cdNewsItem {
    self.id = [cdNewsItem.id integerValue];
    self.body = cdNewsItem.body;
    self.image_source = cdNewsItem.image_source;
    self.title = cdNewsItem.title;
    self.url = cdNewsItem.url;
    self.image = cdNewsItem.image;
    self.share_url = cdNewsItem.share_url;
    self.ga_prefix = cdNewsItem.ga_prefix;
    self.share_image = cdNewsItem.share_image;
    self.thumbnail = cdNewsItem.thumbnail;
    
    self.css = [cdNewsItem.css componentsSeparatedByString:@","];
    self.js = [cdNewsItem.js componentsSeparatedByString:@","];
}

@end
