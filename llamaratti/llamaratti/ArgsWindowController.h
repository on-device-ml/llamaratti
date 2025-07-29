/**
 * @file ArgsWindowController.h
 *
 * @brief Arguments dialog for Llamaratti
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Cocoa/Cocoa.h>

#import "Shared.h"
#import "DragDropTextView.h"
#import "ViewController.h"

@interface ArgsWindowController : NSWindowController

@property (nonatomic, strong) NSString *placeholderString;
@property (nonatomic, strong) ViewController *vcParent;
@property (nonatomic, strong) NSArray *arrModelPair;

@property (weak) IBOutlet DragDropTextView *textArgs;
@property (weak) IBOutlet NSButton *btnOk;

@end
