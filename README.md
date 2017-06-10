# DHDragableCellTableView

## 安装

可以直接将DHDragableCellTableView.h文件跟DHDragableCellTableView.m文件拖到项目中，也可使用cocopods安装

```
pod 'DHDragableCellTableView'
```

### 使用

将tableView继承于DHDragableCellTableView并遵循协议DHDragableCellTableViewDataSource,DHDragableCellTableViewDelegate

设置代理

```objc
tableView.dataSource = self;
tableView.Delegate = self;
```

实现代理方法

```objc
#pragma mark - DHDragableCellTableViewDataSource
- (NSArray *)dataSourceArrayInTableView:(DHDragableCellTableView *)tableView{
    return self.dataSource.copy;//数据源
}

- (void)tableView:(DHDragableCellTableView *)tableView newDataSourceArrayAfterMove:(NSArray *)newDataSourceArray{
    self.dataSource = newDataSourceArray.mutableCopy;//返回的数据源
    [self.tableView reloadData];
}
```



