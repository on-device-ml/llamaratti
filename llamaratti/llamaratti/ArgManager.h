/**
 * @file ArgManager.h
 *
 * @brief Handles parsing and management of command line arguments
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>

@interface ArgManager : NSObject

@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *options;
@property (nonatomic, strong, readonly) NSArray<NSString *> *arguments;

- (id)init;
- (id)initWithArgumentString:(NSString *)argumentString;

- (BOOL)hasOption:(NSString *)key;
- (NSString *)getOption:(NSString *)key;
- (void)setOption:(NSString *)value forKey:(NSString *)key;

- (NSString *)toString;
- (void)addArgumentsFromString:(NSString *)additionalArgumentString;
- (char **)argvAndArgc:(int *)argc;

@end

