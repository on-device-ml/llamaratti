/**
 * @file AckContent.m
 *
 * @brief Formats acknowledgements details
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */

#import <Foundation/Foundation.h>
#import "AckContent.h"
#import "Shared.h"

@implementation AckContent {
    
}

/**
 * @brief Initializes the timer
 *
 * @return initialized object
 *
 */
- (id)init {
    
    if ( self = [super init] ) {
    }
    return self;
}

/**
 * @brief Builds the acknowledgements content
 *
 *
 * @return an NSAttributedString formatted with the acknowledgements
 *
 */
+ (NSAttributedString *)buildAck {
    
    // Build a string with the acknowledgements
    NSString *titleODML=@"on-device-ml.org";
    NSString *titleLlamacpp=@"llama.cpp";
    NSString *line=@"---------------------------------------------------------------------------------------------------------------------------------";
    
    // Append: Prefix Text
    // ------------------------------------------------------------------------------------
    NSError *e=nil;
    NSURL *urlAbout=[[NSBundle mainBundle] URLForResource:@"ABOUT" withExtension:@"txt"];
    NSString *creditsFmt = [NSString stringWithContentsOfURL:urlAbout
                                                    encoding:NSUTF8StringEncoding
                                                       error:&e];
    if ( !creditsFmt ) {
        return nil;
    }
    NSString *credits=[NSString stringWithFormat:creditsFmt,titleODML,titleLlamacpp];
    NSMutableAttributedString *attrCredits = [[NSMutableAttributedString alloc]
                                              initWithString:credits];
    
    // Append: Llamaratti license
    // ------------------------------------------------------------------------------------
    NSString *chunk=[NSString stringWithFormat:@"\n%@\nLlamaratti License\n%@\n\n",line,line];
    [attrCredits appendAttributedString:[[NSMutableAttributedString alloc]
                                         initWithString:chunk]];
    
    e=nil;
    NSURL *urlLicense=[[NSBundle mainBundle] URLForResource:@"LICENSE" withExtension:@"txt"];
    NSAttributedString *attrChunk = [[NSAttributedString alloc]
                                     initWithURL:urlLicense
                                     options:@{NSDocumentTypeDocumentAttribute: NSPlainTextDocumentType}
                                     documentAttributes:nil
                                     error:&e];
    if ( !attrChunk ) {
        return nil;
    }
    [attrCredits appendAttributedString:attrChunk];
    
    // Append: llama.cpp license
    // ------------------------------------------------------------------------------------
    chunk=[NSString stringWithFormat:@"\n%@\nllama.cpp License\n%@\n\n",line,line];
    [attrCredits appendAttributedString:[[NSMutableAttributedString alloc]
                                         initWithString:chunk]];
    
    urlLicense=[[NSBundle mainBundle] URLForResource:@"llamaLICENSE" withExtension:@"txt"];
    attrChunk = [[NSAttributedString alloc]
                 initWithURL:urlLicense
                 options:@{NSDocumentTypeDocumentAttribute: NSPlainTextDocumentType}
                 documentAttributes:nil
                 error:&e];
    if ( !attrChunk ) {
        return nil;
    }
    [attrCredits appendAttributedString:attrChunk];
    
    // Apply the attributes...
    NSRange rangeOfString = NSMakeRange(0,[attrCredits length]);
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:NSTextAlignmentLeft];
    
    NSFont *fontAbout=[NSFont fontWithName:@"Avenir Next Regular" size:FONT_SIZE_SMALL];
    
    // Apply attributes to entire string
    [attrCredits addAttribute:NSFontAttributeName
                        value:fontAbout
                        range:rangeOfString];
    [attrCredits addAttribute:NSParagraphStyleAttributeName
                        value:paraStyle
                        range:rangeOfString];
    [attrCredits addAttribute:NSForegroundColorAttributeName
                        value:[NSColor colorNamed:@"AboutTextColor"]
                        range:rangeOfString];
    
    // Apply attributes to url: on-device-ml.org
    NSString *urlOnDeviceML=@"https://on-device-ml.org/";
    NSRange rangeOfURL = [credits rangeOfString:titleODML];
    [attrCredits addAttribute:NSUnderlineStyleAttributeName
                        value:@(NSUnderlineStyleSingle)
                        range:rangeOfURL];
    [attrCredits addAttribute:NSForegroundColorAttributeName
                        value:[NSColor linkColor]
                        range:rangeOfURL];
    [attrCredits addAttribute:NSLinkAttributeName
                        value:[NSURL URLWithString:urlOnDeviceML]
                        range:rangeOfURL];
    
    // Apply attributes to url: llama.cpp
    NSString *urlLlama=@"https://github.com/ggerganov/llama.cpp";
    rangeOfURL = [credits rangeOfString:titleLlamacpp];
    [attrCredits addAttribute:NSUnderlineStyleAttributeName
                        value:@(NSUnderlineStyleSingle)
                        range:rangeOfURL];
    [attrCredits addAttribute:NSForegroundColorAttributeName
                        value:[NSColor linkColor]
                        range:rangeOfURL];
    [attrCredits addAttribute:NSLinkAttributeName
                        value:[NSURL URLWithString:urlLlama]
                        range:rangeOfURL];
    
    return attrCredits;
}

@end
