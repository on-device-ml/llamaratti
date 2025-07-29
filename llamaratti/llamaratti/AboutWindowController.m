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
#import "Utils.h"
#import "LlamarattiWrapper.h"

@implementation AboutWindowController {
}

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
    
    // Disable window resize & minimize
    self.window.styleMask &= ~NSWindowStyleMaskResizable;
    self.window.styleMask &= ~NSWindowStyleMaskMiniaturizable;
    
    [_imgViewLogo setImage:[NSImage imageNamed:@"AppIcon"]];
    [_imgViewLogo setImageScaling:NSImageScaleProportionallyUpOrDown];
    [_textAck setSelectable:YES];
    [_textAck setEditable:NO];
    
    [self.window setTitle:@"About Llamaratti"];
    
    // Add the acknowledgements text
    NSAttributedString *attrCredits = [AckContent buildAck];

    NSFont *fontMedium=[NSFont fontWithName:gFontNameNormal size:16];

#ifdef DEBUG
    NSString *buildType=@"Debug";
#else
    NSString *buildType=@"Release";
#endif

    // Build an info string
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *appInfo = [NSString stringWithFormat:@"%@ v%@ (b%@ - %@)",gAppName,appVersion,buildVersion,buildType];

    NSString *deviceInfo=[LlamarattiWrapper appleSiliconModel:YES];
    NSString *sandboxInfo=([Utils runningInSandbox]?@"Enabled":@"Disabled");
    NSString *finalDetails=[NSString stringWithFormat:
        @"%@\n\n%@\nSandbox - %@\nBuild - %@\n\n",appInfo,deviceInfo,sandboxInfo,buildType];
    
    [self->_textInfo setTextColor:[NSColor colorNamed:@"AppTextColor"]];
    [self->_textInfo setBackgroundColor:[NSColor windowBackgroundColor]];
    [self->_textInfo setDrawsBackground:NO];
    [self->_textInfo setSelectable:YES];
    [self->_textInfo setEditable:NO];
    [self->_textInfo setFont:fontMedium];
    [self->_textInfo setStringValue:finalDetails];

    [[self->_textAck textStorage] setAttributedString:attrCredits];
    
}

/**
 * @brief btnOk
 *
 */
- (IBAction)btnOk:(id)sender {
    
    [self close];
}

@end
