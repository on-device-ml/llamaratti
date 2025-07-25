// ViewAttachmentCell.m
#import "ViewAttachmentCell.h"

@implementation ViewAttachmentCell

- (NSSize)cellSize {
    return self.embeddedView.frame.size;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (![self.embeddedView superview]) {
        [controlView addSubview:self.embeddedView];
        self.embeddedView.frame = cellFrame;
    }
}

@end
