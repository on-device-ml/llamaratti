/**
 * @file CircularProgressView.h
 *
 * @brief
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
#import <Cocoa/Cocoa.h>

@interface CircularProgressView : NSView

@property (nonatomic) CGFloat progress; // 0.0 to 1.0
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic, strong) NSColor *progressColor;
@property (nonatomic, strong) NSColor *trackColor;

@end
