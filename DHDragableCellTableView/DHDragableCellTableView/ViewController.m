//
//  ViewController.m
//  DHDragableCellTableView
//
//  Created by aiden on 2017/6/9.
//  Copyright © 2017年 aiden. All rights reserved.
//

#import "ViewController.h"
#import "DHDragableCellTableView.h"

@interface ViewController ()<DHDragableCellTableViewDataSource,DHDragableCellTableViewDelegate>
@property (nonatomic, strong) DHDragableCellTableView   *tableView;
@property (nonatomic ,strong) NSMutableArray            *dataSource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.tableView ];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"cell高度为%d",[self.dataSource[indexPath.row] intValue]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self.dataSource[indexPath.row] floatValue];
}

#pragma mark - DHDragableCellTableViewDataSource
- (NSArray *)dataSourceArrayInTableView:(DHDragableCellTableView *)tableView{
    return self.dataSource.copy;
}

- (void)tableView:(DHDragableCellTableView *)tableView newDataSourceArrayAfterMove:(NSArray *)newDataSourceArray{
    self.dataSource = newDataSourceArray.mutableCopy;
    [self.tableView reloadData];
}
#pragma mark - getter
- (DHDragableCellTableView *)tableView{
    if (!_tableView) {
        _tableView = [[DHDragableCellTableView alloc] initWithFrame:self.view.bounds];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (NSMutableArray *)dataSource{
    if (!_dataSource) {
        _dataSource = @[@50,@60,@70,@80,@90,@100,@110,@120,@130,@140,@150].mutableCopy;
    }
    return _dataSource;
}
@end
