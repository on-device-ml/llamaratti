/**
 * @file Shared.h
 *
 * @brief Shared defines/constants
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>

// Utility Macros

#define ULONGLONG unsigned long long

// Validity...
#define isValidString(s) (((s)!=nil)&&(strlen(s)>0))
#define isValidNSString(nss) (((nss)!=nil)&&([(nss) length]>0)?YES:NO)
#define isValidNSArray(arr) (((arr)!=nil)&&([(arr) count]>0)?YES:NO)
#define isValidNSDictionary(dict) (((dict)!=nil)&&([(dict) count]>0)&&([(dict)isKindOfClass:[NSMutableDictionary class]]||[(dict)isKindOfClass:[NSDictionary class]])?YES:NO)
#define isValidNSURL(url) (((url)!=nil)&&([[(url)path] length]>0)?YES:NO)
#define isValidFileNSURL(url) (((url)!=nil)&&([[(url)path] length]>0)&&[url isFileURL]?YES:NO)
#define isValidNSData(data) ((data!=nil)&&([data length]>0)&&[data isKindOfClass:[NSData class]]?YES:NO)
#define isValidNSNumber(num) ([num isKindOfClass:[NSNumber class]]?YES:NO)

#define isInstanceOfClass(obj,type) ((obj!=nil)&&[(obj) isKindOfClass:(type)])

// Conversion...

// NSString/char
#define safeCharFromNSS(s) (char *)(s!=nil?[s UTF8String]:"")
#define safeNSSFromChar(nss) (isValidString(nss)?[NSString stringWithUTF8String:nss]:@"")

// NSException
#define safeName(e) (e!=nil?[[e name] UTF8String]:"")
#define safeReason(e) (e!=nil?[[e reason] UTF8String]:"")

// NSError
#define safeDesc(e) (e!=nil?[[e localizedDescription] UTF8String]:"")
#define safeCode(e) (e!=nil?[e code]:0)

// Toggle level of Mac details in the title bar
#define DISPLAY_DETAILED_DEVICE         NO

// Toggle model hash verification
#define VERIFY_MODEL_HASHES             NO

#define TEXT_INSETS                     NSMakeSize(10, 10)

#define BORDER_WIDTH                    1
#define BORDER_RADIUS                   10

// Gauges
#define GAUGE_TRACK_LINE_WIDTH          2.0

// LLM TEMP - Thresholds
#define THRESHOLD_LLM_TEMP_MIN          LLAMA_MIN_TEMP
#define THRESHOLD_LLM_TEMP_DEFAULT      LLAMA_DEFAULT_TEMP
#define THRESHOLD_LLM_TEMP_WARN         1.0f
#define THRESHOLD_LLM_TEMP_DANGER       1.2f
#define THRESHOLD_LLM_TEMP_MAX          LLAMA_MAX_TEMP

// LLM CTX LEN - Thesholds
#define THRESHOLD_LLM_CTXLEN_MIN         2048
#define THRESHOLD_LLM_CTXLEN_DEFAULT     LLAMA_DEFAULT_CTXLEN
#define THRESHOLD_LLM_CTXLEN_WARN        65536
#define THRESHOLD_LLM_CTXLEN_DANGER      131072
#define THRESHOLD_LLM_CTXLEN_MAX         163840

// SYS MEM - Thresholds
#define THRESHOLD_SYSMEM_WARN            0.70
#define THRESHOLD_SYSMEM_DANGER          0.85

// SYS DSK - Thresholds
#define THRESHOLD_SYSDSK_WARN            0.70
#define THRESHOLD_SYSDSK_DANGER          0.85

// SYS TEMP - Thresholds
#define THRESHOLD_SYSTEMP_WARN           0.60
#define THRESHOLD_SYSTEMP_DANGER         0.70
#define THRESHOLD_SYSTEMP_MAX            380.0

// Response Field - Image sizes
#define RESPONSE_IMAGE_SIZE              500
#define RESPONSE_IMAGE_AUDIO_SIZE        150
#define RESPONSE_IMAGE_ICON_SIZE         45

// Window Size
#define APP_WINDOW_MIN_WIDTH         980.0
#define APP_WINDOW_MIN_HEIGHT        743.0

// Font Sizes
#define FONT_SIZE_SMALL              14
#define FONT_SIZE_MEDIUM             18
#define FONT_SIZE_LARGE              20
#define FONT_SIZE_HUGE               25

#define FONT_SIZE_GAUGE_TITLE        13
#define FONT_SIZE_GAUGE_TEXT         16

extern NSString * const gAppName;

// User Defaults
extern NSString * const gPrefsLastModelPaths;
extern NSString * const gPrefsLastModelBookmarks;
extern NSString * const gPrefsLastPrompts;
extern NSString * const gPrefsLastArgs;

// Fonts...
extern NSString * const gFontNameLight;
extern NSString * const gFontNameNormal;
extern NSString * const gFontNameMedium;
extern NSString * const gFontNameDemiBold;
extern NSString * const gFontNameBold;
extern NSString * const gFontNameLogo;
extern NSString * const gFontNameGauge;
extern NSString * const gFontNameGaugeBold;
extern NSString * const gFontFilenameLogo;

// Colors...
#define COLOR_LIME              @"defe7f"
#define COLOR_CYAN              @"00ffff"
#define COLOR_ROSSOCORSA        @"DC0000"
#define COLOR_ROYAL_BLUE        @"0072ff"
#define COLOR_PINK              @"ff0091"

// Remember user prompts
#define REMEMBER_USER_PROMPTS           1

// Image Ripple Effect...

// Enable ripple images when adding
#define RIPPLE_IMAGES_DURING_ADDING     1

// Enable ripple images during inference
#define RIPPLE_IMAGES_DURING_INFERENCE  0

// How long to ripple
#define RIPPLE_IMAGES_DURATION          0.5

// What kind of loss when converting images
#define IMAGE_CONVERSION_LOSS           1.0


