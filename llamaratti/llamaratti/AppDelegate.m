/**
 * @file AppDelegate.m
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

#import "AppDelegate.h"
#import "ViewController.h"
#import "AboutWindowController.h"
#import "Shared.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

/**
 * @brief applicationDidFinishLaunching
 *
 * @param aNotification unused
 *
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Enable this to Force dark mode
    //[NSApp setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
    
    // Set the minimum window size
    NSWindow *window=[[[NSApplication sharedApplication] windows] firstObject];
    if ( window ) {
        NSSize minSize = NSMakeSize(APP_WINDOW_MIN_WIDTH,APP_WINDOW_MIN_HEIGHT);
        [window setMinSize:minSize];
    }
}

/**
 * @brief Displays the about dialog
 *
 * @param sender unused
 *
 */
- (IBAction)showAboutPanel:(id)sender {
    
    _windowAbout = [[AboutWindowController alloc] init];
    [_windowAbout showWindow:self];
}

/**
 * @brief applicationWillTerminate
 *
 * @param aNotification unused
 *
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

/**
 * @brief applicationSupportsSecureRestorableState
 *
 * @param app unused
 *
 */
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

/**
 * @brief applicationShouldTerminateAfterLastWindowClosed
 *
 * @param app unused
 *
 */
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
    return YES;
}

@end
