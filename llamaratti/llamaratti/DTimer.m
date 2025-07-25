/**
 * @file DTimer.m
 *
 * @brief Provides basic timing methods
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>
#import "DTimer.h"
#import "Shared.h"

@implementation DTimer {
    
    NSDate *_startedAt;
    NSString *_desc;
}

/**
 * @brief Initializes the timer
 *
 * @return initialized object
 *
 */
- (id)init {
    
    if ( self = [super init] ) {
        
        [self reset];
    }
    return self;
}

/**
 * @brief Initializes the timer
 *
 * @return initialized object
 *
 */
- (id)initWithFunc:(NSString *)func
           andDesc:(NSString *)desc {
    
    if ( self = [super init] ) {
        
        [self reset];
        _func=func;
        _desc=desc;
    }
    return self;
}

/**
 * @brief Creates & initializes the timer
 *
 * @return initialized object
 *
 */
+ (id)timer {
    
    DTimer *timer=[DTimer timerWithFunc:safeNSSFromChar(__func__)
                                andDesc:nil];
    return timer;
}

/**
 * @brief Creates & initializes the timer with function & description
 *
 * @return initialized object
 *
 */
+ (id)timerWithFunc:(NSString *)func
            andDesc:(NSString *)desc {
    
    DTimer *dt=[[DTimer alloc] initWithFunc:func
                                    andDesc:desc];
    return dt;
}

/**
 * @brief Re-initializes the timer
 *
 */
- (void)reset {
    
    _startedAt=[NSDate date];
    _func=@"";
    _desc=@"";
}

/**
 * @brief Returns the time interval since we started the timer
 *
 * @returns the time interval
 */
- (NSTimeInterval)ticks {
    
    NSTimeInterval time=[[NSDate date] timeIntervalSinceDate:_startedAt];
    return time;
}

/**
 * @brief Logs the current timing details to the system log
 *
 */
- (void)log {
    
    NSTimeInterval interval=[self ticks];
    NSString *strDesc=[self toString:interval];
    NSLog(@"%@",strDesc);
}

/**
 * @brief Converts the current timing info to a string
 *
 */
- (NSString *)toString:(NSTimeInterval)interval {
    
    return [NSString stringWithFormat:@"%@ - %.4f",
                                        _func,
                                        interval];
}

@end
