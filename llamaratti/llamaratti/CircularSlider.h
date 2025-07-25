/**
 * @file CircularSlider.h
 *
 * @brief
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
#import <Cocoa/Cocoa.h>

@interface CircularSlider : NSControl

@property (nonatomic) double minValue;
@property (nonatomic) double maxValue;
@property (nonatomic) double value;
@property (nonatomic) BOOL isTracking;

@property (nonatomic) NSInteger numberOfTickMarks;
@property (nonatomic) BOOL snapsToTickMarks;
@property (nonatomic) CGFloat knobRadius;
@property (nonatomic) CGFloat trackLineWidth;
@property (nonatomic) CGFloat tickLineWidth;

@property (nonatomic) NSColor *trackColor;
@property (nonatomic) NSColor *tickColor;
@property (nonatomic) NSColor *knobColor;

//@property (nonatomic, assign) BOOL enabled;
@property (assign,getter=isEnabled) BOOL enabled;

@end
