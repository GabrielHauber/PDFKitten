/*
 *	Implements generic behavior of a font.
 *
 *	Most likely used exclusively for subclassing, for Type 0, Type 1 etc.
 *
 *	Ideally, the subclasses are hidden from the user, who interacts with them through this facade class.
 *	
 */
#import <Foundation/Foundation.h>
#import "PDFKFontDescriptor.h"
#import "PDFKCMap.h"

extern const char *kFontDescriptorKey;
extern const char *kTypeKey;

typedef enum : NSUInteger {
	PDFKUnknownEncoding = NSUTF8StringEncoding,
	PDFKStandardEncoding = NSUTF8StringEncoding, // Defined in Type1 font programs
	PDFKMacRomanEncoding = NSMacOSRomanStringEncoding,
	PDFKWinAnsiEncoding = NSWindowsCP1252StringEncoding,
	PDFKDocEncoding = NSUTF8StringEncoding,
	PDFKMacExpertEncoding = NSUTF8StringEncoding,
	
} PDFKCharacterEncoding;


@interface PDFKFont : NSObject {
	PDFKCMap *toUnicode;
	NSMutableDictionary *widths;
    PDFKFontDescriptor *fontDescriptor;
	NSDictionary *ligatures;
	NSRange widthsRange;
	NSString *baseFont;
	PDFKCharacterEncoding encoding;
}

/* Factory method returns a Font object given a PDF font dictionary */
+ (PDFKFont *)fontWithDictionary:(CGPDFDictionaryRef)dictionary;

/* Initialize with a font dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Populate the widths array given font dictionary */
- (void)setWidthsWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Construct a font descriptor given font dictionary */
- (void)setFontDescriptorWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Given a PDF string, returns a Unicode string */
- (void)enumeratePDFStringCharacters:(CGPDFStringRef)pdfString usingBlock:(void(^)(NSUInteger cid, NSString *unicode))block;

/* Returns the width of a charachter (optionally scaled to some font size) */
- (CGFloat)widthOfCharacter:(unichar)characher withFontSize:(CGFloat)fontSize;

/* Import a ToUnicode CMap from a font dictionary */
- (void)setToUnicodeWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Return an equivalent string, replacing ligatures with individual characters */
- (NSString *)stringByExpandingLigatures:(NSString *)string;

@property (nonatomic, strong) PDFKCMap *toUnicode;
@property (nonatomic, strong) NSMutableDictionary *widths;
@property (nonatomic, strong) PDFKFontDescriptor *fontDescriptor;
@property (nonatomic, readonly) CGFloat minY;
@property (nonatomic, readonly) CGFloat maxY;
@property (nonatomic, weak, readonly) NSDictionary *ligatures;
@property (nonatomic, readonly) CGFloat widthOfSpace;
@property (nonatomic, readonly) NSRange widthsRange;
@property (nonatomic, assign) PDFKCharacterEncoding encoding;
@property (nonatomic, weak, readonly) NSArray *descendantFonts;

/*!
 @property baseFont
 */
@property (nonatomic, strong) NSString *baseFont;

/*!
 * The actual name of the base font, sans tag.
 @property baseFontName
 */
@property (weak, nonatomic, readonly) NSString *baseFontName;
@end
