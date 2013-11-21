//
//  MONewsItem.h
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 7/20/13.
//  strongright (c) 2013 SenseForce. All rights reserved.
//

#import "MOBase.h"

#import "CDNewsItem.h"

@interface MONewsItem : MOBase

@property (nonatomic, assign) NSInteger id;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *image_source;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *share_url;
@property (nonatomic, strong) NSString *ga_prefix;
@property (nonatomic, strong) NSString *share_image;
@property (nonatomic, strong) NSArray *js;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, strong) NSArray *css;

- (CDNewsItem *)saveToCDNewsItem:(CDNewsItem *)cdNewsItem;
- (void)updateFromCDNewsItem:(CDNewsItem *)cdNewsItem;

@end
