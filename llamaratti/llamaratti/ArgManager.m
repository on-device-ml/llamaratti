/**
 * @file ArgManager.m
 *
 * @brief Handles parsing and management of command line arguments
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "ArgManager.h"

@interface ArgManager () {
    
    NSMutableDictionary<NSString *, NSString *> *_options;
    NSMutableArray<NSString *> *_arguments;
    NSString *_originalArgumentString;
}

@end

@implementation ArgManager

/**
 * @brief Initializes an instance of this class
 *
 * @return an instance of this class
 *
 */
- (id)init {
    self = [super init];
    if (self) {
        _originalArgumentString = @"";
        _options = [NSMutableDictionary dictionary];
        _arguments = [NSMutableArray array];
    }
    return self;
}

/**
 * @brief Initializes an instance of this class with a specified argument string
 *
 * @return an instance of this class
 *
 */
- (id)initWithArgumentString:(NSString *)argumentString {
    self = [super init];
    if (self) {
        _originalArgumentString = [argumentString copy];
        _options = [NSMutableDictionary dictionary];
        _arguments = [NSMutableArray array];
        NSArray *tokens = [self tokenizeArgumentString:argumentString];
        [self parseArguments:tokens];
    }
    return self;
}


#pragma mark - Tokenizing

/**
 * @brief Tokenizes the specified argument string into an array
 *
 * @return An NSArray of strings
 *
 */
- (NSArray<NSString *> *)tokenizeArgumentString:(NSString *)string {
    
    NSMutableArray *tokens = [NSMutableArray array];
    NSUInteger length = string.length;
    unichar buffer[length + 1];
    [string getCharacters:buffer range:NSMakeRange(0, length)];

    NSMutableString *currentToken = [NSMutableString string];
    BOOL inSingleQuotes = NO;
    BOOL inDoubleQuotes = NO;
    BOOL escaping = NO;

    for (NSUInteger i = 0; i < length; i++) {
        unichar c = buffer[i];

        if (escaping) {
            [currentToken appendFormat:@"%C", c];
            escaping = NO;
        } else if (c == '\\') {
            escaping = YES;
        } else if (c == '"' && !inSingleQuotes) {
            inDoubleQuotes = !inDoubleQuotes;
        } else if (c == '\'' && !inDoubleQuotes) {
            inSingleQuotes = !inSingleQuotes;
        } else if (!inSingleQuotes && !inDoubleQuotes && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c]) {
            if (currentToken.length > 0) {
                [tokens addObject:[currentToken copy]];
                [currentToken setString:@""];
            }
        } else {
            [currentToken appendFormat:@"%C", c];
        }
    }

    if (currentToken.length > 0) {
        [tokens addObject:[currentToken copy]];
    }

    return tokens;
}

#pragma mark - Parsing

/**
 * @brief Parses an array of strings into internal collections used to manage arguments
 *
 * @param args - the arguments to parse
 *
 */
- (void)parseArguments:(NSArray<NSString *> *)args {
    
    NSString *pendingKey = nil;

    for (NSString *arg in args) {
        if ([arg hasPrefix:@"--"] && arg.length > 2) {
            // Long option, maybe with '=': --option or --option=value
            if (pendingKey) {
                _options[pendingKey] = @"YES";
                pendingKey = nil;
            }

            NSString *option = [arg substringFromIndex:2];
            NSRange equalsRange = [option rangeOfString:@"="];
            if (equalsRange.location != NSNotFound) {
                NSString *key = [option substringToIndex:equalsRange.location];
                NSString *value = [option substringFromIndex:equalsRange.location + 1];
                _options[key] = value;
            } else {
                pendingKey = option;
            }

        } else if ([arg hasPrefix:@"-"] && arg.length > 1) {
            // Short option(s)
            if (pendingKey) {
                _options[pendingKey] = @"YES";
                pendingKey = nil;
            }

            NSString *shortOpts = [arg substringFromIndex:1];
            if (shortOpts.length == 1) {
                // Single short option, might expect value next
                pendingKey = shortOpts;
            } else {
                // Treat entire string as single option (e.g., -foo)
                pendingKey = shortOpts;
            }

        } else {
            // Value or positional argument
            if (pendingKey) {
                _options[pendingKey] = arg;
                pendingKey = nil;
            } else {
                [_arguments addObject:arg];
            }
        }
    }

    if (pendingKey) {
        _options[pendingKey] = @"YES";
    }
}

#pragma mark - Accessors

/**
 * @brief Returns the options as an NSDictionary
 *
 * @return an NSDictionary of options
 *
 */
- (NSDictionary<NSString *,NSString *> *)options {
    return [_options copy];
}

/**
 * @brief Returns the options as an NSArray
 *
 * @return an NSArray of options
 *
 */
- (NSArray<NSString *> *)arguments {
    return [_arguments copy];
}

/**
 * @brief Determines whether the specified option exists
 *
 * @return whether the option exists
 *
 */
- (BOOL)hasOption:(NSString *)key {
    return _options[key] != nil;
}

/**
 * @brief Retrives the value of the specified option
 *
 * @return the value of the specified option
 *
 */
- (NSString *)getOption:(NSString *)key {
    return _options[key];
}

- (void)setOption:(NSString *)value forKey:(NSString *)key {
    if (key == nil) return;

    if (value) {
        _options[key] = value;
    } else {
        [_options removeObjectForKey:key];
    }
}

/**
 * @brief Converts the current internal parameters to a string
 *
 * @return the current internal parameters as a string
 *
 */
- (NSString *)toString {
    
    NSMutableArray<NSString *> *components = [NSMutableArray array];
    
    // Sort keys for consistent output (optional)
    NSArray<NSString *> *sortedKeys = [[_options allKeys]
                                    sortedArrayUsingSelector:@selector(compare:)];

    for (NSString *key in sortedKeys) {
        NSString *value = _options[key];

        // Boolean flags (value == @"YES")
        if ( [value isEqualToString:@"YES"] ) {
            if (key.length == 1) {
                [components addObject:[NSString stringWithFormat:@"-%@", key]];
            } else {
                [components addObject:[NSString stringWithFormat:@"--%@", key]];
            }
        } else {
            // Options with values
            NSString *escapedValue = [self shellEscape:value];
            if (key.length == 1) {
                [components addObject:[NSString stringWithFormat:@"-%@ %@", key, escapedValue]];
            } else {
                [components addObject:[NSString stringWithFormat:@"--%@=%@", key, escapedValue]];
            }
        }
    }

    // Add positional arguments
    for (NSString *arg in _arguments) {
        [components addObject:[self shellEscape:arg]];
    }

    return [components componentsJoinedByString:@" "];
}

/**
 * @brief Escapes the specified string, also wrapping arguments in quotes
 *
 * @return the escaped string
 *
 */
- (NSString *)shellEscape:(NSString *)string {
    
    
    NSCharacterSet *unsafeChars = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\"'\\!$&|<>;"];
    if ([string rangeOfCharacterFromSet:unsafeChars].location != NSNotFound) {
        NSString *escaped = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        return [NSString stringWithFormat:@"\"%@\"", escaped];
    }
    return string;
}

/**
 * @brief Adds to the current arguments
 *
 * @param additionalArgumentString - the arguments string to add
 *
 */
- (void)addArgumentsFromString:(NSString *)additionalArgumentString {
    if (additionalArgumentString.length == 0) return;

    NSArray<NSString *> *tokens = [self tokenizeArgumentString:additionalArgumentString];
    [self parseArguments:tokens];
}

/**
 * @brief Creates a C style argv/argc set of parameters from the current state
 *
 * @param argc - the returned number of arguments
 *
 * @note - this method allocates memory that must be free by the caller
 * 
 * @return - the array of argv parameters. Note: This must be freed by the caller
 *
 */
- (char **)argvAndArgc:(int *)argc {
    
    if ( !argc ) {
        return nil;
    }
    
    // Sort keys
    NSMutableArray *components = [NSMutableArray arrayWithObject:@"program"];
    NSArray *allKeys = [_options allKeys];
    for ( NSString *key in allKeys ) {
        
        NSString *value = _options[key];
        if ([value isEqualToString:@"YES"]) {
            
            if (key.length == 1) {
                [components addObject:[NSString stringWithFormat:@"-%@", key]];
            } else {
                [components addObject:[NSString stringWithFormat:@"--%@", key]];
            }
            
        } else {
            
            if (key.length == 1) {
                [components addObject:[NSString stringWithFormat:@"-%@", key]];
            } else {
                [components addObject:[NSString stringWithFormat:@"--%@", key]];
            }
            [components addObject:value];
        }
    }

    [components addObjectsFromArray:_arguments];

    int count = (int)components.count;
    char **argv = (char **)malloc((count + 1) * sizeof(char *));
    for (NSUInteger i = 0; i < count; i++) {
        NSString *str = components[i];
        const char *utf8Str = [str UTF8String];
        argv[i] = strdup(utf8Str);
    }
    argv[count] = NULL;

    *argc=count;
    return argv;
}

@end



