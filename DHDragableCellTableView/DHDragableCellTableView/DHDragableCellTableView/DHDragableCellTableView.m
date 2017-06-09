//
//  DH_DragableCellTableView.m
//  DH_DragableCellTableView
//
//  Created by jiaxin on 16/2/15.
//  Copyright © 2016年 jiaxin. All rights reserved.
//

#import "DHDragableCellTableView.h"

static NSTimeInterval kDH_DragableCellAnimationTime = 0.25;

@interface DHDragableCellTableView ()
@property (nonatomic, strong) UILongPressGestureRecognizer  *gesture;
@property (nonatomic, strong) NSIndexPath                   *selectedIndexPath;
@property (nonatomic, strong) UIView                        *tempView;
@property (nonatomic, strong) NSMutableArray                *tempDataSource;
@property (nonatomic, strong) CADisplayLink                 *edgeScrollTimer;
@property (nonatomic, assign) CGPoint                       lastPoint;
@property (nonatomic, assign) int                           toBottom;
@end

@implementation DHDragableCellTableView

@dynamic dataSource, delegate;

- (void)dealloc
{
    _drawMovalbeCellBlock = nil;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self dh_initData];
        [self dh_addGesture];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self dh_initData];
        [self dh_addGesture];
    }
    return self;
}

- (void)dh_initData
{
    _gestureMinimumPressDuration = 1.0f;
    _canEdgeScroll = YES;
    _edgeScrollRange = 150.f;
}

#pragma mark Setter
/**
 设置长按时间
 */
- (void)setGestureMinimumPressDuration:(CGFloat)gestureMinimumPressDuration
{
    _gestureMinimumPressDuration = gestureMinimumPressDuration;
    _gesture.minimumPressDuration = MAX(0.2, gestureMinimumPressDuration);
}

#pragma mark Gesture

/**
 添加手势
 */
- (void)dh_addGesture
{
    _gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dh_processGesture:)];
    _gesture.minimumPressDuration = _gestureMinimumPressDuration;
    [self addGestureRecognizer:_gesture];
}

/**
 监听手势状态
 */
- (void)dh_processGesture:(UILongPressGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self dh_gestureBegan:gesture];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            if (!_canEdgeScroll) {
                [self dh_gestureChanged:gesture];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            [self dh_gestureEndedOrCancelled:gesture];
        }
            break;
        default:
            break;
    }
}

/**
 开始移动
 */
- (void)dh_gestureBegan:(UILongPressGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:gesture.view];
    self.lastPoint = point;
    NSIndexPath *selectedIndexPath = [self indexPathForRowAtPoint:point];
    if (!selectedIndexPath) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:willMoveCellAtIndexPath:)]) {
        [self.delegate tableView:self willMoveCellAtIndexPath:selectedIndexPath];
    }
    if (_canEdgeScroll) {
        //开启边缘滚动
        [self dh_startEdgeScroll];
    }
    //每次移动开始获取一次数据源
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(dataSourceArrayInTableView:)]) {
        _tempDataSource = [self.dataSource dataSourceArrayInTableView:self].mutableCopy;
    }
    _selectedIndexPath = selectedIndexPath;
    UITableViewCell *cell = [self cellForRowAtIndexPath:selectedIndexPath];
    _tempView = [self dh_snapshotViewWithInputView:cell];
    if (_drawMovalbeCellBlock) {
        //将_tempView通过block让使用者自定义
        _drawMovalbeCellBlock(_tempView);
    }else {
        //配置默认样式
        _tempView.layer.shadowColor = [UIColor grayColor].CGColor;
        _tempView.layer.masksToBounds = NO;
        _tempView.layer.cornerRadius = 0;
        _tempView.layer.shadowOffset = CGSizeMake(-5, 0);
        _tempView.layer.shadowOpacity = 0.4;
        _tempView.layer.shadowRadius = 5;
    }
    _tempView.frame = cell.frame;
    [self addSubview:_tempView];
    //隐藏cell
    cell.hidden = YES;
    [UIView animateWithDuration:kDH_DragableCellAnimationTime animations:^{
        _tempView.center = CGPointMake(_tempView.center.x, point.y);
    }];
}

/**
 手势移动
 */
- (void)dh_gestureChanged:(UILongPressGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:gesture.view];
    //判断拖动的方向
    if (point.y - self.lastPoint.y > 0) {
        _toBottom = 1;//向下拖
    }else if(point.y - self.lastPoint.y < 0){
        _toBottom = -1;//向上拖
    }else{
        _toBottom = 0;
    }
    self.lastPoint = point;
    NSIndexPath *currentIndexPath = [self indexPathForRowAtPoint:point];
    if (currentIndexPath && ![_selectedIndexPath isEqual:currentIndexPath]) {
        UITableViewCell *cell = [self cellForRowAtIndexPath:_selectedIndexPath];
        UITableViewCell *cell1 = [self cellForRowAtIndexPath:currentIndexPath];
        //将拖动的cell跟要交换的cell的centerY进行比较
        if ((_toBottom == 1 && (point.y+cell.frame.size.height/2) >= CGRectGetMaxY(cell1.frame) && (CGRectGetMaxY(cell1.frame) >= CGRectGetMaxY(cell.frame))) || ((_toBottom == -1 && (point.y-cell.frame.size.height/2) <= CGRectGetMinY(cell1.frame)) && (CGRectGetMinY(cell1.frame) <= CGRectGetMinY(cell.frame)))) {
            //交换数据源和cell
            [self dh_updateDataSourceAndCellFromIndexPath:_selectedIndexPath toIndexPath:currentIndexPath];
            if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:didMoveCellFromIndexPath:toIndexPath:)]) {
                [self.delegate tableView:self didMoveCellFromIndexPath:_selectedIndexPath toIndexPath:currentIndexPath];
            }
            _selectedIndexPath = currentIndexPath;
        }
    }
    //让截图跟随手势
    _tempView.center = CGPointMake(_tempView.center.x, point.y);
}

/**
 手势停止
 */
- (void)dh_gestureEndedOrCancelled:(UILongPressGestureRecognizer *)gesture
{
    if (_canEdgeScroll) {
        [self dh_stopEdgeScroll];
    }
    //返回交换后的数据源
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(tableView:newDataSourceArrayAfterMove:)]) {
        [self.dataSource tableView:self newDataSourceArrayAfterMove:_tempDataSource.copy];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:endMoveCellAtIndexPath:)]) {
        [self.delegate tableView:self endMoveCellAtIndexPath:_selectedIndexPath];
    }
    UITableViewCell *cell = [self cellForRowAtIndexPath:_selectedIndexPath];
//    [UIView animateWithDuration:kDH_DragableCellAnimationTime animations:^{
//        _tempView.frame = cell.frame;
//    } completion:^(BOOL finished) {
//        [_tempView removeFromSuperview];
//        _tempView = nil;
//        cell.hidden = NO;
//    }];
    [_tempView removeFromSuperview];
    _tempView = nil;
    cell.hidden = NO;
}

#pragma mark Private action

/**
 截图
 */
- (UIView *)dh_snapshotViewWithInputView:(UIView *)inputView
{
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    return snapshot;
}

- (void)dh_updateDataSourceAndCellFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if ([self numberOfSections] == 1) {
        //只有一组
        [_tempDataSource exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
        //交换cell
        [self moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }else {
        //有多组
        id fromData = _tempDataSource[fromIndexPath.section][fromIndexPath.row];
        id toData = _tempDataSource[toIndexPath.section][toIndexPath.row];
        NSMutableArray *fromArray = [_tempDataSource[fromIndexPath.section] mutableCopy];
        NSMutableArray *toArray = [_tempDataSource[toIndexPath.section] mutableCopy];
        [fromArray replaceObjectAtIndex:fromIndexPath.row withObject:toData];
        [toArray replaceObjectAtIndex:toIndexPath.row withObject:fromData];
        [_tempDataSource replaceObjectAtIndex:fromIndexPath.section withObject:fromArray];
        [_tempDataSource replaceObjectAtIndex:toIndexPath.section withObject:toArray];
        //交换cell
        [self beginUpdates];
        
        [self moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        [self moveRowAtIndexPath:toIndexPath toIndexPath:fromIndexPath];
        [self endUpdates];
    }
    //返回交换后的数据源
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(tableView:newDataSourceArrayAfterMove:)]) {
        [self.dataSource tableView:self newDataSourceArrayAfterMove:_tempDataSource.copy];
    }
    //此处用两个cell的截图实现交换的动画
    UITableViewCell *cell = [self cellForRowAtIndexPath:fromIndexPath];
    cell.hidden = NO;
    UITableViewCell *cell1 = [self cellForRowAtIndexPath:toIndexPath];
    cell1.hidden = YES;
    UIView *tmpCell = [self dh_snapshotViewWithInputView:cell];
    cell.hidden = YES;
    tmpCell.frame = cell1.frame;
    if (_toBottom == -1) {//向上
        tmpCell.frame = CGRectMake(0, CGRectGetMinY(cell1.frame), cell.frame.size.width, cell.frame.size.height);
        [self insertSubview:tmpCell belowSubview:_tempView];
    }else if (_toBottom == 1) {//向下
        tmpCell.frame = CGRectMake(0, CGRectGetMaxY(cell1.frame)-cell.frame.size.height, cell.frame.size.width, cell.frame.size.height);
        [self insertSubview:tmpCell belowSubview:_tempView];
    }else{
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        tmpCell.frame = cell.frame;
    }completion:^(BOOL finished) {
        cell.hidden = NO;
        [tmpCell removeFromSuperview];
    }];
}

#pragma mark EdgeScroll

- (void)dh_startEdgeScroll
{
    _edgeScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(dh_processEdgeScroll)];
    [_edgeScrollTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)dh_processEdgeScroll
{
    [self dh_gestureChanged:_gesture];
    CGFloat minOffsetY = self.contentOffset.y + _edgeScrollRange;
    CGFloat maxOffsetY = self.contentOffset.y + self.bounds.size.height - _edgeScrollRange;
    CGPoint touchPoint = _tempView.center;
    //处理上下达到极限之后不再滚动tableView，其中处理了滚动到最边缘的时候，当前处于edgeScrollRange内，但是tableView还未显示完，需要显示完tableView才停止滚动
    if (touchPoint.y < _edgeScrollRange) {
        if (self.contentOffset.y <= 0) {
            return;
        }else {
            if (self.contentOffset.y - 1 < 0) {
                return;
            }
            [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y - 1) animated:NO];
            _tempView.center = CGPointMake(_tempView.center.x, _tempView.center.y - 1);
        }
    }
    if (touchPoint.y > self.contentSize.height - _edgeScrollRange) {
        if (self.contentOffset.y >= self.contentSize.height - self.bounds.size.height) {
            return;
        }else {
            if (self.contentOffset.y + 1 > self.contentSize.height - self.bounds.size.height) {
                return;
            }
            [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y + 1) animated:NO];
            _tempView.center = CGPointMake(_tempView.center.x, _tempView.center.y + 1);
        }
    }
    //处理滚动
    CGFloat maxMoveDistance = 20;
    if (touchPoint.y < minOffsetY) {
        //cell在往上移动
        CGFloat moveDistance = (minOffsetY - touchPoint.y)/_edgeScrollRange*maxMoveDistance;
        [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y - moveDistance) animated:NO];
        _tempView.center = CGPointMake(_tempView.center.x, _tempView.center.y - moveDistance);
    }else if (touchPoint.y > maxOffsetY) {
        //cell在往下移动
        CGFloat moveDistance = (touchPoint.y - maxOffsetY)/_edgeScrollRange*maxMoveDistance;
        [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y + moveDistance) animated:NO];
        _tempView.center = CGPointMake(_tempView.center.x, _tempView.center.y + moveDistance);
    }
}

- (void)dh_stopEdgeScroll
{
    if (_edgeScrollTimer) {
        [_edgeScrollTimer invalidate];
        _edgeScrollTimer = nil;
    }
}

@end
