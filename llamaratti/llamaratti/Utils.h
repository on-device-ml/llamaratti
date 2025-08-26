/**
 * @file Utils.h
 *
 * @brief Various utility methods
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Cocoa/Cocoa.h>

/**
 * @class Utils
 * 
 * @brief Provides various utility methods
 *
 */
@interface Utils : NSObject

// Methods
+ (BOOL)activateApplicationWithBundleIdentifier:(NSString *)bundleID;

+ (BOOL)openURL:(NSURL *)url;

+ (BOOL)launchActivityMonitor;

+ (NSModalResponse)selectFiles:(NSString *)prompt
                    fromFolder:(NSURL *)urlFolder
             withAllowMultiple:(BOOL)allowMultiple
              withAllowedTypes:(NSArray *)allowedContentTypes
              withSelectedURLs:(NSArray **)arrSelectedURLs;

+ (BOOL)showAlertWithTitle:(NSString *)title
                andMessage:(NSString *)msg
                  urlTitle:(NSString *)urlTitle
                       url:(NSURL *)url
                   buttons:(NSArray *)buttons;

+ (NSImage *)getAppIcon;

+ (NSString *)abbreviatePath:(NSString *)path
                    toLength:(NSUInteger)len;

+ (NSString *)getSHA256ForURL:(NSURL *)urlFile;

+ (BOOL)checkSHA256ForURL:(NSURL *)urlFile
                 withHash:(NSString *)sha256Hash;

+ (BOOL)copyToPasteboard:(NSString *)str;

+ (BOOL)startAccessingSecurityScopedURLs:(NSArray *)arrURLs;

+ (BOOL)stopAccessingSecurityScopedURLs:(NSArray *)arrURLs;

+ (BOOL)isValidModelPair:(NSArray *)arrModelPair;

+ (BOOL)isValidBookmarkModelPair:(NSArray *)arrModelPair;

+ (NSURL *)getUsersRealHomeDirectory;

+ (char *)safeDescFromNSError:(NSError *)e;

+ (NSInteger)safeCodeFromNSError:(NSError *)e;

+ (NSString *)getOSVersion;

+ (BOOL)getTotalSystemMemory:(ULONGLONG *)total;

+ (BOOL)getAvailSystemMemory:(ULONGLONG *)avail;

+ (BOOL)getTotalDiskSpace:(double *)total;

+ (BOOL)getAvailDiskSpace:(double *)avail;

+ (NSUInteger)getCPUCores;

+ (NSString *)formatToGig:(ULONGLONG)bytes;

+ (double)scaleValueToPercent:(CGFloat)fVal
               toUnitRangeMin:(CGFloat)fMin
               toUnitRangeMax:(CGFloat)fMax;

+ (NSString *)getTemperatureUnits;

+ (CGFloat)kelvinsToLocaleTemp:(CGFloat)kelvins
                 returnedUnits:(NSString **)units;

+ (BOOL)runningInSandbox;

+ (NSObject *)readEmbeddedProperty:(NSString *)propertyName
                 forIOServiceNamed:(NSString *)ioServiceName;

+ (BOOL)getBatteryTemperature:(CGFloat *)temp;

+ (BOOL)removeTempFilesMatchingTemplate:(NSString *)templ;

+ (NSString *)stripWhitespace:(NSString *)str;

@end
