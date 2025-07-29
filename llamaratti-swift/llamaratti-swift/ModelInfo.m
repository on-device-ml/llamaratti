/**
 * @file ModelInfo.m
 *
 * @brief Used to store information about model/projection pairs
 * for multimodal llama.cpp
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "ModelInfo.h"
#import "Shared.h"
#import "LlamarattiWrapper.h"
#import "Utils.h"

@implementation ModelInfo {
}

/**
 * @brief Creates and initializes an instance of ModelInfo
 *
 * @param modelTitle the title of the model
 * @param modelFilename the name of the model file
 * @param modelHash the sha256 hash of the model file
 * @param mmprojFilename the name of the model projection file
 * @param mmprojHash the sha256 hash of the model projection file
 * @param dictCtxLen the dictionary used to lookup context length based on memory
 * @param temp the temperature to use with this model
 *
 * @return the initialized object, or nil on error
 *
 */
+(id)modelInfoWithTitle:(NSString *)modelTitle
              withModel:(NSString *)modelFilename
          withModelHash:(NSString *)modelHash
             withMMProj:(NSString *)mmprojFilename
         withMMProjHash:(NSString *)mmprojHash
         withDictCtxLen:(NSDictionary *)dictCtxLen
               withTemp:(float)temp
     withAdditionalArgs:(NSString *)additionArgs {
         
    ModelInfo *mi=[[ModelInfo alloc] initWithTitle:modelTitle
                                         withModel:modelFilename
                                     withModelHash:modelHash
                                        withMMProj:mmprojFilename
                                    withMMProjHash:mmprojHash
                                    withDictCtxLen:dictCtxLen
                                          withTemp:temp
                                withAdditionalArgs:additionArgs];
    return mi;
}

/**
 * @brief Initializes an instance of ModelInfo
 *
 * @return the initialized object, or nil on error
 *
 */
-(id)init {
    
    if ( self=[super init] ) {

        _modelTitle=@"";
        _modelFilename=@"";
        _mmprojFilename=@"";
        _modelHash=@"";
        _mmprojHash=@"";
        _dictCtxLen=@{};
        _temp=LLAMA_DEFAULT_TEMP;
    }
    return self;
}

/**
 * @brief Initializes an instance of ModelInfo
 *
 * @param modelTitle the title of the model
 * @param modelFilename the name of the model file
 * @param modelHash the sha256 hash of the model file
 * @param mmprojFilename the name of the model projection file
 * @param mmprojHash the sha256 hash of the model projection file
 * @param dictCtxLen the dictionary used to lookup context length based on memory
 * @param temp the temperature to use with this model
 * @param additionalArgs and additional arguments needed by the model
 *
 * @return the initialized object, or nil on error
 *
 */
-(id)initWithTitle:(NSString *)modelTitle
         withModel:(NSString *)modelFilename
     withModelHash:(NSString *)modelHash
        withMMProj:(NSString *)mmprojFilename
    withMMProjHash:(NSString *)mmprojHash
    withDictCtxLen:(NSDictionary *)dictCtxLen
          withTemp:(float)temp
withAdditionalArgs:(NSString *)additionalArgs {
    
    if ( self=[super init] ) {

        _modelTitle=modelTitle;
        _modelFilename=modelFilename;
        _modelHash=modelHash;
        _mmprojFilename=mmprojFilename;
        _mmprojHash=mmprojHash;
        _dictCtxLen=dictCtxLen;
        _temp=temp;
        _additionalArgs=additionalArgs;
        _isVerified=NO;
    }
    return self;
}

/**
 * @brief Returns the recommended context length for this model based on the hardware
 *
 * @return recommended context length
 *
 */
- (uint32_t)ctxLen {
    
    uint64_t totalMemoryBytes=0;
    if ( ![Utils getTotalSystemMemory:&totalMemoryBytes] ) {
        return LLAMA_DEFAULT_CTXLEN;
    }
    uint64_t totalMemory = (uint64_t)totalMemoryBytes / (1024.0 * 1024.0 * 1024.0);
    
    // Can we get the default context length for this model?
    NSNumber *numDefaultCtxLen = [_dictCtxLen objectForKey:@0];
    if ( !isValidNSNumber(numDefaultCtxLen) ) {
        return LLAMA_DEFAULT_CTXLEN;
    }
    uint32_t defaultCtxLen=(uint32_t)[numDefaultCtxLen unsignedIntegerValue];
    
    // Do we know of this memory config?
    NSNumber *numKey=[NSNumber numberWithInteger:totalMemory];
    NSNumber *numCtxLen=[_dictCtxLen objectForKey:numKey];
    if ( isValidNSNumber(numCtxLen) ) {
        defaultCtxLen=(uint32_t)[numCtxLen unsignedIntegerValue];
    }
    
    return defaultCtxLen;
}

/**
 * @brief Assigns a custom context length for this model
 *
 */
- (void)setCtxLen:(uint32_t)ctxLen {
    
    self.ctxLen=ctxLen;
}

@end

