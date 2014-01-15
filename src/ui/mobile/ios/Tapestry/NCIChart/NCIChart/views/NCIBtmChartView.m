//
//  NCIBtmChartView.m
//  NCIChart
//
//  Created by Ira on 12/22/13.
//  Copyright (c) 2013 FlowForwarding.Org. All rights reserved.
//

#import "NCIBtmChartView.h"
#import "NCIHandspikeView.h"
#import "NCISimpleGraphView.h"
#import "NCISimpleGridView.h"
#import "NCIChartView.h"
#import "NCITopChartView.h"

@interface NCIBtmChartView(){
    NCIHandspikeView *handspikeLeft;
    NCIHandspikeView *handspikeRight;
    UIView *rightAmputation;
    UIView *leftAmputation;
    
    float handspikeWidth;
    float minRangesDistance;
}

@property(nonatomic)float xHandspikeLeft;
@property(nonatomic)float xHandspikeRight;

@end

@implementation NCIBtmChartView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        handspikeWidth = 2;
        minRangesDistance = 5;
    }
    return self;
}

- (void)addSubviews{
    [super addSubviews];
    handspikeLeft = [[NCIHandspikeView alloc] initWithFrame:CGRectZero];
    [self addSubview:handspikeLeft];
    handspikeRight = [[NCIHandspikeView alloc] initWithFrame:CGRectZero];
    [self addSubview:handspikeRight];
    rightAmputation = [[UIView alloc] initWithFrame:CGRectZero];
    rightAmputation.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.2];
    [self addSubview:rightAmputation];
    leftAmputation = [[UIView alloc] initWithFrame:CGRectZero];
    leftAmputation.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.2];
    [self addSubview:leftAmputation];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    if (self.nciChart.chartData.count == 0)
        return;
    if (self.nciChart.minRangeVal != self.nciChart.minRangeVal){
        self.nciChart.minRangeVal = [self.nciChart.chartData[0][0] doubleValue];
    }
    if (self.nciChart.maxRangeVal != self.nciChart.maxRangeVal){
        self.nciChart.maxRangeVal = [[self.nciChart.chartData lastObject][0] doubleValue];
    }
    [self redrawRanges];
}

- (void)redrawRanges{

    float gridHeigth =  self.graph.grid.frame.size.height;
    _xHandspikeLeft = [self.graph getXByArgument: self.nciChart.minRangeVal] + self.graph.xLabelsWidth;
    _xHandspikeRight = [self.graph getXByArgument: self.nciChart.maxRangeVal] + self.graph.xLabelsWidth;
    
    handspikeLeft.frame = CGRectMake(_xHandspikeLeft, 0, handspikeWidth, gridHeigth);
    leftAmputation.frame = CGRectMake(self.graph.xLabelsWidth, 0, _xHandspikeLeft - self.graph.xLabelsWidth, gridHeigth);
    
    handspikeRight.frame = CGRectMake(_xHandspikeRight, 0, handspikeWidth, gridHeigth);
    rightAmputation.frame = CGRectMake(_xHandspikeRight, 0,
                                       self.frame.size.width - _xHandspikeRight, gridHeigth);

    
}

#pragma all code below is about moving ranges

static float startLeft = -1;
static float startLeftRange = -1;
static float startRight = -1;
static float startRightRange = -1;

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    __block UITouch *touch1;
    __weak NCIBtmChartView *weakSelf = self;
    
    [[event allTouches] enumerateObjectsUsingBlock:^(UITouch  *touch, BOOL *stop) {
        CGPoint location = [touch locationInView:weakSelf];
        if ([event allTouches].count == 2 ){
            if (!touch1){
                touch1 = touch;
            } else {
                [weakSelf startMoveWithPoint:[touch1 locationInView:weakSelf] andPoint:location];
            }
        } else {
            if (location.x <= (_xHandspikeLeft + handspikeWidth)){
                startLeft = location.x - handspikeLeft.center.x;
            } else if (location.x >= _xHandspikeRight){
                startRight = location.x - handspikeRight.center.x;
            } else {
                startLeft = location.x - handspikeLeft.center.x;
                startRight = location.x - handspikeRight.center.x;
            }
        }
    }];
}

- (void)startMoveWithPoint:(CGPoint) point1 andPoint:(CGPoint) point2{
    startLeftRange = handspikeLeft.center.x;
    startRightRange = handspikeRight.center.x;
    if(point1.x < point2.x){
        startLeft = point1.x - handspikeLeft.center.x;
        startRight = point2.x - handspikeRight.center.x;
    } else {
        startLeft = point2.x - handspikeLeft.center.x;
        startRight = point1.x - handspikeRight.center.x;
    }
    // self.chart.rangesMoved();
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    __block UITouch *touch1;
    
    __block float newLeft = -1;
    __block float newRight = -1;
    
    __weak NCIBtmChartView* weakSelf = self;
    //here we set up new min and max ranges values for chart
    [[event allTouches] enumerateObjectsUsingBlock:^(UITouch  *touch, BOOL *stop) {
        CGPoint location = [touch locationInView:weakSelf];
        if ([event allTouches].count == 2 ){
            if (!touch1){
                touch1 = touch;
            } else {
                NSArray *newXPos = [weakSelf detectNewXPosFrom:[touch1 locationInView:weakSelf] and:location];
                newLeft = [(NSNumber *)newXPos[0] doubleValue];
                newRight = [(NSNumber *)newXPos[1] doubleValue];
            }
            
        } else {
            if (location.x <= (_xHandspikeLeft + handspikeWidth)){
                newLeft = location.x - startLeft;
            } else if (location.x >= _xHandspikeRight){
                newRight = location.x - startRight;
            } else {
                newLeft = location.x - startLeft;
                newRight = location.x - startRight;
            }
        };
        
    }];
    
    [self moveRangesFollowingNewLeft:newLeft newRight:newRight];
}


- (void)moveRangesFollowingNewLeft:(double)newLeft newRight:(double)newRight {
    
    if (!( (newLeft != -1 ) && ((newLeft - self.graph.xLabelsWidth) > 0))){
        newLeft = _xHandspikeLeft;
    };
    
    if (!((newRight != -1) && (newRight < self.frame.size.width))){
        newRight = _xHandspikeRight;
    };
    
    if ((newLeft != -1 && newRight != -1) && (newRight - newLeft) < minRangesDistance)
        return;
    
    self.nciChart.minRangeVal = [self.graph getArgumentByX:newLeft - self.graph.xLabelsWidth];
    self.nciChart.maxRangeVal = [self.graph getArgumentByX:newRight - self.graph.xLabelsWidth];

    [self.nciChart.topChart.graph setNeedsLayout];
    [self.nciChart.topChart.graph.grid setNeedsDisplay];
    [self.nciChart.topChart layoutSelectedPoint];
    if (self.nciChart.rangesMoved)
        self.nciChart.rangesMoved();
    [self redrawRanges];
}

//these 2 reverse methods are for Main Graph pinch gesures
- (void)moveReverseRangesWithPoint:(CGPoint) point1 andPoint:(CGPoint) point2{
    NSArray *newXPos = [self detectNewReverseXPosFrom:point1 and:point2];
    [self moveRangesFollowingNewLeft:[(NSNumber *)newXPos[0] doubleValue] newRight:[(NSNumber *)newXPos[1] doubleValue]];
}

- (NSArray *)detectNewReverseXPosFrom:(CGPoint)location1 and:(CGPoint) location2{
    if (location1.x < location2.x){
        return @[@(startLeftRange - ( (location1.x - startLeft) - startLeftRange )),
                 @(startRightRange + (startRightRange -(location2.x - startRight)))];
    } else {
        return @[@(startLeftRange - ( (location2.x - startLeft) - startLeftRange)),
                 @(startRightRange + (startRightRange - (location1.x - startRight)))];
    }
}

- (NSArray *)detectNewXPosFrom:(CGPoint)location1 and:(CGPoint) location2{
    if (location1.x < location2.x){
        return @[@(location1.x - startLeft), @(location2.x - startRight)];
    } else {
        return @[@(location2.x - startLeft), @(location1.x - startRight)];
    }
}

@end
