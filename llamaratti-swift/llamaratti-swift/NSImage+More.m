/**
 * @file NSImage+More.m
 *
 * @brief Extension to add features to NSImage as needed
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "NSImage+More.h"

@implementation NSImage (More)

/**
 * @brief Scales this image proportionally to a specified target size
 *
 * @param newSize the desired scaled size
 *
 * @return a scaled CGSize
 *
 */
- (NSImage *)scaledProportionallyToSize:(NSSize)newSize {
    
    if ( self.size.width == 0 || self.size.height == 0 ) {
        return nil;
    }

    CGFloat widthRatio  = newSize.width  / self.size.width;
    CGFloat heightRatio = newSize.height / self.size.height;
    CGFloat scaleFactor = MIN(widthRatio, heightRatio);

    NSSize targetSize = NSMakeSize(self.size.width * scaleFactor,
                                   self.size.height * scaleFactor);

    NSImage *scaledImage = [[NSImage alloc] initWithSize:targetSize];

    [scaledImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    [self drawInRect:NSMakeRect(0, 0, targetSize.width, targetSize.height)
            fromRect:NSZeroRect
           operation:NSCompositingOperationCopy
            fraction:1.0];

    [scaledImage unlockFocus];

    return scaledImage;
}

/**
 * @brief Tints this image with the specified color
 *
 * @param color the color to tint
 *
 * @return an NSImage with the specified color, or nil on error
 *
 */
- (NSImage *)imageTintedWithColor:(NSColor *)color {
    if ( !color) {
        return nil;
    }

    NSImage *imgNew = [[NSImage alloc] initWithSize:[self size]];
    [imgNew lockFocus];

    // Draw the original image
    [self drawAtPoint:NSZeroPoint
              fromRect:NSMakeRect(0, 0, self.size.width, self.size.height)
             operation:NSCompositingOperationSourceOver
              fraction:1.0];

    // Apply tint color
    [color set];
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);

    [imgNew unlockFocus];
    return imgNew;
}

@end
