//
//  CDNewsItem.h
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 11/22/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDNewsItem : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * image_source;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSString * share_url;
@property (nonatomic, retain) NSString * ga_prefix;
@property (nonatomic, retain) NSString * share_image;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * thumbnail;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSDate * display_date;
@property (nonatomic, retain) NSString * css;
@property (nonatomic, retain) NSString * js;

@end
