/**
 * @file NSColor+More.m
 *
 * @brief Extension to add features to NSColor as needed
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "NSColor+More.h"

@implementation NSColor (More)

/**
 * @brief Creates an NSColor with a hex color string
 *
 * @param hex the hex color string in the format "RRGGBB"
 * @param a the alpha value to use when creating the color
 *
 * @return an NSColor object, or nil on error
 *
 */
+ (NSColor *)colorWithHexString:(NSString *)hex
                          alpha:(CGFloat)a {
    
    // Did we get the parameters we need?
    if  ( !isValidNSString(hex) ) {
        return nil;
    }

    NSInteger len=[hex length];
    if ( len != 6 ) {
        return nil;
    }
    
    NSString *cs=[hex stringByReplacingOccurrencesOfString:@"#"
                                                withString:@""];
    cs=[cs uppercaseString];
    
    // Extract RGB and Alpha Components from hex string
    CGFloat r=0.0f,g=0.0f,b=0.0f;
    r=[self getColorComponent:cs start:0];
    g=[self getColorComponent:cs start:2];
    b=[self getColorComponent:cs start:4];
    
    return [NSColor colorWithRed:r
                           green:g
                            blue:b
                           alpha:a];
}

/**
 * @brief Extracts a color component from a hex color string
 *
 * @param hex the hex color string
 * @param start where to start reading the color
 *
 * @return an NSColor object color, or nil on error
 *
 */
+ (CGFloat)getColorComponent:(NSString *)hex
                       start:(NSUInteger)start {
    
    // Did we get the parameters we need?
    if  ( !isValidNSString(hex) ) {
        return 0.0;
    }

    NSString *hexColorComponent=[hex substringWithRange:NSMakeRange(start,2)];
    if ( [hexColorComponent length] != 2 ) {
        return 0.0;
    }

    unsigned colorComponent=0;
    [[NSScanner scannerWithString:hexColorComponent]
                       scanHexInt:&colorComponent];
    
    return colorComponent/255.0;
}

@end
