/**
 * @file NSImage+More.h
 *
 * @brief Extension to add features to NSImage as needed
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Cocoa/Cocoa.h>
#import "Shared.h"
#import "Errors.h"

@interface NSImage (More)

// Methods
- (NSImage *)scaledProportionallyToSize:(NSSize)newSize ;

- (NSImage *)imageTintedWithColor:(NSColor *)color;

+ (NSURL *)convertHEICtoTmpJPG:(NSURL *)urlImage
                 withTmpPrefix:(NSString *)tmpPrefix
                      withLoss:(CGFloat)loss;

+ (NSURL *)convertWEBPtoTmpJPG:(NSURL *)urlImage
                 withTmpPrefix:(NSString *)tmpPrefix;

+ (CGImageRef) rotateImage:(CGImageRef)imageRef
             toOrientation:(NSInteger)orientation;

@end
