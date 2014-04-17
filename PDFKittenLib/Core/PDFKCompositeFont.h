/*
 *	A composite font is one of the following types:
 *		- Type0
 *		- CIDType0Font
 *		- CIDType2Font
 *
 *	Composite fonts have the following specific traits:
 *		- Default glyph width
 *
 */

#import "PDFKFont.h"

@interface PDFKCompositeFont : PDFKFont {
    CGFloat defaultWidth;
}

@property (nonatomic, assign) CGFloat defaultWidth;
@end
