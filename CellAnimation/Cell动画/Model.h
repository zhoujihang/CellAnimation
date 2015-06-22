//
//  Model.h
//  Cell动画
//
//  Created by zhangwenlu on 15/6/15.
//  Copyright (c) 2015年 zhangwenlu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Model : NSObject <NSCopying>

/*!  排名*/
@property(nonatomic,strong)NSNumber *teamOrder;
/*!  球队名称*/
@property(nonatomic,strong)NSString *teamName;

@property(nonatomic,setter=isNeedMove:) BOOL needMove;

- (instancetype)initWithDict:(NSDictionary *)dict;
+ (instancetype)modelWithDict:(NSDictionary *)dict;
@end
