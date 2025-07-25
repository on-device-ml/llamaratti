/**
 * @file CircularSlider.m
 *
 * @brief
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "CircularSlider.h"

@implementation CircularSlider {
    double _lastValue;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initProperties];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initProperties];
    }
    return self;
}

- (void)initProperties {
    
    _minValue = 0.0;
    _maxValue = 1.0;
    _lastValue = _value = 0.0;
    
    _numberOfTickMarks = _maxValue*10;
    _snapsToTickMarks = YES;
    _knobRadius = 5.0;
    _trackLineWidth = 2.0;
    _tickLineWidth = 0.3;
    
    _trackColor = [NSColor disabledControlTextColor];
    _tickColor = [NSColor disabledControlTextColor];
    _knobColor = [NSColor disabledControlTextColor];
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)setValue:(double)newValue {
    
    double clamped = MIN(MAX(newValue, _minValue), _maxValue);

    if (_snapsToTickMarks && _numberOfTickMarks > 1) {
        double tickSpacing = (_maxValue - _minValue) / (_numberOfTickMarks - 1);
        clamped = round((clamped - _minValue) / tickSpacing) * tickSpacing + _minValue;
    }

    if (_value != clamped) {
        _value = clamped;
        [self setNeedsDisplay:YES];
        [self sendAction:[self action] to:[self target]];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSPoint center = NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds));
    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2 - _knobRadius * 2;

    // Draw track
    NSBezierPath *circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithArcWithCenter:center
                                            radius:radius
                                        startAngle:0
                                          endAngle:360
                                         clockwise:NO];
    
    // Update the trackColor
    NSColor *color=(super.enabled?_trackColor:[NSColor disabledControlTextColor]);
    [color setStroke];
    
    [circlePath setLineWidth:_trackLineWidth];
    [circlePath stroke];

    // Draw tick marks
    for (NSInteger i = 0; i < self.numberOfTickMarks; i++) {
        CGFloat angle = ((CGFloat)i / self.numberOfTickMarks) * 360.0;
        NSPoint outer = [self pointOnCircle:center radius:radius angle:angle];
        NSPoint inner = [self pointOnCircle:center radius:(radius - 10) angle:angle];

        NSBezierPath *tick = [NSBezierPath bezierPath];
        [tick moveToPoint:inner];
        [tick lineToPoint:outer];
        
        // Update the tickColor
        color=(super.enabled?_tickColor:[NSColor disabledControlTextColor]);
        [color setStroke];
        
        [tick setLineWidth:_tickLineWidth];
        [tick stroke];
    }

    // Draw knob
    CGFloat angle = ((_value - _minValue) / (_maxValue - _minValue)) * 360.0;
    NSPoint knobPoint = [self pointOnCircle:center radius:radius angle:angle];

    NSRect knobRect = NSMakeRect(knobPoint.x - _knobRadius,
                                 knobPoint.y - _knobRadius,
                                 _knobRadius * 2,
                                 _knobRadius * 2);

    NSBezierPath *knob = [NSBezierPath bezierPathWithOvalInRect:knobRect];
    
    // Update the knobColor
    color=(super.enabled?_knobColor:[NSColor disabledControlTextColor]);
    [color setFill];
    
    [knob fill];
}

- (void)mouseDown:(NSEvent *)event {
    if ( !super.enabled ) {
        return;
    }
    _isTracking = YES;
    self->_lastValue = self.value;
    [self updateValueWithEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
    if ( !super.enabled ) {
        return;
    }
    if (_isTracking) {
        [self updateValueWithEvent:event];
    }
}

- (void)mouseUp:(NSEvent *)event {
    if ( !super.enabled ) {
        return;
    }
    _isTracking = NO;
    
    // Did the value change?
    if ( self.value != _lastValue ) {
        [self sendAction:[self action] to:[self target]];
    }
}

- (void)updateValueWithEvent:(NSEvent *)event {
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    NSPoint center = NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds));
    CGFloat dx = location.x - center.x;
    CGFloat dy = location.y - center.y;
    CGFloat angle = atan2(dy, dx) * 180.0 / M_PI;
    if (angle < 0) angle += 360;

    double rawValue = (angle / 360.0) * (_maxValue - _minValue) + _minValue;
    self.value = rawValue; // Let setValue handle snapping
    
    if ( ! super.enabled ) {
        [[NSColor colorWithWhite:1.0 alpha:0.5] set];
        NSRectFillUsingOperation(self.bounds, NSCompositingOperationSourceAtop);
    }
}

- (NSPoint)pointOnCircle:(NSPoint)center radius:(CGFloat)radius angle:(CGFloat)angleDegrees {
    CGFloat radians = angleDegrees * M_PI / 180.0;
    return NSMakePoint(center.x + radius * cos(radians),
                       center.y + radius * sin(radians));
}

- (void)setEnabled:(BOOL)enabled {
    if (super.enabled != enabled) {
        super.enabled = enabled;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)isEnabled {
    return super.enabled;
}

@end

