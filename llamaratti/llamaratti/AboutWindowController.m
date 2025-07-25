/**
 * @file AboutWindowController.m
 *
 * @brief About dialog for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "AboutWindowController.h"
#import "AckContent.h"

@implementation AboutWindowController

/**
 * @brief init
 *
 */
- (instancetype)init {
    self = [super initWithWindowNibName:@"AboutWindowController"];
    return self;
}

/**
 * @brief windowDidLoad
 *
 */
- (void)windowDidLoad {
    
    [super windowDidLoad];

    [_imgViewLogo setImage:[NSImage imageNamed:@"AppIcon"]];
    [_imgViewLogo setImageScaling:NSImageScaleProportionallyUpOrDown];
    [_textAck setSelectable:YES];
    [_textAck setEditable:NO];
    
    [self.window setTitle:@"About Llamaratti"];

    // Add the acknowledgements text
    NSAttributedString *attrCredits = [AckContent buildAck];
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        [[self->_textAck textStorage] setAttributedString:attrCredits];
    }];
    
    // Disable window resize
    self.window.styleMask &= ~NSWindowStyleMaskResizable;
}

/**
 * @brief btnOk
 *
 */
- (IBAction)btnOk:(id)sender {
    
    [self close];
}

@end
