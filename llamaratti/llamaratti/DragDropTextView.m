/**
 * @file DragDropTextView.m
 *
 * @brief NSTextView subclass for drag/drop and other custom operations
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import "DragDropTextView.h"
#import "ViewController.h"

#import "NSColor+More.h"
#import "NSImage+More.h"

#import "Shared.h"
#import "Utils.h"

@implementation DragDropTextView
{
    BOOL _dragAborted;
    
    NSColor *_savedBorderColor;
    NSInteger _savedBorderWidth;
}

/**
 * @brief Initializes user interface elements
 *
 */
- (void)awakeFromNib
{
    _dragAccepted=NO;
    _dragAborted=NO;
    
    _savedBorderColor=[NSColor colorWithCGColor:[[self layer] borderColor]];
    _savedBorderWidth=[[self layer] borderWidth];
    
    [self setWantsLayer:YES];

    [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
}

/**
 * @brief drawRect
 *
 */
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
}

#pragma mark - NSDraggingDestination

/**
 * @brief prepareForDragOperation
 *
 */
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    
    return _dragAccepted;
}

/**
 * @brief performDragOperation
 *
 * @returns whether we have accepted the operation
 */
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    return _dragAccepted;
}

/**
 * @brief draggingEntered
 *
 * Highlights the text field when files are dragged into the control
 *
 * @returns NSDragOperation
 */
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    // Are we accepting drag operations?
    if ( !_dragAccepted ) {
        return NSDragOperationNone;
    }
    
    // Yes, highlight the control
    [[self layer] setBorderColor:[[NSColor colorNamed:@"HighlightColor"] CGColor]];
    [[self layer] setBorderWidth:2];
    _dragAborted=NO;
    
    return NSDragOperationEvery;
}

/**
 * @brief draggingUpdated
 *
 * @returns NSDragOperation
 */
- (NSDragOperation) draggingUpdated:(id<NSDraggingInfo>)sender
{
    // Are we accepting drag operations?
    if ( !_dragAccepted ) {
        return NSDragOperationNone;
    }
    return NSDragOperationEvery;
}

/**
 * @brief Called when the dragging operation has ended
 *
 */
- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    // Unhighlight the control
    [[self layer] setBorderColor:[_savedBorderColor CGColor]];
    [[self layer] setBorderWidth:_savedBorderWidth];

    _dragAborted=YES;
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
- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    // Reset our highlighted border
    [[self layer] setBorderColor:[_savedBorderColor CGColor]];
    [[self layer] setBorderWidth:_savedBorderWidth];
    
    // Are we accepting drag operations?
    if ( !_dragAccepted || _dragAborted ) {
        return;
    }
    
    // Do we have our parent view controller?
    if ( !_vcParent || !isInstanceOfClass(_vcParent, [NSViewController class]) ) {
        return;
    }

    // Are we busy?
    ViewController *vc=(ViewController *)_vcParent;
    if ( [vc isBusy] ) {
        return;
    }

    // Do we have a LlamarattiWrapper?
    LlamarattiWrapper *llamaWrapper=[vc llamaWrapper];
    if ( llamaWrapper == nil ) {
        return;
    }

    // Do we have any dragged files?
    NSPasteboard *pb = [sender draggingPasteboard];
    if ( ![[pb types] containsObject:NSPasteboardTypeFileURL] ) {
        return;
    }
    
    // We use these options to access security scoped file URLs
    NSDictionary *options = @{NSPasteboardURLReadingFileURLsOnlyKey:@YES,
                            @"NSPasteboardURLReadingSecurityScopedFileURLsKey":@YES};
    NSArray *arrDraggedURLs = [pb readObjectsForClasses:@[[NSURL class]]
                                                options:options];

    // Did we get a valid array?
    if ( !isValidNSArray(arrDraggedURLs) ) {
        return;
    }
        
    // Add any supported dropped file(s)...
    NSUInteger countAdded=0;
    NSUInteger countMax=[LlamarattiWrapper maxSupportedMedia];
    for ( NSURL *urlTmpDragged in arrDraggedURLs ) {
        
        NSURL *urlDragged = urlTmpDragged;
        
        // Is this a supported audio type?
        if ( [llamaWrapper isSupportedAudioURL:urlDragged] ) {

            if ( [vc loadAudioIntoContext:urlDragged
                         useSecurityScope:YES] ) {
                countAdded++;
            }
        }
        
        // Is this a supported image type?
        else if ( [llamaWrapper isSupportedImageURL:urlDragged] ) {

            BOOL useSecurityScope=YES;
            
            // Is this an HEIC image?
            NSString *pathExt=[urlDragged pathExtension];
            if ( [[pathExt lowercaseString] isEqualToString:@"heic"] ) {
                
                // Yes, can we convert the file?
                urlDragged = [NSImage convertHEICtoTmpJPG:urlTmpDragged
                                            withTmpPrefix:gMediaTemplate
                                                withLoss:IMAGE_CONVERSION_LOSS];
                if ( !urlDragged ) {
                    continue;
                }
                
                // URL points to temp folder within app sandbox
                useSecurityScope=NO;
                
            // Is this a WEBP image?
            } else if ( [[pathExt lowercaseString] isEqualToString:@"webp"] ) {
                
                // Yes, can we convert the file?
                urlDragged = [NSImage convertWEBPtoTmpJPG:urlTmpDragged
                                            withTmpPrefix:gMediaTemplate];
                if ( !urlDragged ) {
                    continue;
                }
                
                // URL points to temp folder within app sandbox
                useSecurityScope=NO;
            }
            
            if ( [vc loadImageIntoContext:urlDragged
                         useSecurityScope:useSecurityScope] ) {
                countAdded++;
            }
        }
        
        // Have we added enough?
        if ( countAdded > countMax ) {
            break;
        }
    }
    
    // Did we add any media files?
    if ( countAdded == 0 ) {
        
        // No, notify...
        NSString *modelName=[llamaWrapper title];
        NSString *suppTypes=[llamaWrapper supportedMediaTypes];
        NSString *title=@"Media Type Not Supported";
        NSString *msg=[NSString stringWithFormat:@"'%@' does not support this media type. Supported types are:\n\n%@\n",modelName,suppTypes];
        [Utils showAlertWithTitle:title
                       andMessage:msg
                         urlTitle:nil
                              url:nil
                          buttons:nil];
    } else {
        
#if RIPPLE_IMAGES_DURING_ADDING
        // Start rippling the images
        [vc startTimedRippleFor:RIPPLE_IMAGES_DURATION];
#endif // RIPPLE_IMAGES_DURING_ADDING
        
        // Hide the drag/drop icon
        [vc toggleDragDropIcon:NO];
    }
}

/**
 * @brief Cleans up the contents of the views and deletes any temporary files
 *
 */

- (void)reset {
    
    NSTextStorage *textStorage = self.textStorage;

    // Remove all embedded subviews
    for (NSView *subview in self.subviews) {
        [subview removeFromSuperview];
    }

    // Remove all attachments
    NSRange fullRange = NSMakeRange(0, textStorage.length);
    [textStorage enumerateAttribute:NSAttachmentAttributeName
                            inRange:fullRange
                            options:0
                         usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value isKindOfClass:[NSTextAttachment class]]) {
            [textStorage deleteCharactersInRange:range];
        }
    }];

    // Clear all text and formatting
    [textStorage setAttributedString:[[NSAttributedString alloc] initWithString:@""]];

    // Reset typing attributes (optional)
    self.typingAttributes = @{};
    
    // Remove any temporary files
    NSString *template=[NSString stringWithFormat:@"%@*",gMediaTemplate];
    [Utils removeTempFilesMatchingTemplate:template];
}

/**
 * @brief Handles redisplay when the view is resized
 *
 */
- (void)viewDidEndLiveResize {
    
    [self displayIfNeeded];
}
@end
