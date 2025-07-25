/**
 * @file AboutWindowController.h
 *
 * @brief About dialog for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Cocoa/Cocoa.h>

#import "Shared.h"

@interface AboutWindowController : NSWindowController

@property (weak) IBOutlet NSImageView *imgViewLogo;
@property (weak) IBOutlet NSTextView *textAck;
@property (weak) IBOutlet NSButton *btnOk;

@end
