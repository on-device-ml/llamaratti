/**
 * @file LlamarattiWrapper.m
 *
 * @brief Objective-C++ wrapper for multimodal llama.cpp
 *
 * Provides a basic set of methods to access multimodal llama.cpp
 *
 * @author Created by Geoff G. on 05/25/2025 based on code from llama.cpp mtmd
 *
 * @attention This example code is subject to change as llama multimodal continues to
 * evolve, and is therefore not production ready
 *
 */

#if !defined(__arm64__)
    #error This code only supports Apple Silicon architecture
#endif

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>

#import "Shared.h"
#import "ModelInfo.h"

extern NSString *gGGUFExt;
extern NSString *gMMProj;
extern NSString *gMediaTemplate;

// LLM temperature
#define LLAMA_DEFAULT_TEMP          0.6

// LLM context length
#define LLAMA_DEFAULT_CTXLEN        2048

// LLM Seed
#define LLAMA_DEFAULT_SEED          0xFFFFFFFF

// Prompt Length
#define MAX_PROMPT_LENGTH           5000
#define MAX_PROMPT_DISPLAY_LENGTH   100

// Media
#define MAX_SUPPORTED_MEDIA         15

// Macros
#define isMMProj(urlFile) ([[[urlFile path] lastPathComponent] containsString:(NSString *)gMMProj])
#define isValidLLMTemp(val) ( ((val)>=THRESHOLD_LLM_TEMP_MIN)&&((val)<=THRESHOLD_LLM_TEMP_MAX) )
#define isValidLLMCtxLen(val) ( ((val)>=THRESHOLD_LLM_CTXLEN_MIN)&&((val)<=THRESHOLD_LLM_CTXLEN_MAX) )

/**
* @class LlamarattiWrapper
*
* @brief Objective-C++ wrapper for multimodal llama.cpp
*
*/
@interface LlamarattiWrapper : NSObject

// Properties
@property NSURL *urlModel;
@property NSURL *urlMMProj;
@property BOOL audioSupported;
@property BOOL visionSupported;

// Methods
+ (id)wrapperWithModelURL:(NSURL *)urlModel
             andMMProjURL:(NSURL *)urlMMProj
             verifyModels:(BOOL)verifyModels
               contextLen:(uint32_t)ctxLen
                     temp:(float)temp
                     seed:(uint32_t)seed
                   target:(id)aTarget
                 selector:(SEL)aSelector;

+ (id)wrapperWithModel:(NSString *)pathModel
             andMMProj:(NSString *)pathMMProj
          verifyModels:(BOOL)verifyModels
            contextLen:(uint32_t)ctxLen
                  temp:(float)temp
                  seed:(uint32_t)seed
                target:(id)aTarget
              selector:(SEL)aSelector;

- (id)initWithModelURL:(NSURL *)urlModel
          andMMProjURL:(NSURL *)urlMMProj
          verifyModels:(BOOL)verifyModels
            contextLen:(uint32_t)ctxLen
                  temp:(float)temp
                  seed:(uint32_t)seed
                target:(id)aTarget
              selector:(SEL)aSelector;

+ (ModelInfo *)modelInfoForFileURL:(NSURL *)urlFile;

+ (NSString *)titleForModelURL:(NSURL *)urlModel;

- (NSString *)title;

+ (NSArray *)samplePrompts;

+ (NSArray *)clearContextPrompts;

- (NSString *)supportedMediaTypes;

+ (NSUInteger)maxSupportedMedia;

- (NSArray *)modelPair;

- (BOOL)modelLoaded;

- (BOOL)loadMedia:(NSURL *)urlMedia;

- (BOOL)isSupportedAudioURL:(NSURL *)urlFile;

- (BOOL)isSupportedImageURL:(NSURL *)urlFile;

+ (NSURL *)convertHEICtoTmpJPG:(NSURL *)urlInput
                      withLoss:(CGFloat)loss;

+ (NSURL *)convertWEBPtoTmpJPG:(NSURL *)urlInput;

+ (CGImageRef) rotateImage:(CGImageRef)imageRef
             toOrientation:(NSInteger)orientation;

- (BOOL)generate:(NSString *)prompt;

- (BOOL)isBusy;

- (BOOL)isInterrupted;

- (BOOL)stop;

- (BOOL)clearHistory;

+ (NSArray *)validateModelAndProjectorURLs:(NSArray *)arrModels;

+ (NSString *)appleSiliconModel:(BOOL)bDetailed;

+ (NSString *)listKnownModels;

@end

