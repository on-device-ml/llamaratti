/**
 * @file AppDelegate.h
 *
 * @brief Application Delegate for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 * @attention
 * This example code is subject to change as llama multimodal continues to
 * evolve and is therefore not production ready.
 *
 */

#import <Cocoa/Cocoa.h>
#import "AboutWindowController.h"
#import "ViewController.h"

/**
 * @class AppDelegate
 * @brief Application Delegate class for Llamaratti
 *
 */
@interface AppDelegate : NSObject <NSApplicationDelegate>

@property AboutWindowController *windowAbout;

@end

