# DHDragableCellTableView

将tableView继承与DHDragableCellTableView并遵循协议DHDragableCellTableViewDataSource,DHDragableCellTableViewDelegate

```objective-c
#pragma mark - DHDragableCellTableViewDataSource
- (NSArray *)dataSourceArrayInTableView:(DHDragableCellTableView *)tableView{
    return self.dataSource.copy;//数据源
}

- (void)tableView:(DHDragableCellTableView *)tableView newDataSourceArrayAfterMove:(NSArray *)newDataSourceArray{
    self.dataSource = newDataSourceArray.mutableCopy;//返回的数据源
    [self.tableView reloadData];
}
```

