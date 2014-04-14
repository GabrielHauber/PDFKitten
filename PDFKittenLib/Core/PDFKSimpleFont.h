/*
 *	A simple font is one of the following types:
 *		- Type1
 *		- Type3
 *		- TrueType
 *		- MMType1
 *
 *	All simple fonts have the following specific traits:
 *		- Encoding
 *		- Widths (custom implementation)
 *
 */

#import <Foundation/Foundation.h>
#import "PDFKFont.h"
#import "PDFKEncodingDifferences.h"

@interface PDFKSimpleFont : PDFKFont {
    PDFKEncodingDifferences *encodingDifferences;
}

/* Custom implementation for all simple fonts */
- (void)setWidthsWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Set encoding with name or dictionary */
- (void)setEncodingWithEncodingObject:(CGPDFObjectRef)object;

/* Set encoding, given a font dictionary */
- (void)setEncodingWithFontDictionary:(CGPDFDictionaryRef)dict;

@property (nonatomic, readonly, strong) PDFKEncodingDifferences *encodingDifferences;
- (void) setupEncodingDifferencesWithEncodingDict:(CGPDFDictionaryRef)encodingDict;

@end
