/**
 * @file AckContent.m
 *
 * @brief Formats acknowledgements details
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

/**
 * @class AckContent
 *
 * @brief Formats acknowledgements details
 *
 */
@interface AckContent : NSObject

// Methods
- (id)init;
+ (NSAttributedString *)buildAck;

@end
