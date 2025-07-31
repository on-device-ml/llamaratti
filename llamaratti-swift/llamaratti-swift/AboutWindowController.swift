/**
 * @file AboutWindowController.swift
 *
 * @brief About dialog for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

import Cocoa

class AboutWindowController: NSWindowController {

    @IBOutlet weak var imgViewLogo: NSImageView!
    @IBOutlet var textAck: NSTextView!
    
    override var windowNibName: NSNib.Name? {
            return NSNib.Name("AboutWindowController")
    }
    
    /**
     * @brief Initializes window controls & content
     *
     */
    override func windowDidLoad() {
        
        super.windowDidLoad()

        // Disable resize
        window?.styleMask.remove(.resizable)

        imgViewLogo.image = NSImage(named:"AppIcon")
        imgViewLogo.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        
        textAck.isSelectable = true
        textAck.isEditable = false

        self.window?.title = "About Llamaratti"
        
        let attrCredits : NSAttributedString = AckContent.buildAck()
        self.textAck.textStorage?.setAttributedString(attrCredits)
    }
    
    /**
     * @brief btnOk
     *
     */
    @IBAction func btnOk(_ sender: Any) {
        
        self.close()
    }
}
