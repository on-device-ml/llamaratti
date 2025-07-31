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

// llama.cpp Arguments
extern NSString * const gArgModel;
extern NSString * const gArgMMProj;
extern NSString * const gArgTemp;
extern NSString * const gArgCtxSize;

extern NSString *gGGUFExt;

extern NSString *gMMProj;
extern NSString *gMediaTemplate;


// LLM temperature
extern const float LLAMA_DEFAULT_TEMP;
extern const float LLAMA_MIN_TEMP;
extern const float LLAMA_MAX_TEMP;

// LLM context length
extern const uint32_t LLAMA_DEFAULT_CTXLEN;

// LLM Seed
#define LLAMA_DEFAULT_SEED          0xFFFFFFFF

// Prompt Length
#define MAX_PROMPT_LENGTH           20000
#define MAX_PROMPT_DISPLAY_LENGTH   100

// Maximum length of arguments for llama.cpp
#define MAX_LLAMA_ARGS_LEN          4096

// Media
#define MAX_SUPPORTED_MEDIA         15

// Macros
#define isMMProj(urlFile) ([[[urlFile path] lastPathComponent] containsString:gMMProj])
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
        andAdditionalArgs:(NSString *)additionalArgs
             verifyModels:(BOOL)verifyModels
                   target:(id)aTarget
                 selector:(SEL)aSelector;

- (id)initWithModelURL:(NSURL *)urlModel
          andMMProjURL:(NSURL *)urlMMProj
     andAdditionalArgs:(NSString *)additionalArgs
          verifyModels:(BOOL)verifyModels
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

- (BOOL)loadMedia:(NSURL *)urlMedia
 useSecurityScope:(BOOL)useSecurityScope;

- (BOOL)isSupportedAudioURL:(NSURL *)urlFile;

- (BOOL)isSupportedImageURL:(NSURL *)urlFile;

- (BOOL)generate:(NSString *)prompt;

- (BOOL)isBusy;

- (BOOL)isInterrupted;

- (BOOL)stop;

- (BOOL)clearHistory;

+ (NSArray *)validateModelAndProjectorURLs:(NSArray *)arrModels;

+ (NSString *)appleSiliconModel:(BOOL)bDetailed;

+ (NSString *)listKnownModels;

@end

