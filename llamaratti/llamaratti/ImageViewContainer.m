// ImageViewContainer.m
#import "ImageViewContainer.h"

@implementation ImageViewContainer

- (instancetype)initWithImage:(NSImage *)image {
    self = [super initWithFrame:NSMakeRect(0, 0, image.size.width, image.size.height)];
    if (self) {
        _image = image;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self.image drawInRect:self.bounds];
}

@end
