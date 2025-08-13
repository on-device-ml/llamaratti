/**
 * @file DragDropTextView.swift
 *
 * @brief NSTextView subclass to support drag/drop and other custom stuff
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
import Cocoa

class DragDropTextView: NSTextView {

    // Placeholder string is not supported by default in NSTextView
    var placeholderString: String?
    
    var dragAccepted: Bool = false
    var dragAborted: Bool = false
    var vcParent: ViewController?
    
    private var savedBorderColor: CGColor?
    private var savedBorderWidth: CGFloat = 0

    /**
     * @brief Initializes user interface elements
     *
     */
    override func awakeFromNib() {
        super.awakeFromNib()

        wantsLayer = true
        if let layer = self.layer {
            savedBorderColor = layer.borderColor
            savedBorderWidth = layer.borderWidth
        }

        registerForDraggedTypes([.fileURL])
    }

    /**
     * @brief draw
     *
     * Required to update placeholder, which is not supported by NSTextView
     *
     */
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // If there is no text, draw the placeholder
        if string.isEmpty, let placeholder = placeholderString {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.placeholderTextColor,
                .font: self.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
            let rect = NSInsetRect(bounds,14, 10)
            placeholder.draw(in: rect,
                withAttributes: attributes)
        }
    }

    /**
     * @brief didChangeText
     *
     * Required to update placeholder, which is not supported by NSTextView
     *
     */
    override func didChangeText() {
        super.didChangeText()
        needsDisplay = true
    }
    
    // MARK: - NSDraggingDestination

    /**
     * @brief prepareForDragOperation
     *
     */
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return dragAccepted
    }

    /**
     * @brief performDragOperation
     *
     * @returns whether we have accepted the operation
     */
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return dragAccepted
    }

    /**
     * @brief draggingEntered
     *
     * Highlights the text field when files are dragged into the control
     *
     * @returns NSDragOperation
     */
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if ( !dragAccepted ) {
            return []
        }

        layer?.borderColor = NSColor(named: "HighlightColor")?.cgColor
        layer?.borderWidth = 2
        dragAborted = false

        return .every
    }
    
    /**
     * @brief draggingUpdated
     *
     * @returns NSDragOperation
     */
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dragAccepted ? .every : []
    }
    
    /**
     * @brief Called when the dragging operation has ended
     *
     */
    override func draggingExited(_ sender: NSDraggingInfo?) {
        layer?.borderColor = savedBorderColor
        layer?.borderWidth = savedBorderWidth
        dragAborted = true
    }

    /**
     * @brief Validates dragged files & adds them to the current context
     *
     * Validates the files dragged into the control and adds them to the
     * current context
     *
     * @param sender - NSDraggingInfo
     *
     */
    override func draggingEnded(_ sender: NSDraggingInfo) {
        
        layer?.borderColor = savedBorderColor
        layer?.borderWidth = savedBorderWidth

        // Are we accepting drag operations?
        if ( !dragAccepted || dragAborted ) {
            return
        }
        
        // Do we have our parent view controller?
        if ( vcParent == nil ) {
            return
        }
        
        // Are we busy?
        if ( vcParent!.isBusy() ) {
            return
        }
        
        // Do we have a Wrapper?
        let llamaWrapper = vcParent?.llamaWrapper
        if ( llamaWrapper == nil ) {
            return
        }
        
        let pb = sender.draggingPasteboard
        guard pb.types?.contains(.fileURL) == true else {
            return
        }

        // Can we get the dragged URLs?
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            // Note: The magic option to enable security-scoped drag drop
            NSPasteboard.ReadingOptionKey(rawValue: "NSPasteboardURLReadingSecurityScopedFileURLsKey"): true
        ]
        guard let arrDraggedURLs = pb.readObjects(
                 forClasses: [NSURL.self],
                    options: options) as? [URL], !arrDraggedURLs.isEmpty else {
            return
        }
        
        // Add any supported dropped file(s)...
        var countAdded = 0
        let countMax = LlamarattiWrapper.maxSupportedMedia()
        for url in arrDraggedURLs {
            
            // Is this a supported audio file?
            if ( vcParent!.llamaWrapper!.isSupportedAudioURL(url) ) {
                
                // Can we load the audio into our context?
                if ( vcParent!.loadAudioIntoContext(urlAudio: url) ) {
                    countAdded += 1
                }
            }
            
            // Is this a supported image?
            else if ( llamaWrapper!.isSupportedImageURL(url) ) {
                
                // Can we load the image into our context?
                if ( vcParent!.loadImageIntoContext(urlImage: url) ) {
                    countAdded += 1
                }
            }

            // Have we added enough?
            if countAdded > countMax {
                break
            }
        }

        // Did we add any media files?
        if countAdded == 0 {
            
            // No, notify...
            let modelName = llamaWrapper!.title()
            let suppTypes = vcParent!.llamaWrapper!.supportedMediaTypes()
            let title = "Media Type Not Supported"
            let msg = String(format:"'%@' does not support this media type. Supported types are:\n\n%@\n",modelName!,suppTypes!)
            _ = vcParent!.showAlert(title: title,
                                  message: msg,
                                  buttons: ["Ok"])
        } else {
            // Hide the drag/drop icon
            vcParent?.toggleDragDropIcon(bDisplay: false)
        }
    }
}
