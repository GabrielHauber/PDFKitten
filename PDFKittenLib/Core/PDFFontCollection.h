#import <Foundation/Foundation.h>
#import "PDFFont.h"

@interface PDFFontCollection : NSObject {
	NSMutableDictionary *fonts;
	NSArray *names;
}

/* Initialize with a font collection dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Return the specified font */
- (PDFFont *)fontNamed:(NSString *)fontName;

@property (nonatomic, weak, readonly) NSDictionary *fontsByName;

@property (nonatomic, readonly) NSArray *names;

@end
