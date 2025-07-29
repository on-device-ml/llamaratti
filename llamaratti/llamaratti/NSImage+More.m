/**
 * @file NSImage+More.m
 *
 * @brief Extension to add features to NSImage as needed
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "NSImage+More.h"
#import "Utils.h"

@implementation NSImage (More)

/**
 * @brief Scales this image proportionally to a specified target size
 *
 * @param newSize the desired scaled size
 *
 * @return a scaled CGSize
 *
 */
- (NSImage *)scaledProportionallyToSize:(NSSize)newSize {
    
    if ( self.size.width == 0 || self.size.height == 0 ) {
        return nil;
    }

    CGFloat widthRatio  = newSize.width  / self.size.width;
    CGFloat heightRatio = newSize.height / self.size.height;
    CGFloat scaleFactor = MIN(widthRatio, heightRatio);

    NSSize targetSize = NSMakeSize(self.size.width * scaleFactor,
                                   self.size.height * scaleFactor);

    NSImage *scaledImage = [[NSImage alloc] initWithSize:targetSize];

    [scaledImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    [self drawInRect:NSMakeRect(0, 0, targetSize.width, targetSize.height)
            fromRect:NSZeroRect
           operation:NSCompositingOperationCopy
            fraction:1.0];

    [scaledImage unlockFocus];

    return scaledImage;
}

/**
 * @brief Tints this image with the specified color
 *
 * @param color the color to tint
 *
 * @return an NSImage with the specified color, or nil on error
 *
 */
- (NSImage *)imageTintedWithColor:(NSColor *)color {
    if ( !color) {
        return nil;
    }

    NSImage *imgNew = [[NSImage alloc] initWithSize:[self size]];
    [imgNew lockFocus];

    // Draw the original image
    [self drawAtPoint:NSZeroPoint
              fromRect:NSMakeRect(0, 0, self.size.width, self.size.height)
             operation:NSCompositingOperationSourceOver
              fraction:1.0];

    // Apply tint color
    [color set];
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);

    [imgNew unlockFocus];
    return imgNew;
}

/**
 * @brief Converts HEIC images to a temporary JPG image
 *
 * This method creates a copy of the image in the users temporary folder
 * that must be cleaned up by the caller.
 *
 * @return a URL to the converted file in the temporary folder. The caller
 * should erase this file once it is no longer needed.
 *
 */
+ (NSURL *)convertHEICtoTmpJPG:(NSURL *)urlImage
                 withTmpPrefix:(NSString *)tmpPrefix
                      withLoss:(CGFloat)loss {
    
    if ( !isValidFileNSURL(urlImage) ||
         !(isValidNSString(tmpPrefix)) ) {
        return nil;
    }
    
    // Can we start accessing this security-scoped url?
    if ( ![Utils startAccessingSecurityScopedURLs:@[urlImage]] ) {
        
        NSString *filename=[urlImage lastPathComponent];
        NSLog(gErrLrtBookmarkAccess,
              __func__,
              filename);
       
        return nil;
    }
    
    // Can we create an image source?
    CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)urlImage, NULL);
    if ( !sourceRef ) {
        
        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        
        return nil;
    }

    // Can we create the image?
    CGImageRef sourceImageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
    if ( !sourceImageRef ) {
        
        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        CFRelease(sourceRef);
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        
        return nil;
    }

    // Rotate the image as needed
    NSDictionary *imageProps = (__bridge_transfer NSDictionary *)
        CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    NSNumber *numOrient = imageProps[(NSString *)kCGImagePropertyOrientation];
    if ( isValidNSNumber(numOrient) ) {
        CGImageRef correctedImage = [NSImage rotateImage:sourceImageRef
                                           toOrientation:numOrient.intValue];
        CGImageRelease(sourceImageRef);
        sourceImageRef = correctedImage;
    }
    
    // Create a temporary output file
    NSString *uuid=[[[NSUUID UUID] UUIDString] lowercaseString];
    NSString *tempFilename = [NSString stringWithFormat:@"%@%@.heic",tmpPrefix,uuid];
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFilename];
    NSURL *urlOutput = [NSURL fileURLWithPath:tempFile];

    // Can we create the image destination?
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(
                                    (__bridge CFURLRef)urlOutput,
                                    (__bridge CFStringRef)UTTypeJPEG.identifier,
                                    1,
                                    NULL);
    if ( !dest ) {
        
        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        CGImageRelease(sourceImageRef);
        CFRelease(sourceRef);
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        
        return nil;
    }

    NSDictionary *options = @{ (__bridge NSString *)kCGImageDestinationLossyCompressionQuality : @(loss) };
    CGImageDestinationAddImage(dest, sourceImageRef, (__bridge CFDictionaryRef)options);

    BOOL bSuccess = CGImageDestinationFinalize(dest);
    if ( !bSuccess ) {
        
        // Clean up
        CGImageRelease(sourceImageRef);
        CFRelease(dest);
        CFRelease(sourceRef);

        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        
        return nil;
    }

    // Stop accessing
    [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
    
    // Clean up
    CGImageRelease(sourceImageRef);
    CFRelease(dest);
    CFRelease(sourceRef);

    return urlOutput;
}

/**
 * @brief Converts WEBP images to a temporary JPG image
 *
 * This method creates a copy of the image in the users temporary folder
 * that must be cleaned up by the caller.
 *
 * @return a URL to the converted file in the temporary folder. The caller
 * should erase this file once it is no longer needed.
 *
 */
+ (NSURL *)convertWEBPtoTmpJPG:(NSURL *)urlImage
                 withTmpPrefix:(NSString *)tmpPrefix {
    
    if ( !isValidFileNSURL(urlImage) ||
         !isValidNSString(tmpPrefix) ) {
        return nil;
    }
    
    // Can we start accessing this security-scoped url?
    if ( ![Utils startAccessingSecurityScopedURLs:@[urlImage]] ) {
        
        NSString *filename=[urlImage lastPathComponent];
        NSLog(gErrLrtBookmarkAccess,
              __func__,
              filename);
       
        return nil;
    }

    NSImage *image = [[NSImage alloc] initWithContentsOfURL:urlImage];
    if ( !image ) {
        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        return nil;
    }
    
    NSData *tiffData = [image TIFFRepresentation];
    if ( !tiffData ) {
        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        return nil;
    }
    
    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:tiffData];
    if ( !bitmap ) {
        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        return nil;
    }
    
    NSData *jpgData = [bitmap representationUsingType:NSBitmapImageFileTypeJPEG properties:@{}];
    if ( !jpgData ) {
        [Utils stopAccessingSecurityScopedURLs:@[urlImage]];
        NSLog(gErrLrtConvertImageFail,
              __func__,
              [urlImage path]);
        return nil;
    }

    // Create a temporary output file
    NSString *uuid=[[[NSUUID UUID] UUIDString] lowercaseString];
    NSString *tempFilename = [NSString stringWithFormat:@"%@%@.webp",tmpPrefix,uuid];
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFilename];
    NSURL *urlOutput = [NSURL fileURLWithPath:tempFile];

    [jpgData writeToURL:urlOutput
             atomically:YES];
    
    // Stop accessing
    [Utils stopAccessingSecurityScopedURLs:@[urlImage]];

    return urlOutput;
}

/**
 * @brief Rotates the specified image to a specified orientation
 *
 * @note the return value must be released by the caller
 * 
 * @return a CGImageRef which must be released by the caller
 *
 */
+ (CGImageRef) rotateImage:(CGImageRef)imageRef
             toOrientation:(NSInteger)orientation {
             
    // Did we get the parameters we need?
    if ( !imageRef ) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);

    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (orientation) {
        case 1:
            break;                                                      // No change
        case 2:
            transform = CGAffineTransformMakeScale(-1, 1); break;       // Flip Horizontally
            break;
        case 3:
            transform = CGAffineTransformMakeRotation(M_PI); break;     // Flip 180 degrees
            break;
        case 4:
            transform = CGAffineTransformMakeScale(1, -1); break;       // Flip Vertically
            break;
        case 5:
        case 6:
            transform = CGAffineTransformMakeRotation(M_PI_2); break;   // Flip 90°
            break;
        case 7:
        case 8:
            transform = CGAffineTransformMakeRotation(-M_PI_2); break;  // Flip -90°
            break;
        default:
            break;
    }

    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             width,
                                             height,
                                             8,
                                             0,
                                             CGImageGetColorSpace(imageRef),
                                             kCGImageAlphaPremultipliedLast);

    CGContextConcatCTM(ctx, transform);

    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef imageRefNew = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);

    return imageRefNew;
}

@end
