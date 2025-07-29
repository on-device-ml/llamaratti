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
 * References:
 *
 * @see https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md
 * @see https://huggingface.co/collections/ggml-org/multimodal-ggufs-68244e01ff1f39e5bebeeedc
 * @see https://github.com/ggml-org/llama.cpp/discussions/5141
 * @see https://huggingface.co/TheBloke
 * @see https://simonwillison.net/2025/May/10/llama-cpp-vision/
 *
 */

#import <string.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>
#import <AppKit/AppKit.h>
#import <ImageIO/ImageIO.h>
#import <CoreGraphics/CoreGraphics.h>

#import "LlamarattiWrapper.h"

#include "ggml.h"
#include "lr-mtmd-cli.h"
#include "lr-mtmd-cli-callback.h"

#include "Shared.h"
#include "Errors.h"
#include "Utils.h"
#include "ArgManager.h"

#pragma mark Globals

// LLM temperature
const float LLAMA_DEFAULT_TEMP = 0.2f;

// LLM context length
const uint32_t LLAMA_DEFAULT_CTXLEN = 2048;

// llama.cpp Arguments
NSString * const gArgModel=@"model";
NSString * const gArgMMProj=@"mmproj";
NSString * const gArgTemp=@"temp";
NSString * const gArgCtxSize=@"ctx-size";

// Extension
NSString *gGGUFExt=@"GGUF";

// Multimedia projection files
NSString *gMMProj=@"mmproj";

// Template for temporary files
NSString *gMediaTemplate=@"lr-media-";

// "Known" model/projection pairs
NSArray *gArrModelInfo;

// Sample prompts
NSArray *gArrSamplePrompts;

// "Known" Mac Devices
NSMutableDictionary *gArrMacDeviceInfo;

// Clear context prompts
NSArray *gArrClearContextPrompts;

// Supported file types for drag & drop
NSArray *gArrSuppAudioTypes;
NSArray *gArrSuppVisionTypes;

// Used by C callback below to access Obj-C selector
id      gTarget;
SEL     gSelector;

/**
 * @brief C callback function that calls our Obj-C/Swift selector
 *
 * @param vmtmd an lr_mtmd_cli instance
 * @param type the event type
 * @param text the text piece from the text generation
 *
 * @return the status of the operation
 *
 */
bool llama_multimodal_callback(void *vmtmd, LlamarattiEvent type, const char *text) {
    
    // Did we get the parameters we need?
    if ( vmtmd == NULL ||
         gTarget == nil ||
         gSelector == NULL ) {
        
        // No, outta here...
        NSLog(gErrLrtParams,__func__);
        return false;
    }
    
    lr_mtmd_cli *mtmd = (lr_mtmd_cli *)vmtmd;
    
    // Call our Objective-C selector
    NSMutableArray *arrParms=[NSMutableArray arrayWithObjects:
                                    [NSNumber numberWithInt:type],
                                    safeNSSFromChar(text),
                                    nil];
    [gTarget performSelectorOnMainThread:gSelector
                              withObject:arrParms
                           waitUntilDone:YES];
    
    // Keep generating?
    return mtmd->is_interrupted();
}

@implementation LlamarattiWrapper
{
    lr_mtmd_cli *_mtmd;
}

/**
 * @brief Initializes arrays used by the wrapper when the class is used
 *
 */
+ (void)initialize {
    
    if ( self == [LlamarattiWrapper class] ) {
        
        [self initArrays];
    }
}

/**
 * @brief Initializes arrays used by the wrapper when the class is used
 *
 * @return the status of the operation
 *
 */
+ (BOOL)initArrays {
    
    /**
     * @brief Known multimodal models array used by wrapper. Eases model selection & validation.
     *
     * @todo Keep updated with latest multimodal model pairs
     *
     * @note Use "llama-lookup-stats -m <model.GGUF>" "context_length" for model info.

     * @note To generate model hashes, use "sha256 <model.GGUF>"
     *
     * @ref https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md
     * @ref https://huggingface.co/collections/ggml-org/multimodal-ggufs-68244e01ff1f39e5bebeeedc
     *
     */
    gArrModelInfo=[NSMutableArray arrayWithObjects:
        
           [ModelInfo modelInfoWithTitle:@"Gemma 3 4B"
                               withModel:@"unsloth_gemma-3-4b-it-GGUF_gemma-3-4b-it-UD-Q4_K_XL.gguf"
                           withModelHash:@"c05bd745da387bf9200ffa7070665305d886d5093638c4f8b6c3862ea26ca8aa"
                              withMMProj:@"unsloth_gemma-3-4b-it-GGUF_mmproj-F16.gguf"
                          withMMProjHash:@"731199e016ec5f227b8293fef839899472e0ee4c51adf5f9e5cb66f6558fa142"
                          withDictCtxLen:@{@0:@2048,@16:@65536,@36:@131072,@64:@131072,@128:@131072}
                                withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],
           
           [ModelInfo modelInfoWithTitle:@"Gemma 3 12B"
                               withModel:@"ggml-org_gemma-3-12b-it-GGUF_gemma-3-12b-it-Q4_K_M.gguf"
                           withModelHash:@"7bb69bff3f48a7b642355d64a90e481182a7794707b3133890646b1efa778ff5"
                              withMMProj:@"ggml-org_gemma-3-12b-it-GGUF_mmproj-model-f16.gguf"
                          withMMProjHash:@"30c02d056410848227001830866e0a269fcc28aaf8ca971bded494003de9f5a5"
                          withDictCtxLen:@{@0:@2048,@16:@65536,@36:@131072,@64:@131072,@128:@131072}
                                withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],
           
           [ModelInfo modelInfoWithTitle:@"Gemma 3 27B"
                               withModel:@"ggml-org_gemma-3-27b-it-GGUF_gemma-3-27b-it-Q4_K_M.gguf"
                           withModelHash:@"edc9aff4d811a285b9157618130b08688b0768d94ee5355b02dc0cb713012e15"
                              withMMProj:@"ggml-org_gemma-3-27b-it-GGUF_mmproj-model-f16.gguf"
                          withMMProjHash:@"54cb61c842fe49ac3c89bc1a614a2778163eb49f3dec2b90ff688b4c0392cb48"
                          withDictCtxLen:@{@0:@2048,@16:@65536,@36:@65536,@64:@65536,@128:@65536}
                                withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],
           
           [ModelInfo modelInfoWithTitle:@"Llama 4 Scout 17B"
                               withModel:@"ggml-org_Llama-4-Scout-17B-16E-Instruct-GGUF_Llama-4-Scout-17B-16E-Instruct-UD-IQ1_S.gguf"
                           withModelHash:@"27f0722ff2c4cc39f30f004877d0738c209c15d3a85f7415333bc7a11e50210b"
                              withMMProj:@"ggml-org_Llama-4-Scout-17B-16E-Instruct-GGUF_mmproj-Llama-4-Scout-17B-16E-Instruct-f16.gguf"
                          withMMProjHash:@"a7eec12068ae70f993fbba6eb350c095727be20f7a6ecbe6e431940c1a8823fb"
                          withDictCtxLen:@{@0:@2048}
                                withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],
           
           [ModelInfo modelInfoWithTitle:@"Mistral 3.1 24B"
                               withModel:@"ggml-org_Mistral-Small-3.1-24B-Instruct-2503-GGUF_Mistral-Small-3.1-24B-Instruct-2503-UD-IQ2_M.gguf"
                           withModelHash:@"fadb5c04d1140ac878f8e59187853258a2c0e4e127ddcb19cc76a111a9450b3a"
                              withMMProj:@"ggml-org_Mistral-Small-3.1-24B-Instruct-2503-GGUF_mmproj-Mistral-Small-3.1-24B-Instruct-2503-Q8_0.gguf"
                          withMMProjHash:@"6de5bee5ce4950fa362b97b875d0ffd1ae7e058c399834c1d0d1f7b014714fb4"
                          withDictCtxLen:@{@0:@2048,@16:@4096,@36:@65536,@64:@131072,@128:@131072,@192:@131072}
                                withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],
           
           [ModelInfo modelInfoWithTitle:@"Pixtral 12B"
                               withModel:@"ggml-org_pixtral-12b-GGUF_pixtral-12b-Q4_K_M.gguf"
                           withModelHash:@"8c87eb351c62c4f1d2e98d3d4eed7c1674a4f1869bfb8fa6c9afa0dbbca72147"
                              withMMProj:@"ggml-org_pixtral-12b-GGUF_mmproj-pixtral-12b-Q8_0.gguf"
                          withMMProjHash:@"5504fe00067629053e6f99abac05f628c653a50394f4929bcc185bc80a10daf4"
                          withDictCtxLen:@{@0:@32768}
                                withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],
           
            [ModelInfo modelInfoWithTitle:@"InternVL 2 1B"
                                withModel:@"ggml-org_InternVL2_5-1B-GGUF_InternVL2_5-1B-Q8_0.gguf"
                            withModelHash:@"61c02b37762eeb1ea86427541bdc0696ea9b1cc676ccbf7966c187678bdebb6f"
                               withMMProj:@"ggml-org_InternVL2_5-1B-GGUF_mmproj-InternVL2_5-1B-Q8_0.gguf"
                           withMMProjHash:@"bab5e4294eda170db20c361f087a4c568c97380c8982d2404dfb19a9d294b72f"
                           withDictCtxLen:@{@0:@32768}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],
            
            [ModelInfo modelInfoWithTitle:@"InternVL 3 8B"
                                withModel:@"ggml-org_InternVL3-8B-Instruct-GGUF_InternVL3-8B-Instruct-Q4_K_M.gguf"
                            withModelHash:@"645b5db5754711f90adcc85dd99217a66d1306c97c2a2d3ae69071e3dea7a42e"
                               withMMProj:@"ggml-org_InternVL3-8B-Instruct-GGUF_mmproj-InternVL3-8B-Instruct-Q8_0.gguf"
                           withMMProjHash:@"de6a246f6b2ec51e5863e987c994c7b6d3edfa742b8d0ccf115ac4c67eb6b7aa"
                           withDictCtxLen:@{@0:@8192,@36:@32768,@64:@32768,@128:@32768,@192:@32768}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],
                   
            [ModelInfo modelInfoWithTitle:@"SmolVLM Instruct"
                               withModel:@"ggml-org_SmolVLM-Instruct-GGUF_SmolVLM-Instruct-Q4_K_M.gguf"
                           withModelHash:@"dc80966bd84789de64115f07888939c03abb1714d431c477dfb405517a554af5"
                              withMMProj:@"ggml-org_SmolVLM-Instruct-GGUF_mmproj-SmolVLM-Instruct-Q8_0.gguf"
                          withMMProjHash:@"86b84aa7babf1ab51a6366d973b9d380354e92c105afaa4f172cc76d044da739"
                          withDictCtxLen:@{@0:@16384}
                                withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],
                  
        [ModelInfo modelInfoWithTitle:@"SmolVLM2 Instruct 256M"
                            withModel:@"ggml-org_SmolVLM-256M-Instruct-GGUF_SmolVLM-256M-Instruct-Q8_0.gguf"
                        withModelHash:@"2a31195d3769c0b0fd0a4906201666108834848db768af11de1d2cef7cd35e65"
                           withMMProj:@"ggml-org_SmolVLM-256M-Instruct-GGUF_mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"
                       withMMProjHash:@"7e943f7c53f0382a6fc41b6ee0c2def63ba4fded9ab8ed039cc9e2ab905e0edd"
                       withDictCtxLen:@{@0:@16384}
                             withTemp:LLAMA_DEFAULT_TEMP
                   withAdditionalArgs:@"--repeat-penalty=1.5"],

         [ModelInfo modelInfoWithTitle:@"SmolVLM2 Instruct 500M"
                             withModel:@"ggml-org_SmolVLM-500M-Instruct-GGUF_SmolVLM-500M-Instruct-Q8_0.gguf"
                         withModelHash:@"9d4612de6a42214499e301494a3ecc2be0abdd9de44e663bda63f1152fad1bf4"
                            withMMProj:@"ggml-org_SmolVLM-500M-Instruct-GGUF_mmproj-SmolVLM-500M-Instruct-Q8_0.gguf"
                        withMMProjHash:@"d1eb8b6b23979205fdf63703ed10f788131a3f812c7b1f72e0119d5d81295150"
                        withDictCtxLen:@{@0:@16384}
                              withTemp:LLAMA_DEFAULT_TEMP
                    withAdditionalArgs:nil],

          [ModelInfo modelInfoWithTitle:@"SmolVLM2 Instruct 2.2B"
                             withModel:@"ggml-org_SmolVLM2-2.2B-Instruct-GGUF_SmolVLM2-2.2B-Instruct-Q4_K_M.gguf"
                         withModelHash:@"0cf76814555b8665149075b74ab6b5c1d428ea1d3d01c1918c12012e8d7c9f58"
                            withMMProj:@"ggml-org_SmolVLM2-2.2B-Instruct-GGUF_mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf"
                        withMMProjHash:@"ae07ea1facd07dd3230c4483b63e8cda96c6944ad2481f33d531f79e892dd024"
                        withDictCtxLen:@{@0:@16384}
                              withTemp:LLAMA_DEFAULT_TEMP
                     withAdditionalArgs:nil],

           [ModelInfo modelInfoWithTitle:@"SmolVLM2 Video Instruct 250M"
                              withModel:@"ggml-org_SmolVLM2-256M-Video-Instruct-GGUF_SmolVLM2-256M-Video-Instruct-Q8_0.gguf"
                          withModelHash:@"af7ce9951a2f46c4f6e5def253e5b896ca5e417010e7a9949fdc9e5175c27767"
                             withMMProj:@"ggml-org_SmolVLM2-256M-Video-Instruct-GGUF_mmproj-SmolVLM2-256M-Video-Instruct-Q8_0.gguf"
                         withMMProjHash:@"d34913a588464ff7215f086193e0426a4f045eaba74456ee5e2667d8ed6798b1"
                         withDictCtxLen:@{@0:@16384}
                               withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],

            [ModelInfo modelInfoWithTitle:@"SmolVLM2 Video Instruct 500M"
                               withModel:@"ggml-org_SmolVLM2-500M-Video-Instruct-GGUF_SmolVLM2-500M-Video-Instruct-Q8_0.gguf"
                           withModelHash:@"6f67b8036b2469fcd71728702720c6b51aebd759b78137a8120733b4d66438bc"
                              withMMProj:@"ggml-org_SmolVLM2-500M-Video-Instruct-GGUF_mmproj-SmolVLM2-500M-Video-Instruct-Q8_0.gguf"
                          withMMProjHash:@"921dc7e259f308e5b027111fa185efcbf33db13f6e35749ddf7f5cdb60ef520b"
                          withDictCtxLen:@{@0:@16384}
                                withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],
                  
           [ModelInfo modelInfoWithTitle:@"Qwen2 VL 2B"
                              withModel:@"ggml-org_Qwen2-VL-2B-Instruct-GGUF_Qwen2-VL-2B-Instruct-Q4_K_M.gguf"
                          withModelHash:@"5745685d2e607a82a0696c1118e56a2a1ae0901da450fd9cd4f161c6b62867d7"
                             withMMProj:@"ggml-org_Qwen2-VL-2B-Instruct-GGUF_mmproj-Qwen2-VL-2B-Instruct-Q8_0.gguf"
                         withMMProjHash:@"a0ad91f00a7a80dcf84d719a61b00ee2e07b71794f4ee2dfa81a254621a8c418"
                          withDictCtxLen:@{@0:@32768}
                                withTemp:LLAMA_DEFAULT_TEMP
                      withAdditionalArgs:nil],

            [ModelInfo modelInfoWithTitle:@"Qwen Omni 2.5 3B"
                               withModel:@"ggml-org_Qwen2.5-Omni-3B-GGUF_Qwen2.5-Omni-3B-Q4_K_M.gguf"
                           withModelHash:@"fac13cb507141119bcc3a6c92e75437542448f2b5b38a06a5f6b2241e59199f9"
                              withMMProj:@"ggml-org_Qwen2.5-Omni-3B-GGUF_mmproj-Qwen2.5-Omni-3B-Q8_0.gguf"
                          withMMProjHash:@"4e6c816cd33f7298d07cb780c136a396631e50e62f6501660271f8c6e302e565"
                           withDictCtxLen:@{@0:@32768}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],

            [ModelInfo modelInfoWithTitle:@"Qwen Omni 2.5 7B"
                                withModel:@"ggml-org_Qwen2.5-Omni-7B-GGUF_Qwen2.5-Omni-7B-Q4_K_M.gguf"
                            withModelHash:@"09883dff531dc56923a041c9c99c7c779e26ffde32caa83adeeb7502ec3b50fe"
                               withMMProj:@"ggml-org_Qwen2.5-Omni-7B-GGUF_mmproj-Qwen2.5-Omni-7B-Q8_0.gguf"
                           withMMProjHash:@"4a7bc5478a2ec8c5d186d63532eb22e75b79ba75ec3c0ce821676157318ef4ad"
                           withDictCtxLen:@{@0:@32768}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],

            [ModelInfo modelInfoWithTitle:@"MobileVLM 3B"
                                withModel:@"guinmoon_MobileVLM-3B-GGUF_MobileVLM-3B-Q4_K_M.gguf"
                            withModelHash:@"22ae82a42706020e8980178f2cf7b0e1c62476c03ef15886fc7a8585ab088665"
                               withMMProj:@"guinmoon_MobileVLM-3B-GGUF_MobileVLM-3B-mmproj-f16.gguf"
                           withMMProjHash:@"c8dda06f00ae031c5428591603a4c3a27dbbf4414a1e269ede4d1c450ca31d51"
                           withDictCtxLen:@{@0:@2048}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:@"--chat-template deepseek"],

            [ModelInfo modelInfoWithTitle:@"Llava v1.5 7B"
                                withModel:@"second-state_Llava-v1.5-7B-GGUF_llava-v1.5-7b-Q4_K_M.gguf"
                            withModelHash:@"2687b20ac8b7a23f6c70296d5b1e7f908fef2ce4769ecdebd1bb9503528a75bf"
                               withMMProj:@"second-state_Llava-v1.5-7B-GGUF_llava-v1.5-7b-mmproj-model-f16.gguf"
                           withMMProjHash:@"50da4e5b0a011615f77686f9b02613571e65d23083c225e107c08c3b1775d9b1"
                           withDictCtxLen:@{@0:@4096}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:@"--chat-template vicuna"],

            [ModelInfo modelInfoWithTitle:@"Llava 1.6 Mistral 7B"
                                withModel:@"cjpais_llava-1.6-mistral-7b-gguf_llava-1.6-mistral-7b.Q6_K.gguf"
                            withModelHash:@"31826170ffa2e8080bbcd74cac718f906484fd5a59895550ef94c1baa4997595"
                               withMMProj:@"cjpais_llava-1.6-mistral-7b-gguf_mmproj-model-f16.gguf"
                           withMMProjHash:@"00205ee8a0d7a381900cd031e43105f86aa0d8c07bf329851e85c71a26632d16"
                           withDictCtxLen:@{@0:@8192}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],

            [ModelInfo modelInfoWithTitle:@"MiniCPM v2.6"
                                withModel:@"openbmb_MiniCPM-V-2_6-gguf_ggml-model-Q4_K_M.gguf"
                            withModelHash:@"3a4078d53b46f22989adbf998ce5a3fd090b6541f112d7e936eb4204a04100b1"
                               withMMProj:@"openbmb_MiniCPM-V-2_6-gguf_mmproj-model-f16.gguf"
                           withMMProjHash:@"4485f68a0f1aa404c391e788ea88ea653c100d8e98fe572698f701e5809711fd"
                           withDictCtxLen:@{@0:@32768}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],

            [ModelInfo modelInfoWithTitle:@"Moondream 2"
                                withModel:@"ggml-org_moondream2-20250414-GGUF_moondream2-text-model-f16_ct-vicuna.gguf"
                            withModelHash:@"917dfd3794e8e190e4c8b3c979a6823f7e6713592fae4362fb6102a36e9c76d7"
                               withMMProj:@"ggml-org_moondream2-20250414-GGUF_moondream2-mmproj-f16-20250414.gguf"
                           withMMProjHash:@"4cc1cb3660d87ff56432ebeb7884ad35d67c48c7b9f6b2856f305e39c38eed8f"
                           withDictCtxLen:@{@0:@2048}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],

            [ModelInfo modelInfoWithTitle:@"Ultravox 3.2 1B"
                                withModel:@"ggml-org_ultravox-v0_5-llama-3_2-1b-GGUF_Llama-3.2-1B-Instruct-Q4_K_M.gguf"
                            withModelHash:@"6f85a640a97cf2bf5b8e764087b1e83da0fdb51d7c9fab7d0fece9385611df83"
                               withMMProj:@"ggml-org_ultravox-v0_5-llama-3_2-1b-GGUF_mmproj-ultravox-v0_5-llama-3_2-1b-f16.gguf"
                           withMMProjHash:@"b34dde1835752949d6b960528269af93c92fec91c61ea0534fcc73f96c1ed8b2"
                           withDictCtxLen:@{@0:@8192,@16:@32768,@36:@32768,@64:@32768,@128:@32768,@192:@32768}
                                 withTemp:LLAMA_DEFAULT_TEMP
                       withAdditionalArgs:nil],
            
           // Add new here...
//           [ModelInfo modelInfoWithTitle:@""
//                               withModel:@""
//                           withModelHash:@""
//                              withMMProj:@""
//                          withMMProjHash:@""
//                          withDictCtxLen:LLM_CTXLEN_DEFAULT
//                                withTemp:LLM_TEMP_DEFAULT
//                      withAdditionalArgs:nil]],
                                      
        nil];

    /**
     * @brief Sample prompts available in the right click menu
     *
     * @todo Keep updated with additional prompts as needed
     * @todo Persist in updateable text file
     *
     */
    gArrSamplePrompts=[NSMutableArray arrayWithObjects:
        
        // Handled by the application
        @"Clear Context",

        // Handled by the model
        @"Hi There :)",
        @"Yes",
        
        @"Describe what you see in this image",

        @"Describe this image",
        @"Describe all images",
 
        @"Describe this scene",
        @"Describe all scenes",
 
        @"Describe this room",
        @"Describe all the objects in this room",

        @"Describe this newspaper",

        @"Describe this scene as an early 1800s explorer",
        @"What time of day is it in this scene?",
                       
        @"Describe this audio",
        @"Describe all audio",
   
        @"Where is this?",
        @"Who is this celebrity?",
                       
        @"Can you explain in detail?",
        @"Summarize this:",
        @"Explain this in more detail:",
                                         
        @"Can you suggest a recipe for dinner?",
        @"Show me a recipe for a delicious dessert?",
                       
        nil];
    
    // Clear context prompts
    gArrClearContextPrompts=[NSMutableArray arrayWithObjects:
        
        @"clear",
        @"clear context",
        @"clear all",
        @"reset",
        @"reset all",
        @"reset context",
                             
        nil];
    
    /**
     * @brief Supported file types for drag & drop
     *
     * @todo Update with latest llama.cpp mtmd supported file types
     *
     */
    gArrSuppAudioTypes=[NSArray arrayWithObjects:@"wav", @"mp3", @"flac",nil];
    gArrSuppVisionTypes=[NSArray arrayWithObjects:@"heic", @"jpg", @"jpeg", @"png", @"bmp", @"gif", @"webp", nil];
    
    /**
     * @brief Mac Silicon Device Model Info
     *
     * @todo Update with latest Apple Silicon devices
     *
     * @ref https://support.apple.com/en-us/108052
     * @ref https://everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
     *
     */
    gArrMacDeviceInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                      
               // M4
               @"14\" MacBook Pro (M4) 2024",                   @"Mac16,1",
               @"24\" iMac (M4, two‑port) 2024",                @"Mac16,2",
               @"24\" iMac (M4, four‑port) 2024",               @"Mac16,3",
               @"16\" MacBook Pro (M4 Max) 2024",               @"Mac16,5",
               @"14\" MacBook Pro (M4 Max) 2024",               @"Mac16,6",
               @"16\" MacBook Pro (M4 Pro) 2024",               @"Mac16,7",
               @"14\" MacBook Pro (M4 Pro) 2024",               @"Mac16,8",
               @"Mac Studio (M3 Ultra / M4 Max) 2025",          @"Mac16,9",
               @"Mac mini (M4) 2024",                           @"Mac16,10",
               @"Mac mini (M4 Pro) 2024",                       @"Mac16,11",
               @"13\" MacBook Air (M4) 2025",                   @"Mac16,12",
               @"15\" MacBook Air (M4) 2025",                   @"Mac16,13",

               // M3
               @"14\" MacBook Pro (M3) 2023",                   @"Mac15,3",
               @"24\" iMac (M3, two-port) 2023",                @"Mac15,4",
               @"24\" iMac (M3, four-port) 2023",               @"Mac15,5",
               @"14\" MacBook Pro (M3 Pro) 2023",               @"Mac15,6",
               @"16\" MacBook Pro (M3 Pro) 2023",               @"Mac15,7",
               @"14\" MacBook Pro (M3 Max) 2023",               @"Mac15,8",
               @"16\" MacBook Pro (M3 Max) 2023",               @"Mac15,9",
               @"14\" MacBook Pro (highest M3 Max spec) 2023",  @"Mac15,10",
               @"16\" MacBook Pro (highest M3 Max spec) 2023",  @"Mac15,11",
               @"13\" MacBook Air (M3) 2024",                   @"Mac15,12",
               @"15\" MacBook Air (M3) 2024",                   @"Mac15,13",

               // M2
               @"13\" MacBook Air (M2) 2022",                   @"Mac14,2",
               @"Mac mini (M2) 2023",                           @"Mac14,3",
               @"14 \"MacBook Pro (M2 Max) 2023",               @"Mac14,5",
               @"16\" MacBook Pro (M2 Max) 2023",               @"Mac14,6",
               @"13\" MacBook Pro (M2) 2022",                   @"Mac14,7",
               @"Mac Pro (M2 Ultra) 2023",                      @"Mac14,8",
               @"14\" MacBook Pro (M2 Pro) 2023",               @"Mac14,9",
               @"16\" MacBook Pro (M2 Pro) 2023",               @"Mac14,10",
               @"Mac mini (M2 Pro) 2023",                       @"Mac14,12",
               @"Mac Studio (M2 Max) 2023",                     @"Mac14,13",
               @"Mac Studio (M2 Ultra) 2023",                   @"Mac14,14",
               @"15\" MacBook Air (M2) 2023",                   @"Mac14,15",

               // M1
               @"16\" MacBook Pro (M1 Pro) 2021",               @"MacBookPro18,1",
               @"16\" MacBook Pro (M1 Max) 2021",               @"MacBookPro18,2",
               @"14\" MacBook Pro (M1 Pro) 2021",               @"MacBookPro18,3",
               @"14\" MacBook Pro (M1 Max) 2021",               @"MacBookPro18,4",

               @"13\" MacBook Pro (M1) 2020",                   @"MacBookPro17,1",
            
               // Intel are 16, and below...
               
               nil];
    
    return YES;
}

/**
 * @brief Creates and initializes an instance of the wrapper
 *
 * @param urlModel the URL path to the model file
 * @param urlMMProj the URL path to the model projection file
 * @param additionalArgs additional arguments for llama.cpp
 * @param verifyModels whether to perform a hash check on the files
 * @param aTarget the target selector object
 * @param aSelector the target selector method
 *
 * @return an instance of the wrapper, or nil on error
 *
 */
+ (id)wrapperWithModelURL:(NSURL *)urlModel
             andMMProjURL:(NSURL *)urlMMProj
        andAdditionalArgs:(NSString *)additionalArgs
             verifyModels:(BOOL)verifyModels
                   target:(id)aTarget
                 selector:(SEL)aSelector {
    
    LlamarattiWrapper *lw=[[LlamarattiWrapper alloc]
                             initWithModelURL:urlModel
                                 andMMProjURL:urlMMProj
                           andAdditionalArgs:additionalArgs
                                 verifyModels:verifyModels
                                       target:aTarget
                                     selector:aSelector];
    return lw;
}

/**
 * @brief Initializes an instance of the wrapper
 *
 * @param urlModel the URL path to the model file
 * @param urlMMProj the URL path to the model projection file
 * @param additionalArgs additional arguments (optional)
 * @param verifyModels whether to perform a hash check on the files
 * @param aTarget the target selector object to receive llama.cpp notifications
 * @param aSelector the target selector method to receive llama.cpp notifications

 * @return an instance of the wrapper, or nil on error
 *
 */
- (id)initWithModelURL:(NSURL *)urlModel
          andMMProjURL:(NSURL *)urlMMProj
     andAdditionalArgs:(NSString *)additionalArgs
          verifyModels:(BOOL)verifyModels
                target:(id)aTarget
              selector:(SEL)aSelector {

    // Did we get the parameters we need?
    if ( !isValidFileNSURL(urlModel) ||
         !isValidFileNSURL(urlMMProj) ||
         // Optional: additionalArgs
         !aTarget ||
         !aSelector ) {
        
        return nil;
    }
    
    if (self=[super init]) {
        
        // Do we already have an mtmd-client instance?
        if ( !_mtmd ) {
            // No, create a new one
            _mtmd=new lr_mtmd_cli();
        }
        
        gTarget=aTarget;
        gSelector=aSelector;
        _urlModel=nil;
        _urlMMProj=nil;

        // Can we start accessing our security-scoped Model Pair?
        NSArray *arrModelPair=@[urlModel,urlMMProj];
        BOOL bSuccess = [Utils startAccessingSecurityScopedURLs:arrModelPair];
        if ( !bSuccess ) {
            return nil;
        }

        // Yes, do we know of this model?
        ModelInfo *mi=[LlamarattiWrapper modelInfoForFileURL:urlModel];
        if ( mi ) {
            
            // Has it been verified?
            if ( verifyModels && ![mi isVerified] ) {
                
                // Yes, is the model valid?
                BOOL bResult=[Utils checkSHA256ForURL:urlModel
                                             withHash:[mi modelHash]];
                if ( !bResult ) {
                    [Utils stopAccessingSecurityScopedURLs:arrModelPair];
                    NSLog(gErrLrtHashCheckFail,
                          __func__,
                          [urlModel path]);
                    return nil;
                }
                
                // Yes, is the mmproj valid?
                bResult=[Utils checkSHA256ForURL:urlMMProj
                                        withHash:[mi mmprojHash]];
                if ( !bResult ) {
                    [Utils stopAccessingSecurityScopedURLs:arrModelPair];
                    NSLog(gErrLrtHashCheckFail,
                          __func__,
                          [urlModel path]);
                    return nil;
                }
                
                // Prevents re-verifying for this session
                [mi setIsVerified:YES];
            }
        }

        // Build the argv C array for llama.cpp
        ArgManager *am=[[ArgManager alloc] initWithArgumentString:additionalArgs];
        NSURL *urlModel=(NSURL *)[arrModelPair objectAtIndex:0];
        NSURL *urlMMProj=(NSURL *)[arrModelPair objectAtIndex:1];
        [am setOption:[urlModel path]
               forKey:gArgModel];
        [am setOption:[urlMMProj path]
               forKey:gArgMMProj];
        
        int argc=0;
        char **argv = [am argvAndArgc:&argc];

        // Can we initialize llama.cpp?
        int res =_mtmd->init(argv,
                             argc,
                             &_visionSupported,
                             &_audioSupported,
                             llama_multimodal_callback);
        
        // Free our argv C array
        [self freeArgsForLlama:argv
                      withArgc:argc];
        
        // Stop accessing security scoped resources
        [Utils stopAccessingSecurityScopedURLs:arrModelPair];
        
        if ( res ) {
            return nil;
        }
        
        // Remember the model URLs
        _urlModel=urlModel;
        _urlMMProj=urlMMProj;
    }
    return self;
}

#pragma mark - Model Info & Prompts

/**
 * @brief Returns known model info for the specified file
 *
 * @param urlFile the URL path to the model or mmproj file

 * @return an instance of ModelInfo if known, or nil on error
 *
 */
+ (ModelInfo *)modelInfoForFileURL:(NSURL *)urlFile {
    
    // Did we get the parameters we need?
    if ( !isValidFileNSURL(urlFile) ) {
        return nil;
    }
    
    // Is this a model we know about?
    NSString *fileName=[[urlFile lastPathComponent] lowercaseString];
    for ( ModelInfo *mi in gArrModelInfo ) {
        
        // Do we have a Model match?
        NSString *modelName=[[mi modelFilename] lowercaseString];
        if ( [fileName isEqualToString:modelName] ) {
            return mi;
        }
        
        // Do we have an MMProj match?
        NSString *mmprojName=[[mi mmprojFilename] lowercaseString];
        if ( [fileName isEqualToString:mmprojName] ) {
            return mi;
        }
    }
    return nil;
}

/**
 * @brief Returns a title for the specified model
 *
 * The title can be used for display purposes
 *
 * @param urlModel the url of the model file
  *
 * @return a title if known, otherwise a default string
 *
 */
+ (NSString *)titleForModelURL:(NSURL *)urlModel {
    
    // Did we get the parameters we need?
    if ( !isValidNSURL(urlModel) ) {
        return @"";
    }
    
    // Is this a model we know about?
    ModelInfo *mi=[LlamarattiWrapper modelInfoForFileURL:urlModel];
    NSString *title=@"";
    if ( mi ) {
        title=[mi modelTitle];
    } else {
        title=[self shortModelNameFromURL:urlModel];
    }
    return title;
}

/**
 * @brief Returns a title for the current model
 *
 * The title can be used for display purposes
 *
 * @return a title if known, otherwise a default string
 *
 */
- (NSString *)title {
    return [LlamarattiWrapper titleForModelURL:self->_urlModel];
}

/**
 * @brief Determines a short Model name based on its URL
 *
 * Looks for specific indicators in the model string and uses
 * these to extract a short model name. If these aren't found
 * the model filename is returned
 *
 * @return a short name for the model, or the model filename,
 * or empty string on error
 *
 */
+ (NSString *)shortModelNameFromURL:(NSURL *)urlModel {
    
    // Did we get the parameters we need?
    if ( !isValidNSURL(urlModel) ) {
        return @"";
    }
    
    NSString *fileName=[[[urlModel path] lastPathComponent] stringByDeletingPathExtension];
    
    // Extract from the first "_" to the next non-alphanumeric
    NSString *title = fileName;
    NSRange range = [title rangeOfString:@"_"];
    if (range.location != NSNotFound) {
        title = [title substringFromIndex:range.location+1];
        NSCharacterSet *nonAlphaNumeric=[[NSCharacterSet alphanumericCharacterSet] invertedSet];
        range = [title rangeOfCharacterFromSet:nonAlphaNumeric];
        if (range.location != NSNotFound) {
            title = [title substringToIndex:range.location];
            title = [title stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                withString:[[title substringToIndex:1] uppercaseString]];
        }
    }
    return title;
}

/**
 * @brief Returns the array of sample prompts
 *
 * This array can be used to populate the sample prompts menu
 *
 * @return an NSArray of prompt strings
 *
 */
+ (NSArray *)samplePrompts {
    return gArrSamplePrompts;
}

/**
 * @brief Returns the array of clear context prompts
 *
 * @return an NSArray of clear context prompt strings
 *
 */
+ (NSArray *)clearContextPrompts {
    return gArrClearContextPrompts;
}

/**
 * @brief Creates a model pair array
 *
 * @return an array representing a model pair
 *
 */
- (NSArray *)modelPair {
    
    if ( !isValidFileNSURL(_urlModel) || !isValidFileNSURL(_urlMMProj) ) {
        return nil;
    }
    return @[_urlModel,_urlMMProj];
}

/**
 * @brief Determines whether a model is currently loaded
 *
 * @return whether a model is currently loaded
 *
 */
- (BOOL)modelLoaded {
    return ( isValidNSURL(_urlModel) &&
             isValidNSURL(_urlMMProj) );
}

#pragma mark - Inference

/**
 * @brief Starts generating text based on the specified prompt
 *
 * @param prompt the user prompt
 *
 * @return the status of the operation
 *
 */
- (BOOL)generate:(NSString *)prompt {
    
    // Did we get the parameters we need?
    if ( !_mtmd ||
         !isValidNSString(prompt) ) {
        return NO;
    }

    // Can we evaluate & get a response?
    int res = _mtmd->evaluate_and_respond(safeCharFromNSS(prompt));
    return (res==GGML_STATUS_SUCCESS);
}

/**
 * @brief Returns whether we are busy generating
 *
 * @return whether we are busy generating
 *
 */
- (BOOL)isBusy {
    
    if ( !_mtmd ) {
        return NO;
    }
    
    return _mtmd->is_generating();
}

/**
 * @brief Returns whether we were interrupted
 *
 * @return whether we were interrupted
 *
 */
- (BOOL)isInterrupted {
    
    if ( !_mtmd ) {
        return NO;
    }
    
    return _mtmd->is_interrupted();
}

/**
 * @brief Stops/interrupts text generation
 *
 * @return the status of the operation
 *
 */
- (BOOL)stop {
    
    if ( !_mtmd ) {
        return NO;
    }
    
    _mtmd->stop_generating();
    
    return YES;
}

/**
 * @brief Loads the specified media into the model context
 *
 * @param urlMedia path of the media to load
 *
 * @return the status of the operation
 *
 */
- (BOOL)loadMedia:(NSURL *)urlMedia
 useSecurityScope:(BOOL)useSecurityScope {
    
    // Did we get the parameters we need?
    if ( !_mtmd ||
         !isValidFileNSURL(urlMedia) ) {
        return NO;
    }
    
    if ( useSecurityScope ) {
        // Can we start accessing this security-scoped file?
        BOOL bSuccess = [Utils startAccessingSecurityScopedURLs:@[urlMedia]];
        if ( !bSuccess ) {
            return NO;
        }
    }
    
    // Can we load the specified media?
    int res = _mtmd->load_media(safeCharFromNSS([urlMedia path]));
    
    if ( useSecurityScope ) {
        // Stop accessing
        [Utils stopAccessingSecurityScopedURLs:@[urlMedia]];
    }
    
    return (res==GGML_STATUS_SUCCESS);
}

#pragma mark - Multimedia File Support

/**
 * @brief Returns whether this model supports the specified audio file type
 *
 * @param urlFile path to the audio file
 *
 * @return whether this model supports the specified audio file type
 *
 */
- (BOOL)isSupportedAudioURL:(NSURL *)urlFile {
    
    // Is audio supported by this model?
    if ( !_audioSupported ) {
        return NO;
    }

    // Is this file type supported?
    NSString *ext=[[urlFile pathExtension] lowercaseString];
    return [gArrSuppAudioTypes containsObject:ext];
}

/**
 * @brief Returns whether this model supports the specified image file type
 *
 * @param urlFile path to the image file
 *
 * @return whether this model supports the specified image file type
 *
 */
- (BOOL)isSupportedImageURL:(NSURL *)urlFile {
    
    // Is vision supported by this model?
    if ( !_visionSupported ) {
        return NO;
    }
    
    // Is this file type supported?
    NSString *ext=[[urlFile pathExtension] lowercaseString];
    return [gArrSuppVisionTypes containsObject:ext];
}

/**
 * @brief Returns the file types supported by the current model
 *
 * @return a string of all supported file types
 *
 */
- (NSString *)supportedMediaTypes {
    
    NSMutableArray *arrAll=[NSMutableArray array];
    
    // Is audio supported?
    if ( _audioSupported ) {
        [arrAll addObjectsFromArray:gArrSuppAudioTypes];
    }
    
    // Is vision supported?
    if ( _visionSupported ) {
        [arrAll addObjectsFromArray:gArrSuppVisionTypes];
    }
    
    NSString *suppTypes=@"";
    NSInteger count=[arrAll count];
    for ( NSInteger i=0; i<count; i++ ) {
        NSString *ext=arrAll[i];
        suppTypes=[suppTypes stringByAppendingFormat:@"%@%@",ext,i<(count-1)?@", ":@""];
    }
    return suppTypes;
}

#pragma mark - Misc

/**
 * @brief Returns a descriptive string about the current Apple Silicon
 * device
 *
 * @param bDetailed - return more details
 *
 * @return a descriptive string, or nil on error
 *
 */
+ (NSString *)appleSiliconModel:(BOOL)bDetailed {
        
    // Can we get the size required to store the brand string?
    size_t size=0;
    char *idBrand=(char *)"machdep.cpu.brand_string";
    if ( sysctlbyname(idBrand, NULL, &size, NULL, 0) ) {
        return nil;
    }
    
    // Can we get the brand string?
    char *brand = (char *)malloc(size);
    memset(brand,0,size);
    if ( sysctlbyname(idBrand, brand, &size, NULL, 0) ) {
        free(brand);
        brand=NULL;
        return nil;
    }
    NSString *deviceDesc = [NSString stringWithUTF8String:brand];
    free(brand);
    
    // Were we asked for more details?
    if ( bDetailed ) {
        
        // Can we get the size required to store the model identifier?
        size=0;
        char *idModel=(char *)"hw.model";
        if ( sysctlbyname(idModel, NULL, &size, NULL, 0) ) {
            return nil;
        }
        
        // Can we get the model identifier?
        char *model = (char *)malloc(size);
        memset(model,0,size);
        if ( sysctlbyname(idModel, model, &size, NULL, 0) ) {
            free(model);
            model=NULL;
            return nil;
        }
        
        NSString *strModelID = [NSString stringWithUTF8String:model];
        free(model);

        // Can we lookup a more accurate name for this model?
        NSString *strModel=[gArrMacDeviceInfo valueForKey:strModelID];
        if ( isValidNSString(strModel) ) {
            
            // Yes, use this instead
            deviceDesc = strModel;
        }
        
        // Can we get the number of CPU cores?
        int cores=0;
        size = sizeof(cores);
        if ( sysctlbyname("hw.physicalcpu", &cores, &size, NULL, 0) ) {
            return nil;
        }
        // Yes, append CPU cores
        deviceDesc=[deviceDesc stringByAppendingFormat:@" with %d CPU Cores",cores];
    }
    
    return deviceDesc;
}

/**
 * @brief Returns maximum number of loaded media files supported by the current model
 *
 * @return the number of supported media files
 *
 */
+ (NSUInteger)maxSupportedMedia {
    
    return MAX_SUPPORTED_MEDIA;
}

/**
 * @brief Clears the current chat history
 *
 * @return the status of the operation
 *
 */
- (BOOL)clearHistory {
    
    // Did we get the parameters we need?
    if ( !_mtmd ) {
        return NO;
    }

    // Can we clear our chat history?
    int res = _mtmd->clear_history();
    return (res==GGML_STATUS_SUCCESS);
}

/**
 * @brief Determines the model and projection file URLS from a model array
 *
 * @param arrModels - an array of 2 model file URLs
 *
 * @return - An NSArray representing a model pair, or nil on error
 *
 */
+ (NSArray *)validateModelAndProjectorURLs:(NSArray *)arrModels {
    
    // Did we get the parameters we need?
    if ( ![Utils isValidModelPair:arrModels] ) {
        return nil;
    }
    
    // Determine which is the model & which is the projection
    NSURL *urlModel=nil;
    NSURL *urlMMProj=nil;
    if ( isMMProj(arrModels[0]) ) {
        urlMMProj=arrModels[0];
        urlModel=arrModels[1];
    } else
    {
        urlModel=arrModels[0];
        urlMMProj=arrModels[1];
    }
    
    // Do the files have the same prefix?
    NSString *filenameModel=[urlModel lastPathComponent];
    NSRange range=[[filenameModel lowercaseString] rangeOfString:@"-gguf_"];
    if ( range.location == NSNotFound ) {
        return nil;
    }
    NSString *pfxRequired=[filenameModel substringToIndex:range.location];
    if ( ![[urlMMProj lastPathComponent] hasPrefix:pfxRequired] ) {
        return nil;
    }
    
    // Return the model pair
    NSArray *arrModelPair=@[urlModel,urlMMProj];
    return arrModelPair;
}

/**
 * @brief Returns the titles of known model pairs that exist in gArrModelInfo
 *
 * @return - A string with model titles
 *
 */
+ (NSString *)listKnownModels {
    
    NSString *modelsList=@"";
    for ( ModelInfo *mi in gArrModelInfo ) {
        modelsList=[modelsList stringByAppendingFormat:@"%@\n",mi.modelTitle];
        NSLog(@"- %@\n",mi.modelTitle);
    }
    return modelsList;
}

/**
 * @brief Frees the specified dynamically allocated argv array
 *
 */
- (void)freeArgsForLlama:(char **)argv
                withArgc:(int)argc {
    
    // Did we get the parameters we need?
    if ( argv == nil || argc == 0 ) {
        return;
    }
    
    for ( int ind=0; ind<argc; ind++ ) {
        if ( argv[ind] ) {
            free(argv[ind]);
            argv[ind]=NULL;
        }
    }
    free(argv);
    argv=NULL;

}

#pragma mark - Cleanup

/**
 * @brief Performs various cleanup operations
 *
 */
- (void)dealloc {
    
    // Did we get the parameters we need?
    if ( !_mtmd ) {
        return;
    }

    // Uninitialize/delete our object
    _mtmd->deinit();
    delete _mtmd;
}

@end
