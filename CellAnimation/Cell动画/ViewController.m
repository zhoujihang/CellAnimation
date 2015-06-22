//
//  ViewController.m
//  Cell动画
//
//  Created by zhangwenlu on 15/6/11.
//  Copyright (c) 2015年 zhangwenlu. All rights reserved.
//


#import "ViewController.h"
#import "Model.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
     NSIndexPath *destination;
     NSIndexPath *source;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(nonatomic,strong)NSMutableArray *oldArray;
@property(nonatomic,strong)NSMutableArray *refreshArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //延时
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self cellAnimation];
    });
}

- (void)cellAnimation{
    NSLog(@"排序前：%@",self.oldArray);
    [UIView animateWithDuration:0.6 animations:^{
        // 先清理已经被淘汰了的球队
        [self clearEliminatedTeam];
    } completion:^(BOOL finished) {
        // 再从旧的排名过渡到新的排名
        [self cellExchangeWithTeamName:[self.refreshArray[0] teamName] refreshIndex:0];
    }];
    
}
// 将未出现在新排名中的球队删掉
- (void)clearEliminatedTeam{
    NSMutableArray *eliminatedOldModel = [NSMutableArray array];
    NSMutableArray *eliminatedIndexPathMArr = [NSMutableArray array];
    for (int i=0;i<self.oldArray.count;i++) {
        Model *oldModel = self.oldArray[i];
        // 标记 oldModel 是否已经在新数组中被淘汰了
        BOOL isEliminated = YES;
        for (Model *newModel in self.refreshArray) {
            if ([oldModel.teamName isEqualToString:newModel.teamName]) {
                isEliminated = NO;
                break;
            }
        }
        if (isEliminated) {
            // 已经淘汰了的球队
            [eliminatedOldModel addObject:oldModel];
            NSIndexPath *indexPath= [NSIndexPath indexPathForRow:i inSection:0];
            [eliminatedIndexPathMArr addObject:indexPath];
        }
    }
    [self.oldArray removeObjectsInArray:eliminatedOldModel];
    [self.tableView deleteRowsAtIndexPaths:eliminatedIndexPathMArr withRowAnimation:UITableViewRowAnimationFade];
}

- (void)cellExchangeWithTeamName:(NSString *)teamName refreshIndex:(NSInteger)refreshIndex{
    // 新的模型
    Model *newModel = nil;
    for (Model *model in self.refreshArray) {
        if ([model.teamName isEqualToString:teamName]) {
            newModel = model;
            break;
        }
    }
    // 新的位置
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newModel.teamOrder.integerValue-1 inSection:0];
    
    // 旧的模型
    Model *oldModel = nil;
    for (Model *model in self.oldArray) {
        if ([model.teamName isEqualToString:teamName]) {
            oldModel = model;
            break;
        }
    }
    // 旧的的位置
    NSIndexPath *oldIndexPath = nil;
    if (oldModel){
        // 并非新加入的球队
        oldIndexPath = [NSIndexPath indexPathForRow:[self.oldArray indexOfObject:oldModel] inSection:0];
        if (oldIndexPath.row == newIndexPath.row){
            // 如果位置没变化直接开始下一个cell的移动
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (refreshIndex+1 <= self.refreshArray.count-1) {
                    [self cellExchangeWithTeamName:[self.refreshArray[refreshIndex+1] teamName] refreshIndex:refreshIndex+1];
                }
            });
            return;
        }
    }else{
        // 新加入的球队,设置成旧模型中的最后一个，排名也暂时设置为最后一位
        [self.oldArray addObject:[newModel copy]];
        [[self.oldArray lastObject] setTeamOrder:@(self.oldArray.count)];
        oldIndexPath = [NSIndexPath indexPathForRow:self.oldArray.count-1 inSection:0];
        // 执行cell交换动画之前，先将新增的cell插入到tableview中
        [self.tableView insertRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    // 模型交换位置,并更新球队的排名
    NSNumber *tempRange = [self.oldArray[oldIndexPath.row] teamOrder];
    [self.oldArray[oldIndexPath.row] setTeamOrder:newModel.teamOrder];
    [self.oldArray[newIndexPath.row] setTeamOrder:tempRange];
    [self.oldArray exchangeObjectAtIndex:oldIndexPath.row withObjectAtIndex:newIndexPath.row];
    NSLog(@"排序后：%@",self.oldArray);
    // 视图交换位置
    [UIView animateWithDuration:0.6 animations:^{
        [self.tableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
        if (newIndexPath.row > oldIndexPath.row) {
            // 向下挪动     move方法不会触发 tableview的跟新视图的方法
            [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:newIndexPath.row-1 inSection:0] toIndexPath:oldIndexPath];
        }else{
            // 向上挪动
            [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:newIndexPath.row+1 inSection:0] toIndexPath:oldIndexPath];
        }
    } completion:^(BOOL finished) {
        // 开始下一个cell的移动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 动画完成后更新视图
            [self.tableView reloadRowsAtIndexPaths:@[oldIndexPath,newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            // 判断是否还需要继续
            if (refreshIndex+1 <= self.refreshArray.count-1) {
                [self cellExchangeWithTeamName:[self.refreshArray[refreshIndex+1] teamName] refreshIndex:refreshIndex+1];
            }
        });
    }];

    
}
- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark ----- tableView代理和数据源方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.oldArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSInteger count = 0;
    NSLog(@"count:%ld",++count);
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    //设置cell的内容
    Model *item = self.oldArray[indexPath.row];
    NSString *scoreStr = [NSString stringWithFormat:@"%@",item.teamOrder];
    cell.detailTextLabel.text = scoreStr;
    cell.textLabel.text = [NSString stringWithFormat:@"%@",item.teamName];
    return  cell;
}

- (NSArray *)oldArray
{
    if (!_oldArray) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Property.plist" ofType:nil];
        NSArray *arr = [NSArray arrayWithContentsOfFile:path];
        NSMutableArray *arrayModels = [NSMutableArray array];

        for (NSDictionary *dict in arr) {
            Model *model = [Model modelWithDict:dict];
            [arrayModels addObject:model];
        }
        _oldArray = arrayModels;
    }
    return  _oldArray;
}
- (NSArray *)refreshArray
{
    if (!_refreshArray) {
        NSString *path = [[NSBundle mainBundle]pathForResource:@"NewArray.plist" ofType:nil];
        NSArray *arr = [NSArray arrayWithContentsOfFile:path];
        NSMutableArray *arrayModels = [NSMutableArray array];
        
        for (NSDictionary *dict in arr) {
            Model *model = [Model modelWithDict:dict];
            [arrayModels addObject:model];
        }
        // 按照 obj1.teamOrder 排序数组
        [arrayModels sortUsingComparator:^NSComparisonResult(Model *obj1, Model *obj2) {
            return obj1.teamOrder.integerValue > obj2.teamOrder.integerValue ? NSOrderedDescending : obj1.teamOrder.integerValue == obj2.teamOrder.integerValue ? NSOrderedSame : NSOrderedAscending;
        }];
        _refreshArray = arrayModels;
    }
    return  _refreshArray;
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
#pragma mark - deprecated
- (void)animationArray:(NSMutableArray *)cellArray
{
    if (cellArray.count > 0) {
        
        Model *item = [cellArray firstObject];
        NSNumber *newOrder = item.teamOrder;
        
        //通过数据库查询，根据teamName获得旧的teamOrder
        NSNumber *oldOrder = nil;
        for (Model *team in self.oldArray) {
            if ([team.teamName isEqualToString:item.teamName]) {
                oldOrder = team.teamOrder;
                break;
            }
        }
        NSLog(@"%@--, 新排名 - %@, 旧排名 - %@",item.teamName,newOrder, oldOrder);
        if (newOrder && newOrder.intValue != oldOrder.intValue) {
            
            NSIndexPath *path = [NSIndexPath indexPathForRow:[newOrder intValue]-1 inSection:0];
            NSIndexPath *oldPath = [NSIndexPath indexPathForRow:[oldOrder intValue]-1 inSection:0];
            
            [UIView animateWithDuration:0.6 animations:^{
                [self.tableView moveRowAtIndexPath:oldPath toIndexPath:path];
            } completion:^(BOOL finished) {
                
                
                if (1) {
                    
                    //如果移动的距离等于1，直接删除并添加
                    if (oldOrder.intValue - newOrder.intValue <= 1) {
                        
                        //需要将移动之后的数组  设置为旧的数组。必须统一
                        Model *n = self.oldArray[newOrder.intValue-1];
                        [self.oldArray removeObjectAtIndex:oldOrder.intValue-1];
                        [self.oldArray insertObject:n atIndex:oldOrder.intValue-1];
                        [self.oldArray removeObjectAtIndex:newOrder.intValue-1];
                        [self.oldArray insertObject:[cellArray firstObject] atIndex:newOrder.intValue-1];
                        
                        //更新旧的数组的排名
                        Model *old = [self.oldArray objectAtIndex:newOrder.intValue-1];
                        old.teamOrder = newOrder;
                        old = [self.oldArray objectAtIndex:oldOrder.intValue-1];
                        old.teamOrder = oldOrder;
                        
                        
                    }else
                    {
                        //在新的排名那儿插入，然后更新旧的数组
                        [self.oldArray insertObject:[cellArray firstObject] atIndex:newOrder.intValue-1];
                        [self.oldArray removeObjectAtIndex:oldOrder.intValue];
                        //在插入的地方到旧的排名之间的 更新排名
                        for (int i = newOrder.intValue; i < oldOrder.intValue; i++) {
                            
                            Model *t = self.oldArray[i];
                            t.teamOrder = @(t.teamOrder.intValue+1);
                            if (i>=self.oldArray.count) {
                                break;
                            }
                        }
                    }
                    for (Model *m in self.oldArray) {
                        NSLog(@"更新排名之后的数组  %@ %d",m.teamName, [m.teamOrder intValue]);
                    }
                    
                    NSIndexPath *updatePath = [NSIndexPath indexPathForRow:newOrder.integerValue-1 inSection:0];
                    //                    [self.tableView reloadRowsAtIndexPaths:@[updatePath] withRowAnimation:UITableViewRowAnimationFade];
                    
                    [cellArray removeObjectAtIndex:0];
                }
            }];
            NSLog(@"3");
            NSMutableArray *arr = [NSMutableArray arrayWithArray:cellArray];
            [arr removeObjectAtIndex:0];
            
            [self performSelector:@selector(animationArray:) withObject:arr afterDelay:0.6];
            
        }else{
            NSLog(@"4");
            [cellArray removeObjectAtIndex:0];
            [self animationArray:cellArray ];
        }
        //更新UI
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.03 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //            NSIndexPath *updatePath = [NSIndexPath indexPathForRow:oldOrder.integerValue-1 inSection:0];
        //            [self.tableView reloadRowsAtIndexPaths:@[updatePath] withRowAnimation:UITableViewRowAnimationFade];
        //        });
    }
}
@end
