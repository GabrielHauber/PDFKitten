@import Foundation;
@import CoreGraphics;

/* Flags as defined in PDF 1.7 */
typedef enum : NSUInteger {
	PDFKFontFixedPitch		= 1 << 0,
	PDFKFontSerif			= 1 << 1,
	PDFKFontSymbolic		= 1 << 2,
	PDFKFontScript			= 1 << 3,
	PDFKFontNonSymbolic		= 1 << 5,
	PDFKFontItalic			= 1 << 6,
	PDFKFontAllCap			= 1 << 16,
	PDFKFontSmallCap		= 1 << 17,
	PDFKFontForceBold		= 1 << 18,
} PDFKFontFlags;

@class PDFKFontFile;

@interface PDFKFontDescriptor : NSObject {
	CGFloat descent;
	CGFloat ascent;
	CGFloat leading;
	CGFloat capHeight;
	CGFloat xHeight;
	CGFloat averageWidth;
	CGFloat maxWidth;
	CGFloat missingWidth;
	CGFloat verticalStemWidth;
	CGFloat horizontalStemHeigth;
	CGFloat italicAngle;
	CGRect bounds;
	NSUInteger flags;
	NSString *fontName;
	PDFKFontFile *fontFile;
}

/* Initialize a descriptor using a FontDescriptor dictionary */
- (id)initWithPDFDictionary:(CGPDFDictionaryRef)dict;

@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, assign) CGFloat ascent;
@property (nonatomic, assign) CGFloat descent;
@property (nonatomic, assign) CGFloat leading;
@property (nonatomic, assign) CGFloat capHeight;
@property (nonatomic, assign) CGFloat xHeight;
@property (nonatomic, assign) CGFloat averageWidth;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, assign) CGFloat missingWidth;
@property (nonatomic, assign) CGFloat verticalStemWidth;
@property (nonatomic, assign) CGFloat horizontalStemWidth;
@property (nonatomic, assign) CGFloat italicAngle;
@property (nonatomic, assign) NSUInteger flags;
@property (nonatomic, readonly, getter = isSymbolic) BOOL symbolic;
@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, readonly) PDFKFontFile *fontFile;
@end
