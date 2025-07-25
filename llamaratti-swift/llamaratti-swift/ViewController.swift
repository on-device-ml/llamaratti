/**
 * @file ViewController.m
 *
 * @brief Application View Controller for Llamaratti
 *
 * Demonstrates use of the LlamarattiWrapper.h/mm Objective-C++ wrapper for llama.cpp
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 * @attention This example code is subject to change as llama multimodal continues to
 * evolve, and is therefore not production ready
 *
 * References:
 *
 * @see https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md
 * @see https://huggingface.co/collections/ggml-org/multimodal-ggufs-68244e01ff1f39e5bebeeedc
 * @see https://github.com/ggml-org/llama.cpp/discussions/5141
 * @see https://huggingface.co/TheBloke
 * @see https://simonwillison.net/2025/May/10/llama-cpp-vision/
 *
 */

import Cocoa
import AppKit
import UniformTypeIdentifiers

// MARK: App Constants
// ---------------------------------------------------------------------------

struct AppConstants {
    
    struct ModelParams {
        
        // Default Context Length
        static let defaultCtxLen = UInt32(LLAMA_DEFAULT_CTXLEN)

        // Default Temperature
        static let defaultTemp = Float(LLAMA_DEFAULT_TEMP)
        
        // Default Temperature
        static let defaultSeed = UInt32(LLAMA_DEFAULT_SEED)
        
        // 👇👇👇 Verify Model Hashes (Disable to speed things up)
        static let verifyModels = false

        static let displayDetailedDevice : Bool = false
    }
    
    struct ModelFolders {
        
        // Where llama.cpp stores its downloaded models
        static let pathLlamaCacheFolder = "Library/Caches/llama.cpp"
    }
    
    struct Fonts {
        
        // Fonts Available
        static let fontLightName="Avenir Next Ultra Light"
        static let fontNormalName="Avenir Next Regular"
        static let fontMediumName="Avenir Next Medium"
        static let fontDemiBoldName="Avenir Next Demi Bold"
        static let fontBoldName="Avenir Next Bold"
        static let fontLogoPSName="FerroRosso"
        static let fontLogoFilename="FerroRosso"
        static let fontLogoExt="ttf"

        // Fonts Used
        static let fontSmallNormal=NSFont(name: fontNormalName, size: 14)
        static let fontSmallNormalDate=NSFont(name: fontNormalName, size: 14)
        static let fontMediumLight=NSFont(name: fontLightName, size: 18)
        static let fontNormal=NSFont(name: fontNormalName, size: 18)
        static let fontLargeDemiBold=NSFont(name: fontDemiBoldName, size:20)
    }
    
    struct Attributes {

        // Used to format attributed strings
        static let paraAlignRight: NSMutableParagraphStyle = {
                let style = NSMutableParagraphStyle()
                style.alignment = .right
                return style
        }()
        
        static let dictAttrDateLeft: [NSAttributedString.Key: Any] = {
            return [
                .font: AppConstants.Fonts.fontSmallNormalDate!,
                .foregroundColor: NSColor.gray
            ]
        }()
        
        static let dictAttrDateRight: [NSAttributedString.Key: Any] = {
            return [
                .font: AppConstants.Fonts.fontSmallNormalDate!,
                .foregroundColor: NSColor.gray,
                .paragraphStyle: paraAlignRight
            ]
        }()
        
        static let dictAttrResponseTitleLeft: [NSAttributedString.Key: Any] = {
            return [
                .font: AppConstants.Fonts.fontLargeDemiBold!,
                .foregroundColor: NSColor(named:"ResponseTextColor")!
            ]
        }()
        
        static let dictAttrResponseTitleRight: [NSAttributedString.Key: Any] = {
            return [
                .font: AppConstants.Fonts.fontLargeDemiBold!,
                .foregroundColor: NSColor(named:"ResponseTextColor")!,
                .paragraphStyle: paraAlignRight
            ]
        }()
        
        static let dictAttrResponseText: [NSAttributedString.Key: Any] = {
            return [
                .font: AppConstants.Fonts.fontNormal!,
                .foregroundColor: NSColor(named:"ResponseTextColor")!
            ]
        }()
    }
    
    struct ImageSizes {
        static let responseImageSize: Double  = 500.0
        static let responseImageAudioSize: Double = 100
        static let responseImageIconSize: Double  = 45.0
    }

    struct Images {
        static let modelEntityIcon = NSImage(named: "AppIcon")?.scaledProportionally(to: NSMakeSize(AppConstants.ImageSizes.responseImageIconSize, AppConstants.ImageSizes.responseImageIconSize))
    }
    
    struct Insets {
        static let textInsets = NSMakeSize(10, 10)
    }
    
    struct Strings {

        static let appName="Llamaratti"
        static let placeholderPromptNoModel = "Select \u{25B2} to load a model"
        static let placeholderPromptAsk = "Ask me anything, then select \u{25B6}"
    }

    struct URLs {
        static let llamaModels = "https://huggingface.co/collections/ggml-org/multimodal-ggufs-68244e01ff1f39e5bebeeedc"
    }
    
    struct Prefs {
        static let prefsLastModelPaths = "lastModelPaths"
    }
}

// MARK: Inline Functions
// ---------------------------------------------------------------------------

@inline(__always)
func hexClr(_ hex: Int) -> CGFloat {
    return CGFloat(hex)/0xFF
}

@inline(__always)
func isValidString(_ str: String?) -> Bool {
    return !(str?.isEmpty ?? true)
}

@inline(__always)
func isValidFileURL(_ url: URL?) -> Bool {
    return url != nil && url!.isFileURL
}

func isValidArray<T>(_ array: [T]?) -> Bool {
    guard let array = array, !array.isEmpty else {
        return false
    }
    return array.count > 0
}

@inline(__always)
func isValidModelPair(array: [Any]?) -> Bool {
  guard let array = array else { return false }
  return array.count == 2
}

// Extract a C string from an NSString/String
func safeCharFromNSS(_ s: NSString?) -> UnsafePointer<CChar> {
    return s?.utf8String ?? UnsafePointer<CChar>(strdup(""))
}

// MARK: ViewController
// ---------------------------------------------------------------------------

class ViewController: NSViewController {

    // Wrapper
    var llamaWrapper : LlamarattiWrapper?

    // Current Apple device
    private var appleDevice : String?
    
    // Model Information
    private var modelName : String?
    private var firstResponse : Bool = true

    // Images
    private var imgSupportsAudio : NSImage?
    private var imgSupportsImages : NSImage?

    private var imgCopy : NSImage?
    private var imgModel : NSImage?
    private var imgGPU : NSImage?
    private var imgClear : NSImage?
    private var imgStop : NSImage?
    private var imgGo : NSImage?

    // Attributed String
    private let attrNL=NSAttributedString(string:"\n")

    @IBOutlet var textResponse: DragDropTextView!
    
    @IBOutlet weak var imgViewDragDrop: NSImageView!
    @IBOutlet weak var textDragDrop: NSTextField!
    
    @IBOutlet weak var textPrompt: DragDropTextView!
    @IBOutlet weak var textStatus: NSTextField!
    @IBOutlet weak var activity : NSProgressIndicator!
    
    @IBOutlet weak var imgViewImages: NSImageView!
    @IBOutlet weak var imgViewAudio: NSImageView!
    
    @IBOutlet weak var btnCopyResponse: NSButton!
    @IBOutlet weak var btnModel: NSButton!
    @IBOutlet weak var btnGPU: NSButton!
    @IBOutlet weak var btnClear: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    @IBOutlet weak var btnGo: NSButton!

    @IBOutlet weak var textLogo: NSTextField!
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
    
    /**
     * @brief Initializes properties of the view controller
     */
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Enable this to clear prefs
        //resetPrefs()
        
        appleDevice = LlamarattiWrapper.appleSiliconModel(AppConstants.ModelParams.displayDetailedDevice)
        modelName = ""
        
        // Configure our UI controls
        configureControls()
                
        // Disable our multimedia support
        toggleMultimodalSupport(bImageSupport: false, bAudioSupport: false)

        // Disable controls initially
        toggleControls(enabled: false, stopEnabled: false, selectEnabled: true)
        
        // Update window title
        updateWindowTitle(modelTitle: "No Model Loaded")
        
        // Add observer for appearance changes
        self.view.addObserver(self, forKeyPath: "effectiveAppearance", options: .new,  context: nil)
    }
    
    /**
     * @brief Loads the last used model following initialization
     */
    override func viewDidAppear() {

        super.viewDidAppear()
        
        _ = self.reloadLastModelPair()
    }

    /**
     * @brief Observes appearance changes and updates controls accordingly
     */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if ( keyPath == "effectiveAppearance" ) {
            let newAppearance : NSAppearance = change![NSKeyValueChangeKey.newKey] as! NSAppearance

            var colorBtn : NSColor
            let appearances = [NSAppearance.Name.darkAqua, NSAppearance.Name.vibrantDark, NSAppearance.Name.accessibilityHighContrastDarkAqua, NSAppearance.Name.accessibilityHighContrastVibrantDark]
            if (( newAppearance.bestMatch(from: appearances) ) != nil) {
                colorBtn=NSColor(named:"ButtonTintColorDark")!
            } else {
                colorBtn=NSColor(named:"ButtonTintColorLight")!
            }

            // Update image tinting
            var imgBtn = imgSupportsImages!.imageTinted(with: colorBtn)
            imgBtn?.isTemplate = true
            imgViewImages.image = imgBtn
            
            imgBtn = imgSupportsAudio!.imageTinted(with: colorBtn)
            imgBtn?.isTemplate = true
            imgViewAudio.image = imgBtn
            
            // Update button image tinting
            imgBtn = imgCopy!.imageTinted(with: colorBtn)
            btnCopyResponse.image = imgBtn

            imgBtn = imgModel!.imageTinted(with: colorBtn)
            btnModel.image = imgBtn

            imgBtn = imgGPU!.imageTinted(with: colorBtn)
            btnGPU.image = imgBtn

            imgBtn = imgClear!.imageTinted(with: colorBtn)
            btnClear.image = imgBtn

            imgBtn = imgStop!.imageTinted(with: colorBtn)
            btnStop.image = imgBtn
            
            imgBtn = imgGo!.imageTinted(with: colorBtn)
            btnGo.image = imgBtn
        }
    }

    // MARK: Model
    // ---------------------------------------------------------------------------
    
    /**
     * @brief Loads the specified model pair
     *
     * @param arrModelPair - First element is the model URL, Second is the mmproj URL
     *
     * @return The status of the operation
     */
    private func loadModelPair(arrModelPair : Array<URL>) -> Bool {
        
        // Did we get the parameters we need?
        if ( !isValidModelPair(array: arrModelPair) ) {
            return false
        }
        
        // Disable Controls
        toggleControls(enabled: false, stopEnabled: false, selectEnabled: false)

        // Hide the drag/drop icon
        toggleDragDropIcon(bDisplay: false)
         
        toggleMultimodalSupport(bImageSupport: false, bAudioSupport: false)
        
        toggleAnimation(isOn: true)
        
        setPromptPlaceholder(placeholder: AppConstants.Strings.placeholderPromptNoModel)
        
        // Execute in background
        DispatchQueue.global(qos: .background).async {
            
            // Can we initialize our wrapper?
            let urlModel : URL = arrModelPair[0]
            let urlMMProj : URL = arrModelPair[1]
            self.modelName = LlamarattiWrapper.title(forModelURL: urlModel)
            
            // Update status
            self.appendStatus("Loading model %@...", self.modelName! )
            
            // Start Timer
            let dt : DTimer = DTimer.timer(withFunc: #function, andDesc: nil) as! DTimer
            
            self.llamaWrapper = LlamarattiWrapper( modelURL: urlModel,
                                                   andMMProjURL: urlMMProj,
                                                   verifyModels: AppConstants.ModelParams.verifyModels,
                                                   contextLen: AppConstants.ModelParams.defaultCtxLen,
                                                   temp: AppConstants.ModelParams.defaultTemp,
                                                   seed: AppConstants.ModelParams.defaultSeed,
                                                   target: self,
                                                   selector: #selector(ViewController.llamaEventsSelector))
            self.toggleAnimation(isOn: false)
            
            if ( self.llamaWrapper == nil ) {
                
                // No, outta here...
                self.toggleControls(enabled: false, stopEnabled: false, selectEnabled: true)
                
                self.appendStatus(gErrLrtCantLoadModel,self.modelName!)

                return
            }
            
            // Yes, record the time taken
            let interval : TimeInterval = dt.ticks()
            
            // Save them in prefs as last used
            _ = self.saveLastUsedModelPair(arrModelPair: arrModelPair)
            
            // Enable controls
            self.toggleControls(enabled: true, stopEnabled: false, selectEnabled: true)
            
            // Clear fields
            self.clearTextFields(clearPrompt: false, clearResponse: true, clearStatus: true)

            // Update window title
            self.updateWindowTitle(modelTitle: self.modelName!)
            
            // Update status
            self.appendStatus("Loaded model %@ in %.3fs",self.modelName!,interval)

            // Update our Prompt placeholder
            self.setPromptPlaceholder(placeholder: AppConstants.Strings.placeholderPromptAsk)
            
            // Update our multimedia support
            self.toggleMultimodalSupport(bImageSupport: self.llamaWrapper!.visionSupported,bAudioSupport: self.llamaWrapper!.audioSupported)
        }
        
        return true
    }

    /**
     * @brief Reloads the last successfully loaded model pair
     *
     * @return Bool - the status of the operation
     */
    private func reloadLastModelPair() -> Bool {
        
        // Do we have a previously saved model pair?
        let arrModelPair = getLastUsedModelPair()
        if ( !isValidModelPair(array: arrModelPair) ) {
            return false
        }
        return loadModelPair(arrModelPair: arrModelPair)
    }

    // MARK: User Interface - Fields
    
    /**
     * @brief Configures the user interface controls
     *
     */
    private func configureControls() {
        
        // Icon/Label - Drag/Drop
        imgViewDragDrop.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        imgViewDragDrop.image = NSImage(systemSymbolName: "photo.fill.on.rectangle.fill", accessibilityDescription: nil)!
        imgViewDragDrop.unregisterDraggedTypes()

        textDragDrop.alignment=NSTextAlignment.center
        textDragDrop.stringValue="Drag Media Here"
        textDragDrop.font=AppConstants.Fonts.fontSmallNormal
        textDragDrop.textColor=NSColor(named: "ResponseTextColor")
        textDragDrop.isSelectable=false
        textDragDrop.isEditable=false
        
        // Text View - Response
        textResponse.textColor = NSColor(named:"ResponseTextColor")!
        textResponse.backgroundColor = NSColor(named:"TextBackgroundColor")!
        textResponse.font = AppConstants.Fonts.fontNormal
        textResponse.isSelectable = true
        textResponse.isEditable = false
        textResponse.textContainerInset = AppConstants.Insets.textInsets
        textResponse.vcParent = self
        textResponse.dragAccepted = false

        // Text View - Prompt
        textPrompt.textColor = NSColor(named:"PromptTextColor")!
        textPrompt.backgroundColor = NSColor(named:"TextBackgroundColor")!
        textPrompt.font = AppConstants.Fonts.fontNormal
        textPrompt.isSelectable = true
        textPrompt.isEditable = true
        textPrompt.textContainerInset = AppConstants.Insets.textInsets
        textPrompt.vcParent = self
        textPrompt.dragAccepted = false
        setPromptPlaceholder(placeholder: AppConstants.Strings.placeholderPromptNoModel)

        // Logo, can we register our logo font?
        var fontLogo : NSFont
        if ( registerCustomFont(fontFilename: AppConstants.Fonts.fontLogoFilename,
                                fontExt: AppConstants.Fonts.fontLogoExt) ) {
            // Yes, use it
            fontLogo = NSFont(name: AppConstants.Fonts.fontLogoPSName, size:25)!
        } else {
            // No, use standard font
            fontLogo = NSFont(name: AppConstants.Fonts.fontNormalName, size:25)!
        }
        
        textLogo.stringValue=AppConstants.Strings.appName
        textLogo.alignment=NSTextAlignment.left
        textLogo.font=fontLogo
        textLogo.textColor=NSColor(named:"LogoTextColor")

        // Text Field - Status
        textStatus.textColor = NSColor.textColor
        textStatus.isEditable = false
        textStatus.font = AppConstants.Fonts.fontSmallNormal
        textStatus.textColor = NSColor(named:"StatusTextColor")
        textStatus.alignment = .right

        // Activity Indicator
        activity.isDisplayedWhenStopped = false
        
        // Available Multimedia Support Image Views
        imgViewImages.toolTip = "Supports Images"
        imgSupportsImages = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!

        imgViewAudio.toolTip = "Supports Audio"
        imgSupportsAudio = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)!

        // Buttons
        imgCopy = NSImage(systemSymbolName: "doc.on.doc.fill", accessibilityDescription: nil)!
        btnCopyResponse.image=imgCopy
        btnCopyResponse.toolTip = "Copy"
        
        imgModel = NSImage(systemSymbolName: "arrowtriangle.up.fill", accessibilityDescription: nil)!
        btnModel.image=imgModel
        btnModel.toolTip = "Load Model/Projection"
        btnModel.isEnabled=false

        imgGPU = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: nil)!
        btnGPU.image=imgGPU
        btnGPU.toolTip = "Show System Stats"
        
        imgClear = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
        btnClear.image=imgClear
        btnClear.toolTip = "Clear Chat History"
        
        imgStop = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: nil)!
        btnStop.image=imgStop
        btnStop.toolTip = "Stop Generating"
        
        imgGo = NSImage(systemSymbolName: "play.fill", accessibilityDescription: nil)!
        btnGo.image=imgGo
        btnGo.toolTip = "Start Generating"
    }
    
    /**
     * @brief Registers a specified custom font
     *
     * @param fontFilename - the filename of the font file (not the postscript name)
     * @param fontExt - the filename extension of the font file
     *
     * @return Bool - the status of the registration
     */
    private func registerCustomFont( fontFilename : String, fontExt : String ) -> Bool {
        
        let fontURL = Bundle.main.url(forResource: fontFilename, withExtension: fontExt)
        if ( fontURL == nil ) {
            NSLog(gErrLrtFontRegFailed,
                  safeCharFromNSS(#function),
                  fontFilename,
                  0,
                  "")
            return false
        }
        
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL! as CFURL, .process, &error)
        if let e = error?.takeUnretainedValue() {
            
            NSLog(gErrLrtFontRegFailed,
                  safeCharFromNSS(#function),
                  fontFilename,
                  Utils.safeDesc(from: e),
                  Utils.safeCode(from: e))
            
            appendStatus(gErrLrtFontRegFailed,
                         safeCharFromNSS(#function),
                         fontFilename,
                         Utils.safeDesc(from: e),
                         Utils.safeCode(from: e))

            return false
        }
        return true
    }

    /**
     * @brief Updates the window title with the model name & hardware type
     *
     * @param modelTitle - the currently loaded model
     *
     */
    private func updateWindowTitle(modelTitle: String) {
        
        DispatchQueue.main.async {
            let windowTitle: String
            
            if let device = self.appleDevice, !device.isEmpty {
                windowTitle = "\(modelTitle) - \(device) - \(AppConstants.Strings.appName)"
            } else {
                windowTitle = "\(modelTitle) - \(AppConstants.Strings.appName)"
            }
            self.view.window?.title = windowTitle
        }
    }

    /**
     * @brief Selectively clear UI text fields
     *
     * @param clearPrompt - clear the prompt field?
     * @param clearResponse - clear the response field?
     * @param clearStatus - clear the status field?
     *
     */
    private func clearTextFields(clearPrompt: Bool, clearResponse: Bool, clearStatus: Bool) {
        
        DispatchQueue.main.async {
            
            if ( clearPrompt) {
                self.textPrompt.string = ""
            }
            if ( clearResponse ) {
                self.textResponse.string = ""
            }
            if ( clearStatus ) {
                self.textStatus.stringValue = ""
            }
        }
    }

    /**
     * @brief Selectively enable/disable UI controls
     *
     * @param bEnabled - enable/disable all other controls?
     * @param bStopEnabled - enable/disable the Stop button?
     * @param bSelectEnabled - enable/disable the Select Model button?
     *
     */
    private func toggleControls(enabled : Bool, stopEnabled : Bool, selectEnabled : Bool ) {
        
        DispatchQueue.main.async {
            
            // Indicate whether response window is accepting dragged items
            self.textResponse.dragAccepted=enabled

            self.btnCopyResponse.isEnabled=enabled
            self.textPrompt.isEditable=enabled
            self.btnClear.isEnabled=enabled
            self.btnGo.isEnabled=enabled
            self.btnStop.isEnabled=stopEnabled
            self.btnModel.isEnabled=selectEnabled
        }
    }
            
    /**
     * @brief Selectively enable/disable multimedia support indicators
     *
     * Indicators on the UI are used to indicate the types of media that
     * the currently loaded model pair supports
     *
     * @param bTextSupported - whether the current model supports text
     * @param bImagesSupported - whether the current model supports images
     * @param bAudioSupported - whether the current model supports audio
     *
     */
    private func toggleMultimodalSupport(bImageSupport: Bool, bAudioSupport: Bool) {
        
        DispatchQueue.main.async {
            
            // Update status indicators
            let colorSupported=NSColor(named:"MediaSupportedColor")
            let colorNotSupported=NSColor(named:"MediaNotSupportedColor")
            
            self.imgViewImages.contentTintColor = bImageSupport ? colorSupported : colorNotSupported
            self.imgViewImages.toolTip = String(format: "Images %@Supported", bImageSupport ? "" : "Not ")

            self.imgViewAudio.contentTintColor = bAudioSupport ? colorSupported : colorNotSupported
            self.imgViewAudio.toolTip = String(format: "Audio %@Supported", bAudioSupport ? "" : "Not ")

            self.toggleDragDropIcon(bDisplay: bImageSupport||bAudioSupport)
        }
    }
    
    /**
     * @brief Selectively start/stop the activity indicator
     *
     * @param isOn - toggle activity
     *
     */
    private func toggleAnimation( isOn : Bool ) {
        
        DispatchQueue.main.async {
            
            if ( isOn ) {
                self.activity.startAnimation(self)
            } else {
                self.activity.stopAnimation(self)
            }
        }
    }

    // MARK: User Interface - Buttons

    /**
     * @brief Copies the text in the response window to the pasteboard
     *
     * @param sender - unused
     *
     */
    @IBAction func btnCopyResponse(_ sender: Any) {
        
        let text=textResponse.string
        if ( !isValidString(text) ) {
            return
        }
        Utils.copy(toPasteboard: text)
    }

    /**
     * @brief Displays the model load options menu
     *
     * @param sender - unused
     *
     * @todo - implement
     */
    @IBAction func btnModel(_ sender: Any) {
        
        showModelLoadOptionsMenu()
    }
    
    /**
     * @brief Launches the macOS Activity Monitor application
     *
     * Press CMD-4 to display GPU utilization
     *
     * @param sender - unused
     *
     */
    @IBAction func btnGPU(_ sender: Any) {
        
        // Launch Activity Monitor
        Utils.launchActivityMonitor()
    }

    /**
     * @brief Clears the current chat history & reloads the model
     *
     * @param sender - unused
     *
     */
    @IBAction func btnClear(_ sender: Any) {
        
        // Do we have an initialized wrapper?
        if ( self.llamaWrapper == nil ) {
            return
        }

        // Display confirmation
        let response = showAlert(title: "Clear Chat History?",
                               message: "",
                               buttons: ["Yes","Cancel"])
        if ( response != NSApplication.ModalResponse.alertFirstButtonReturn ) {
            return
        }
        
        clearTextFields(clearPrompt: true, clearResponse: true, clearStatus: true)
        
        // Execute in background
        DispatchQueue.global(qos: .background).async {
            
            // Clear history
            let bSuccess : Bool = self.llamaWrapper!.clearHistory()
            if ( bSuccess ) {
                self.appendStatus("History Cleared Successfully")
            } else {
                self.appendStatus("History Could not be Cleared")
            }
        }
        
        // Reload our last model
        _ = reloadLastModelPair()
    }
    
    /**
     * @brief Stops current text generation
     *
     * @param sender - unused
     *
     */
    @IBAction func btnStop(_ sender: Any) {
        
        // Do we have an initialized wrapper?
        if ( self.llamaWrapper == nil ) {
            return
        }

        // Stop
        llamaWrapper?.stop()
    }

    /**
     * @brief Starts text generation using the contents of the prompt field
     *
     * @param sender - unused
     *
     */
    @IBAction func btnGo(_ sender: Any) {
        
        // Do we have an initialized wrapper?
        if ( self.llamaWrapper == nil ) {
            return
        }

        // Can we process the prompt?
        let prompt = processPrompt(prompt: textPrompt.string)
        if ( !isValidString(prompt) ) {
            return
        }
        
        // Append the prompt to the context window
        let final = prompt + "\n"
        appendUserPromptToResponse(prompt: final)

        // Disable controls
        toggleControls(enabled: false, stopEnabled: true, selectEnabled: false)
        
        // Clear fields
        clearTextFields(clearPrompt: true, clearResponse: false, clearStatus: true)

        toggleAnimation(isOn: true)
        
        DispatchQueue.global(qos: .background).async {
            
            self.firstResponse=true

            // Start Timer
            let dt = DTimer.timer(withFunc: #function, andDesc: "") as! DTimer
            
            // Can we execute the prompt?
            var strStatus = ""
            let bSuccess = self.llamaWrapper?.generate(prompt)

            // Record the time taken
            let fmtInterval = String(format: "%.2f", dt.ticks())
            
            self.toggleAnimation(isOn: false)

            if ( bSuccess! ) {
                strStatus = "Generation Completed in \(fmtInterval)s"
            } else {
                
                // No, clear our chat history
                self.llamaWrapper!.clearHistory()
                
                strStatus = "Generation Aborted after \(fmtInterval)s. Chat context cleared."
                
                // Remove the currently loaded model from preferences
                //
                // This prevents us from trying to auto-load a model pair on startup
                // that the system can't handle (no soup for you!)
                //
                let arrModelPair = self.llamaWrapper!.modelPair() as? [URL]
                _ = self.clearRecentlyUsedModelPair(arrModelPair: arrModelPair!)
            }
            
            self.appendModelTextToResponse(prompt: "\n",
                                        firstCall: false)
            
            self.toggleControls(enabled: true, stopEnabled: false, selectEnabled: true)

            self.appendStatus(strStatus)
        }
    }

    /**
     * @brief Clears all previously used model pairs from UserDefaults
     *
     * @param sender - unused
     *
     */
    @objc private func btnClearPreviousUsedModelPairs(_ sender: Any) {
        
        // Do they want to proceed?
        let response = showAlert(title: "Clear Recently Loaded Models?",
                               message: "",
                               buttons: ["Yes","No"])
        if ( response != NSApplication.ModalResponse.alertFirstButtonReturn ) {
            return
        }

        if ( clearRecentlyUsedModelPairs() ) {
            appendStatus("Recent Models Cleared")
        }
    }

    /**
     * @brief Loads a specified model pair
     *
     * Called by the model selection menu to load a specified model pair
     *
     * @param sender - representedObject contains the model pair to load
     *
     */
    @objc private func btnLoadSelectedModelPair(_ sender: Any) {
        
        let arrModelPair : Array<URL> = ((sender as AnyObject).representedObject as? Array<URL>)!
        if ( !isValidArray(arrModelPair) ) {
            return
        }
        
        // Yes, can we initialize it?
        _ = loadModelPair(arrModelPair: arrModelPair)
    }
    
    /**
     * @brief Opens a folder selection dialog to the specified folder
     *
     * Called by the model selection menu to display a folder selection
     * dialog
     *
     * @param sender - representedObject an NSMenuItem. Title contains
     * the folder path
     *
     */
    @objc private func btnFolder(_ sender: Any) {
        
        let menuItem = sender as? NSMenuItem
        if ( menuItem == nil ) {
            return
        }
        let urlFolder = URL(fileURLWithPath: menuItem!.title)
        selectModelFiles(urlFolder: urlFolder)
    }

    /**
     * @brief Opens a folder selection dialog to the ~/Downloads folder
     *
     * Called by the model selection menu to display a folder selection
     * dialog
     *
     * @param sender - unused
     *
     */
    @objc private func btnFolderOther(_ sender: Any) {
        
        selectModelFiles(urlFolder: URL.downloadsDirectory)
    }

    /**
     * @brief Opens a URL to the model/mmproj downloads URL
     *
     * @param sender - unused
     *
     */
    @objc private func btnDownload(_ sender: Any) {
        
        Utils.open(URL(string: AppConstants.URLs.llamaModels))
    }

    /**
     * @brief Toggles display of drag/drop icon
     *
     */
    public func toggleDragDropIcon(bDisplay: Bool) {
        
        DispatchQueue.main.async {
            
            self.imgViewDragDrop.isHidden = !bDisplay
            self.textDragDrop.isHidden = !bDisplay
        }
    }

    /**
     * @brief Returns whether we are busy generating text
     *
     */
    public func isBusy() ->Bool {
        
        return self.llamaWrapper?.isBusy() ?? false
    }

    // MARK: User Interface  - Prompt/Response Fields
    // ---------------------------------------------------------------------------

    /**
     * @brief Loads the specified audio file into the current model context
     *
     * @param urlAudio the url of the audio file
     *
     * @return the status of the operation
     */
    public func loadAudioIntoContext(urlAudio : URL) -> Bool {
        
        // Do we have an initialized wrapper?
        if ( self.llamaWrapper == nil ) {
            return false
        }

        // Did we get the parameters we need?
        if ( !isValidFileURL(urlAudio) ) {
            return false
        }
        
        // Can we load the audio into our context?
        if ( !(llamaWrapper!.loadMedia(urlAudio)) ) {
            return false
        }
        
        // Yes, append the image to the response window
        let urlAudioImage=Bundle.main.urlForImageResource("audio")
        _ = appendUserImageToResponse(urlImage: urlAudioImage!,
                              useSecurityScope: false,
                                    imageWidth: AppConstants.ImageSizes.responseImageAudioSize)
        
        return true
    }

    /**
     * @brief Loads the specified image file into the current model context
     *
     * @param urlImage the url of the image file
     *
     * @return the status of the operation
     */
    public func loadImageIntoContext(urlImage : URL) -> Bool {
        
        // Do we have an initialized wrapper?
        if ( self.llamaWrapper == nil ) {
            return false
        }

        // Did we get the parameters we need?
        if ( !isValidFileURL(urlImage) ) {
            return false
        }
        
        // Can we load the audio into our context?
        if ( !(llamaWrapper!.loadMedia(urlImage)) ) {
            return false
        }

        // Append the image
        _ = appendUserImageToResponse(urlImage: urlImage,
                              useSecurityScope: true,
                                    imageWidth: AppConstants.ImageSizes.responseImageSize)
        
        return true
    }

    /**
     * @brief Appends the specified text to the status field
     *
     * @message - the message to append
     *
     */
    func appendStatus(_ format: String, _ args: CVarArg...) {
        let message = String(format: format, arguments: args)
        DispatchQueue.main.async {

            self.textStatus.stringValue = message
        }
    }
    
    /**
     * @brief Sets the placeholder string for the prompt field
     *
     * NSTextView doesn't natively support placeholder strings, so
     * we must use various trickery in DragDropTextView
     *
     * @param placeholder the placeholder string
     *
     */
    private func setPromptPlaceholder(placeholder: String){
        
        // Did we get the parameters we need?
        if ( !isValidString(placeholder) ) {
            return
        }
        
        DispatchQueue.main.async {
            self.textPrompt.placeholderString = placeholder
        }
    }

    /**
     * @brief Sets the user-provided prompt string in the prompt field
     *
     * @param prompt the user-provided prompt string
     *
     */
    private func setPrompt(prompt: String) {
        
        // Did we get the parameters we need?
        if ( !isValidString(prompt) ) {
            return
        }
        
        DispatchQueue.main.async {
            self.textPrompt.string = prompt
        }
    }
     
    /**
     * @brief Appends the specified user-provided prompt to the response field
     *
     * User prompt strings are RIGHT justified in the response window
     *
     * @param prompt the user prompt string to append
     */
    private func appendUserPromptToResponse(prompt: String) {
        
        // Hide the drag/drop icon
        toggleDragDropIcon(bDisplay: false)
        
        let attrDate = NSMutableAttributedString(string: getFormattedDate(), attributes: AppConstants.Attributes.dictAttrDateRight)
        attrDate.append(attrNL)

        let attrFinal = NSMutableAttributedString(string: prompt, attributes: AppConstants.Attributes.dictAttrResponseTitleRight)
        attrFinal.append(attrDate)
        
        DispatchQueue.main.async {
            self.textResponse.textStorage?.append(attrFinal)
            self.textResponse.scrollToEndOfDocument(nil)
        }
    }

    /**
     * @brief Appends the specified model-generated text to the response field
     *
     * Model text strings are LEFT justified in the response window. These are
     * prefixed by an entity icon, a model name & the current date/time
     *
     * @param prompt the prompt string to append
     * @param firstCall indicates whether this is the first append for the
     * current prompt
     */
    private func appendModelTextToResponse(prompt : String, firstCall: Bool ) {
        
        // Do we have an initialized wrapper?
        if ( self.llamaWrapper == nil ) {
            return
        }

        // Is this the first call for this response?
        let attrFinal = NSMutableAttributedString.init(string: "")
        if ( firstCall ) {
            
            // Hide the drag/drop icon
            toggleDragDropIcon(bDisplay: false)
            
            // Yes, append entity details & date/time...
            let attach = NSTextAttachment()
            attach.image = AppConstants.Images.modelEntityIcon
            
            //let attrModelIcon = NSAttributedString(attachment: attach, attributes: (dictAttrResponseTitleLeft as! [NSAttributedString.Key : Any]) )
             
            // Convert it to an NSMutableAttributedString
            let attrModelIcon: NSMutableAttributedString = NSAttributedString(attachment: attach).mutableCopy() as! NSMutableAttributedString
            attrModelIcon.addAttributes(AppConstants.Attributes.dictAttrResponseTitleLeft, range: NSMakeRange(0, attrModelIcon.length))
            
            let modelName = " " + self.modelName!
            let attrModel = NSMutableAttributedString(string: modelName, attributes: AppConstants.Attributes.dictAttrResponseTitleLeft)

            attrFinal.append(attrModelIcon)
            attrFinal.append(attrModel)
            attrFinal.append(attrNL)
            
            // Append the date/time
            let attrDate=NSMutableAttributedString(string: getFormattedDate(), attributes: AppConstants.Attributes.dictAttrDateLeft)

            attrFinal.append(attrDate)
            attrFinal.append(attrNL)
        }
        
        let attrResponse = NSMutableAttributedString(string: prompt, attributes: AppConstants.Attributes.dictAttrResponseText)
        attrFinal.append(attrResponse)

        DispatchQueue.main.async {
            
            self.textResponse.textStorage?.append(attrFinal)
            self.textResponse.scrollToEndOfDocument(nil)
        }
    }

    /**
     * @brief Returns the current date/time for use in the response window
     *
     * @return a String with the date
     */
    private func getFormattedDate() -> String {
        
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium

        let dateStr = df.string(from: Date.now)
        return dateStr
    }

    /**
     * @brief Appends the specified image file to the response field
     *
     * Scales down the image prior to appending to the response field
     *
     * @param urlImage the url of the image file
     *
     */
    public func appendUserImageToResponse( urlImage: URL,
                                           useSecurityScope: Bool,
                                           imageWidth: Double ) -> Bool {
        
        // Did we get the parameters we need?
        if ( !isValidFileURL(urlImage) ) {
            return false
        }
        
        // Were we asked to security scope this file access?
        if ( useSecurityScope ) {
            
            // Yes, can we start accessing this security-scoped url
            if ( !Utils.startAccessingSecurityScopedURLs([urlImage]) ) {
                
                // No, ...
                let filename=urlImage.lastPathComponent
                NSLog(gErrLrtBookmarkAccess,
                      safeCharFromNSS(#function),
                      filename)
                appendStatus(gErrLrtBookmarkAccess,
                             safeCharFromNSS(#function),
                             filename)
                
                return false
            }
        }
        
        // Can we load the image?
        let fullImage = NSImage(contentsOf: urlImage)

        if ( useSecurityScope ) {
            // Stop accessing this security-scoped url
            urlImage.stopAccessingSecurityScopedResource()
        }
        
        // Hide the drag/drop icon
        toggleDragDropIcon(bDisplay: false)
        
        let thumbNail=fullImage!.scaledProportionally(to: CGSizeMake(imageWidth,imageWidth))

        let attach=NSTextAttachment()
        attach.image = thumbNail
        
        // Convert it to an NSMutableAttributedString
        let attrImage: NSMutableAttributedString = NSAttributedString(attachment: attach).mutableCopy() as! NSMutableAttributedString
        attrImage.addAttributes(AppConstants.Attributes.dictAttrResponseTitleRight, range: NSMakeRange(0, attrImage.length))
        
        textResponse.textStorage?.append(attrNL)
        textResponse.textStorage?.append(attrImage)
        textResponse.textStorage?.append(attrNL)
        textResponse.scrollToEndOfDocument(nil)
        
        return true
    }
       
    // MARK: User Interface - User Interface - Misc
    // ---------------------------------------------------------------------------
    
    /**
     * @brief Displays a menu to load previous and new models
     *
     * Allows the user to select from previously used models as well as selecting
     * new model pairs from the llama.cpp cache folder and the ~/Downloads folder
     *
     */
    func showModelLoadOptionsMenu() {
        
        var index : NSInteger = 0
        let ctxMenu : NSMenu = NSMenu()
        
        // Do we have any previously saved models?
        let arrModelPairs = getRecentlyUsedModelPairs()
        if ( isValidArray(arrModelPairs) ) {
            
            // Yes, add them to the menu
            ctxMenu.insertItem(withTitle: "Recently Used...",
                               action: nil,
                               keyEquivalent: "",
                               at: index)
            index+=1
            
            ctxMenu.insertItem(NSMenuItem.separator(), at: index)
            index+=1
            
            // Add each previously loaded model to the menu
            for (_, arrModelPair) in arrModelPairs.enumerated() {
                
                // Is this model pair valid?
                if ( !isValidModelPair(array: arrModelPair) ) {
                    continue
                }
                
                // Get a title for this model url
                let thisModelURL = arrModelPair[0]
                let thisModelTitle = LlamarattiWrapper.title(forModelURL: thisModelURL)
                
                let mi : NSMenuItem = NSMenuItem.init(title: thisModelTitle!,
                                                      action: #selector(btnLoadSelectedModelPair(_:)),
                                                      keyEquivalent: "")
                mi.representedObject = arrModelPair
                ctxMenu.insertItem(mi, at: index)
                index+=1
            }
            
            ctxMenu.insertItem(withTitle: "Clear Recents...",
                               action: #selector(btnClearPreviousUsedModelPairs(_:)),
                               keyEquivalent: "",
                               at: index)
            index+=1
            
            ctxMenu.insertItem(NSMenuItem.separator(), at: index)
            index+=1
        }


        ctxMenu.insertItem(withTitle: "Load From Folder...",
                           action: nil,
                           keyEquivalent: "",
                           at: index)
        index+=1
        
        ctxMenu.insertItem(NSMenuItem.separator(), at: index)
        index+=1

        // Can we get the user's real home directory?
        let urlHomeDirectory : URL = Utils.getUsersRealHomeDirectory()
        if ( !isValidFileURL(urlHomeDirectory) ) {
            return
        }
        
        let urlLlamaCacheFolder: URL = urlHomeDirectory.appendingPathComponent(AppConstants.ModelFolders.pathLlamaCacheFolder)
        if ( FileManager.default.fileExists(atPath: urlLlamaCacheFolder.path()) ) {
            
            // Yes, add it to the menu
            ctxMenu.insertItem(withTitle: urlLlamaCacheFolder.path(),
                                  action: #selector(btnFolder(_:)),
                           keyEquivalent: "",
                                      at: index)
            index+=1
        }
        
        // Do we have a previously saved last used model pair?
        let arrModelPair : Array = getLastUsedModelPair()
        if ( isValidModelPair(array: arrModelPair) ) {
            
            // Yes, is it valid & was it loaded from the Llama cache folder?
            let urlModel : URL = arrModelPair[0]
            let urlLastModelFolder : URL = urlModel.deletingLastPathComponent()
            if ( !isValidFileURL(urlLastModelFolder) ||
                 urlLlamaCacheFolder != urlLastModelFolder ) {
                
                // No, add it to the menu
                ctxMenu.insertItem(withTitle: urlLastModelFolder.path(),
                                      action: #selector(btnFolder(_:)),
                               keyEquivalent: "",
                                          at: index)
                index+=1
            }
        }

        // Add an "Other..." option
        ctxMenu.insertItem(withTitle: "Other...",
                              action: #selector(btnFolderOther(_:)),
                       keyEquivalent: "",
                                  at: index)
        index+=1
        
        ctxMenu.insertItem(NSMenuItem.separator(), at: index)
        index+=1
        
        ctxMenu.insertItem(withTitle: "Download...",
                              action: #selector(btnDownload(_:)),
                       keyEquivalent: "",
                                  at: index)
        index+=1

        // Display the popup menu
        let theEvent : NSEvent = NSApplication.shared.currentEvent!
        NSMenu.popUpContextMenu(ctxMenu,
                                with: theEvent,
                                for: self.view)
    }

    /**
     * @brief Guides the user through loading a model pair
     *
     * Displays a model selection dialog to get model and projection files,
     * then proceeds to load the model pair. Performs various validation against
     * the selected files..
     *
     */
    private func selectModelFiles(urlFolder : URL) {
        
        let msg = "Hold the CMD key to select:\n\n1) A Model and\n2) A Multimodal Projector (mmproj) file\n\nThe 2 files should be from the same vendor & have the same prefix."
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.directoryURL = urlFolder
        panel.allowedContentTypes = [UTType(filenameExtension: gGGUFExt)!]
        panel.beginSheetModal(for: self.view.window!) { response in
        
            panel.close()
            if (response == .OK) {
                
                let arrSelectedURLs = panel.urls
                
                // Did we get 2 URLs?
                if ( !isValidArray(arrSelectedURLs) ||
                     arrSelectedURLs.count != 2 ) {
        
                    // No, message & outta here...
                    _ = self.showAlert(title: "Please Select 2 Files",
                                       message: msg,
                                       buttons: ["OK"])
                    return
                }
                
                
                // Can we validate the URLs selected?
                let arrModelPair = LlamarattiWrapper.validateModelAndProjectorURLs(arrSelectedURLs) as? Array<URL>
                if ( !isValidArray(arrModelPair) ) {
        
                    _ = self.showAlert(title:"Did you Select 2 Files from Different Models?",
                                       message:msg,
                                       buttons:["OK"])
                    return
                }
                 
                // Can we load the model pair?
                if ( !self.loadModelPair(arrModelPair: arrModelPair!) ) {
        
                    // No, message & outta here...
                    let modelName = LlamarattiWrapper.title(forModelURL: arrModelPair!.first)
                    let msg = String(format:"I was unable to load '%@'",modelName!)
                    _ = self.showAlert(title: "Unable to Load Model",
                                     message: msg,
                                     buttons: ["OK"])
                }
            } else {
                return
            }
        }
    }

    /**
     * @brief Displays an alert message
     *
     * @title - the title to display
     * @message - the message to display
     * @buttons - an array of buttons to display
     *
     * @return - NSApplication.ModalResponse - the response from the user
     */

    public func showAlert( title: String, message: String, buttons: Array<String> ) -> NSApplication.ModalResponse {
        
        let alert = NSAlert()
        alert.messageText = title
        
        if ( !message.isEmpty ) {
            alert.informativeText = message
        }
        
        alert.alertStyle = .warning

        if ( !buttons.isEmpty ) {
            for (_, btnTitle) in buttons.enumerated() {
                alert.addButton(withTitle: btnTitle)
            }
        } else {
            alert.addButton(withTitle: "Ok")
        }
        
        return alert.runModal()
    }
    
    // MARK: UserDefaults - Recently Used Models
    // ---------------------------------------------------------------------------
    
    /**
     * @brief Resets UserDefaults app settings
     *
     */
    private func resetPrefs() {
        
        _ = clearRecentlyUsedModelPairs()

        // Add: Other stuff to reset...
    }

    /**
     * @brief Retrieves the recently used model pairs from UserDefaults
     *
     * To support App sandboxing, the recently used model pairs are stored as security
     * scoped bookmarks (Data). This method converts them back to URL model
     * pairs so they can be displayed or compared.
     *
     * @return An Array of an Array of URL's representing model pairs, or empty array on failure
     *
     */
    private func getRecentlyUsedModelPairs() -> Array<Array<URL>> {

        // Do we have any previously saved recent model pairs?
        let arrModelBookmarkPairs = UserDefaults.standard.array(forKey: AppConstants.Prefs.prefsLastModelPaths) as? Array<Array<Data>>
        if ( !isValidArray(arrModelBookmarkPairs) ) {
            return []
        }
        
        // Convert the Array of Datas to URLs
        var arrModelPairs: Array<Array<URL>> = []
        for arrModelBookmarkPair in arrModelBookmarkPairs! {

            // Can we resolve this bookmarked model pair?
            let arrModelPair : Array<URL> = resolveBookmarksForModelPair(arrBookmarkModelPair: arrModelBookmarkPair )
            if ( isValidModelPair(array: arrModelPair) ) {
                arrModelPairs.append(arrModelPair)
            }
        }
        return arrModelPairs
    }

    /**
     * @brief Clears the recently used model pairs from UserDefaults
     *
     * To support App sandboxing, the recently used model pairs are stored as security
     * scoped bookmarks (Data)
     *
     * @return Bool - the status of the operation
     */
    private func clearRecentlyUsedModelPairs() -> Bool {
        
        UserDefaults.standard.removeObject(forKey: AppConstants.Prefs.prefsLastModelPaths)
        UserDefaults.standard.synchronize()
        return true
    }

    /**
     * @brief Clears the specified recently used model pair from UserDefaults
     *
     * To support App sandboxing, the recently used model pairs are stored as security
     * scoped bookmarks (Data)
     *
     * @param arrModelPair the model pair to clear
     *
     * @return Bool - the status of the operation
     */
    private func clearRecentlyUsedModelPair(arrModelPair: Array<URL>) -> Bool {
        
        // Did we get the parameters we need?
        if ( !isValidModelPair(array: arrModelPair) ) {
            return false
        }
        
        // Do we have any previously saved model pairs?
        let arrModelPairs = getRecentlyUsedModelPairs()
        if ( !isValidArray(arrModelPairs) ) {
            return false
        }
        
        // Is our current model pair already in there?
        let ind = arrModelPairs.firstIndex(of: arrModelPair)
        if ( ind == NSNotFound ) {
            return false
        }
        
        // Do we have any existing model pairs in prefs?
        let arrModelBookmarkPairs : Array<Array<Data>>? = UserDefaults.standard.array(forKey: AppConstants.Prefs.prefsLastModelPaths) as? [Array<Data>]
        if ( isValidArray(arrModelBookmarkPairs) ) {
            return false
        }

        // Yes, clone to a new mutable copy
        var arrNewModelBookmarkPairs = arrModelBookmarkPairs! as [Array<Data>]
        arrNewModelBookmarkPairs.remove(at: ind!)

        // Update User Defaults
         UserDefaults.standard.set(arrNewModelBookmarkPairs,
                            forKey: AppConstants.Prefs.prefsLastModelPaths)
         
        UserDefaults.standard.synchronize()

        return true
    }

    /**
     * @brief Returns the last used model pair from UserDefaults
     *
     * To support App sandboxing, the recently used model pairs are stored as security
     * scoped bookmarks (Data)
     *
     * @return a valid model pair, or empty array on failure
     *
     */
    private func getLastUsedModelPair() -> Array<URL> {
        
        // Do we have any existing model pairs in prefs?
        let arrModelBookmarkPairs : Array<Array<Data>>? = UserDefaults.standard.array(forKey: AppConstants.Prefs.prefsLastModelPaths) as? [Array<Data>]
        if ( !isValidArray(arrModelBookmarkPairs) ) {
            return []
        }
        
        // Is it valid?
        let arrModelBookmarkPair = arrModelBookmarkPairs?.last
        if ( !isValidArray(arrModelBookmarkPair) ||
             arrModelBookmarkPair!.count != 2 ) {
            return []
        }
        
        // Can we resolve the bookmarks for this model pair?
        let arrModelPair = resolveBookmarksForModelPair(arrBookmarkModelPair: arrModelBookmarkPair!)
        if ( !isValidModelPair(array: arrModelPair) ) {
            return []
        }
        return arrModelPair
    }
    
    /**
     * @brief Saves the specified last used model pair to UserDefaults
     *
     * The model pairs are ordered in the array so they appear in recently used
     * order when displayed in a menu. To support App sandboxing, the recently
     * used model pairs are stored as security scoped bookmarks (Data)
     *
     * @param arrModelPair the model pair to save
     *
     * @return Bool - the status of the operation
     *
     */
    private func saveLastUsedModelPair(arrModelPair: Array<URL>) -> Bool {
        
        // Did we get the parameters we need?
        if ( !isValidModelPair(array: arrModelPair) ) {
            return false
        }
        
        var arrBookmarkModelPair : Array<Data> = []
        var arrNewModelBookmarkPairs : Array<Array<Data>> = []

        // Do we have any existing model pairs in prefs?
        let arrModelBookmarkPairs : Array<Array<Data>>? = UserDefaults.standard.array(forKey: AppConstants.Prefs.prefsLastModelPaths) as? [Array<Data>]
        if ( isValidArray(arrModelBookmarkPairs) ) {
            
            // Yes, clone to a new mutable copy
            arrNewModelBookmarkPairs = arrModelBookmarkPairs!
            
            let arrModelPairs = getRecentlyUsedModelPairs()
            if ( isValidArray(arrModelPairs) ) {
                
                // Is our model pair already in there?
                if let ind = arrModelPairs.firstIndex(of: arrModelPair) {

                    // Yes, is it at the end of the array?
                    if ( ind == (arrNewModelBookmarkPairs.endIndex-1) ) {
                        
                        // Yes, outta here...
                        return true
                    }
                    
                    // No, remove it so we can append it later
                    arrBookmarkModelPair = arrNewModelBookmarkPairs[ind]
                    arrNewModelBookmarkPairs.remove(at: ind)
                 }
            }
        } else {
            // No, make a new mutable array
            arrNewModelBookmarkPairs=Array()
        }

        // Should we create a new bookmarked model pair?
        if ( !isValidArray(arrBookmarkModelPair) ) {
            
            // Yes, can we?
            arrBookmarkModelPair = createBookmarkedModelPair(arrModelPair: arrModelPair)
            if ( !isValidArray(arrBookmarkModelPair) ||
                 arrBookmarkModelPair.count != 2 ) {
                return false
            }
        }
        
        // Append this model pair as the most recently used
        arrNewModelBookmarkPairs.append(arrBookmarkModelPair)
        UserDefaults.standard.set(arrNewModelBookmarkPairs,
                            forKey: AppConstants.Prefs.prefsLastModelPaths)
         
        UserDefaults.standard.synchronize()
        
        return true
    }

    // MARK: Security Scoped Bookmarks
    // ---------------------------------------------------------------------------

    /**
     * @brief Creates a bookmarked model pair suitable for saving to UserDefaults
     *
     * To support App sandboxing, the URL model pairs need to be stored as security
     * scoped bookmarks (Data) model pairs. This method converts a URL model
     * pair to an Data model pair
     *
     * @param - arrModelPair - the model pair to convert to a  bookmarked model pair
     *
     * @return An Array of Data representing the bookmarked model pair
     *
     */
    private func createBookmarkedModelPair(arrModelPair: Array<URL>) -> Array<Data> {
        
        // Did we get the parameters we need?
        if ( !isValidModelPair(array: arrModelPair) ) {
            return []
        }
        
        // Can we create bookmarks for these file URLs?
        var arrModelBookmarkPair : Array<Data> = []
        for (_, url) in arrModelPair.enumerated() {
            
            do {
                let modelBookmark = try url.bookmarkData(options:.withSecurityScope)
                arrModelBookmarkPair.append(modelBookmark)
                
            } catch let e as NSError {
                
                NSLog(gErrLrtBookmarkCreate,
                      safeCharFromNSS(#function),
                      "",
                      Utils.safeDesc(from: e),
                      Utils.safeCode(from: e))
                
                appendStatus(gErrLrtBookmarkCreate,
                             safeCharFromNSS(#function),
                             "",
                             Utils.safeDesc(from: e),
                             Utils.safeCode(from: e))
            }
        }
        return arrModelBookmarkPair
    }
    
    /**
     * @brief Resolves the Data bookmarks in a model pair back to their original URLs
     *
     * @param arrBookmarkModelPair - the security-scoped bookmarked model pair
     *
     * @return An Array or URLs representing the resolved model pair
     *
     */
    private func resolveBookmarksForModelPair(arrBookmarkModelPair : Array<Data>) -> Array<URL> {
        
        // Did we get the parameters we need?
        if ( !isValidModelPair(array: arrBookmarkModelPair) ) {
            return []
        }
        
        // Can we resolve the security bookmarks for this model pair back
        // to URLs?
        var arrModelPair : Array<URL> = []
        for modelBookmark in arrBookmarkModelPair {

            var isStale = false
            do {
                // Can we resolve this bookmark?
                let urlResolved = try URL( resolvingBookmarkData: modelBookmark,
                                           options: [.withSecurityScope],
                                           relativeTo: nil,
                                           bookmarkDataIsStale: &isStale)
                if ( !isValidFileURL(urlResolved) ) {
                    return []
                }
                
                if ( !isStale ) {
                    arrModelPair.append(urlResolved)
                }
                
            } catch let e as NSError {
                
                NSLog(gErrLrtBookmarkResolve,
                      safeCharFromNSS(#function),
                      "",
                      Utils.safeDesc(from: e),
                      Utils.safeCode(from: e))
                
                appendStatus(gErrLrtBookmarkResolve,
                             safeCharFromNSS(#function),
                             "",
                             Utils.safeDesc(from: e),
                             Utils.safeCode(from: e))
            }
        }
        return arrModelPair
    }

    // MARK: Misc
    // ---------------------------------------------------------------------------
    
    /**
     * @brief Pre-processes the prompt removing whitespace characters & any other processing
     *
     * @param prompt - the input prompt to process
     *
     * @return String - the processed prompt
     *
     */
    private func processPrompt(prompt : String) -> String {
       
        let newPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return newPrompt;
    }
    
    // MARK: User Selector
    // ---------------------------------------------------------------------------

    /**
     * @brief User Selector for tapping into llama.cpp events
     *
     * This selector is called by the llama.cpp wrapper on the main thread to indicate
     * current activity
     *
     * @param parms NSArray - parms[0]=LlamarattiEvent (NSNumber), parms[1]=NSString
     *
     */
    @objc public func llamaEventsSelector(parms : AnyObject) {
        
        // Did we get the parameters we need?
        let params = parms as? Array<AnyObject>
        if (params == nil || parms.count < 2) {
            return
        }
        let numType = params?[0] as? NSNumber
        if ( numType == nil ) {
            return
        }
        let eventType = LlamarattiEvent(rawValue: UInt32(numType!.intValue))
        let text = params?[1] as? String
        if ( text == nil ) {
            return
        }

        switch eventType {
            
            case LlamarattiEventStatus:
                
                // Update status
                appendStatus(text!)
            
            case LlamarattiEventResponse:

                // Update response
                appendModelTextToResponse(prompt: text!, firstCall: firstResponse)
                firstResponse = false
            
            default:
                return
        }
    }
}

