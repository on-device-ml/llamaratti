/**
 * @file DragDropTextView.h
 *
 * @brief NSTextView subclass to support drag/drop and other custom stuff
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "LlamarattiWrapper.h"

@interface DragDropTextView : NSTextView <NSDraggingDestination>
{
}

// Properties
@property NSObject *vcParent;
@property BOOL dragAccepted;
@property BOOL cmdReturnAccepted;
@property (nonatomic, strong) NSString *placeholderString;

// Methods
- (void)reset;

@end
