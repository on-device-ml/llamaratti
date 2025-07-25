/**
 * @file RippleMetaView.h
 *
 * @brief Provides a view that can apply a Metal ripple effect to images
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
#import <MetalKit/MetalKit.h>

@interface RippleMetalView : MTKView

// Methods
- (instancetype)initWithFrame:(NSRect)frameRect image:(NSImage *)image;
- (void)startRipple;
- (void)stopRipple;
- (void)toggleRipple:(BOOL)bEnabled;

@end
