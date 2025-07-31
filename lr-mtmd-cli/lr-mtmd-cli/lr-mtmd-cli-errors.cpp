/**
 *
 * @file lr-mtmd-cli-errors.cpp
 *
 * @brief Defines error constants
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "lr-mtmd-cli-errors.h"

// Error strings
const char *gErrMtmdGeneric="{} | 􀇾 {}";
const char *gErrMtmdParams="{} | 􀇾 ERROR: One or more parameters were not specified";
const char *gErrMtmdLoadVisionModel="{} | 􀇾 ERROR: Unable to load vision model '{}'.";
const char *gErrMtmdTokenize="{} | 􀇾 ERROR: Unable to tokenize prompt. Result={}.";
const char *gErrMtmdEvalPrompt="{} | 􀇾 ERROR: Unable to evaluate prompt. Result={}.";
const char *gErrMtmdParseParams="{} | 􀇾 ERROR: Unable to parse parameters";
const char *gErrMtmdClientContext="{} | 􀇾 ERROR: Unable to create client context. Desc={}";
const char *gErrMtmdDecodeToken="{} | 􀇾 ERROR: Unable to decode token";
const char *gErrMtmdLoadMedia="{} | 􀇾 ERROR: Unable to load media '{}'";
