#import <Foundation/Foundation.h>
#import "PDFKFont.h"

@interface PDFKFontCollection : NSObject {
	NSMutableDictionary *fonts;
	NSArray *names;
}

/* Initialize with a font collection dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Return the specified font */
- (PDFKFont *)fontNamed:(NSString *)fontName;

@property (nonatomic, weak, readonly) NSDictionary *fontsByName;

@property (nonatomic, readonly) NSArray *names;

@end
