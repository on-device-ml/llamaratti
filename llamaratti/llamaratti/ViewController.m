/**
 * @file ViewController.m
 *
 * @brief Application View Controller for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 * Demonstrates use of the LlamarattiWrapper.h/mm Objective-C++ wrapper for llama.cpp
 *
 * @attention
 * This example code is subject to change as llama multimodal continues to
 * evolve and is therefore not production ready.
 *
 * References:
 *
 * @see https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md
 * @see https://huggingface.co/collections/ggml-org/multimodal-ggufs-68244e01ff1f39e5bebeeedc
 * @see https://github.com/ggml-org/llama.cpp/discussions/5141
 * @see https://huggingface.co/TheBloke
 * @see https://simonwillison.net/2025/May/10/llama-cpp-vision/
 *
 */

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>

#import "ViewController.h"
#import "ArgsWindowController.h"

#include "lr-mtmd-cli-callback.h"

#include "Errors.h"
#include "Utils.h"
#include "Shared.h"
#include "DTimer.h"

#import "NSImage+More.h"

#import "RippleMetalView.h"
#import "ViewAttachmentCell.h"
#import "ArgManager.h"

#pragma mark - String Constants

// Title
NSString * const gAppName=@"Llamaratti";

// Llama.cpp caches folder suffix
NSString * const gLlamaCacheFolder=@"/Library/Caches/llama.cpp";

// User Defaults
NSString * const gPrefsLastModelPaths=@"lastModelPaths";
NSString * const gPrefsLastModelBookmarks=@"lastModelBookmarks";
NSString * const gPrefsLastPrompts=@"lastPrompts";
NSString * const gPrefsLastArgs=@"lastArgs";

// Fonts
NSString * const gFontNameLight=@"Avenir Next Ultra Light";
NSString * const gFontNameNormal=@"Avenir Next Regular";
NSString * const gFontNameMedium=@"Avenir Next Medium";
NSString * const gFontNameDemiBold=@"Avenir Next Demi Bold";
NSString * const gFontNameBold=@"Avenir Next Bold";
NSString * const gFontNameLogo=@"FerroRosso";
NSString * const gFontNameGauge=@"AvenirNextCondensed-Regular";
NSString * const gFontNameGaugeBold=@"Avenir Next Condensed Demi Bold";
NSString * const gFontFilenameLogo=@"FerroRosso";

// URLs
NSString * const gURLOnDeviceML=@"https://github.com/on-device-ml";
NSString * const gURLLlamaModels=@"https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md";

// Placeholders for Prompt Field
NSString * const gPlaceholderPromptNoModel=@"Select \U000025B2 to load a model";
NSString * const gPlaceholderPromptAsk=@"Right click or ask me anything, then press \U000025B6 or \U00002318+Return";

#pragma mark - Constants

@implementation ViewController {
    
    // Current Apple device
    NSString *_appleDevice;
    
    BOOL _runningInSandbox;
    
    // Current model Information
    NSImage *_modelIcon;
    
    // System Information
    ULONGLONG _sysMemTotal;
    double _sysDskTotal;
    
    // Images
    NSImage *_imgSupportsImages;
    NSImage *_imgSupportsAudio;
    
    NSImage *_imgModel;
    NSImage *_imgArgs;
    NSImage *_imgGPU;
    NSImage *_imgClear;
    NSImage *_imgStop;
    NSImage *_imgGo;
    
    // Fonts
    NSFont *_fontSmallNormal;
    NSFont *_fontSmallBold;
    NSFont *_fontSmallNormalDate;
    NSFont *_fontNormal;
    NSFont *_fontLargeDemiBold;
    NSFont *_fontLogo;

    NSFont *_fontGaugeText;
    NSFont *_fontGaugeTextBold;
    NSFont *_fontGaugeTitle;
    NSFont *_fontGaugeTitleBold;

    NSColor *_disabledColor;
    NSColor *_statusColor;
    NSColor *_statusWarnColor;
    NSColor *_statusDangerColor;
    
    // Attributes
    NSMutableAttributedString *_attrNL;
    
    NSMutableDictionary *_dictAttrDateLeft;
    NSMutableDictionary *_dictAttrDateRight;
    NSMutableDictionary *_dictAttrResponseTitleLeft;
    NSMutableDictionary *_dictAttrResponseTitleRight;
    NSMutableDictionary *_dictAttrResponseText;
    
    BOOL _bFirstResponse;
    BOOL _bVerifyModels;
    BOOL _bSuppressGaugePrompts;
    BOOL _addtlArgsApplied;
    
    NSMutableArray *_arrRippleViews;
    NSTimer *_rippleTimer;
    NSTimer *_gaugesMonitorTimer;
    
    ArgsWindowController *_argsWindow;
}

#pragma mark - ViewController

/**
 * @brief Initializes properties of the view controller
 */
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Enable this to clear prefs
    //[self resetPrefs];
    
    // Initialize class properties
    [self initProperties];
    
    // Intialize Controls
    [self initControls];
    
    // Initialialize Gauges
    [self initGaugeControls];
    
    // Start monitor to update gauges
    [self startMonitorForGauges];
}

/**
 * @brief Initializes class properties
 */
- (void)initProperties {
    
    _appleDevice=[LlamarattiWrapper appleSiliconModel:DISPLAY_DETAILED_DEVICE];
    [Utils getTotalSystemMemory:&_sysMemTotal];
    [Utils getTotalDiskSpace:&_sysDskTotal];
    _runningInSandbox = [Utils runningInSandbox];
    
    _modelName=@"";
    _bVerifyModels=VERIFY_MODEL_HASHES;
    _bSuppressGaugePrompts=NO;
    _addtlArgsApplied=NO;
    
    // Rippled Images
    _arrRippleViews=[NSMutableArray array];
    _rippleTimer=nil;
    
    // Create an icon for model responses
    NSSize scaledSize=CGSizeMake(RESPONSE_IMAGE_ICON_SIZE,RESPONSE_IMAGE_ICON_SIZE);
    _modelIcon = [[NSImage imageNamed:@"AppIcon"] scaledProportionallyToSize:scaledSize];
    
    _attrNL=[[NSMutableAttributedString alloc] initWithString:@"\n"];
    
    // Fonts
    _fontSmallNormal=[NSFont fontWithName:gFontNameNormal size:FONT_SIZE_SMALL];
    _fontSmallBold=[NSFont fontWithName:gFontNameBold size:FONT_SIZE_SMALL];
    _fontSmallNormalDate=[NSFont fontWithName:gFontNameNormal size:FONT_SIZE_SMALL];
    _fontNormal=[NSFont fontWithName:gFontNameNormal size:FONT_SIZE_MEDIUM];
    _fontLargeDemiBold=[NSFont fontWithName:gFontNameDemiBold size:FONT_SIZE_LARGE];
    _fontLogo=[NSFont fontWithName:gFontNameNormal size:FONT_SIZE_MEDIUM];
    
    _fontGaugeText=[NSFont fontWithName:gFontNameGauge size:FONT_SIZE_GAUGE_TEXT];
    _fontGaugeTextBold=[NSFont fontWithName:gFontNameGaugeBold size:FONT_SIZE_GAUGE_TEXT];
    _fontGaugeTitle=[NSFont fontWithName:gFontNameGauge size:FONT_SIZE_GAUGE_TITLE];
    _fontGaugeTitleBold=[NSFont fontWithName:gFontNameGaugeBold size:FONT_SIZE_GAUGE_TITLE];
    
    // Colors
    _disabledColor=[NSColor disabledControlTextColor];
    _statusColor=[NSColor colorNamed:@"StatusTextColor"];
    _statusWarnColor=[NSColor colorNamed:@"StatusTextWarnColor"];
    _statusDangerColor=[NSColor colorNamed:@"StatusTextDangerColor"];
    
    // Can we register & load our custom font?
    NSString *fontPath = [[NSBundle mainBundle] pathForResource:gFontFilenameLogo
                                                         ofType:@"ttf"];
    NSURL *fontURL = [NSURL fileURLWithPath:fontPath];
    CFErrorRef cfError=NULL;
    if ( !CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontURL,
                                           kCTFontManagerScopeProcess,
                                           &cfError) ) {
        if ( cfError ) {
            
            NSError *e=(__bridge NSError *)cfError;
            NSLog(gErrLrtFontRegFailed,
                  __func__,
                  gFontFilenameLogo,
                  safeDesc(e),
                  safeCode(e));
            
            [self appendStatus:gErrLrtFontRegFailed,
             __func__,
             gFontFilenameLogo,
             safeDesc(e),
             safeCode(e)];
            
            CFRelease(cfError);
        }
    } else {
        _fontLogo=[NSFont fontWithName:gFontNameLogo size:FONT_SIZE_HUGE];
    }
    
    NSMutableParagraphStyle *paraAlignRight=[[NSMutableParagraphStyle alloc] init];
    [paraAlignRight setAlignment:NSTextAlignmentRight];
    
    // Response Date
    _dictAttrDateLeft=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       _fontSmallNormalDate, NSFontAttributeName,
                       [NSColor grayColor], NSForegroundColorAttributeName,
                       nil];
    
    _dictAttrDateRight=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                        _fontSmallNormalDate, NSFontAttributeName,
                        paraAlignRight, NSParagraphStyleAttributeName,
                        [NSColor grayColor], NSForegroundColorAttributeName,
                        nil];
    
    // Response Titles
    _dictAttrResponseTitleLeft=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                _fontLargeDemiBold, NSFontAttributeName,
                                [NSColor colorNamed:@"ResponseTextColor"], NSForegroundColorAttributeName,
                                nil];
    
    _dictAttrResponseTitleRight=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 _fontLargeDemiBold, NSFontAttributeName,
                                 paraAlignRight, NSParagraphStyleAttributeName,
                                 [NSColor colorNamed:@"ResponseTextColor"], NSForegroundColorAttributeName,
                                 nil];
    
    // Response Text
    _dictAttrResponseText=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                           _fontNormal, NSFontAttributeName,
                           [NSColor colorNamed:@"ResponseTextColor"], NSForegroundColorAttributeName,
                           nil];
}

/**
 * @brief Initializes user interface controls
 */
- (void)initControls {
    
    // Colors for below
    NSColor *textBackgroudColor=[NSColor colorNamed:@"TextBackgroundColor"];

    // --------------------------------------------------------------------------------
    // Text View - Response
    // --------------------------------------------------------------------------------
    [_scrollResponse setWantsLayer:YES];
    [_scrollResponse setBorderType:NSNoBorder];
    [[_scrollResponse layer] setBorderWidth:BORDER_WIDTH];
    [[_scrollResponse layer] setCornerRadius:BORDER_RADIUS];
    [[_scrollResponse layer] setBorderColor:[[NSColor darkGrayColor] CGColor]];
    
    [_textResponse setTextColor:[NSColor colorNamed:@"ResponseTextColor"]];
    [_textResponse setBackgroundColor:textBackgroudColor];
    [_textResponse setFont:_fontNormal];
    [_textResponse setSelectable:YES];
    [_textResponse setEditable:NO];
    [_textResponse setTextContainerInset:TEXT_INSETS];
    [_textResponse setVcParent:self];
    [_textResponse setDragAccepted:NO];
    
    // Icon - Drag/Drop
    [_imgViewDragDrop setImageScaling:NSImageScaleProportionallyUpOrDown];
    [_imgViewDragDrop setImage:[NSImage imageWithSystemSymbolName:@"photo.fill.on.rectangle.fill"
                                         accessibilityDescription:nil]];
    [_imgViewDragDrop unregisterDraggedTypes];
    [_imgViewDragDrop setHidden:YES];
    
    // Text - Drag/Drop
    [_textDragDrop setAlignment:NSTextAlignmentCenter];
    [_textDragDrop setStringValue:@"Drop Media Here"];
    [_textDragDrop setFont:_fontSmallNormal];
    [_textDragDrop setTextColor:[NSColor colorNamed:@"ResponseTextColor"]];
    [_textDragDrop setSelectable:NO];
    [_textDragDrop setEditable:NO];
    [_textDragDrop setHidden:YES];
    
    // --------------------------------------------------------------------------------
    // Text View - Prompt
    // --------------------------------------------------------------------------------
    // Curved borders
    [_scrollPrompt setWantsLayer:YES];
    [_scrollPrompt setBorderType:NSNoBorder];
    [[_scrollPrompt layer] setBorderWidth:BORDER_WIDTH];
    [[_scrollPrompt layer] setCornerRadius:BORDER_RADIUS];
    [[_scrollPrompt layer] setBorderColor:[[NSColor darkGrayColor] CGColor]];
    
    [_textPrompt setTextColor:[NSColor colorNamed:@"PromptTextColor"]];
    [_textPrompt setBackgroundColor:textBackgroudColor];
    [_textPrompt setFont:_fontNormal];
    [_textPrompt setSelectable:YES];
    [_textPrompt setEditable:YES];
    [_textPrompt setTextContainerInset:TEXT_INSETS];
    [_textPrompt setVcParent:self];
    [_textPrompt setDragAccepted:NO];
    [_textPrompt setCmdReturnAccepted:YES];
    [self setPromptPlaceholder:gPlaceholderPromptNoModel];
    
    // Right click menu for Response window
    NSClickGestureRecognizer *rightClickRecognizerForResponse =
    [[NSClickGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(handleRightClickOnResponse:)];
    [rightClickRecognizerForResponse setButtonMask:0x2];
    [rightClickRecognizerForResponse setNumberOfClicksRequired:1];
    [_textResponse addGestureRecognizer:rightClickRecognizerForResponse];

    // Right click menu for Prompt window
    NSClickGestureRecognizer *rightClickRecognizerForPrompt =
    [[NSClickGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(handleRightClickOnPrompt:)];
    [rightClickRecognizerForPrompt setButtonMask:0x2];
    [rightClickRecognizerForPrompt setNumberOfClicksRequired:1];
    [_textPrompt addGestureRecognizer:rightClickRecognizerForPrompt];
    
    // --------------------------------------------------------------------------------
    // Text View - Status
    // --------------------------------------------------------------------------------
    [_textStatus setTextColor:_statusColor];
    [_textStatus setBackgroundColor:textBackgroudColor];
    [_textStatus setFont:_fontSmallNormal];
    [_textStatus setAlignment:NSTextAlignmentRight];
    [_textStatus setSelectable:NO];
    [_textStatus setEditable:NO];
    
    // --------------------------------------------------------------------------------
    // Image View - Logo
    // --------------------------------------------------------------------------------
    [_textLogo setStringValue:gAppName];
    [_textLogo setAlignment:NSTextAlignmentLeft];
    [_textLogo setFont:_fontLogo];
    [_textLogo setTextColor:[NSColor colorNamed:@"LogoTextColor"]];
    NSClickGestureRecognizer *gesture = [[NSClickGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(textLogoClicked:)];
    [_textLogo addGestureRecognizer:gesture];
    
    // Images
    _imgSupportsImages=[NSImage imageWithSystemSymbolName:@"photo"
                                 accessibilityDescription:nil];
    
    _imgSupportsAudio=[NSImage imageWithSystemSymbolName:@"waveform"
                                accessibilityDescription:nil];
    
    _imgModel=[NSImage imageWithSystemSymbolName:@"arrowtriangle.up.fill"
                        accessibilityDescription:nil];
    
    _imgArgs=[NSImage imageWithSystemSymbolName:@"gearshape.fill"
                       accessibilityDescription:nil];
    
    _imgGPU=[NSImage imageWithSystemSymbolName:@"chart.bar.fill"
                      accessibilityDescription:nil];
    
    _imgClear=[NSImage imageWithSystemSymbolName:@"doc"
                        accessibilityDescription:nil];
    
    _imgStop=[NSImage imageWithSystemSymbolName:@"stop.fill"
                       accessibilityDescription:nil];
    
    _imgGo=[NSImage imageWithSystemSymbolName:@"play.fill"
                     accessibilityDescription:nil];
    
    // Buttons - Tooltips
    [_btnModel setToolTip:@"Load model/projection"];
    [_btnGPU setToolTip:@"Show system stats"];
    [_btnClear setToolTip:@"Reload with defaults"];
    [_btnStop setToolTip:@"Stop generating"];
    [_btnGo setToolTip:@"Start generating"];
    
    // Disable all capabilities initially
    [self toggleMultimodalSupportWithImages:NO
                                   andAudio:NO];
    
    // Disable controls initially
    [self toggleControls:NO
         withStopEnabled:NO
         withArgsEnabled:NO
       withSelectEnabled:YES
       withGaugesEnabled:NO];
    
    // Update window title
    [self updateWindowTitle:@"No Model Loaded"];
    
    // Add observer for appearance changes
    [self.view addObserver:self
                forKeyPath:@"effectiveAppearance"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
}

/**
 * @brief Loads the last used model following initialization
 */
- (void)viewDidAppear {
    
    [super viewDidAppear];
    
    // Load our last used model
    [self loadLastModelPairWithDefaults];
}

- (void)viewWillDisappear {
    
    [super viewWillDisappear];
    
    // Stop gauge monitoring
    [self stopMonitorForGauges];
     
     // Remove the appearance change observer
     [self.view removeObserver:self forKeyPath:@"effectiveAppearance"];
     
     // Cleanup drag/drop temp files
     [self->_textResponse reset];
}

/**
 * @brief Observes appearance changes and updates controls accordingly
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"effectiveAppearance"]) {
        NSAppearance *newAppearance = change[NSKeyValueChangeNewKey];
        
        NSColor *colorBtn=nil;
        if ([newAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua, NSAppearanceNameVibrantDark, NSAppearanceNameAccessibilityHighContrastDarkAqua, NSAppearanceNameAccessibilityHighContrastVibrantDark]] != nil) {
            colorBtn=[NSColor colorNamed:@"ButtonTintColorDark"];
        } else {
            colorBtn=[NSColor colorNamed:@"ButtonTintColorLight"];
        }
        
        // Update image tinting
        NSImage *imgBtn=[_imgSupportsImages imageTintedWithColor:colorBtn];
        [imgBtn setTemplate:YES];
        [_imgViewImages setImage:imgBtn];
        
        imgBtn=[_imgSupportsAudio imageTintedWithColor:colorBtn];
        [imgBtn setTemplate:YES];
        [_imgViewAudio setImage:imgBtn];
        
        imgBtn=[_imgModel imageTintedWithColor:colorBtn];
        [_btnModel setImage:imgBtn];
        
        imgBtn=[_imgArgs imageTintedWithColor:colorBtn];
        [_btnArgs setImage:imgBtn];
        
        imgBtn=[_imgGPU imageTintedWithColor:colorBtn];
        [_btnGPU setImage:imgBtn];
        
        imgBtn=[_imgClear imageTintedWithColor:colorBtn];
        [_btnClear setImage:imgBtn];
        
        imgBtn=[_imgStop imageTintedWithColor:colorBtn];
        [_btnStop setImage:imgBtn];
        
        imgBtn=[_imgGo imageTintedWithColor:colorBtn];
        [_btnGo setImage:imgBtn];
    }
}

#pragma mark - Model

/**
 * @brief Loads the specified model pair
 *
 * @param arrModelPair - an array containing the model & mmproj URLs to load
 *
 * @return The status of the operation
 */
- (BOOL)loadModelPair:(NSArray *)arrModelPair
    useAdditionalArgs:(BOOL)useAdditionalArgs
         useGaugeArgs:(BOOL)useGaugeArgs {
    
    // Did we get the parameters we need?
    if ( ![Utils isValidModelPair:arrModelPair] ) {
        return NO;
    }
    
    // Disable Controls
    [self toggleControls:NO
         withStopEnabled:NO
         withArgsEnabled:NO
       withSelectEnabled:NO
       withGaugesEnabled:NO];
    
    // Hide the drag/drop icon
    [self toggleDragDropIcon:NO];
    
    [self toggleMultimodalSupportWithImages:NO
                                   andAudio:NO];
    
    [self toggleAnimation:YES];
    
    [self setPromptPlaceholder:gPlaceholderPromptNoModel];
    
    // Execute in background
    NSOperationQueue *obq=[[NSOperationQueue alloc] init];
    [obq addOperationWithBlock:^{
        
        NSURL *urlModel=arrModelPair[0];
        NSURL *urlMMProj=arrModelPair[1];
        
        // Save the title of this model
        self->_modelName=[LlamarattiWrapper titleForModelURL:urlModel];
        
        // Update status
        [self appendStatus:@"Loading model %@...",self->_modelName];
        
        // Start Timer
        DTimer *dt=[DTimer timerWithFunc:safeNSSFromChar(__func__)
                                 andDesc:nil];
        
        // Build Arguments String
        float temp=LLAMA_DEFAULT_TEMP;
        uint32_t ctxLen=LLAMA_DEFAULT_CTXLEN;
        NSString *finalArgs = [self buildArgumentsForModelPair:arrModelPair
                                         withUseAdditionalArgs:useAdditionalArgs
                                              withUseGaugeArgs:useGaugeArgs
                                                  returnedTemp:&temp
                                                returnedCtxLen:&ctxLen];

        // Can we create the llama wrapper?
        self->_llamaWrapper=[LlamarattiWrapper wrapperWithModelURL:urlModel
                                                      andMMProjURL:urlMMProj
                                                 andAdditionalArgs:finalArgs
                                                      verifyModels:self->_bVerifyModels
                                                            target:self
                                                          selector:@selector(llamaEventsSelector:)];
        [self toggleAnimation:NO];
        
        if ( !self->_llamaWrapper ) {
            
            // Disable Controls
            [self toggleControls:NO
                 withStopEnabled:NO
                 withArgsEnabled:YES
               withSelectEnabled:YES
               withGaugesEnabled:YES];
            
            // Update status
            NSString *modelTitle=[LlamarattiWrapper titleForModelURL:urlModel];
            [self appendStatus:gErrLrtCantLoadModel,modelTitle];
            
            return;
        }
        
        // Record the time taken
        NSTimeInterval interval=[dt ticks];
        
        // Clear our RippleViews
        [self->_arrRippleViews removeAllObjects];
        
        // Save them in prefs as last used
        [self saveLastUsedModelPair:arrModelPair];
        
        // Update the gauges
        [self updateGaugesWithTemp:(CGFloat)temp
                         andCtxLen:(NSUInteger)ctxLen];
        
        // Enable controls
        [self toggleControls:YES
             withStopEnabled:NO
             withArgsEnabled:YES
           withSelectEnabled:YES
           withGaugesEnabled:YES];
        
        // Apply additional arguments?
        [self updateArgsBtnState];
        
        // Clear fields
        [self clearTextFields:NO
                clearResponse:YES
                  clearStatus:YES];
        
        // Update window title
        [self updateWindowTitle:self->_modelName];
        
        // Update status
        [self appendStatus:@"Loaded model '%@' in %.3fs",self->_modelName,interval];
        
        // Update our Prompt placeholder
        [self setPromptPlaceholder:gPlaceholderPromptAsk];
        
        // Update our multimedia support
        [self toggleMultimodalSupportWithImages:[self->_llamaWrapper visionSupported]
                                       andAudio:[self->_llamaWrapper audioSupported]];
    }];
    return YES;
}

/**
 * @brief Builds a command line argument string for llama.cpp based on various sources
 *
 */
- (NSString *)buildArgumentsForModelPair:(NSArray *)arrModelPair
                   withUseAdditionalArgs:(BOOL)useAdditionalArgs
                        withUseGaugeArgs:(BOOL)useGaugeArgs
                            returnedTemp:(float *)temp
                          returnedCtxLen:(uint32_t *)ctxLen {
    
    // Did we get the parameters we need?
    if ( ![Utils isValidModelPair:arrModelPair] || !temp || !ctxLen ) {
        return nil;
    }
    
    float finalTemp=*temp;
    uint32_t finalCtxLen=*ctxLen;
    
    // Do we have default arguments for this model?
    ArgManager *am = [[ArgManager alloc] init];
    ModelInfo *mi=[LlamarattiWrapper modelInfoForFileURL:[arrModelPair firstObject]];
    if ( mi ) {
        finalTemp = [mi temp];
        finalCtxLen = [mi ctxLen];
        if ( isValidNSString([mi additionalArgs]) ) {
            [am addArgumentsFromString:[mi additionalArgs]];
        }
    }
    
    // Were we asked to apply any additional arguments?
    self->_addtlArgsApplied=NO;
    if ( useAdditionalArgs ) {
        
        // Yes, do we actually have any?
        NSString *additionalArgs = [self getAdditionalArgumentsForModelName:_modelName];
        if ( isValidNSString(additionalArgs) ) {
            
            [am addArgumentsFromString:additionalArgs];
            if ( [am hasOption:gArgTemp] ) {
                finalTemp = [[am getOption:gArgTemp] floatValue];
            }
            if ( [am hasOption:gArgCtxSize] ) {
                finalCtxLen = [[am getOption:gArgCtxSize] intValue];
            }
            self->_addtlArgsApplied=YES;
        }
    }
    
    // Were we asked to apply the current gauge values?
    if ( useGaugeArgs ) {
        finalTemp = [self->_sliderLLMTemp value];
        finalCtxLen = [self->_sliderCtxLen value];
    }
    
    // Add arguments
    [am setOption:[NSString stringWithFormat:@"%0.1f",finalTemp]
           forKey:gArgTemp];
    [am setOption:[NSString stringWithFormat:@"%u",finalCtxLen]
           forKey:gArgCtxSize];
    
    // Return values
    *temp=finalTemp;
    *ctxLen=finalCtxLen;
    NSString *finalArgs = [am toString];
    
    return finalArgs;
}

/**
 * @brief Loads the last used model pair with default params
 *
 * @return The status of the operation
 */
- (BOOL)loadLastModelPairWithDefaults {
    
    // Do we have a previously saved model pair?
    NSArray *arrModelPair=[self getLastUsedModelPair];
    if ( ![Utils isValidModelPair:arrModelPair] ) {
        return NO;
    }
    
    return [self loadModelPair:arrModelPair
             useAdditionalArgs:NO
                  useGaugeArgs:NO];
}

/**
 * @brief Asks the user if they want to reload the current model with settings
 * from the gauges and any additional arguments
 *
 */
- (BOOL)promptToReloadWithSettingsFromGaugeValues:(BOOL)useGaugeArgs
                                andAdditionalArgs:(BOOL)useAdditionalArgs {
    
    // Yes, confirm apply changes?
    if ( ![Utils showAlertWithTitle:@"Apply New Settings?"
                         andMessage:@"This will reload the current model with the new settings"
                           urlTitle:nil
                                url:nil
                            buttons:@[@"Yes",@"No"]] ) {
        // No, outta here...
        return NO;
    }
    
    // Do we have a previously saved model pair?
    NSArray *arrModelPair=[self getLastUsedModelPair];
    if ( ![Utils isValidModelPair:arrModelPair] ) {
        return NO;
    }
    
    return [self loadModelPair:arrModelPair
             useAdditionalArgs:useAdditionalArgs
                  useGaugeArgs:useGaugeArgs];
}

#pragma mark - User Interface - Fields

/**
 * @brief Updates the window title with the model name & hardware type
 *
 * @param modelName - the currently loaded model
 *
 */
- (void)updateWindowTitle:(NSString *)modelName {
    
    // Did we get the paramters we need?
    if ( !isValidNSString(modelName) ) {
        return;
    }
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        NSString *windowTitle=@"";
        if ( isValidNSString(self->_appleDevice) ) {
            windowTitle=[NSString stringWithFormat:@"%@ | %@ | %@",
                         modelName,
                         self->_appleDevice,
                         gAppName];
        } else {
            windowTitle=[NSString stringWithFormat:@"%@ | %@",
                         modelName,
                         gAppName];
        }
        
        [self.view.window setTitle:windowTitle];
    }];
}

/**
 * @brief Selectively clear UI text fields
 *
 * @param clearPrompt - clear the prompt field?
 * @param clearResponse - clear the response field?
 * @param clearStatus - clear the status field?
 *
 */
- (void)clearTextFields:(BOOL)clearPrompt
          clearResponse:(BOOL)clearResponse
            clearStatus:(BOOL)clearStatus {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        if ( clearPrompt ) {
            [self->_textPrompt setString:@""];
        }
        if ( clearResponse ) {
            [self->_textResponse reset];
        }
        if ( clearStatus ) {
            [self->_textStatus setStringValue:@""];
        }
    }];
}

/**
 * @brief Selectively enable/disable UI controls
 *
 * @param enabled - enable/disable all other controls?
 * @param stopEnabled - enable/disable the Stop button?
 * @param argsEnabled - enable/disable the Args button?
 * @param selectEnabled - enable/disable the Select Model button?
 * @param gaugesEnabled - enable/disable the Guages?
 *
 */
- (IBAction)toggleControls:(BOOL)enabled
           withStopEnabled:(BOOL)stopEnabled
           withArgsEnabled:(BOOL)argsEnabled
         withSelectEnabled:(BOOL)selectEnabled
         withGaugesEnabled:(BOOL)gaugesEnabled {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        // Gauge - LLM TEMP
        [self setGaugeColorForLLMTemp:[self->_sliderLLMTemp value]
                              enabled:gaugesEnabled];
        [self->_sliderLLMTemp setEnabled:gaugesEnabled];
        [self->_textLLMTempTitle setEnabled:gaugesEnabled];
        [self->_textLLMTemp setEnabled:gaugesEnabled];

        // Gauge - CTX LEN
        [self setGaugeColorForLLMCtxLen:[self->_sliderCtxLen value]
                                enabled:gaugesEnabled];
        [self->_sliderCtxLen setEnabled:gaugesEnabled];
        [self->_textCtxLenTitle setEnabled:gaugesEnabled];
        [self->_textCtxLen setEnabled:gaugesEnabled];

        // Fields
        [self->_textPrompt setEditable:enabled];
        [self->_textResponse setDragAccepted:enabled];
        
        // Buttons
        [self->_btnModel setEnabled:selectEnabled];
        [self->_btnArgs setEnabled:argsEnabled];
        [self->_btnClear setEnabled:enabled];
        [self->_btnStop setEnabled:stopEnabled];
        [self->_btnGo setEnabled:enabled];
    }];
}

/**
 * @brief Selectively toggle supported multimedia indicators
 *
 * Indicators on the UI are used to indicate the types of media that
 * the currently loaded model pair supports
 *
 * @param imagesSupported - whether the current model supports images
 * @param audioSupported - whether the current model supports audio
 *
 */
- (IBAction)toggleMultimodalSupportWithImages:(BOOL)imagesSupported
                                     andAudio:(BOOL)audioSupported {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        // Update status indicators
        NSColor *colorSupport=[NSColor colorNamed:@"MediaSupportedColor"];
        NSColor *colorNoSupport=[NSColor colorNamed:@"MediaNotSupportedColor"];
        
        [self->_imgViewImages setContentTintColor:imagesSupported?colorSupport:colorNoSupport];
        NSString *strTip=[NSString stringWithFormat:@"Images %@Supported",imagesSupported?@"":@"Not "];
        [self->_imgViewImages setToolTip:strTip];
        
        [self->_imgViewAudio setContentTintColor:audioSupported?colorSupport:colorNoSupport];
        strTip=[NSString stringWithFormat:@"Audio %@Supported",audioSupported?@"":@"Not "];
        [self->_imgViewAudio setToolTip:strTip];

        [self toggleDragDropIcon:imagesSupported|audioSupported];
    }];
}

/**
 * @brief Selectively toggle the inference activity indicator
 *
 * @param bOn - toggle activity
 *
 */
- (void)toggleAnimation:(BOOL)bOn {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        if ( bOn ) {
            [self->_activity startAnimation:self];
        } else {
            [self->_activity stopAnimation:self];
        }
    }];
}

#pragma mark - User Interface - Buttons

/**
 * @brief Copies the text in the response window to the pasteboard
 *
 * @param sender - unused
 *
 */
- (IBAction)btnCopyResponse:(id)sender {
    
    NSString *text=[_textResponse string];
    [Utils copyToPasteboard:text];
}

/**
 * @brief Displays the model load options menu
 *
 * @param sender - unused
 *
 */
- (IBAction)btnModel:(id)sender {
    
    [self showModelLoadOptionsMenu];
}

/**
 * @brief Displays the model load options menu
 *
 * @param sender - unused
 *
 */
- (IBAction)btnArgs:(id)sender {
    
    // Do we have a previously saved model pair?
    NSArray *arrModelPair=[self getLastUsedModelPair];
    if ( ![Utils isValidModelPair:arrModelPair] ) {
        return;
    }

    _argsWindow = [[ArgsWindowController alloc] init];
    [_argsWindow setVcParent:self];
    [_argsWindow setArrModelPair:arrModelPair];
    [_argsWindow showWindow:self];
}

/**
 * @brief Adds text to the prompt field & starts text generation
 *
 * @param sender - unused
 *
 */
- (IBAction)btnAddPrompt:(id)sender {
    
    // Did we get a valid prompt?
    NSString *prompt=[sender representedObject];
    if ( !isValidNSString(prompt) ) {
        return;
    }
    
    [self setPrompt:prompt];
}

/**
 * @brief Clears all previously used prompts from NSUserDefaults
 *
 * @param sender - unused
 *
 */
- (IBAction)btnClearLastUsedPrompts:(id)sender {
    
    // Do they want to proceed?
    if ( ![Utils showAlertWithTitle:@"Clear Recently Used Prompts?"
                         andMessage:nil
                           urlTitle:nil
                                url:nil
                            buttons:@[@"Yes",@"No"]] ) {
        // No, outta here...
        return;
    }
    
    if ( [self clearRecentlyUsedPrompts] ) {
        [self appendStatus:@"Recent Prompts Cleared"];
    }
}

/**
 * @brief Clears all previously used model pairs from NSUserDefaults
 *
 * @param sender - unused
 *
 */
- (IBAction)btnClearPreviousUsedModelPairs:(id)sender {
    
    // Do they want to proceed?
    if ( ![Utils showAlertWithTitle:@"Clear Recently Loaded Models?"
                         andMessage:nil
                           urlTitle:nil
                                url:nil
                            buttons:@[@"Yes",@"No"]] ) {
        // No, outta here...
        return;
    }
    
    if ( [self clearRecentlyUsedModelPairs] ) {
        [self appendStatus:@"Recent Models Cleared"];
    }
}

/**
 * @brief Loads a specified model pair
 *
 * Called by the model selection menu to load a specified model pair
 *
 * @param sender - representedObject contains the model pair to load
 *
 */
- (IBAction)btnLoadSelectedModelPair:(id)sender {
    
    // Did we get a valid model pair?
    NSArray *arrModelPair=[sender representedObject];
    if ( [Utils isValidModelPair:arrModelPair] ) {
        
        // Can we load the model pair?
        if ( ![self loadModelPair:arrModelPair
                useAdditionalArgs:NO
                     useGaugeArgs:NO] ) {
            
            return;
        }
    }
}

/**
 * @brief Opens a folder selection dialog to the specified folder
 *
 * Called by the model selection menu to display a folder selection
 * dialog
 *
 * @param sender - representedObject an NSMenuItem. Title contains
 * the folder path
 *
 */
- (IBAction)btnFolder:(id)sender {
    
    NSMenuItem *menuItem=(NSMenuItem *)sender;
    if ( !menuItem ) {
        return;
    }
    NSURL *urlFolder=[NSURL fileURLWithPath:[menuItem title]];
    [self selectModelFiles:urlFolder];
}

/**
 * @brief Opens a folder selection dialog to the ~/Downloads folder
 *
 * Called by the model selection menu to display a folder selection
 * dialog
 *
 * @param sender - unused
 *
 */
- (IBAction)btnFolderOther:(id)sender {
    
    // Can we get the Downloads folder?
    NSURL *urlDownloads=nil;
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory,
                                                       NSUserDomainMask,
                                                       YES);
    if ( isValidNSArray(paths) ) {
        urlDownloads=[NSURL fileURLWithPath:[paths firstObject]];
    }
    [self selectModelFiles:urlDownloads];
}

/**
 * @brief Opens a URL to the model/mmproj downloads URL
 *
 * @param sender - unused
 *
 */
- (IBAction)btnDownload:(id)sender {
    [Utils openURL:[NSURL URLWithString:gURLLlamaModels]];
}

/**
 * @brief Launches the macOS Activity Monitor application
 *
 * Press CMD-4 to display GPU utilization
 *
 * @param sender - unused
 *
 */
- (IBAction)btnGPU:(id)sender {
    
    // Launch Activity Monitor
    [Utils launchActivityMonitor];
}

/**
 * @brief Clears the current chat history & reloads the model
 *
 * @param sender - unused
 *
 */
- (IBAction)btnClear:(id)sender {
    
    // Do we have an initialized wrapper?
    if ( !self->_llamaWrapper ) {
        return;
    }
    
    // Do they want to proceed?
    if ( ![Utils showAlertWithTitle:@"Reload with Defaults?"
                         andMessage:@"This will re-load the current model with default settings"
                           urlTitle:nil
                                url:nil
                            buttons:@[@"Yes",@"Cancel"]] ) {
        // No, outta here...
        return;
    }
    
    // Clear fields
    [self clearTextFields:YES
            clearResponse:YES
              clearStatus:YES];
    
    // Execute in background
    NSOperationQueue *obq=[[NSOperationQueue alloc] init];
    [obq addOperationWithBlock:^{
        
        // Clear our context
        [self clearContext];
    }];
}

/**
 * @brief Stops current text generation
 *
 * @param sender - unused
 *
 */
- (IBAction)btnStop:(id)sender {
    
    // Do we have an initialized wrapper?
    if ( !self->_llamaWrapper ) {
        return;
    }
    
    // Stop
    [_llamaWrapper stop];
}

/**
 * @brief Processes the prompt as needed
 *
 * @param prompt - the input prompt to process
 *
 */
- (NSString *)processPrompt:(NSString *)prompt {
    
    // Do we have more than just whitespace?
    NSMutableCharacterSet *wsChars=[NSMutableCharacterSet whitespaceCharacterSet];
    [wsChars formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
    prompt=[Utils stripWhitespace:prompt];
    if ( !isValidNSString(prompt) ) {
        return nil;
    }
    
    // Were we asked to clear the context?
    NSArray *arrSamplePrompts=[LlamarattiWrapper clearContextPrompts];
    if ( [arrSamplePrompts containsObject:[prompt lowercaseString]] ) {
        
        [self clearContext];
        return nil;
    }
    
    // Is the input too long?
    if ([prompt length] > MAX_PROMPT_LENGTH) {
        
        // Yes, message & outta here...
        NSString *title=@"Smaller Prompt Please 🫠";
        NSString *msg=[NSString stringWithFormat:@"\nPlease enter a question that is less than %u characters 👍",MAX_PROMPT_LENGTH];
        [Utils showAlertWithTitle:title
                       andMessage:msg
                         urlTitle:nil
                              url:nil
                          buttons:nil];
        return nil;
    }
    
    return prompt;
}

/**
 * @brief Starts text generation using the contents of the prompt field
 *
 * @param sender - unused
 *
 */
- (IBAction)btnGo:(id)sender {
    
    // Do we have an initialized wrapper?
    if ( !self->_llamaWrapper ) {
        return;
    }
    
    // Can we process the prompt?
    NSString *prompt=[self processPrompt:[_textPrompt string]];
    if ( !isValidNSString(prompt) ) {
        return;
    }
    
    // Append the prompt to the context window
    NSString *final=[prompt stringByAppendingFormat:@"\n"];;
    [self appendUserPromptToResponse:final];
    
#if REMEMBER_USER_PROMPTS
    
    // Save the prompt in prefs
    [self saveLastUsedPrompt:prompt];
    
#endif // REMEMBER_USER_PROMPTS
    
    // Disable controls
    [self toggleControls:NO
         withStopEnabled:YES
         withArgsEnabled:NO
       withSelectEnabled:NO
       withGaugesEnabled:NO];
    
    // Clear fields
    [self clearTextFields:YES
            clearResponse:NO
              clearStatus:YES];
    
    [self toggleAnimation:YES];
    
    // Execute in background
    NSOperationQueue *obq=[[NSOperationQueue alloc] init];
    [obq addOperationWithBlock:^{
        
        self->_bFirstResponse=YES;
        
#if RIPPLE_IMAGES_DURING_INFERENCE
        // Start rippling the current images
        [self toggleImageRipple:YES];
#endif
        
        // Start Timer
        DTimer *dt=[DTimer timerWithFunc:safeNSSFromChar(__func__)
                                 andDesc:nil];
        
        // Can we execute the prompt?
        NSString *strStatus=@"";
        BOOL bSuccess=[self->_llamaWrapper generate:prompt];
        NSTimeInterval interval=[dt ticks];
        
        [self toggleAnimation:NO];
        
        if ( bSuccess ) {
            
            // Yes, ...
            strStatus=[NSString stringWithFormat:@"Generation Completed in %.3fs",
                       interval];
        } else {
            
            // No, clear our chat history
            [self->_llamaWrapper clearHistory];
            
            strStatus=[NSString stringWithFormat:@"Generation Aborted after %.3fs. Chat context cleared.",
                       interval];
            
            // Remove the currently loaded model from preferences
            //
            // This prevents us from trying to auto-load a model pair on startup
            // that the system can't handle (no soup for you!)
            //
            NSArray *arrModelPair=[self->_llamaWrapper modelPair];
            [self clearRecentlyUsedModelPair:arrModelPair];
        }
        
#if RIPPLE_IMAGES_DURING_INFERENCE
        // Stop rippling the current images
        [self toggleImageRipple:NO];
#endif
        
        [self appendModelTextToResponse:@"\n"
                              firstCall:NO];
        
        [self toggleControls:YES
             withStopEnabled:NO
             withArgsEnabled:YES
           withSelectEnabled:YES
           withGaugesEnabled:YES];
        
        [self appendStatus:strStatus];
    }];
}

/**
 * @brief Updates the color of the Args button based on available arguments
 *
 */
- (void)updateArgsBtnState {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        NSImage *imgBtn=nil;
        if ( self->_addtlArgsApplied ) {
            imgBtn=[self->_imgArgs imageTintedWithColor:self->_statusWarnColor];
            [self->_btnArgs setToolTip:@"Additional Argmuments Applied"];
            
        } else {
            imgBtn=[self->_imgArgs imageTintedWithColor:self->_statusColor];
            [self->_btnArgs setToolTip:@"Add Arguments"];
         }
        [self->_btnArgs setImage:imgBtn];

    }];
}

/**
 * @brief Launches to the web site when the text field is clicked
 *
 * @param gesture - unused
 *
 */
- (void)textLogoClicked:(NSClickGestureRecognizer *)gesture {
    
    [Utils openURL:[NSURL URLWithString:gURLOnDeviceML]];
}

#pragma mark - User Interface - Misc

/**
 * @brief Displays a menu to load previous and new models
 *
 * Allows the user to select from previously used models as well as selecting
 * new model pairs from the llama.cpp cache folder and their ~/Downloads folder
 */
- (void)showModelLoadOptionsMenu {
    
    NSInteger index=0;
    NSMenu *ctxMenu=[[NSMenu alloc] init];
    
    // Do we have any previously saved models?
    NSArray *arrModelPairs=[self getRecentlyUsedModelPairs];
    if ( isValidNSArray(arrModelPairs) ) {
        
        // Yes, add them to the menu
        [ctxMenu insertItemWithTitle:@"Recently Used..."
                              action:nil
                       keyEquivalent:@""
                             atIndex:index++];
        [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
        
        // Add each previously loaded model to the menu
        for ( NSArray *arrModelPair in arrModelPairs ) {
            
            // Is this model pair valid?
            if ( ![Utils isValidModelPair:arrModelPair] ) {
                continue;
            }
            
            // Get a title for this model url
            NSURL *thisModelURL=arrModelPair[0];
            NSString *thisModelTitle=[LlamarattiWrapper titleForModelURL:thisModelURL];
            
            NSMenuItem *mi=[[NSMenuItem alloc] initWithTitle:thisModelTitle
                                                      action:@selector(btnLoadSelectedModelPair:)
                                               keyEquivalent:@""];
            [mi setRepresentedObject:arrModelPair];
            [ctxMenu insertItem:mi
                        atIndex:index++];
        }
        
        [ctxMenu insertItemWithTitle:@"Clear Recents..."
                              action:@selector(btnClearPreviousUsedModelPairs:)
                       keyEquivalent:@""
                             atIndex:index++];
        [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
    }
    
    
    [ctxMenu insertItemWithTitle:@"Load From Folder..."
                          action:nil
                   keyEquivalent:@""
                         atIndex:index++];
    [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
    
    // Can we get the user's actual home directory?
    NSURL *urlLlamaCacheFolder=nil;
    NSURL *urlHomeDirectory=[Utils getUsersRealHomeDirectory];
    if ( isValidFileNSURL(urlHomeDirectory) ) {
        
        // Yes, do we have a previously created Llama caches folder?
        urlLlamaCacheFolder=[urlHomeDirectory URLByAppendingPathComponent:gLlamaCacheFolder];
        NSFileManager *fm=[NSFileManager defaultManager];
        BOOL isFolder=NO;
        if ( [fm fileExistsAtPath:[urlLlamaCacheFolder path]
                      isDirectory:&isFolder] && isFolder ) {
            
            // Yes, add it to the menu
            [ctxMenu insertItemWithTitle:[urlLlamaCacheFolder path]
                                  action:@selector(btnFolder:)
                           keyEquivalent:@""
                                 atIndex:index++];
        }
    }
    
    // Do we have a previously saved last used model pair?
    NSArray *arrModelPair=[self getLastUsedModelPair];
    if ( [Utils isValidModelPair:arrModelPair] ) {
        
        // Yes, is it valid & was it loaded from the Llama cache folder?
        NSURL *urlModel=arrModelPair[0];
        NSURL *urlLastModelFolder=[urlModel URLByDeletingLastPathComponent];
        if ( !isValidNSURL(urlLlamaCacheFolder) ||
            ![urlLlamaCacheFolder isEqualTo:urlLastModelFolder] ) {
            
            // No, add to our menu
            [ctxMenu insertItemWithTitle:[urlLastModelFolder path]
                                  action:@selector(btnFolder:)
                           keyEquivalent:@""
                                 atIndex:index++];
        }
    }
    
    // Add an "Other..." option
    [ctxMenu insertItemWithTitle:@"Other..."
                          action:@selector(btnFolderOther:)
                   keyEquivalent:@""
                         atIndex:index++];
    
    [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
    [ctxMenu insertItemWithTitle:@"Download..."
                          action:@selector(btnDownload:)
                   keyEquivalent:@""
                         atIndex:index++];
    
    // Display the popup menu
    NSEvent *theEvent=[[NSApplication sharedApplication] currentEvent];
    [NSMenu popUpContextMenu:ctxMenu
                   withEvent:theEvent
                     forView:[self view]];
}

/**
 * @brief Guides the user through loading a model pair
 *
 * Displays a model selection dialog to get model and projection files,
 * then proceeds to load the model pair. Performs various validation against
 * the selected files..
 *
 * @param urlFolder - the initial folder to display in the dialog
 *
 */
- (void)selectModelFiles:(NSURL *)urlFolder {
    
    NSString *msg=@"Hold the CMD key to select:\n\n1) A Model and\n2) A Multimodal Projector (mmproj) file\n\nThe 2 files should be from the same vendor & have the same prefix.";
    
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setDirectoryURL:urlFolder];
    UTType *type = [UTType typeWithFilenameExtension:gGGUFExt];
    openPanel.allowedContentTypes = @[type];
    
    [openPanel beginSheetModalForWindow:self.view.window
                      completionHandler:^(NSModalResponse result) {
        
        [openPanel close];
        
        // Did the user select OK?
        if ( result == NSModalResponseOK ) {
            
            // Yes, validate their selection
            NSArray *arrSelectedURLs=[openPanel URLs];
            if ( !isValidNSArray(arrSelectedURLs) ||
                [arrSelectedURLs count] != 2 ) {
                
                // No, message & outta here...
                [Utils showAlertWithTitle:@"Please Select 2 Files"
                               andMessage:msg
                                 urlTitle:nil
                                      url:nil
                                  buttons:nil];
                return;
            }
            
            // Can we validate which is the model and projector?
            NSArray *arrModelPair=[LlamarattiWrapper validateModelAndProjectorURLs:arrSelectedURLs];
            if ( ![Utils isValidModelPair:arrModelPair] ) {
                
                // No, message & outta here...
                [Utils showAlertWithTitle:@"Did you Select Files from Different Models?"
                               andMessage:msg
                                 urlTitle:nil
                                      url:nil
                                  buttons:nil];
                return;
            }
            
            // Yes, can we load the model pair?
            if ( ![self loadModelPair:arrModelPair
                    useAdditionalArgs:NO
                         useGaugeArgs:NO] ) {
                
                // No, message & outta here...
                NSURL *urlModel=arrModelPair[0];
                NSString *title=@"Unable to Load Model";
                NSString *msg=[NSString stringWithFormat:@"I was unable to load '%@'",[urlModel path]];
                [Utils showAlertWithTitle:title
                               andMessage:msg
                                 urlTitle:nil
                                      url:nil
                                  buttons:nil];
            }
        }
    }];
}

/**
 * @brief Displays a menu to select response window options
 *
 */
- (void)showResponseMenu {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        NSInteger index=0;
        NSMenu *ctxMenu=[[NSMenu alloc] init];
        
        // Add a Copy option
        [ctxMenu insertItemWithTitle:@"Copy"
                              action:@selector(btnCopyResponse:)
                       keyEquivalent:@""
                             atIndex:index++];

        // Add a Clear History option
        [ctxMenu insertItemWithTitle:@"Clear History"
                              action:@selector(btnClear:)
                       keyEquivalent:@""
                             atIndex:index++];

        // Display the popup menu
        NSEvent *theEvent=[[NSApplication sharedApplication] currentEvent];
        [NSMenu popUpContextMenu:ctxMenu
                       withEvent:theEvent
                         forView:[self view]];
    }];
}

/**
 * @brief Displays a menu to select previously used prompts
 *
 * Allows the user to select from a selection of default prompts,
 * as well as prompts they have used previously, then starts text
 * generation with the selected prompt
 *
 */
- (void)showLastPromptsMenu {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        NSInteger index=0;
        NSMenu *ctxMenu=[[NSMenu alloc] init];
        
        // Add our default prompts...
        [ctxMenu insertItemWithTitle:@"Examples..."
                              action:nil
                       keyEquivalent:@""
                             atIndex:index++];
        [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
        NSArray *arrDefaultPrompts=[LlamarattiWrapper samplePrompts];
        
        for ( NSString *prompt in arrDefaultPrompts ) {
            
            // Limit the length of the prompt display
            NSString *promptTitle=nil;
            if ( [prompt length] > MAX_PROMPT_DISPLAY_LENGTH ) {
                 promptTitle = [[prompt substringToIndex:MAX_PROMPT_DISPLAY_LENGTH] stringByAppendingString:@"..."];
            } else {
                promptTitle = prompt;
            }
            NSMenuItem *mi=[[NSMenuItem alloc] initWithTitle:promptTitle
                                                      action:@selector(btnAddPrompt:)
                                               keyEquivalent:@""];
            [mi setRepresentedObject:prompt];
            [ctxMenu insertItem:mi
                        atIndex:index++];
        }
        
        // Add our previously saved prompts...
        NSArray *arrLastPrompts=[self getRecentlyUsedPrompts];
        if ( isValidNSArray(arrLastPrompts) ) {
            
            [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
            [ctxMenu insertItemWithTitle:@"Recently Used..."
                                  action:nil
                           keyEquivalent:@""
                                 atIndex:index++];
            [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
            
            // Add each last used prompt to the menu
            for ( NSString *prompt in arrLastPrompts ) {
                
                NSString *promptTitle=nil;
                if ( [prompt length] > MAX_PROMPT_DISPLAY_LENGTH ) {
                     promptTitle = [[prompt substringToIndex:MAX_PROMPT_DISPLAY_LENGTH] stringByAppendingString:@"..."];
                } else {
                    promptTitle = prompt;
                }
                NSMenuItem *mi=[[NSMenuItem alloc] initWithTitle:promptTitle
                                                          action:@selector(btnAddPrompt:)
                                                   keyEquivalent:@""];
                [mi setRepresentedObject:prompt];
                [ctxMenu insertItem:mi
                            atIndex:index++];
            }
            
            [ctxMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
            [ctxMenu insertItemWithTitle:@"Clear Recents..."
                                  action:@selector(btnClearLastUsedPrompts:)
                           keyEquivalent:@""
                                 atIndex:index++];
        }
        
        // Display the popup menu
        NSEvent *theEvent=[[NSApplication sharedApplication] currentEvent];
        [NSMenu popUpContextMenu:ctxMenu
                       withEvent:theEvent
                         forView:[self view]];
    }];
}

/**
 * @brief Toggles display of drag/drop icon
 *
 */
- (void)toggleDragDropIcon:(BOOL)bDisplay {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        [self->_imgViewDragDrop setHidden:!bDisplay];
        [self->_textDragDrop setHidden:!bDisplay];
    }];
}

/**
 * @brief Returns whether we are busy generating text
 *
 */
- (BOOL)isBusy {
    
    // Do we have an initialized wrapper?
    if ( !self->_llamaWrapper ) {
        return NO;
    }
    
    return ([_llamaWrapper isBusy]);
}

#pragma mark - User Interface - Add Text/Multimedia To Fields

/**
 * @brief Appends the specified user-provided prompt to the response field
 *
 * User prompt strings are RIGHT justified in the response window
 *
 * @param prompt the user prompt string to append
 */
- (void)appendUserPromptToResponse:(NSString *)prompt {
    
    // Hide the drag/drop icon
    [self toggleDragDropIcon:NO];
    
    NSMutableAttributedString *attrDate=[[NSMutableAttributedString alloc]
                                         initWithString:[self getFormattedDate]
                                         attributes:_dictAttrDateRight];
    [attrDate appendAttributedString:_attrNL];
    NSMutableAttributedString *attrFinal=[[NSMutableAttributedString alloc]
                                          initWithString:prompt
                                          attributes:_dictAttrResponseTitleRight];
    [attrFinal appendAttributedString:attrDate];
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        [[self->_textResponse textStorage] appendAttributedString:attrFinal];
        [self->_textResponse scrollToEndOfDocument:nil];
    }];
}

/**
 * @brief Appends the specified image file to the response field
 *
 * Scales down the image prior to appending to the response field
 *
 * @param urlImage the url of the image file
 *
 */
- (BOOL)appendUserImageToResponse:(NSURL *)urlImage
                 useSecurityScope:(BOOL)useSecurityScope
                   withImageWidth:(NSUInteger)imageWidth {
    
    // Did we get the parameters we need?
    if ( !isValidNSURL(urlImage) ) {
        return NO;
    }
    
    // Were we asked to security scope this file access?
    if ( useSecurityScope ) {
        
        // Yes, can we start accessing this security-scoped url
        if ( ![Utils startAccessingSecurityScopedURLs:@[urlImage]] ) {
            
            NSString *filename=[urlImage lastPathComponent];
            NSLog(gErrLrtBookmarkAccess,
                  __func__,
                  filename);
            [self appendStatus:gErrLrtBookmarkAccess,
             __func__,
             filename];
            
            return NO;
        }
    }
    
    // Can we load the image to display in the UI?
    NSImage *fullImage=[[NSImage alloc] initWithContentsOfURL:urlImage];
    
    if ( useSecurityScope ) {
        // Stop accessing this security-scoped url
        [urlImage stopAccessingSecurityScopedResource];
    }
    
    if ( fullImage == nil ) {
        return NO;
    }
    
    // Hide the drag/drop icon
    [self toggleDragDropIcon:NO];
    
    // Scale our image to something appropriate for the response window
    NSImage *imgRippled=[fullImage scaledProportionallyToSize:CGSizeMake(imageWidth,imageWidth)];
    
    // Create a custom RippleMetalView which will ripple the image and
    // add it to our context
    NSRect rippleFrame = NSMakeRect(0, 0, imgRippled.size.width, imgRippled.size.height);
    RippleMetalView *rippleView = [[RippleMetalView alloc] initWithFrame:rippleFrame
                                                                   image:imgRippled];
    [_arrRippleViews addObject:rippleView];
    
    // Create an attachment cell & add it to a text attachment
    ViewAttachmentCell *cell = [[ViewAttachmentCell alloc] init];
    cell.embeddedView = rippleView;
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    [attachment setAttachmentCell:cell];
    
    // Convert it to an NSMutableAttributedString
    NSMutableAttributedString *attrImage=[[NSAttributedString
                                           attributedStringWithAttachment:attachment] mutableCopy];
    [attrImage addAttributes:_dictAttrResponseTitleRight
                       range:NSMakeRange(0, attrImage.length)];
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        [[self->_textResponse textStorage] appendAttributedString:self->_attrNL];
        [[self->_textResponse textStorage] appendAttributedString:attrImage];
        [[self->_textResponse textStorage] appendAttributedString:self->_attrNL];
        [self->_textResponse scrollToEndOfDocument:nil];
    }];
    
    return YES;
}

/**
 * @brief Appends the specified model-generated text to the response field
 *
 * Model text strings are LEFT justified in the response window. These are
 * prefixed by an entity icon, a model name & the current date/time
 *
 * @param prompt the prompt string to append
 * @param firstCall indicates whether this is the first append for the
 * current prompt
 */
- (void)appendModelTextToResponse:(NSString *)prompt
                        firstCall:(BOOL)firstCall {
    
    // Is this the first call for this response?
    NSMutableAttributedString *attrFinal=[[NSMutableAttributedString alloc] initWithString:@""];
    if ( firstCall ) {
        
        // Yes, hide the drag/drop icon
        [self toggleDragDropIcon:NO];
        
        // Append model icon, name & date/time...
        NSTextAttachment *attachIcon=[[NSTextAttachment alloc] init];
        [attachIcon setImage:_modelIcon];
        
        NSMutableAttributedString *attrModelIcon=[[NSAttributedString
                                                   attributedStringWithAttachment:attachIcon] mutableCopy];
        [attrModelIcon addAttributes:_dictAttrResponseTitleLeft
                               range:NSMakeRange(0,attrModelIcon.length)];
        NSMutableAttributedString *attrModel=[[NSMutableAttributedString alloc]
                                              initWithString:(NSString *)[@"  " stringByAppendingString:_modelName]
                                              attributes:_dictAttrResponseTitleLeft];
        
        [attrFinal appendAttributedString:attrModelIcon];
        [attrFinal appendAttributedString:attrModel];
        [attrFinal appendAttributedString:_attrNL];
        
        // Append the date/time
        NSMutableAttributedString *attrDate=[[NSMutableAttributedString alloc]
                                             initWithString:[self getFormattedDate]
                                             attributes:_dictAttrDateLeft];
        [attrFinal appendAttributedString:attrDate];
        [attrFinal appendAttributedString:_attrNL];
    }
    
    NSMutableAttributedString *attrResponse=[[NSMutableAttributedString alloc]
                                             initWithString:prompt
                                             attributes:_dictAttrResponseText];
    [attrFinal appendAttributedString:attrResponse];
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        [[self->_textResponse textStorage] appendAttributedString:attrFinal];
        [self->_textResponse scrollToEndOfDocument:nil];
    }];
}

/**
 * @brief Returns the current date/time for use in the response window
 *
 * @return an NSString with the date, or nil on error
 */
- (NSString *)getFormattedDate {
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];
    [df setTimeStyle:NSDateFormatterMediumStyle];
    NSString *dateStr = [df stringFromDate:[NSDate date]];
    return dateStr;
}

/**
 * @brief Loads the specified audio file into the current model context
 *
 * @param urlAudio the url of the audio file
 *
 * @return the status of the operation
 */
- (BOOL)loadAudioIntoContext:(NSURL *)urlAudio
            useSecurityScope:(BOOL)useSecurityScope {
    
    // Do we have an initialized wrapper?
    if ( !self->_llamaWrapper ) {
        return NO;
    }
    
    // Did we get the parameters we need?
    if ( !isValidFileNSURL(urlAudio) ) {
        return NO;
    }
    
    // Can we start accessing this security-scoped file?
    if ( useSecurityScope ) {
        BOOL bSuccess = [Utils startAccessingSecurityScopedURLs:@[urlAudio]];
        if ( !bSuccess ) {
            return NO;
        }
    }

    // Can we load the audio into our context?
    if ( [_llamaWrapper loadMedia:urlAudio
                 useSecurityScope:useSecurityScope] == false ) {
        return NO;
    }
    
    // Yes, append the image to the response window
    NSURL *urlAudioImage=[[NSBundle mainBundle] URLForImageResource:@"audio"];
    [self appendUserImageToResponse:urlAudioImage
                   useSecurityScope:NO
                     withImageWidth:RESPONSE_IMAGE_AUDIO_SIZE];
    
    return YES;
}

/**
 * @brief Loads the specified image file into the current model context
 *
 * @param urlImage the url of the image file
 *
 * @return the status of the operation
 */
- (BOOL)loadImageIntoContext:(NSURL *)urlImage
            useSecurityScope:(BOOL)useSecurityScope {
    
    // Do we have an initialized wrapper?
    if ( !self->_llamaWrapper ) {
        return NO;
    }
    
    // Did we get the parameters we need?
    if ( !isValidFileNSURL(urlImage) ) {
        return NO;
    }
    
    // Can we load the image into our context?
    if ( [_llamaWrapper loadMedia:urlImage
                 useSecurityScope:useSecurityScope] == false ) {
        return NO;
    }
    
    // Append the image
    [self appendUserImageToResponse:urlImage
                   useSecurityScope:useSecurityScope
                     withImageWidth:RESPONSE_IMAGE_SIZE];
    
    return YES;
}

/**
 * @brief Appends the specified text to the status field
 *
 * Scales down the image prior to appending to the response window
 *
 * @param format variable arguments for the text
 *
 */
- (void)appendStatus:(NSString *)format, ... {
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format
                                               arguments:args];
    va_end(args);
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        // Do we already have some text in this field?
        NSString *current=[self->_textStatus stringValue];
        if ( isValidNSString(current) ) {
            current=[current stringByAppendingString:@"\n"];
        }
        current=[current stringByAppendingFormat:@"%@",message];
        
        [self->_textStatus setStringValue:current];
    }];
}

/**
 * @brief Sets the placeholder string for the prompt field
 *
 * NSTextView doesn't natively support placeholder strings, so
 * we must use various trickery in DragDropTextView
 *
 * @param placeholder the placeholder string
 *
 */
- (void)setPromptPlaceholder:(const NSString *)placeholder {
    
    // Did we get the parameters we need?
    if ( !isValidNSString(placeholder) ) {
        return;
    }
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        [self->_textPrompt setPlaceholderString:(NSString *)placeholder];
    }];
}

/**
 * @brief Sets the user-provided prompt string in the prompt field
 *
 * @param prompt the user-provided prompt string
 *
 */
- (void)setPrompt:(NSString *)prompt {
    
    // Did we get the parameters we need?
    if ( !isValidNSString(prompt) ) {
        return;
    }
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        [self->_textPrompt setString:prompt];
    }];
}

/**
 * @brief Clears the current context
 *
 * @return status of the operation
 *
 */
- (BOOL)clearContext {
    
    // Clear our RippleImageViews
    [_arrRippleViews removeAllObjects];
    
    // Clear fields
    [self clearTextFields:YES
            clearResponse:YES
              clearStatus:YES];
    
    // Execute in background
    NSOperationQueue *obq=[[NSOperationQueue alloc] init];
    [obq addOperationWithBlock:^{
        
        // Clear history
        BOOL bSuccess = [self->_llamaWrapper clearHistory];
        if ( bSuccess ) {
            [self appendStatus:@"Chat History Cleared"];
        } else {
            [self appendStatus:@"Chat History Could not be Cleared"];
        }
    }];
    
    // Load our last used model
    [self loadLastModelPairWithDefaults];
    
    return YES;
}

#pragma mark - User Interface - Gauges

/**
 * @brief Initializes gauge related user interface controls
 */

- (void)initGaugeControls {
    
    // Number formatter for CGFloat fields
    NSNumberFormatter *floatFormatter = [[NSNumberFormatter alloc] init];
    [floatFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [floatFormatter setAllowsFloats:YES];
    
    // Number formatter for Integer fields
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormatter setAllowsFloats:NO];
    
    // Colors for below
     NSColor *textBackgroudColor=[NSColor colorNamed:@"TextBackgroundColor"];
    
    // --------------------------------------------------------------------------------
    // LLM Temperature
    // --------------------------------------------------------------------------------
    
    // Slider
    [_sliderLLMTemp setTrackColor:_statusColor];
    [_sliderLLMTemp setTickColor:_statusColor];
    [_sliderLLMTemp setKnobColor:_statusColor];
    [_sliderLLMTemp setMinValue:THRESHOLD_LLM_TEMP_MIN];
    [_sliderLLMTemp setMaxValue:THRESHOLD_LLM_TEMP_MAX];
    [_sliderLLMTemp setValue:THRESHOLD_LLM_TEMP_MIN];
    [_sliderLLMTemp setKnobRadius:5.0];
    [_sliderLLMTemp setTickLineWidth:0.3];
    [_sliderLLMTemp setTrackLineWidth:GAUGE_TRACK_LINE_WIDTH];
    [_sliderLLMTemp setNumberOfTickMarks:THRESHOLD_LLM_TEMP_MAX*10];
    [_sliderLLMTemp setSnapsToTickMarks:YES];
    [_sliderLLMTemp setAction:@selector(sliderLLMTempValueChanged:)];
    [_sliderLLMTemp setToolTip:@"Adjust LLM Temperature"];
    
    // Title
    [_textLLMTempTitle setTextColor:_statusColor];
    [_textLLMTempTitle setBackgroundColor:textBackgroudColor];
    [_textLLMTempTitle setAlignment:NSTextAlignmentCenter];
    [_textLLMTempTitle setStringValue:@"LM TEMP"];
    [_textLLMTempTitle setSelectable:NO];
    [_textLLMTempTitle setFont:_fontGaugeTitle];
    
    // Value
    [_textLLMTemp setTextColor:_statusColor];
    [_textLLMTemp setBackgroundColor:textBackgroudColor];
    [_textLLMTemp setAlignment:NSTextAlignmentCenter];
    [_textLLMTemp setStringValue:[NSString stringWithFormat:@"%0.2f",THRESHOLD_LLM_TEMP_MIN/100.0]];
    [_textLLMTemp setSelectable:YES];
    [_textLLMTemp setEditable:YES];
    [_textLLMTemp setFont:_fontGaugeText];
    [_textLLMTemp setFormatter:floatFormatter];
    [_textLLMTemp setDelegate:self];
    [_textLLMTemp setToolTip:@"Enter a new LLM temperature"];
    

    // --------------------------------------------------------------------------------
    // Slider - LLM Context Length
    // --------------------------------------------------------------------------------
    
    // Slider
    [_sliderCtxLen setTrackColor:_statusColor];
    [_sliderCtxLen setTickColor:_statusColor];
    [_sliderCtxLen setKnobColor:_statusColor];
    [_sliderCtxLen setMinValue:THRESHOLD_LLM_CTXLEN_MIN];
    [_sliderCtxLen setMaxValue:THRESHOLD_LLM_CTXLEN_MAX];
    [_sliderCtxLen setValue:THRESHOLD_LLM_CTXLEN_DEFAULT];
    [_sliderCtxLen setKnobRadius:5.0];
    [_sliderCtxLen setTickLineWidth:0.3];
    [_sliderCtxLen setTrackLineWidth:GAUGE_TRACK_LINE_WIDTH];
    [_sliderCtxLen setNumberOfTickMarks:(THRESHOLD_LLM_CTXLEN_MAX/THRESHOLD_LLM_CTXLEN_MIN)];
    [_sliderCtxLen setSnapsToTickMarks:YES];
    [_sliderCtxLen setTarget:self];
    [_sliderCtxLen setAction:@selector(sliderLLMCtxLenValueChanged:)];
    [_sliderCtxLen setToolTip:@"Adjust LLM Context Length"];

    // Title
    [_textCtxLenTitle setTextColor:_statusColor];
    [_textCtxLenTitle setBackgroundColor:textBackgroudColor];
    [_textCtxLenTitle setAlignment:NSTextAlignmentCenter];
    [_textCtxLenTitle setStringValue:@"CTX LEN"];
    [_textCtxLenTitle setSelectable:NO];
    [_textCtxLenTitle setFont:_fontGaugeTitle];
    
    // Value
    [_textCtxLen setTextColor:_statusColor];
    [_textCtxLen setBackgroundColor:textBackgroudColor];
    [_textCtxLen setAlignment:NSTextAlignmentCenter];
    [_textCtxLen setStringValue:[NSString stringWithFormat:@"%d",LLAMA_DEFAULT_CTXLEN]];
    [_textCtxLen setSelectable:YES];
    [_textCtxLen setEditable:YES];
    [_textCtxLen setTarget:self];
    [_textCtxLen setFont:_fontGaugeText];
    [_textCtxLen setFormatter:numFormatter];
    [_textCtxLen setDelegate:self];
    [_textCtxLen setToolTip:@"Enter a new LLM context length"];
    
    // --------------------------------------------------------------------------------
    // Progress - System Memory
    // --------------------------------------------------------------------------------
    
    // Slider
    [_progressSysMem setLineWidth:GAUGE_TRACK_LINE_WIDTH];
    [_progressSysMem setProgressColor:_statusColor];
    [_progressSysMem setTrackColor:textBackgroudColor];
    [_progressSysMem setToolTip:@"Available System Memory"];
    
    // Title
    [_textSysMemTitle setTextColor:_statusColor];
    [_textSysMemTitle setBackgroundColor:textBackgroudColor];
    [_textSysMemTitle setAlignment:NSTextAlignmentCenter];
    [_textSysMemTitle setStringValue:@"SYS MEM"];
    [_textSysMemTitle setSelectable:NO];
    [_textSysMemTitle setFont:_fontGaugeTitle];
    
    // Value
    [_textSysMem setTextColor:_statusColor];
    [_textSysMem setBackgroundColor:textBackgroudColor];
    [_textSysMem setAlignment:NSTextAlignmentCenter];
    [_textSysMem setSelectable:NO];
    [_textSysMem setEditable:NO];
    [_textSysMem setFont:_fontGaugeText];
    
    [self progressSysMemValueChanged];
    
    // --------------------------------------------------------------------------------
    // Progress - System Disk
    // --------------------------------------------------------------------------------
    
    // Slider
    [_progressSysDsk setLineWidth:GAUGE_TRACK_LINE_WIDTH];
    [_progressSysDsk setProgressColor:_statusColor];
    [_progressSysDsk setTrackColor:textBackgroudColor];
    [_progressSysDsk setToolTip:@"Available System Disk Space"];
    
    // Title
    [_textSysDskTitle setTextColor:_statusColor];
    [_textSysDskTitle setBackgroundColor:textBackgroudColor];
    [_textSysDskTitle setAlignment:NSTextAlignmentCenter];
    [_textSysDskTitle setStringValue:@"SYS DSK"];
    [_textSysDskTitle setSelectable:NO];
    [_textSysDskTitle setFont:_fontGaugeTitle];
    
    // Value
    [_textSysDsk setTextColor:_statusColor];
    [_textSysDsk setBackgroundColor:textBackgroudColor];
    [_textSysDsk setAlignment:NSTextAlignmentCenter];
    [_textSysDsk setSelectable:NO];
    [_textSysDsk setEditable:NO];
    [_textSysDsk setFont:_fontGaugeText];
    
    [self progressSysDskValueChanged];
    
    // --------------------------------------------------------------------------------
    // Progress - CPU Temp
    // --------------------------------------------------------------------------------
    
    // Are we running in a sandbox?
    if ( !_runningInSandbox ) {
        
        // No, init controls...
        
        // Progress
        [_progressSysTemp setLineWidth:GAUGE_TRACK_LINE_WIDTH];
        [_progressSysTemp setProgressColor:_statusColor];
        [_progressSysTemp setTrackColor:textBackgroudColor];
        [_progressSysTemp setToolTip:@"Current System Temperature"];
        
        // Title
        [_textSysTempTitle setTextColor:_statusColor];
        [_textSysTempTitle setBackgroundColor:textBackgroudColor];
        [_textSysTempTitle setAlignment:NSTextAlignmentCenter];
        [_textSysTempTitle setStringValue:@"SYS TEMP"];
        [_textSysTempTitle setSelectable:NO];
        [_textSysTempTitle setFont:_fontGaugeTitle];
        
        // Value
        [_textSysTemp setTextColor:_statusColor];
        [_textSysTemp setBackgroundColor:textBackgroudColor];
        [_textSysTemp setAlignment:NSTextAlignmentCenter];
        [_textSysTemp setSelectable:NO];
        [_textSysTemp setEditable:NO];
        [_textSysTemp setFont:_fontGaugeText];
        
        [self toggleSystemTempGaugeControls:YES];

        [self progressSysTempValueChanged];
        
    } else {
        
        // Yes, hide controls...
        [self toggleSystemTempGaugeControls:NO];
    }
}

/**
 * @brief Starts a monitor that updates gauges
 *
 */
- (void)startMonitorForGauges {
    
    // Schedule a timer to monitor system metrics & update gauges
    _gaugesMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                           target:self
                                                         selector:@selector(gaugeMonitorTimerFunc:)
                                                         userInfo:nil
                                                          repeats:YES];
}

/**
 * @brief Starts the monitor that updates gauges
 *
 */
- (void)stopMonitorForGauges {
    
    // Shut down the system metrics timer
    if ( _gaugesMonitorTimer ) {
        [_gaugesMonitorTimer invalidate];
        _gaugesMonitorTimer = nil;
    }
}

/**
 * @brief Timer func to poll system metrics & update gauges
 *
 * @param timer - NSTimer
 *
 */
- (void)gaugeMonitorTimerFunc:(NSTimer *)timer {
    
    [self progressSysMemValueChanged];
    
    [self progressSysDskValueChanged];
    
    [self progressSysTempValueChanged];
}

/**
 * @brief Sets the LLM TEMP gauge controls color
 *
 * @param fTemp - the LLM temperature value
 * @param bEnabled - whether the control is enabled
 *
 */
- (void)setGaugeColorForLLMTemp:(float)fTemp
                        enabled:(BOOL)bEnabled {
    
    NSColor *color=nil;
    if ( fTemp > THRESHOLD_LLM_TEMP_DANGER) {
        color=(bEnabled?_statusDangerColor:_disabledColor);
    } else if ( fTemp > THRESHOLD_LLM_TEMP_WARN ) {
        color=(bEnabled?_statusWarnColor:_disabledColor);
    } else {
        color=(bEnabled?_statusColor:_disabledColor);
    }
    [self->_sliderLLMTemp setTrackColor:color];
    [self->_sliderLLMTemp setTickColor:color];
    [self->_sliderLLMTemp setKnobColor:color];
    [self->_textLLMTempTitle setTextColor:color];
    [self->_textLLMTemp setTextColor:color];
}

/**
 * @brief Sets the CTX LEN gauge controls color
 *
 * @param ctxLen - the LLM context length value
 * @param bEnabled - whether the control is enabled
 *
 */
- (void)setGaugeColorForLLMCtxLen:(uint32_t)ctxLen
                          enabled:(BOOL)bEnabled {
    
    NSColor *color=nil;
    if ( ctxLen > THRESHOLD_LLM_CTXLEN_DANGER) {
        color=(bEnabled?_statusDangerColor:_disabledColor);
    } else if ( ctxLen > THRESHOLD_LLM_CTXLEN_WARN ) {
        color=(bEnabled?_statusWarnColor:_disabledColor);
    } else {
        color=(bEnabled?_statusColor:_disabledColor);
    }
    [self->_sliderCtxLen setTrackColor:color];
    [self->_sliderCtxLen setTickColor:color];
    [self->_sliderCtxLen setKnobColor:color];
    [self->_textCtxLenTitle setTextColor:color];
    [self->_textCtxLen setTextColor:color];
}

/**
 * @brief Updates the temperature controls
 *
 * @param sender - sender - the source slider control
 *
 */
- (void)sliderLLMTempValueChanged:(NSObject *)sender {
    
    // Do we have a wrapper with a model loaded?
    if ( _llamaWrapper == nil || ![_llamaWrapper modelLoaded] ) {
        
        return;
    }
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        float fTemp = [self->_sliderLLMTemp value];
        [self setGaugeColorForLLMTemp:fTemp
                              enabled:YES];
        if ( fTemp > THRESHOLD_SYSMEM_WARN) {
            [self->_textLLMTempTitle setFont:self->_fontGaugeTitleBold];
            [self->_textLLMTemp setFont:self->_fontGaugeTextBold];
        } else {
            [self->_textLLMTempTitle setFont:self->_fontGaugeTitle];
            [self->_textLLMTemp setFont:self->_fontGaugeText];
        }
        [self->_textLLMTemp setStringValue:[NSString stringWithFormat:@"%0.1f",fTemp]];
    }];
    
    // Are gauge change prompts currently suppressed?
    if ( !sender || _bSuppressGaugePrompts ) {
        return;
    }
    
    // No, is the user done selecting?
    if ( ![_sliderLLMTemp isTracking] ) {
        
        // Yes, confirm changes
        [self promptToReloadWithSettingsFromGaugeValues:YES
                                      andAdditionalArgs:YES];
    }
}

/**
 * @brief Updates the context length controls
 *
 * @param sender - sender - the source slider control
 *
 */
- (void)sliderLLMCtxLenValueChanged:(NSObject *)sender {
    
    // Do we have a wrapper with a model loaded?
    if ( _llamaWrapper == nil || ![_llamaWrapper modelLoaded] ) {
        
        return;
    }

    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        uint32_t ctxLen = [self->_sliderCtxLen value];
        [self setGaugeColorForLLMCtxLen:ctxLen
                                enabled:YES];
        if ( ctxLen > THRESHOLD_LLM_CTXLEN_WARN ) {
            [self->_textCtxLenTitle setFont:self->_fontGaugeTitleBold];
            [self->_textCtxLen setFont:self->_fontGaugeTextBold];
            
        } else {
            [self->_textCtxLenTitle setFont:self->_fontGaugeTitle];
            [self->_textCtxLen setFont:self->_fontGaugeText];
        }
        [self->_textCtxLen setStringValue:[NSString stringWithFormat:@"%u",ctxLen]];
    }];
    
    // Are gauge change prompts currently suppressed?
    if ( !sender || _bSuppressGaugePrompts ) {
        return;
    }
    
    // No, is the user done selecting?
    if ( ![_sliderCtxLen isTracking] ) {
        
        // Yes, confirm changes
        [self promptToReloadWithSettingsFromGaugeValues:YES
                                      andAdditionalArgs:YES];
    }
}

/**
 * @brief Updates the system memory related controls
 *
 */
- (void)progressSysMemValueChanged {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        ULONGLONG sysMemAvail=0;
        [Utils getAvailSystemMemory:&sysMemAvail];
        ULONGLONG sysMemUsed=self->_sysMemTotal-sysMemAvail;
        CGFloat fSysMemUsed=[Utils scaleValueToPercent:sysMemUsed
                                        toUnitRangeMin:0.0
                                        toUnitRangeMax:self->_sysMemTotal];
        [self->_progressSysMem setProgress:fSysMemUsed];
        NSString *strVal=[NSString stringWithFormat:@"%@/%@G",
                          [Utils formatToGig:sysMemUsed],
                          [Utils formatToGig:self->_sysMemTotal]];
        [self->_textSysMem setStringValue:strVal];
        
        NSColor *color=nil;
        if ( fSysMemUsed < THRESHOLD_SYSMEM_WARN ) {
            color=self->_statusColor;
            [self->_textSysMemTitle setFont:self->_fontGaugeTitle];
            [self->_textSysMem setFont:self->_fontGaugeText];
        } else {
            [self->_textSysMemTitle setFont:self->_fontGaugeTitleBold];
            [self->_textSysMem setFont:self->_fontGaugeTextBold];
            if ( fSysMemUsed < THRESHOLD_SYSMEM_DANGER ) {
                color=self->_statusWarnColor;
            } else {
                color=self->_statusDangerColor;
            }
        }
        [self->_progressSysMem setProgressColor:color];
        [self->_textSysMemTitle setTextColor:color];
        [self->_textSysMem setTextColor:color];
    }];
}

/**
 * @brief Updates the system disk space related controls
 *
 */
- (void)progressSysDskValueChanged {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        // Can we get the total & available disk space
        double sysDskAvail=0.0;
        if ( ![Utils getAvailDiskSpace:&sysDskAvail] ) {
            return;
        }
        double sysDskUsed=self->_sysDskTotal-sysDskAvail;
        
        CGFloat fSysDskUsed=[Utils scaleValueToPercent:sysDskUsed
                                        toUnitRangeMin:0.0
                                        toUnitRangeMax:self->_sysDskTotal];
        [self->_progressSysDsk setProgress:fSysDskUsed];
        NSString *strVal=[NSString stringWithFormat:@"%@/%@G",
                          [Utils formatToGig:sysDskUsed],
                          [Utils formatToGig:self->_sysDskTotal]];
        [self->_textSysDsk setStringValue:strVal];
        
        NSColor *color=nil;
        if ( fSysDskUsed < THRESHOLD_SYSDSK_WARN ) {
            color=self->_statusColor;
            [self->_textSysDskTitle setFont:self->_fontGaugeTitle];
            [self->_textSysDsk setFont:self->_fontGaugeText];
        } else {
            [self->_textSysDskTitle setFont:self->_fontGaugeTitleBold];
            [self->_textSysDsk setFont:self->_fontGaugeTextBold];
            if ( fSysDskUsed < THRESHOLD_SYSDSK_DANGER ) {
                color=self->_statusWarnColor;
            } else {
                color=self->_statusDangerColor;
            }
        }
        [self->_progressSysDsk setProgressColor:color];
        [self->_textSysDskTitle setTextColor:color];
        [self->_textSysDsk setTextColor:color];
    }];
}

/**
 * @brief Updates the system temp related controls
 *
 * Uses the battery temperature if one exists
 *
 */
- (void)progressSysTempValueChanged {
    
    // Are we sandboxed?
    if ( _runningInSandbox ) {
        // Yes, IOService calls won't work...
        return;
    }
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        // Can we read the temperature of the Apple battery?
        CGFloat fTempKelvins=0.0;
        NSString *strVal=@"...";
        CGFloat fTempScaled=0.0;
        if ( [Utils getBatteryTemperature:&fTempKelvins] ) {

            NSString *strUnits=@"";
            CGFloat fLocalTemp = [Utils kelvinsToLocaleTemp:fTempKelvins
                                              returnedUnits:&strUnits];
            
            CGFloat fLocalTempMax = [Utils kelvinsToLocaleTemp:THRESHOLD_SYSTEMP_MAX
                                                 returnedUnits:&strUnits];
            
            fTempScaled = [Utils scaleValueToPercent:fLocalTemp
                                      toUnitRangeMin:0.0f
                                      toUnitRangeMax:fLocalTempMax];
            
            strVal=[NSString stringWithFormat:@"%0.1f%@",
                                                fLocalTemp,
                                                strUnits];
        }

        // Update gauge values
        [self->_progressSysTemp setProgress:fTempScaled];
        [self->_textSysTemp setStringValue:strVal];
        
        NSColor *color=nil;
        if ( fTempScaled < THRESHOLD_SYSTEMP_WARN ) {
            color=self->_statusColor;
            [self->_textSysTempTitle setFont:self->_fontGaugeTitle];
            [self->_textSysTemp setFont:self->_fontGaugeText];
        } else {
            [self->_textSysTempTitle setFont:self->_fontGaugeTitleBold];
            [self->_textSysTemp setFont:self->_fontGaugeTextBold];
            if ( fTempScaled < THRESHOLD_SYSTEMP_DANGER ) {
                color=self->_statusWarnColor;
            } else {
                color=self->_statusDangerColor;
            }
        }
        [self->_progressSysTemp setProgressColor:color];
        [self->_textSysTempTitle setTextColor:color];
        [self->_textSysTemp setTextColor:color];
    }];
}

/**
 * @brief Validates new values enetered into the gauge text fields
 *
 * @param notification - unused
 *
 */
- (void)controlTextDidEndEditing:(NSNotification *)notification {
    
    id control = [notification object];
    
    // Was the LLM TEMP text field updated?
    if ( control == _textLLMTemp ) {

        // Yes, is the new value within range?
        NSString *strVal=[[_textLLMTemp stringValue] stringByReplacingOccurrencesOfString:@"," withString:@""];
        CGFloat fVal=[strVal floatValue];
        if ( isValidLLMTemp(fVal) ) {
            
            // Yes, use it
            [_sliderLLMTemp setValue:fVal];
            
        } else {
            
            // No, Was anything entered?
            if ( isValidNSString(strVal) ) {
                NSString *title=@"Provide a Valid LLM Temperature";
                NSString *msg=[NSString stringWithFormat:@"Please provide an LLM temperature from %0.1f to %0.1f",THRESHOLD_LLM_TEMP_MIN,THRESHOLD_LLM_TEMP_MAX];
                [Utils showAlertWithTitle:title
                               andMessage:msg
                                 urlTitle:nil
                                      url:nil
                                  buttons:nil];
            }
        }
        // Refresh gauge controls
        [self sliderLLMTempValueChanged:nil];
    }
    
    // Was the CTX LEN text field updated?
    else if ( control == _textCtxLen ) {

        // Yes, is the new value within range?
        NSString *strVal=[[_textCtxLen stringValue] stringByReplacingOccurrencesOfString:@"," withString:@""];
        NSUInteger val=[strVal integerValue];
        if ( isValidLLMCtxLen(val) ) {
            
            // Yes, use it
            [_sliderCtxLen setValue:val];
            
        } else {
            
            // No, was anything entered?
            if ( isValidNSString(strVal) ) {
                NSString *title=@"Provide a Valid LLM Context Length";
                NSString *msg=[NSString stringWithFormat:@"Please provide an LLM Context Length from %d to %d",THRESHOLD_LLM_CTXLEN_MIN,THRESHOLD_LLM_CTXLEN_MAX];
                [Utils showAlertWithTitle:title
                               andMessage:msg
                                 urlTitle:nil
                                      url:nil
                                  buttons:nil];
            }
        }
        // Refresh gauge controls
        [self sliderLLMCtxLenValueChanged:nil];
    }
}

/**
 * @brief Toggles display of the SYS TEMP related controls
 *
 * This can be used to toggle display of the SYS TEMP gauge, based on whether
 * sandboxing is enabled or not in the app.
 *
 */
- (void)toggleSystemTempGaugeControls:(BOOL)bVisible {
    
    [_progressSysTemp setHidden:!bVisible];
    [_textSysTempTitle setHidden:!bVisible];
    [_textSysTemp setHidden:!bVisible];
}

/**
 * @brief Updates the gauges with specified values
 *
 * @param temp - the current model temperature
 * @param ctxLen - the current model context length
 *
 */
- (void)updateGaugesWithTemp:(CGFloat)temp
                   andCtxLen:(NSUInteger)ctxLen {
    
    NSOperationQueue *omq=[NSOperationQueue mainQueue];
    [omq addOperationWithBlock:^{
        
        self->_bSuppressGaugePrompts=YES;
        
        // Gauge - LLM TEMP
        [self->_sliderLLMTemp setValue:temp];
        
        // Gauge - CTX LEN
        [self->_sliderCtxLen setValue:ctxLen];
        
        self->_bSuppressGaugePrompts=NO;
    }];
}

#pragma mark - User Interface - Image Ripple Timer

/**
 * @brief Toggles ripple effect on images in the current context
 *
 * bEnabled - Enable or disable the ripple effect
 *
 */
- (void)toggleImageRipple:(BOOL)bEnabled {
    
    // Do we have the parameters we need?
    if ( !isValidNSArray(_arrRippleViews) ) {
        return;
    }
    
    // Enumerate our RippleMetalViews to toggle ripple effect
    for ( RippleMetalView *rippleView in _arrRippleViews ) {
        [rippleView toggleRipple:bEnabled];
    }
}

/**
 * @brief Starts a timed ripple effect on images in the current context
 *
 * @param time - The amount of time before stopping the ripple effect
 *
 */
- (void)startTimedRippleFor:(CGFloat)time {
    
    // Do we have the parameters we need?
    if ( !isValidNSArray(_arrRippleViews) ) {
        return;
    }
    
    // Start rippling the images
    [self toggleImageRipple:YES];
    
    // Schedule a timer to stop them
    _rippleTimer = [NSTimer scheduledTimerWithTimeInterval:time
                                                    target:self
                                                  selector:@selector(stopTimedRippleTimerFunc:)
                                                  userInfo:nil
                                                   repeats:NO];
}

/**
 * @brief Stops the ripple effect on images in the current context
 *
 * @param timer - NSTimer
 *
 */
- (void)stopTimedRippleTimerFunc:(NSTimer *)timer {
    
    // Stop rippling the images
    [self toggleImageRipple:NO];
    
    [_rippleTimer invalidate];
    _rippleTimer=nil;
}

#pragma mark - NSUserDefaults - Recently Used Models

/**
 * @brief Resets NSUserDefaults app settings
 *
 */
- (void)resetPrefs {
    
    [self clearRecentlyUsedModelPairs];

    [self clearRecentlyUsedPrompts];
    
    [self clearAllAdditionalArguments];
    
    // Add: Other stuff to reset...
}

/**
 * @brief Clears the recently used model pairs from NSUserDefaults
 *
 * When App sandboxing is enabled, the recently used model pairs are stored as
 * arrays of security scoped bookmark pairs (NSData), otherwise they are
 * stored as arrays of file path pairs (NSString)
 *
 * The model pairs are ordered in the array so they appear in recently used
 * order when displayed in a menu.
 *
 * @return the status of the operation
 */
- (BOOL)clearRecentlyUsedModelPairs {
    
    // Are we running sandboxed?
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    if ( _runningInSandbox ) {
        // Yes, clear Model Bookmarks
        [ud setURL:nil
            forKey:gPrefsLastModelBookmarks];
        
    } else {
        // No, clear Model Paths
        [ud setURL:nil
            forKey:gPrefsLastModelPaths];
    }
    [ud synchronize];
    
    return YES;
}

/**
 * @brief Retrieves the recently used model pairs from NSUserDefaults
 *
 * When App sandboxing is enabled, the recently used model pairs are stored as
 * arrays of security scoped bookmark pairs (NSData), otherwise they are
 * stored as arrays of file path pairs (NSString)
 *
 * The model pairs are ordered in the array so they appear in recently used
 * order when displayed in a menu. This method reads them from user defaults and
 * converts them back to NSURL model pairs.
 *
 * @return an NSArray of NSURL model pairs, or nil on failure
 *
 */
- (NSArray *)getRecentlyUsedModelPairs {
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray *modelPairs = [NSMutableArray array];

    // Are we running sandboxed?
    if (_runningInSandbox) {
        
        // Yes, can we read the model bookmarks?
        NSArray *bookmarkPairs = [ud arrayForKey:gPrefsLastModelBookmarks];
        if (!isValidNSArray(bookmarkPairs)) {
            return nil;
        }
        
        // Resolve the bookmarks
        for ( NSArray *bookmarkPair in bookmarkPairs ) {
            NSArray *resolvedPair = [self resolveBookmarksForModelPair:bookmarkPair];
            if ( [Utils isValidModelPair:resolvedPair] ) {
                [modelPairs addObject:resolvedPair];
            }
        }
    } else {
        
        // No, can we read the model paths?
        NSArray *modelPaths = [ud arrayForKey:gPrefsLastModelPaths];
        if (!isValidNSArray(modelPaths)) {
            return nil;
        }
        
        // Convert the array to URLs
        for (NSArray *pathPair in modelPaths) {
            if (pathPair.count != 2) {
                continue;
            }
            NSURL *url1 = [NSURL fileURLWithPath:pathPair[0]];
            NSURL *url2 = [NSURL fileURLWithPath:pathPair[1]];
            [modelPairs addObject:@[url1, url2]];
        }
    }

    return modelPairs;
}

/**
 * @brief Clears the specified recently used model pair from NSUserDefaults
 *
 * When App sandboxing is enabled, the recently used model pairs are stored as
 * arrays of security scoped bookmark pairs (NSData), otherwise they are
 * stored as arrays of file path pairs (NSString)
 *
 * The model pairs are ordered in the array so they appear in recently used
 * order when displayed in a menu.
 *
 * @param arrModelPair the model pair to clear
 *
 * @return the status of the operation
 */
- (BOOL)clearRecentlyUsedModelPair:(NSArray *)arrModelPair {
    
    // Do we have the parameters we need?
    if ( ![Utils isValidModelPair:arrModelPair] ) {
        return NO;
    }

    NSArray *recentModelPairs = [self getRecentlyUsedModelPairs];
    if ( !isValidNSArray(recentModelPairs) ) {
        return NO;
    }
    
    NSUInteger index = [recentModelPairs indexOfObject:arrModelPair];
    if ( index == NSNotFound ) {
        return NO;
    }

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    // Are we running sandboxed?
    if (_runningInSandbox) {
        
        // Yes, can we get the model bookmarks?
        NSArray *bookmarkPairs = [ud arrayForKey:gPrefsLastModelBookmarks];
        if ( !isValidNSArray(bookmarkPairs) ) {
            return NO;
        }
        NSMutableArray *updatedBookmarkPairs = [bookmarkPairs mutableCopy];
        [updatedBookmarkPairs removeObjectAtIndex:index];
        [ud setObject:updatedBookmarkPairs
               forKey:gPrefsLastModelBookmarks];
        
    } else {
        
        // No, can we get the model paths?
        NSArray *modelPaths = [ud arrayForKey:gPrefsLastModelPaths];
        if ( !isValidNSArray(modelPaths) ) {
            return NO;
        }
        NSMutableArray *updatedModelPaths = [modelPaths mutableCopy];
        [updatedModelPaths removeObjectAtIndex:index];
        [ud setObject:updatedModelPaths
               forKey:gPrefsLastModelPaths];
    }
    [ud synchronize];
    return YES;
}

/**
 * @brief Returns the last used model pair from NSUserDefaults
 *
 * When App sandboxing is enabled, the recently used model pairs are stored as
 * arrays of security scoped bookmark pairs (NSData), otherwise they are
 * stored as arrays of file path pairs (NSString)
 *
 * The model pairs are ordered in the array so they appear in recently used
 * order when displayed in a menu.
 *
 * @return a valid model pair, or nil on failure
 *
 */
- (NSArray *)getLastUsedModelPair {
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *arrModelPair = [NSMutableArray array];

    // Are we running sandboxed?
    if (_runningInSandbox) {
        
        // Yes, can we get the model bookmarks?
        NSArray *arrModelBookmarkPairs = [ud arrayForKey:gPrefsLastModelBookmarks];
        if (!isValidNSArray(arrModelBookmarkPairs)){
            return nil;
        }
        
        NSArray *arrModelBookmarkPair = [arrModelBookmarkPairs lastObject];
        if (![Utils isValidBookmarkModelPair:arrModelBookmarkPair]) {
            return nil;
        }
        
        for ( NSData *modelBookmark in arrModelBookmarkPair ) {
            BOOL isStale = NO;
            NSError *error = nil;

            NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:modelBookmark
                                                            options:NSURLBookmarkResolutionWithSecurityScope
                                                      relativeToURL:nil
                                                bookmarkDataIsStale:&isStale
                                                              error:&error];
            if ( !resolvedURL ||
                  isStale ||
                 ![fm fileExistsAtPath:[resolvedURL path]] ) {
                return nil;
            }

            [arrModelPair addObject:resolvedURL];
        }
    } else {
        
        // No, can we get the model paths?
        NSArray *arrModelPairs = [self getRecentlyUsedModelPairs];
        if ( !isValidNSArray(arrModelPairs) ) {
            return nil;
        }
        
        arrModelPair = [[arrModelPairs lastObject] mutableCopy];
        for ( NSURL *url in arrModelPair ) {
            if ( ![fm fileExistsAtPath:[url path]] ) {
                return nil;
            }
        }
    }
    return arrModelPair;
}

/**
 * @brief Saves the specified last used model pair to NSUserDefaults
 *
 * When App sandboxing is enabled, the recently used model pairs are stored as
 * arrays of security scoped bookmark pairs (NSData), otherwise they are
 * stored as arrays of file path pairs (NSString)
 *
 * The model pairs are ordered in the array so they appear in recently used
 * order when displayed in a menu.
 *
 * @param arrModelPair the model pair to save
 *
 * @return the status of the operation
 *
 */
- (BOOL)saveLastUsedModelPair:(NSArray *)arrModelPair {
    
    // Do we have the parameters we need?
    if (![Utils isValidModelPair:arrModelPair]) {
        return NO;
    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    // Are we running sandboxed?
    if (_runningInSandbox) {

        // Yes, save as model bookmarks
        NSArray *existingBookmarks = [ud arrayForKey:gPrefsLastModelBookmarks];
        NSMutableArray *mutableBookmarks = isValidNSArray(existingBookmarks) ? [existingBookmarks mutableCopy] : [NSMutableArray array];
        
        NSArray *recentPairs = [self getRecentlyUsedModelPairs];
        NSUInteger existingIndex = isValidNSArray(recentPairs) ? [recentPairs indexOfObject:arrModelPair] : NSNotFound;

        // Is this model pair already at the end?
        if (existingIndex != NSNotFound && existingIndex == mutableBookmarks.count - 1) {
            return YES;
        }

        // Is it already in there?
        NSArray *bookmarkModelPair = nil;
        if (existingIndex != NSNotFound) {
            // Yes, remove...
            bookmarkModelPair = mutableBookmarks[existingIndex];
            [mutableBookmarks removeObjectAtIndex:existingIndex];
        } else {
            // No, create new
            bookmarkModelPair = [self createBookmarkedModelPair:arrModelPair];
            if (![Utils isValidBookmarkModelPair:bookmarkModelPair]) {
                return NO;
            }
        }
        
        // Add and save to prefs
        [mutableBookmarks addObject:bookmarkModelPair];
        [ud setObject:mutableBookmarks forKey:gPrefsLastModelBookmarks];
        
    } else {
        
        // No, save as model paths
        NSArray *existingPairs = [ud arrayForKey:gPrefsLastModelPaths];
        NSMutableArray *mutablePairs = isValidNSArray(existingPairs) ? [existingPairs mutableCopy] : [NSMutableArray array];
        
        NSArray *newModelPair = @[[arrModelPair[0] path], [arrModelPair[1] path]];
        NSUInteger existingIndex = [mutablePairs indexOfObject:newModelPair];
        
        // Is this model pair already at the end?
        if (existingIndex != NSNotFound && existingIndex == mutablePairs.count - 1) {
            return YES;
        }

        // Is it already in there?
        if (existingIndex != NSNotFound) {
            // Yes, remove...
            [mutablePairs removeObjectAtIndex:existingIndex];
        }
        
        // Add and save to prefs
        [mutablePairs addObject:[newModelPair mutableCopy]];
        [ud setObject:mutablePairs forKey:gPrefsLastModelPaths];
    }

    [ud synchronize];
    return YES;
}

#pragma mark - Security Scoped Bookmarks

/**
 * @brief Creates a bookmarked model pair suitable for saving to UserDefaults
 *
 * When App sandboxing is enabled, the model pairs need to be stored as security
 * scoped bookmarks (NSData) in user defaults.
 *
 * This method converts a URL model pair to an NSData model pair
 *
 * @param arrModelPair - the model pair to convert to a  bookmarked model pair
 *
 * @return the bookmarked NSData model pair
 *
 */
- (NSArray *)createBookmarkedModelPair:(NSArray *)arrModelPair {
    
    // Did we get the parameters we need?
    if ( ![Utils isValidModelPair:arrModelPair] ) {
        return nil;
    }
    
    // Can we create bookmarks for these file URLs?
    NSMutableArray *arrModelBookmarkPair=[NSMutableArray array];
    NSError *e=nil;
    for ( NSURL *url in arrModelPair ) {
        NSData *modelBookmark=[url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                 includingResourceValuesForKeys:nil
                                                  relativeToURL:nil
                                                          error:&e];
        if ( modelBookmark == nil ) {
            
            NSLog(gErrLrtBookmarkCreate,
                  __func__,
                  [url path],
                  safeDesc(e),
                  safeCode(e));
            
            [self appendStatus:gErrLrtBookmarkCreate,
                               __func__,
                               @"",
                               [Utils safeDescFromNSError:e],
                               [Utils safeCodeFromNSError:e]];
            
            return nil;
        }
        [arrModelBookmarkPair addObject:modelBookmark];
    }
    return arrModelBookmarkPair;
}

/**
 * @brief Resolves the Data bookmarks in a model pair back to their original URLs
 *
 * When App sandboxing is enabled, the model pairs need to be stored as security
 * scoped bookmarks (NSData) in user defaults.
 *
 * This method converts an NSData model pair to an NSURL model pair
 *
 * @param arrBookmarkModelPair - the security-scoped bookmarked model pair
 *
 * @return the resolved URL model pair
 *
 */
- (NSArray *)resolveBookmarksForModelPair:(NSArray *)arrBookmarkModelPair {
    
    // Did we get the parameters we need?
    if ( ![Utils isValidBookmarkModelPair:arrBookmarkModelPair] ) {
        return @[];
    }
    
    // Can we resolve the security bookmarks for this model pair back
    // to URLs?
    NSMutableArray *arrModelPair = [NSMutableArray array];
    for ( NSData *modelBookmark in arrBookmarkModelPair ) {

        NSError *e=nil;
        BOOL isStale=NO;
        
        // Can we resolve this bookmark?
        NSURL *urlResolved=[NSURL URLByResolvingBookmarkData:modelBookmark
                                                     options:NSURLBookmarkResolutionWithSecurityScope
                                               relativeToURL:nil
                                         bookmarkDataIsStale:&isStale
                                                       error:&e];
        if ( !isValidFileNSURL(urlResolved) ) {
            
            NSLog(gErrLrtBookmarkResolve,
                  __func__,
                  "",
                  0);
            
            [self appendStatus:gErrLrtBookmarkResolve,
                               __func__,
                               "",
                               0];
            return nil;
        }
        
        if ( !isStale ) {
            
            [arrModelPair addObject:urlResolved];
        }
    }
    return arrModelPair;
}

#pragma mark - NSUserDefaults - Recently Used Prompts

/**
 * @brief Retrieves the recently used user prompts from NSUserDefaults
 *
 * @return An NSArray of recently used user prompts or an empty array
 * on failure
 *
 */
- (NSArray *)getRecentlyUsedPrompts {
    
    // Do we have any previously saved prompts?
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    NSArray *arrLastPrompts=(NSMutableArray *)[ud arrayForKey:gPrefsLastPrompts];
    if ( !isValidNSArray(arrLastPrompts) ) {
        return [NSMutableArray array];
    }
    return arrLastPrompts;
}

/**
 * @brief Saves the specified last used prompt to NSUserDefaults
 *
 * The prompts are ordered in the array so they appear in last used order
 * when displayed in a menu
 *
 * @param prompt the prompt to save
 *
 * @return the status of the operation
 */
- (BOOL)saveLastUsedPrompt:(NSString *)prompt {
    
    // Did we get the parameters we need?
    if ( !isValidNSString(prompt) ) {
        return NO;
    }
    
    // Limit the length of the prompt
    if ([prompt length] > MAX_PROMPT_LENGTH) {
        prompt = [prompt substringToIndex:MAX_PROMPT_LENGTH];
    }
    
    // Is this prompt in our sample prompts?
    NSArray *samplePrompts=[LlamarattiWrapper samplePrompts];
    for ( NSString *samplePrompt in samplePrompts ) {
        if ( [[prompt lowercaseString] isEqualToString:[samplePrompt lowercaseString]] ) {
            return NO;
        }
    }
    
    // Do we have any previously saved prompts in prefs?
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    NSMutableArray *arrPrompts;
    NSArray *arrSavedPrompts=(NSMutableArray *)[ud arrayForKey:gPrefsLastPrompts];
    if ( isValidNSArray(arrSavedPrompts) ) {
        
        // Yes, is our current prompt already in there?
        arrPrompts=[arrSavedPrompts mutableCopy];
        NSUInteger ind=[arrPrompts indexOfObject:prompt];
        if ( ind != NSNotFound ) {
            [arrPrompts removeObjectAtIndex:ind];
        }
    }
    else {
        arrPrompts=[NSMutableArray array];
    }
    
    // Append this prompt as the most recently used
    [arrPrompts addObject:prompt];
    [ud setObject:arrPrompts
           forKey:gPrefsLastPrompts];
    [ud synchronize];
    
    return YES;
}
    
/**
 * @brief Clears the recently used prompts from NSUserDefaults
 *
 * @return the status of the operation
 */
- (BOOL)clearRecentlyUsedPrompts {
    
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    [ud setURL:nil
        forKey:gPrefsLastPrompts];
    [ud synchronize];
    
    return YES;
}

#pragma mark - NSUserDefaults - Additional Arguments

/**
 * @brief Retrieves recently used arguments for the specified model name from NSUserDefaults
 *
 * @return An NSString representing the recently used arguments for the specified model name
 *
 */
- (NSString *)getAdditionalArgumentsForModelName:(NSString *)modelName {
    
    // Did we get the parameters we need?
    if ( !isValidNSString(modelName) ) {
        return nil;
    }
    
    // Do we have any previously saved arguments?
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dictLastArgs=[ud objectForKey:gPrefsLastArgs];
    if ( !isValidNSDictionary(dictLastArgs) ) {
        return @"";
    }
    NSString *lastArgs=[dictLastArgs objectForKey:modelName];
    return lastArgs;
}

/**
 * @brief Saves the specified last used arguments for the specified model name to NSUserDefaults
 *
 * @param args the arguments to save
 * @param modelName the name of the model
 *
 * @return the status of the operation
 *
 */
- (BOOL)saveAdditionalArguments:(NSString *)args
                   forModelName:(NSString *)modelName {
    
    // Did we get the parameters we need?
    if ( !args || !isValidNSString(modelName) ) {
        return NO;
    }

    // Remove leading/trailing whitespace
    args = [Utils stripWhitespace:args];
    
    // Can we get the current arguments for all models?
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dictArgs=[ud objectForKey:gPrefsLastArgs];
    if ( !isValidNSDictionary(dictArgs) ) {
        dictArgs=[NSMutableDictionary dictionary];
    } else {
        dictArgs=[dictArgs mutableCopy];
    }
    
    // Update the specific arguments for this model name
    [dictArgs setObject:args
                 forKey:modelName];
    
    // Save the dictionary back to NSUserDefaults
    [ud setObject:dictArgs
           forKey:gPrefsLastArgs];
    [ud synchronize];
    
    return YES;
}

/**
 * @brief Clears all additional arguments from NSUserDefaults
 *
 * @return the status of the operation
 */
- (BOOL)clearAllAdditionalArguments {
    
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    [ud setURL:nil
        forKey:gPrefsLastArgs];
    [ud synchronize];
    
    return YES;
}

#pragma mark - Mouse

/**
 * @brief Right click handler for the Response window
 *
 * @param recognizer unused
 *
 */
- (void)handleRightClickOnResponse:(NSClickGestureRecognizer *)recognizer {
    
    // Are we busy?
    if ( [self isBusy] ) {
        return;
    }
    [self showResponseMenu];
}

/**
 * @brief Right click handler for the Prompt field to display prompts menu
 *
 * @param recognizer unused
 *
 */
- (void)handleRightClickOnPrompt:(NSClickGestureRecognizer *)recognizer {
    
    // Are we busy?
    if ( [self isBusy] ) {
        return;
    }
    [self showLastPromptsMenu];
}

#pragma mark - User Selector

/**
 * @brief User Selector for tapping into llama.cpp events
 *
 * This selector is called by the llama.cpp wrapper on the main thread to indicate
 * current activity
 *
 * @param parms NSArray - parms[0]=LlamarattiEvent (NSNumber), parms[1]=NSString
 *
 */
- (IBAction)llamaEventsSelector:(id)parms {
    
    // Did we get our parameters?
    NSArray *arrParms=(NSArray *)parms;
    if ( !isValidNSArray(arrParms) ||
         [arrParms count] < 2 ) {
        return;
    }
    
    NSNumber *numType=parms[0];
    NSString *text=parms[1];
    switch(numType.intValue) {
            
        case LlamarattiEventStatus:
        {
            [self appendStatus:text];
            break;
        }
            
        case LlamarattiEventResponse:
        {
            // Update the response
            //NSLog(@"%@\n",text);
            
            [self appendModelTextToResponse:text
                                  firstCall:_bFirstResponse];
            
            if ( _bFirstResponse ) {
                _bFirstResponse=NO;
                
                // Stop rippling the current images
                [self toggleImageRipple:NO];
            }
            break;
        }
    }
}

@end
