//
//  NCISimpleGraphView.m
//  NCIChart
//
//  Created by Ira on 12/20/13.
//  Copyright (c) 2013 FlowForwarding.Org. All rights reserved.
//

#import "NCISimpleGraphView.h"
#import "NCISimpleGridView.h"

@interface NCISimpleGraphView(){
    
}

@end

@implementation NCISimpleGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _xLabelsDistance = 200;
        _yLabelsDistance = 50;
        _xLabelsWidth = 100;
        _yLabelsHeigth = 40;
        _yAxisLabels = [[NSMutableArray alloc] init];
        _xAxisLabels = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor clearColor];
        [self addSubviews];
    }
    return self;
}

- (void)addSubviews{
    self.grid = [[NCISimpleGridView alloc] initWithGraph:self];
    [self addSubview:self.grid];
}

- (id)initWithChart: (NCISimpleChartView *)chartHolder{
    self = [self initWithFrame:CGRectZero];
    if (self){
        _chart = chartHolder;
    }
    return  self;
}

- (void)layoutSubviews{
    for (UILabel *label in _yAxisLabels){
        [label removeFromSuperview];
    }
    for (UILabel *label in _xAxisLabels){
        [label removeFromSuperview];
    }
    [_yAxisLabels removeAllObjects];
    [_xAxisLabels removeAllObjects];
    
    _gridHeigth = self.frame.size.height- _yLabelsHeigth;
    _gridWidth = self.frame.size.width - _xLabelsWidth;
    if (_chart.chartData.count > 0){
        _minXVal = [_chart.chartData[0][0] timeIntervalSince1970];
        _maxXVal = [[_chart.chartData lastObject][0] timeIntervalSince1970];
        _xStep = _gridWidth/(_maxXVal - _minXVal);
        [self detectRanges];
        for(int i = 0; i<= _gridHeigth/_yLabelsDistance; i++){
            UILabel *label = [[UILabel alloc] initWithFrame:
                              CGRectMake(0, self.frame.size.height - i*_yLabelsDistance - _yLabelsHeigth, _xLabelsWidth, 20)];
            label.text = [@([self getValByY: (_yLabelsHeigth + _yLabelsDistance *i)]) description];
            [_yAxisLabels addObject:label];
            [self addSubview:label];
        }
        [self redrawXLabels];
    }
    _grid.frame = CGRectMake(_xLabelsWidth, 0, _gridWidth, _gridHeigth);
   // [grid setNeedsDisplay];
}

- (void)detectRanges{
    NSArray *yVals = [_chart getBoundaryValues];
    _minYVal = [yVals[0] floatValue];
    _maxYVal = [yVals[1] floatValue];
    _yStep = _gridHeigth/(_maxYVal - _minYVal);
}

- (void)redrawXLabels{
    for(int i = 0; i<= _gridWidth/_xLabelsDistance; i++){
        UILabel *label = [[UILabel alloc] initWithFrame:
                          CGRectMake(_xLabelsWidth + _xLabelsDistance *i,
                                     self.frame.size.height - _yLabelsHeigth, _xLabelsDistance,
                                     _yLabelsHeigth)];
        label.text = [[self getDateByX: (_xLabelsWidth + _xLabelsDistance *i)] description];
        [_xAxisLabels addObject:label];
        [self addSubview:label];
    }
}

- (NSDate *)getDateByX:(float) pointX{
    return [NSDate dateWithTimeIntervalSince1970:(_minXVal + (pointX - _xLabelsWidth)/_xStep)];
}

- (float )getValByY:(float) pointY{
    return _minYVal + (pointY - _yLabelsHeigth)/_yStep;
}

- (CGPoint)pointByServerDataInGrid:(NSArray *)data{
    NSDate *date = data[0];
    float yVal = self.frame.size.height - (([data[1] integerValue] - _minYVal)*_yStep) - _yLabelsHeigth;
    float xVal = [self getXValueByDate: date];
    return CGPointMake(xVal, yVal);
}

- (float)getXValueByDate:(NSDate *)date{
    return ([date timeIntervalSince1970] - _minXVal)*_xStep;
}

@end
