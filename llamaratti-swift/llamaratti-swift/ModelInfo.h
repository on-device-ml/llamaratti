/**
 * @file ModelInfo.h
 *
 * @brief Used to store information about model/projection pairs
 * for multimodal llama.cpp
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

/**
* @class ModelInfo
* @brief Contains information about one model pair
*
*/
@interface ModelInfo : NSObject

// Properties
@property NSString *modelTitle;
@property NSString *modelFilename;
@property NSString *mmprojFilename;
@property NSString *modelHash;
@property NSString *mmprojHash;
@property uint32_t ctxLen;
@property NSDictionary *dictCtxLen;
@property float temp;
@property int32_t seed;
@property BOOL isVerified;

// Methods
-(id)init;

+(id)modelInfoWithTitle:(NSString *)modelTitle
              withModel:(NSString *)modelFilename
          withModelHash:(NSString *)modelHash
             withMMProj:(NSString *)mmprojFilename
         withMMProjHash:(NSString *)mmprojHash
         withDictCtxLen:(NSDictionary *)dictCtxLen
               withTemp:(float)temp
               withSeed:(uint32_t)seed;

@end

