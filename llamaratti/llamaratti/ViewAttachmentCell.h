// ViewAttachmentCell.h
#import <Cocoa/Cocoa.h>

@interface ViewAttachmentCell : NSTextAttachmentCell
@property (nonatomic, strong) NSView *embeddedView;
@end

