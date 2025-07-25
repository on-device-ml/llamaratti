/**
 * @file CircularProgressView..m
 *
 * @brief
 *
 * @author Created by Geoff G. on 05/25/2025
 * 
 */
#import "CircularProgressView.h"

@implementation CircularProgressView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0.0;
        _lineWidth = 6.0;
        _progressColor = [NSColor systemBlueColor];
        _trackColor = [NSColor lightGrayColor];
        self.wantsLayer = YES;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    _progress = fmin(fmax(progress, 0.0), 1.0);
    [self setNeedsDisplay:YES];
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    [self setNeedsDisplay:YES];
}

- (void)setProgressColor:(NSColor *)progressColor {
    _progressColor = progressColor;
    [self setNeedsDisplay:YES];
}

- (void)setTrackColor:(NSColor *)trackColor {
    _trackColor = trackColor;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSRect bounds = self.bounds;
    CGPoint center = CGPointMake(NSMidX(bounds), NSMidY(bounds));
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) / 2 - self.lineWidth / 2;

    // Draw track
    NSBezierPath *trackPath = [NSBezierPath bezierPath];
    [trackPath appendBezierPathWithArcWithCenter:center
                                           radius:radius
                                       startAngle:0
                                         endAngle:360
                                        clockwise:NO];
    trackPath.lineWidth = self.lineWidth;
    [self.trackColor setStroke];
    [trackPath stroke];

    // Draw progress
    NSBezierPath *progressPath = [NSBezierPath bezierPath];
    CGFloat endAngle = self.progress * 360.0;
    [progressPath appendBezierPathWithArcWithCenter:center
                                              radius:radius
                                          startAngle:90
                                            endAngle:90 - endAngle
                                           clockwise:YES];
    progressPath.lineWidth = self.lineWidth;
    [self.progressColor setStroke];
    [progressPath stroke];
}

@end
