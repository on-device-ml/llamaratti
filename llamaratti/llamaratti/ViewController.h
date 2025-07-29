/**
 * @file ViewController.h
 *
 * @brief Application View Controller for Llamaratti
 * 
 * @author Created by Geoff G. on 05/25/2025
 *
 * Demonstrates use of the LlamarattiWrapper.h/m Objective-C wrapper for llama.cpp
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
#import <AVFoundation/AVFoundation.h>

#import "LlamarattiWrapper.h"
#import "DragDropTextView.h"
#import "CircularSlider.h"
#import "CircularProgressView.h"

/**
 * @class ViewController
 * @brief A view controller that manages Llamaratti interaction
 *
 * This class handles the primary user interface and interactions
 * for the main screen in the application.
 */
@interface ViewController : NSViewController <NSTextFieldDelegate>

// Text View - Response
@property (weak) IBOutlet NSScrollView *scrollResponse;
@property (weak) IBOutlet DragDropTextView *textResponse;

// Text View - Prompt
@property (weak) IBOutlet NSScrollView *scrollPrompt;
@property (weak) IBOutlet DragDropTextView *textPrompt;
@property (weak) IBOutlet NSImageView *imgViewDragDrop;
@property (weak) IBOutlet NSTextField *textDragDrop;

// Text Field - Status
@property (weak) IBOutlet NSTextField *textStatus;

// ImageView - Supported Media
@property (weak) IBOutlet NSImageView *imgViewImages;
@property (weak) IBOutlet NSImageView *imgViewAudio;

// Circular Slider - LLM Temp
@property (weak) IBOutlet CircularSlider *sliderLLMTemp;
@property (weak) IBOutlet NSTextField *textLLMTempTitle;
@property (weak) IBOutlet NSTextField *textLLMTemp;

// Circular Slider - Context Length
@property (weak) IBOutlet CircularSlider *sliderCtxLen;
@property (weak) IBOutlet NSTextField *textCtxLenTitle;
@property (weak) IBOutlet NSTextField *textCtxLen;

// Progress Indicator - Memory
@property (weak) IBOutlet CircularProgressView *progressSysMem;
@property (weak) IBOutlet NSTextField *textSysMemTitle;
@property (weak) IBOutlet NSTextField *textSysMem;

// Progress Indicator - Disk Space
@property (weak) IBOutlet CircularProgressView *progressSysDsk;
@property (weak) IBOutlet NSTextField *textSysDskTitle;
@property (weak) IBOutlet NSTextField *textSysDsk;

// Progress Indicator - CPU Temp
@property (weak) IBOutlet CircularProgressView *progressSysTemp;
@property (weak) IBOutlet NSTextField *textSysTempTitle;
@property (weak) IBOutlet NSTextField *textSysTemp;

@property (weak) IBOutlet NSButton *btnModel;
@property (weak) IBOutlet NSButton *btnArgs;
@property (weak) IBOutlet NSButton *btnGPU;
@property (weak) IBOutlet NSButton *btnClear;
@property (weak) IBOutlet NSButton *btnStop;
@property (weak) IBOutlet NSButton *btnGo;

@property (weak) IBOutlet NSProgressIndicator *activity;

@property (weak) IBOutlet NSTextField *textLogo;

@property LlamarattiWrapper *llamaWrapper;
@property NSString *modelName;

// Methods
- (void)toggleDragDropIcon:(BOOL)bDisplay;

- (BOOL)isBusy;

- (BOOL)loadAudioIntoContext:(NSURL *)urlAudio
            useSecurityScope:(BOOL)useSecurityScope;

- (BOOL)loadImageIntoContext:(NSURL *)urlImage
            useSecurityScope:(BOOL)useSecurityScope;

- (void)startTimedRippleFor:(CGFloat)time;

- (void)updateGaugesWithTemp:(CGFloat)temp
                   andCtxLen:(NSUInteger)ctxLen;

- (BOOL)saveAdditionalArguments:(NSString *)args
                   forModelName:(NSString *)modelName;

- (BOOL)promptToReloadWithSettingsFromGaugeValues:(BOOL)useGaugeArgs
                                andAdditionalArgs:(BOOL)useAdditionalArgs;

- (NSString *)buildArgumentsForModelPair:(NSArray *)arrModelPair
                   withUseAdditionalArgs:(BOOL)useAdditionalArgs
                        withUseGaugeArgs:(BOOL)useGaugeArgs
                            returnedTemp:(float *)temp
                          returnedCtxLen:(uint32_t *)ctxLen;

- (IBAction)btnGo:(id)sender;

@end

