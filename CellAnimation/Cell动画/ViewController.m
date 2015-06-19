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
//@property(nonatomic,strong)NSMutableArray *nArr;
@property (nonatomic,strong) NSArray *oldArrayBeforeAnimate;   // 开始cell移动动画前保存最初的模型数组
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
    // 开始cell移动动画前保存最初的模型数组
    self.oldArrayBeforeAnimate = [NSArray arrayWithArray:self.oldArray];
    if (self.oldArrayBeforeAnimate.count <1) return;
    
    NSLog(@"排序前：%@",self.oldArray);
    [self cellExchangeWithTeamName:[self.oldArrayBeforeAnimate[0] teamName] oldIndexBeforeAnimate:0];
}
- (void)cellExchangeWithTeamName:(NSString *)teamName oldIndexBeforeAnimate:(NSInteger)oldIndex{
    // 旧的模型
    Model *oldModel = nil;
    for (Model *model in self.oldArray) {
        if ([model.teamName isEqualToString:teamName]) {
            oldModel = model;
            break;
        }
    }
    // 旧的的位置
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:[self.oldArray indexOfObject:oldModel] inSection:0];
    
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
    
    if (oldIndexPath.row == newIndexPath.row){
        // 如果位置没变化直接开始下一个cell的移动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (oldIndex+1 <= self.oldArrayBeforeAnimate.count-1) {
                [self cellExchangeWithTeamName:[self.oldArrayBeforeAnimate[oldIndex+1] teamName] oldIndexBeforeAnimate:oldIndex+1];
            }
        });
        return;
    }
    
    // 模型交换位置,并更新排名
    NSNumber *tempRange = [self.oldArray[oldIndexPath.row] teamOrder];
    [self.oldArray[oldIndexPath.row] setTeamOrder:@(newIndexPath.row+1)];
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
            if (oldIndex+1 <= self.oldArrayBeforeAnimate.count-1) {
                [self cellExchangeWithTeamName:[self.oldArrayBeforeAnimate[oldIndex+1] teamName] oldIndexBeforeAnimate:oldIndex+1];
            }
        });
    }];
}



- (void)refreshDataSourceModelArr{
    
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
        _refreshArray = arrayModels;
    }
    return  _refreshArray;
}
//- (NSArray *)nArr
//{
//    if (!_nArr) {
//        NSString *path = [[NSBundle mainBundle]pathForResource:@"NewArray.plist" ofType:nil];
//        NSArray *arr = [NSArray arrayWithContentsOfFile:path];
//        NSMutableArray *arrayModels = [NSMutableArray array];
//        
//        for (NSDictionary *dict in arr) {
//            Model *model = [Model modelWithDict:dict];
//            [arrayModels addObject:model];
//        }
//        _nArr = arrayModels;
//    }
//    return _nArr;
//}

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
