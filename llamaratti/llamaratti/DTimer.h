/**
 * @file DTimer.h
 *
 * @brief Provides basic timing methods
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
#import <Foundation/Foundation.h>

/**
 * @class DTimer
 * @brief Provides basic timing operations
 *
 */
@interface DTimer : NSObject

// Properties
@property NSString *func;
@property NSString *desc;

// Methods
+ (id)timer;
+ (id)timerWithFunc:(NSString *)func
            andDesc:(NSString *)desc;

- (id)init;
- (void)reset;
- (NSTimeInterval)ticks;
- (void)log;
- (NSString *)toString:(NSTimeInterval)interval;

@end
