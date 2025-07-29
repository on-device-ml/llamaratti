/**
 * @file ArgsWindowController.m
 *
 * @brief Arguments dialog for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "ArgsWindowController.h"
#import "AckContent.h"
#import "ArgManager.h"
#import "Utils.h"

@implementation ArgsWindowController
{
    ArgManager *_argMgr;
}

/**
 * @brief Initializes this object
 *
 */
- (instancetype)init {
    
    self = [super initWithWindowNibName:@"ArgsWindowController"];
    
    return self;
}

/**
 * @brief Initializes the arguments window
 *
 */
- (void)windowDidLoad {
    
    [super windowDidLoad];
    
    if ( !_vcParent || ![Utils isValidModelPair:_arrModelPair] ) {
        return;
    }
    
    // Disable window resize & minimize
    self.window.styleMask &= ~NSWindowStyleMaskResizable;
    self.window.styleMask &= ~NSWindowStyleMaskMiniaturizable;

    // Font
    NSFont *fontNormal = [NSFont fontWithName:gFontNameNormal
                                         size:FONT_SIZE_MEDIUM];

    // Title
    NSString *title = @"Add Arguments";
    NSString *modelName = [_vcParent modelName];
    if ( isValidNSString(modelName) ) {
        title = [NSString stringWithFormat:@"%@ | %@",title,modelName];
    }
    [self.window setTitle:title];
    
    // Arguments
    float temp=0.0f;
    uint32_t ctxLen=0;
    NSString *finalArgs = [_vcParent buildArgumentsForModelPair:_arrModelPair
                                          withUseAdditionalArgs:YES
                                               withUseGaugeArgs:YES
                                                   returnedTemp:&temp
                                                 returnedCtxLen:&ctxLen];
    
    // Arguments Field
    [_textArgs setTextColor:[NSColor colorNamed:@"StatusTextColor"]];
    [_textArgs setBackgroundColor:[NSColor colorNamed:@"TextBackgroundColor"]];
    [_textArgs setPlaceholderString:@"Provide additional llama.cpp arguments..."];
    [_textArgs setFont:fontNormal];
    [_textArgs setSelectable:YES];
    [_textArgs setEditable:YES];
    [_textArgs setTextContainerInset:TEXT_INSETS];
    [_textArgs setDragAccepted:NO];
    [_textArgs setRichText:NO];
    [_textArgs setAutomaticDashSubstitutionEnabled:NO];
    [_textArgs setAutomaticQuoteSubstitutionEnabled:NO];
    [_textArgs setAutomaticTextReplacementEnabled:NO];
    [_textArgs setAutomaticSpellingCorrectionEnabled:NO];
    [_textArgs setString:finalArgs];
}

/**
 * @brief Saves the arguments to the preferences entry for this model and closes the dialog
 *
 */
- (IBAction)btnOk:(id)sender {
    
    if ( !_vcParent ) {
        return;
    }
    
    // Were we overloaded with arguments?
    NSString *currentArgs=[_textArgs string];
    if ( [currentArgs length] > MAX_ARGS_LEN ) {
        
        // Yes, ask user to reduce length
        NSString *title=@"Too Many Arguments";
        NSString *msg=[NSString stringWithFormat:@"You have exceeded the maximum length of allowable arguments.\n\nPlease enter less than %u characters.",MAX_ARGS_LEN];
        [Utils showAlertWithTitle:title
                       andMessage:msg
                         urlTitle:nil
                              url:nil
                          buttons:nil];
        return;
    }

    NSString *modelName = [_vcParent modelName];
    [_vcParent saveAdditionalArguments:currentArgs
                          forModelName:modelName];
    
    // Ask the user to reload the current model with the new
    // arguments
    [_vcParent promptToReloadWithSettingsFromGaugeValues:NO
                                       andAdditionalArgs:YES];

    
    [self close];
}

/**
 * @brief Cancels this dialog
 *
 */
- (IBAction)btnCancel:(id)sender {
    [self close];
}

/**
 * @brief Clears the contents of the arguments field
 *
 */
- (IBAction)btnClear:(id)sender {
    [_textArgs setString:@""];
}

@end
