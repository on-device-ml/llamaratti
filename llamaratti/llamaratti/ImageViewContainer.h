// ImageViewContainer.h
#import <Cocoa/Cocoa.h>

@interface ImageViewContainer : NSView
@property (nonatomic, strong) NSImage *image;
- (instancetype)initWithImage:(NSImage *)image;
@end
