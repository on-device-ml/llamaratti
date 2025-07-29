/**
 * @file Utils.m
 *
 * @brief Various utility methods
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <CommonCrypto/CommonDigest.h>

#import <IOKit/IOKitLib.h>

#import <os/proc.h>
#import <sys/sysctl.h>
#import <IOKit/IOKitLib.h>
#import <Metal/Metal.h>

#include <pwd.h>

#import "Shared.h"
#import "Errors.h"
#import "Utils.h"
#import "LlamarattiWrapper.h"

#define SHA256_READ_BLOCK_SIZE 32768

#define SYSTEMP_MIN_KELVINS              288.15
#define SYSTEMP_MAX_KELVINS              383.15

NSString * const gActMonBundleID=@"com.apple.ActivityMonitor";

@implementation Utils

/**
 * @brief Activates the specified running application
 *
 * @param bundleID the bundle identifier of the application
 *
 * @return the status of the operation
 *
 */
+ (BOOL)activateApplicationWithBundleIdentifier:(NSString *)bundleID {
    
    // Any running apps with this bundle identifier?
    NSArray *apps=[NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID];
    if ( !isValidNSArray(apps) ) {
        
        // No, outta here...
        return NO;
    }
    
    // Yes, activate the first one
    NSRunningApplication *app=[apps firstObject];
    BOOL bActivated=[app activateWithOptions:NSApplicationActivateAllWindows];
    
    // All Good!
    return bActivated;
}

/**
 * @brief Opens the specified URL in the default web browser
 *
 * @param url the URL to open
 *
 * @return the status of the operation
 *
 */
+ (BOOL)openURL:(NSURL *)url {
    
    return ([[NSWorkspace sharedWorkspace] openURL:url]);
}

/**
 * @brief Launches the macOS Activity Monitor app
 *
 * @return the status of the operation
 *
 */
+ (BOOL)launchActivityMonitor {
    
    // Build a path to the Activity Monitor App
    NSWorkspace *ws=[NSWorkspace sharedWorkspace];
    NSURL *actMonUrl=[ws URLForApplicationWithBundleIdentifier:gActMonBundleID];

    // Launch
    NSWorkspaceOpenConfiguration *cfg=[NSWorkspaceOpenConfiguration configuration];
    [ws openURLs:@[]
withApplicationAtURL:actMonUrl
   configuration:cfg
completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable e) {
        
        // Did we have a problem?
        if (e) {
            // Yes, log & outta here...
            NSLog(gErrLrtCantLaunchApp,
                  __func__,
                  [actMonUrl path],
                  safeDesc(e),
                  safeCode(e));
            return;
        }

        // Bring App into the foreground
        [self activateApplicationWithBundleIdentifier:gActMonBundleID];
    }];

    return YES;
}

/**
 * @brief Displays a file selection dialog, and returns a selected file URL
 *
 * @param prompt the prompt to display
 * @param urlFolder the default folder to display
 * @param allowMultiple whether multiple file selections are allowed
 * @param allowedContentTypes the file types that can be selected
 * @param arrSelectedURLs - the returned selected URLs
 *
 * @return the status of the operation, or nil if the user cancels
 *
 */
+ (NSModalResponse)selectFiles:(NSString *)prompt
                    fromFolder:(NSURL *)urlFolder
             withAllowMultiple:(BOOL)allowMultiple
              withAllowedTypes:(NSArray *)allowedContentTypes
              withSelectedURLs:(NSArray **)arrSelectedURLs {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:YES];
    if ( isValidFileNSURL(urlFolder) ) {
        [panel setDirectoryURL:urlFolder];
    }
    
    // Did we get any allowed content types?
    if ( isValidNSArray(allowedContentTypes) ) {
        [panel setAllowedContentTypes:allowedContentTypes];
    }
    [panel setCanCreateDirectories:NO];
    [panel setMessage:prompt];
    
    // Did the user select OK?
    NSModalResponse response=[panel runModal];
    if ( response == NSModalResponseOK ) {

        // Yes, return the URLs
        if ( arrSelectedURLs != nil ) {
            *arrSelectedURLs=[panel URLs];
        }
    }
    return response;
}

/**
 * @brief Displays an alert dialog with a message with an embedded URL
 *
 * @param title the title to display
 * @param msg the message to display
 * @param urlTitle the title for the embedded URL
 * @param url the embedded URL
 * @param buttons an array of button titles
 *
 * @return the status of the operation, or nil if the user cancels
 *
 */
+ (BOOL)showAlertWithTitle:(NSString *)title
                andMessage:(NSString *)msg
                  urlTitle:(NSString *)urlTitle
                       url:(NSURL *)url
                   buttons:(NSArray *)buttons {
    
    // Did we get the parameters we need?
    if ( !isValidNSString(title) ) {
        return NO;
    }
    
    NSAlert *alert=[[NSAlert alloc] init];
    [alert setMessageText:title];
    if ( isValidNSString(msg) ) {
        
        [alert setInformativeText:msg];
    }
    // Did they give us any custom buttons?
    if ( isValidNSArray(buttons) )
    {
        // Yes, add them
        for ( NSString *btnTitle in buttons ) {
            [alert addButtonWithTitle:btnTitle];
        }
    } else {
        
        // No, use default
        [alert addButtonWithTitle:@"Ok"];
    }
    
    // Do we have a valid URL and Title?
    if ( isValidNSString(urlTitle) && isValidNSURL(url) ) {
        
        // Yes, add an NSTextView to display the URL
        NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 320, 30)];
        [textView setAutomaticLinkDetectionEnabled:YES];
        [textView setDrawsBackground:NO];
        [textView setEditable:NO];
        [textView setSelectable:YES];
        [textView setAlignment:NSTextAlignmentLeft];
        
       // Create an attributed string with a hyperlink
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:urlTitle];
        
        [attrStr addAttribute:NSUnderlineStyleAttributeName
                        value:@(NSUnderlineStyleSingle)
                        range:NSMakeRange(0, [urlTitle length])];
        [attrStr addAttribute:NSForegroundColorAttributeName
                        value:[NSColor linkColor]
                        range:NSMakeRange(0, [urlTitle length])];
        [attrStr addAttribute:NSLinkAttributeName
                        value:[url absoluteString]
                        range:NSMakeRange(0, [urlTitle length])];
        
        [[textView textStorage] setAttributedString:attrStr];
        
        // Add the NSTextView to this NSAlert dialog
        alert.accessoryView = textView;
    }

    NSModalResponse response=[alert runModal];
    
    return (response==NSAlertFirstButtonReturn);
}

/**
 * @brief Returns the Application icon
 *
 * @return the application icon as an NSImage
 *
 */
+ (NSImage *)getAppIcon {
    
    NSDictionary *dictInfo=[[NSBundle mainBundle] infoDictionary];
    if ( !isValidNSDictionary(dictInfo) ) {
        return nil;
    }
    NSDictionary *dictIcons=dictInfo[@"CFBundleIcons"];
    if ( !isValidNSDictionary(dictIcons) ) {
        return nil;
    }
    NSDictionary *dictPriIcon=dictIcons[@"CFBundlePrimaryIcon"];
    if ( !isValidNSDictionary(dictPriIcon) ) {
        return nil;
    }
    NSArray *arrIcons=dictPriIcon[@"CFBundleIconFiles"];
    if ( !isValidNSArray(arrIcons) ) {
        return nil;
    }
    NSString *iconName=[arrIcons lastObject];
    NSImage *appIcon=[NSImage imageNamed:iconName];
    
    return appIcon;
}

/**
 * @brief Returns the abbreviated version of a long path for display
 *
 * @param path - the path to abbreviate
 * @param len - the desired length of the abbreviated path
 *
 * @return the abbreviated path
 *
 */
+ (NSString *)abbreviatePath:(NSString *)path
                    toLength:(NSUInteger)len {
    
    // Did we get the parameters we need?
    if ( !isValidNSString(path) ) {
        return nil;
    }
    
    // Is this path already small enough?
    if ( [path length] <= len ) {
        return path;
    }
    
    // Reduce the length by abbreviating
    NSUInteger indHalf=len/2;
    NSString *first=[path substringToIndex:indHalf-1];
    NSUInteger indLast=[path length]-indHalf;
    NSString *second=[path substringFromIndex:indLast];
    NSString *final=[NSString stringWithFormat:@"%@...%@",first,second];
    
    return final;
}

/**
 * @brief Checks the SHA256 of the specified file against a hash
 *
 * @param urlFile the file URL of the file to check
 * @param sha256Hash the hash to use when validating the file content
 *
 * @return whether the hash matches the file content
 *
 */
+ (BOOL)checkSHA256ForURL:(NSURL *)urlFile
                 withHash:(NSString *)sha256Hash {
    
    // Did we get the parameters we need?
    if ( !isValidFileNSURL(urlFile) ||
         !isValidNSString(sha256Hash) ) {
        return NO;
    }

    // Can we open the file?
    NSError *e=nil;
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:urlFile
                                                           error:&e];
    if ( !fh ) {
        NSLog(gErrLrtCantLoadFile,
              __func__,
              [urlFile path],
              safeDesc(e),
              safeCode(e));
        return NO;
    }

    CC_SHA256_CTX sha256;
    CC_SHA256_Init(&sha256);
    @autoreleasepool {
        
        while (true) {
            NSData *fd = [fh readDataOfLength:SHA256_READ_BLOCK_SIZE];
            if ( fd.length == 0 ) {
                break;
            }
            CC_SHA256_Update(&sha256, fd.bytes, (CC_LONG) fd.length);
        }
    }

    [fh closeFile];

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &sha256);

    NSMutableString *fileHash=[NSMutableString
                                   stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for ( int i=0; i<CC_SHA256_DIGEST_LENGTH; i++ ) {
        [fileHash appendFormat:@"%02x", digest[i]];
    }

    // Do we have a match?
    if ( [fileHash caseInsensitiveCompare:sha256Hash] != NSOrderedSame ) {
        return NO;
    }
    return YES;
}

/**
 * @brief Copies the specified text to the pasteboard
 *
 * @param text - the text to copy to the pasteboard
 *
 * @return the status of the operation
 *
 */
+ (BOOL)copyToPasteboard:(NSString *)text {

    // Did we get the parameters we need?
    if ( !isValidNSString(text) ) {
        return NO;
    }
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    if ( !pasteboard ) {
        return NO;
    }
    [pasteboard clearContents];
    [pasteboard setString:text
                  forType:NSPasteboardTypeString];
    return YES;
}

/**
 * @brief Starts accessing an array of security scoped files
 *
 * @param arrFileURLs an array of file URLs
 *
 * @return the status of the operation
 *
 */
+ (BOOL)startAccessingSecurityScopedURLs:(NSArray *)arrFileURLs {
    
    // Did we get the parameters we need?
    if ( !isValidNSArray(arrFileURLs) ) {
        return NO;
    }
    
    // Attempt to start accessing the file URLs in the array
    for ( NSURL *urlFile in arrFileURLs ) {
        
        // Is this a valid File URL?
        if ( !isValidFileNSURL(urlFile) ) {
            continue;
        }
        
        // Can we start accessing this file?
        if ( ![urlFile startAccessingSecurityScopedResource] ) {
            return NO;
        }
    }
    return YES;
}

/**
 * @brief Stops accessing an array of security scoped files
 *
 * @param arrFileURLs an array of file URLs
 *
 * @return the status of the operation
 *
 */
+ (BOOL)stopAccessingSecurityScopedURLs:(NSArray *)arrFileURLs {

    // Did we get the parameters we need?
    if ( !isValidNSArray(arrFileURLs) ) {
        return NO;
    }
    
    // Attempt to stop accessing the file URLs in the array
    for ( NSURL *urlFile in arrFileURLs ) {
        
        // Is this a valid File URL?
        if ( !isValidFileNSURL(urlFile) ) {
            continue;
        }
        
        // Stop accessing this file
        [urlFile stopAccessingSecurityScopedResource];
        
    }
    return YES;
}

/**
 *
 * @brief Returns whether the specified array is a valid model pair
 *
 * A valid  model pair is one that has 2 NSURL entries representing
 * the model and the model projector files
 *
 * @param arrModelPair - an NSArray of 2 File URLs
 *
 * @return - the validity of the model pair
 *
 */
+ (BOOL)isValidModelPair:(NSArray *)arrModelPair {
    
    if ( !isValidNSArray(arrModelPair) ||
         [arrModelPair count] != 2 ) {
        return NO;
    }
    return (isValidFileNSURL(arrModelPair[0]) &&
            isValidFileNSURL(arrModelPair[1]));
}

/**
 *
 * @brief Returns whether the specified array is a valid model pair
 *
 * A valid bookmark model pair is one that has 2 NSData entries representing
 * the security scoped bookmarks of the model and the model projector files
 *
 * @param arrBookmarkModelPair - an NSArray of 2 NSData bookmarks
 *
 * @return - the validity of the bookmarked model pair
 *
 */
+ (BOOL)isValidBookmarkModelPair:(NSArray *)arrBookmarkModelPair {
    
    if ( isValidNSArray(arrBookmarkModelPair) &&
        [arrBookmarkModelPair count] != 2 ) {
        return NO;
    }
    return (isValidNSData(arrBookmarkModelPair[0]) &&
            isValidNSData(arrBookmarkModelPair[1]));
}

/**
 *
 * @brief Returns the current user's real home directory vs. the sandboxed one
 *
 * @return the user's real home directory, or nil on error
 *
 */
+ (NSURL *)getUsersRealHomeDirectory {
    
    // Can we get the user's real home directory?
    struct passwd *pw=getpwuid(getuid());
    if ( !pw ) {
        return nil;
    }
    
    // Yes, does it actually exist?
    NSString *homeFolder=safeNSSFromChar(pw->pw_dir);
    NSFileManager *fm=[NSFileManager defaultManager];
    BOOL isFolder=NO;
    if ( ![fm fileExistsAtPath:homeFolder
                  isDirectory:&isFolder] || !isFolder ) {
        return nil;
    }
    return [NSURL fileURLWithPath:homeFolder];
}

/**
 *
 * @brief Safely returns the code field of an NSError
 *
 * @param e - the NSError object
 *
 * @return the code field of an NSError
 *
 */
+ (NSInteger)safeCodeFromNSError:(NSError *)e {
    
    // Do we have an error?
    if ( e == nil ) {
        return 0;
    }
    return [e code];
}

/**
 *
 * @brief Safely returns the localizedDescription field of an NSError
 *
 * @param e - the NSError object
 *
 * @return - the localizedDescription field of an NSError as a C string
 *
 */
+ (char *)safeDescFromNSError:(NSError *)e {
    
    // Do we have an error and a valid description?
    if ( e == nil || !isValidNSString([e localizedDescription]) ) {
        return "";
    }
    return safeCharFromNSS([e description]);
}

/**
 *
 * @brief Returns the total available system memory
 *
 * @param total - the returned total available system memory
 *
 * @return - the status of the operation
 *
 */
+ (BOOL)getTotalSystemMemory:(ULONGLONG *)total {
    
    if ( !total ) {
        return NO;
    }
    *total = [[NSProcessInfo processInfo] physicalMemory];
    
    return YES;
}

/**
 *
 * @brief Returns the currently available system memory
 *
 * @param avail - the returned currently available system memory
 *
 * @return - the status of the operation
 *
 */
+ (BOOL)getAvailSystemMemory:(ULONGLONG *)avail {
    
    if ( !avail ) {
        return NO;
    }

    // Can we get host statistics?
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    vm_statistics64_data_t vmStats;
    kern_return_t kr = host_statistics64(mach_host_self(),
                                             HOST_VM_INFO64,
                                             (host_info64_t)&vmStats,
                                             &count);
    if ( kr != KERN_SUCCESS ) {
        
        // No, log & outta here...
        NSLog(gErrLrtGetMemFailed,
              __func__,
              mach_error_string(kr),
              kr);
        return NO;
    }

    int64_t freeMemory = (int64_t)vmStats.free_count +
                         (int64_t)vmStats.inactive_count;

    int64_t pageSize;
    host_page_size(mach_host_self(), (vm_size_t*)&pageSize);

    *avail = freeMemory * pageSize;
    
    return YES;
}

/**
 *
 * @brief Returns the total system disk space
 *
 * @param total - the returned total system disk space
 *
 * @return - the status of the operation
 *
 */
+ (BOOL)getTotalDiskSpace:(double *)total {
    
    if ( !total ) {
        return NO;
    }
    
    // Can we get attributes of the file system?
    NSError *e=nil;
    NSString *rootPath=@"/";
    NSDictionary *attr=[[NSFileManager defaultManager]
                        attributesOfFileSystemForPath:rootPath
                        error:&e];
    if ( !attr ) {
        if (e) {
            // No, log & outta here...
            NSLog(gErrLrtGetDskSpcFailed,
                  __func__,
                  rootPath,
                  safeDesc(e),
                  safeCode(e));
            return NO;
        }
    }
    // No, return final value
    NSNumber *numVal=[attr objectForKey:NSFileSystemSize];
    *total=[numVal doubleValue];
    return YES;
}

/**
 *
 * @brief Returns the available system disk space
 *
 * @param avail - the returned available disk space
 *
 * @return - the status of the operation
 *
 */
+ (BOOL)getAvailDiskSpace:(double *)avail {
    
    if ( !avail ) {
        return NO;
    }
    
    // Can we get attributes of the file system?
    NSError *e=nil;
    NSString *rootPath=@"/";
    NSDictionary *attr=[[NSFileManager defaultManager]
                        attributesOfFileSystemForPath:rootPath
                        error:&e];
    if ( !attr ) {
        if (e) {
            // No, log & outta here...
            NSLog(gErrLrtGetDskSpcFailed,
                  __func__,
                  rootPath,
                  safeDesc(e),
                  safeCode(e));
            return NO;
        }
    }
    // No, return final value
    NSNumber *numVal=[attr objectForKey:NSFileSystemFreeSize];
    *avail=[numVal doubleValue];
    return YES;
}

/**
 *
 * @brief Returns the number of CPU cores
 *
 * @return the number of CPU cores
 *
 */
+ (NSUInteger)getCPUCores {
    return [[NSProcessInfo processInfo] processorCount];
}

/**
 * @brief Formats a specified integer to Gigabytes
 *
 * @param bytes - the bytes value to format
 *
 * @return the formatted Gigabytes string
 *
 */
+ (NSString *)formatToGig:(ULONGLONG)bytes {
    double gb = (double)bytes / (1024.0 * 1024.0 * 1024.0);
    return [NSString stringWithFormat:@"%.1f", gb];
}

/**
 * @brief Scales down a specified min/max range to a percentile range
 *
 * @param fVal - the value to scale
 * @param fMin - the minimum value
 * @param fMax - the minimum value
 *
 * @return - the scaled value
 */
+ (double)scaleValueToPercent:(CGFloat)fVal
               toUnitRangeMin:(CGFloat)fMin
               toUnitRangeMax:(CGFloat)fMax {
    
    // Prevent divide by zero
    if (fMin == fMax) {
        return 0.0;
    }

    double fScaled = (fVal - fMin) / (fMax - fMin);

    // Clamp the result between 0.0 and 1.0
    if (fScaled < 0.0) fScaled = 0.0;
    if (fScaled > 1.0) fScaled = 1.0;

    return fScaled;
}

/**
 * @brief Determines the locale-specific temperature units
 *
 * @return - the temperature units C or F
 *
 */
+ (NSString *)getTemperatureUnits {
    
    NSLocale *locale = [NSLocale currentLocale];
    NSMeasurementFormatter *formatter = [[NSMeasurementFormatter alloc] init];
    formatter.locale = locale;

    // Create a sample temperature measurement
    NSMeasurement *tempMeasurement =
                [[NSMeasurement alloc] initWithDoubleValue:0
                                                      unit:NSUnitTemperature.celsius];

    NSString *formatted = [formatter stringFromMeasurement:tempMeasurement];

    if ([formatted containsString:@"F"]) {
        return @"F";
    } else if ([formatted containsString:@"C"]) {
        return @"C";
    }
    return @"";
}

/**
 * @brief Converts a kelvins temperature to the locale-specific temperature
 *
 * @param kelvins - the kelvins value to convert
 * @param units - the returned units
 *
 * @return - locale specific temperature
 */
+ (CGFloat)kelvinsToLocaleTemp:(CGFloat)kelvins
                 returnedUnits:(NSString **)units {
    
    // Did we get the parameters we need?
    if ( units == nil ) {
        return 0.0f;
    }

    // Are we running in farenheit territory?
    CGFloat result = kelvins - 273.15;
    *units=[Utils getTemperatureUnits];
    if ( [*units isEqualToString:@"F"] ) {
        result = result * (9.0 / 5.0) + 32.0;
        *units = @"F";
    } else {
        *units = @"C";
    }
    return result;
}

/**
 * @brief Determines whether the app is running in a sandboxed environment
 *
 * Project Settings - Signing & Capabilities - +Capability - App Sandbox
 *
 * @return - whether the app is sandboxed
 */
+ (BOOL)runningInSandbox {
    
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    NSString *sandboxID = env[@"APP_SANDBOX_CONTAINER_ID"];
    return isValidNSString(sandboxID);
}

/**
 * @brief Reads a specified embedded property name from the specified IOService
 *
 * @note Using this method will get your app rejected if you're submitting to the App Store
 *
 * @param propertyName - the embedded property name for the specified IOService
 * @param ioServiceName - the name of the IOService
 *
 * @return NSObject - generic return representing the property value, or nil on failure
 *
 */
+ (NSObject *)readEmbeddedProperty:(NSString *)propertyName
                 forIOServiceNamed:(NSString *)ioServiceName {

    // Did we get the parameters we need?
    if ( !isValidNSString(propertyName) ||
         !isValidNSString(ioServiceName) ) {
        
        return nil;
    }
    
    io_service_t ioSvc = IOServiceGetMatchingService(kIOMainPortDefault,
        IOServiceMatching(safeCharFromNSS(ioServiceName)));

    if (!ioSvc) {
        NSLog(gErrLrtIOServiceNotFound,
              __func__,
              ioServiceName);
        return nil;
    }

    CFMutableDictionaryRef properties = NULL;
    kern_return_t result = IORegistryEntryCreateCFProperties(ioSvc,
                                                             &properties,
                                                             kCFAllocatorDefault,
                                                             0);

    if (result != KERN_SUCCESS || !properties) {
        
        IOObjectRelease(ioSvc);
        NSLog(gErrLrtIOServiceProperties,
              __func__,
              ioServiceName);
        return nil;
    }

    // Can we get the specified property?
    NSDictionary *props = (__bridge_transfer NSDictionary *)properties;
    NSNumber *propVal = props[propertyName];
    if ( !isValidNSNumber(propVal) ) {
        
        IOObjectRelease(ioSvc);
        NSLog(gErrLrtIOServiceProp,
              __func__,
              ioServiceName);
        return nil;
    }

    IOObjectRelease(ioSvc);
    
    return propVal;
}

/**
 * @brief Reads the battery temperature from IOServices
 *
 * This method only works for MacBooks that have a battery as a power source. Apple desktop
 * models such as Mac mini, Studio & Pro are not supported.
 *
 * I dream of a world, where one day Apple can provide the granular temperature of their systems
 * via a simple, sandbox friendly API that doesn't make me feel like a criminal.
 *
 * We read two properties of the AppleSmartBattery because each property has it's own pros
 * and cons based on the state of the device. Note: The scanForIOServices method below
 * which can help you dig into services.
 *
 * @note Using this method will get your app rejected if you're submitting to the App Store
 *
 * @param temp - the returned temperature in Kelvins
 *
 * @return NSObject - generic return representing the property value, or nil on failure
 * 
 */

+ (BOOL)getBatteryTemperature:(CGFloat *)temp {
    
    // Did we get the parameters we need?
    if ( temp == nil ) {
        return NO;
    }
    
    NSString *ioSvcName=@"AppleSmartBattery";
    NSString *ioSvcProp1=@"VirtualTemperature";
    NSString *ioSvcProp2=@"Temperature";
    
    // Can we read the VirtualTemperature of the Apple battery?
    NSObject *objVal=[Utils readEmbeddedProperty:ioSvcProp1
                               forIOServiceNamed:ioSvcName];
    if ( !isValidNSNumber(objVal) ) {
        
        return NO;
    }
    
    // Convert deciKelvins to local units (F/C)
    CGFloat fTempKelvins = [(NSNumber *)objVal floatValue]/10.0;

    // Is our temperature within a valid range?
    if ( fTempKelvins < SYSTEMP_MIN_KELVINS ||
         fTempKelvins > SYSTEMP_MAX_KELVINS ) {
        
        // No, can we read the raw Temperature?
        objVal=[Utils readEmbeddedProperty:ioSvcProp2
                         forIOServiceNamed:ioSvcName];
        if ( !isValidNSNumber(objVal) ) {
            
            return NO;
        }
        fTempKelvins = [(NSNumber *)objVal floatValue]/10.0;
        
        // Is our temperature within a valid range?
        if ( fTempKelvins < SYSTEMP_MIN_KELVINS ||
             fTempKelvins > SYSTEMP_MAX_KELVINS ) {
            return NO;
        }
    }
    
    *temp = fTempKelvins;
    
    return YES;
}

/**
 * @brief Removes all temporary files matching a specified template
 *
 * @return the status of the operation
 *
 */
+ (BOOL)removeTempFilesMatchingTemplate:(NSString *)templ {
    
    // Did we get the parameters we need?
    if ( !isValidNSString(templ) ) {
        return NO;
    }
    
    NSError *e = nil;
    NSString *tempDir = NSTemporaryDirectory();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *contents = [fm contentsOfDirectoryAtPath:tempDir
                                                error:&e];
    if ( e ) {
        NSLog(gErrLrtEnumeratingFolder,
              __func__,
              tempDir,
              safeDesc(e),
              safeCode(e));
        return NO;
    }
    
    // Define pattern using NSPredicate (wildcard: tempfile-*.tmp)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF LIKE %@", templ];
    NSArray *matchingFiles = [contents filteredArrayUsingPredicate:predicate];
    
    // Can we remove these files?
    BOOL countFailed=0;
    for ( NSString *fileName in matchingFiles ) {
        
        NSString *fullPath = [tempDir stringByAppendingPathComponent:fileName];
        if ( ![fm removeItemAtPath:fullPath
                             error:&e] ) {
            countFailed++;
            NSLog(gErrLrtCantRemoveFile,
                  __func__,
                  fullPath,
                  safeDesc(e),
                  safeCode(e));
            continue;
        }
    }
    return (countFailed == 0);
}

/**
 * @brief Removes leading and trailing whitespace from a string
 *
 * @return the new string
 *
 */
+ (NSString *)stripWhitespace:(NSString *)str {
    
    if ( !isValidNSString(str) ) {
        return @"";
    }
    NSMutableCharacterSet *wsChars=[NSMutableCharacterSet whitespaceCharacterSet];
    [wsChars formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
    return [str stringByTrimmingCharactersInSet:wsChars];
}

/**
 * @brief Enable this if you are looking for interesting machine-specific sensor values
 *
 * @note Using this method will get your app rejected if you're submitting to the App Store
 *
 */

//+ (void)scanForIOServices {
//
//    io_iterator_t iterator;
//    kern_return_t kr = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOService"), &iterator);
//    if (kr != KERN_SUCCESS) {
//        NSLog(@"Failed to get IOService iterator: %d", kr);
//        return;
//    }
//
//    io_service_t service;
//    while ((service = IOIteratorNext(iterator)) != 0) {
//        CFStringRef classNameCF = IOObjectCopyClass(service);
//        NSString *className = (__bridge_transfer NSString *)classNameCF;
//
//        // Filter to likely sensor/thermal services
//        if ([className localizedCaseInsensitiveContainsString:@"Apple"] ||
//            [className localizedCaseInsensitiveContainsString:@"Therm"] ||
//            [className localizedCaseInsensitiveContainsString:@"Sensor"]) {
//
//            NSLog(@"\nFound service: %@", className);
//
//            CFMutableDictionaryRef props = NULL;
//            kern_return_t res = IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0);
//            if (res == KERN_SUCCESS && props != NULL) {
//                NSDictionary *properties = (__bridge_transfer NSDictionary *)props;
//
//                for (NSString *key in properties) {
//                    id value = properties[key];
//                    if ([key localizedCaseInsensitiveContainsString:@"temp"] ||
//                        [key localizedCaseInsensitiveContainsString:@"temperature"]) {
//                        NSLog(@"  %@ = %@", key, value);
//                    }
//                }
//            } else {
//                NSLog(@"  Could not get properties for this service.");
//            }
//        }
//
//        IOObjectRelease(service);
//    }
//    IOObjectRelease(iterator);
//}

@end


