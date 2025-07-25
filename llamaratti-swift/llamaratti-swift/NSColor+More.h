/**
 * @file NSColor+More.h
 *
 * @brief NSColor extension
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "Shared.h"

/**
 * @brief Extension to add features to NSColor as needed
 *
 */
@interface NSColor (More)

+ (NSColor *)colorWithHexString:(NSString *)hex
                          alpha:(CGFloat)a;

@end
