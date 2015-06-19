//
//  LETableViewCell.m
//  Cell动画
//
//  Created by zhangwenlu on 15/6/15.
//  Copyright (c) 2015年 zhangwenlu. All rights reserved.
//

#import "LETableViewCell.h"

@implementation LETableViewCell{
    UILabel *rankingL;      //排名
    UILabel *teamNameL;     //球队名

}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        rankingL = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 8, 20)];
        rankingL.font = [UIFont systemFontOfSize:12];
        rankingL.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:rankingL];
    
        teamNameL = [[UILabel alloc] initWithFrame:CGRectMake(80, 5, 8, 20)];
        teamNameL.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:teamNameL];
        
        
    }
    return self;
}


- (void)setModel:(Model *)item
{
    _item = item;
    
    rankingL.text = [NSString stringWithFormat:@"%ld",item.teamOrder];
    if (item.teamOrder < 4) {
        rankingL.layer.cornerRadius = 10;
    }else{
        rankingL.layer.cornerRadius = 0;
    }
    
    teamNameL.text = item.teamName;
}


@end
