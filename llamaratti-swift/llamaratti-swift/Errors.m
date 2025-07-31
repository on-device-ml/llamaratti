/**
 * @file Errors.m
 *
 * @brief Error constants
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "Errors.h"

// Error strings
const NSString *gErrLrtGeneric=@"%s | 􀇾 %s";
const NSString *gErrLrtException=@"%s | 􀇾 ERROR: An exception occurred. Error=%s, Code=%ld";

const NSString *gErrLrtParams=@"%s | 􀇾 ERROR: One or more parameters were not specified";
const NSString *gErrLrtCantLoadFile=@"%s | 􀇾 ERROR: Unable to load file '%@'. Error='%s', Code=%ld";
const NSString *gErrLrtCantRemoveFile=@"%s | 􀇾 ERROR: Unable to remove file '%@'. Error='%s', Code=%ld";
const NSString *gErrLrtHashCheckFail=@"%s | 􀇾 ERROR: Hash check of the file '%@' has failed.";
const NSString *gErrLrtLlamaContext=@"%s | 􀇾 ERROR: Failed to create llama_context.";
const NSString *gErrLrtTokenizePrompt=@"%s | 􀇾 ERROR: Failed to tokenize the prompt.";
const NSString *gErrLrtContextSizeExceeded=@"%s | 􀇾 ERROR: The context size has been exceeded.";
const NSString *gErrLrtDecodeFailed=@"%s | 􀇾 ERROR: The decode failed.";
const NSString *gErrLrtTokenToPiece=@"%s | 􀇾 ERROR: Failed to convert token to piece.";
const NSString *gErrLrtOutOfMemory=@"%s | 􀇾 ERROR: Out of memory.";
const NSString *gErrLrtApplyChatTemplate=@"%s | 􀇾 ERROR: Unable to apply chat template.";
const NSString *gErrLrtCantLaunchApp=@"%s | 􀇾 ERROR: Unable to launch application '%@'. Error='%s', Code=%ld";
const NSString *gErrLrtFontRegFailed=@"%s | 􀇾 ERROR: Font registration failed for '%@'. Error='%s', Code=%ld";
const NSString *gErrLrtGetMemFailed=@"%s | 􀇾 ERROR: Unable to get system memory metric. Error='%s', Code=%ld";
const NSString *gErrLrtGetDskSpcFailed=@"%s | 􀇾 ERROR: Unable to get disk space metric for '%@'. Error='%s', Code=%ld";
const NSString *gErrLrtConvertImageFail=@"%s | 􀇾 ERROR: Unable to convert image '%@'.";
const NSString *gErrLrtEnumeratingFolder=@"%s | 􀇾 ERROR: Unable to enumerate files in folder '%@'. Error='%s', Code=%ld";

const NSString *gErrLrtIOServiceNotFound=@"%s | 􀇾 ERROR: The specified IOService '%@' was not found.";
const NSString *gErrLrtIOServiceProperties=@"%s | 􀇾 ERROR: Unable to get properties for the specified IOService '%@'.";
const NSString *gErrLrtIOServiceProp=@"%s | 􀇾 ERROR: Unable to get property '%@' for the specified IOService '%@'.";

const NSString *gErrLrtBookmarkCreate=@"%s | 􀇾 ERROR: Unable to create bookmark for '%@'. Error='%s', Code=%ld";
const NSString *gErrLrtBookmarkResolve=@"%s | 􀇾 ERROR: Unable to resolve bookmark. Error='%s', Code='%ld'";
const NSString *gErrLrtBookmarkAccess=@"%s | 􀇾 ERROR: Unable to start accessing security scoped resource for '%@'.";

const NSString *gErrLrtCantLoadModel=@"􀇾 ERROR: Unable to load/reload model '%@'";

