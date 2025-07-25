/**
 * @file NSImage+More.h
 *
 * @brief Extension to add features to NSImage as needed
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Cocoa/Cocoa.h>

@interface NSImage (More)

// Methods
- (NSImage *)scaledProportionallyToSize:(NSSize)newSize ;

- (NSImage *)imageTintedWithColor:(NSColor *)color;

@end
