//
//  Model.m
//  Cell动画
//
//  Created by zhangwenlu on 15/6/15.
//  Copyright (c) 2015年 zhangwenlu. All rights reserved.
//

#import "Model.h"

@implementation Model

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

+ (instancetype)modelWithDict:(NSDictionary *)dict
{
    return [[self alloc] initWithDict:dict];
}
- (id)copyWithZone:(NSZone *)zone{
    Model *copyModel = [[Model alloc]init];
    copyModel.teamName = [self.teamName copy];
    copyModel.teamOrder = [self.teamOrder copy];
    copyModel.needMove = self.needMove;
    return copyModel;
}
- (NSString *)description{
    return [NSString stringWithFormat:@"%@ - %ld",self.teamName,self.teamOrder.integerValue];
}
@end
