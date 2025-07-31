/**
 * @file AppDelegate.swift
 *
 * @brief Application Delegate for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

import Cocoa

@main

/**
 * @class AppDelegate
 * @brief Application Delegate class for Llamaratti
 *
 */
class AppDelegate: NSObject, NSApplicationDelegate {

    var aboutWindow : AboutWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Set the minimum window size
        let window = NSApplication.shared.windows.first
        window?.minSize = AppConstants.Display.displayMinSize
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    /**
     * @brief Displays the about dialog
     *
     * @param sender unused
     *
     */
    @IBAction func showAboutPanel(_ sender: Any) {

        self.aboutWindow = AboutWindowController()
        self.aboutWindow!.showWindow(self)
    }

}

