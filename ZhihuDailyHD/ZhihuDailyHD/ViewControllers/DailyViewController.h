//
//  DailyViewController.h
//  ZhihuDailyHD
//
//  Created by Jiang Chuncheng on 11/14/13.
//  Copyright (c) 2013 SenseForce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobClick.h"

@interface DailyViewController : UIViewController

@end

@interface NewsCollectionCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end
