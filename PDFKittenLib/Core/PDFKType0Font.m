#import "PDFKType0Font.h"
#import "PDFKCIDType0Font.h"
#import "PDFKCIDType2Font.h"


@interface PDFKType0Font ()
@property (nonatomic, weak, readonly) NSMutableArray *descendantFonts;
@end

@implementation PDFKType0Font

/* Initialize with font dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if ((self = [super initWithFontDictionary:dict]))
	{
		CGPDFArrayRef dFonts;
		if (CGPDFDictionaryGetArray(dict, "DescendantFonts", &dFonts))
		{
			NSUInteger count = CGPDFArrayGetCount(dFonts);
			for (int i = 0; i < count; i++)
			{
				CGPDFDictionaryRef fontDict;
				if (!CGPDFArrayGetDictionary(dFonts, i, &fontDict)) continue;
				const char *subtype;
				if (!CGPDFDictionaryGetName(fontDict, "Subtype", &subtype)) continue;

//				NSLog(@"Descendant font type %s", subtype);

				if (strcmp(subtype, "CIDFontType0") == 0)
				{
					// Add descendant font of type 0
					PDFKCIDType0Font *font = [[PDFKCIDType0Font alloc] initWithFontDictionary:fontDict];
					if (font) [self.descendantFonts addObject:font];
				}
				else if (strcmp(subtype, "CIDFontType2") == 0)
				{
					// Add descendant font of type 2
					PDFKCIDType2Font *font = [[PDFKCIDType2Font alloc] initWithFontDictionary:fontDict];
					if (font) [self.descendantFonts addObject:font];
				}
			}
		}
	}
	return self;
}

/* Custom implementation, using descendant fonts */
- (CGFloat)widthOfCharacter:(unichar)characher withFontSize:(CGFloat)fontSize
{
	for (PDFKFont *font in self.descendantFonts)
	{
		CGFloat width = [font widthOfCharacter:characher withFontSize:fontSize];
		if (width > 0) return width;
	}
	return self.defaultWidth;
}

- (NSDictionary *)ligatures
{
    return [[self.descendantFonts lastObject] ligatures];
}

- (PDFKFontDescriptor *)fontDescriptor {
	PDFKFont *descendantFont = [self.descendantFonts lastObject];
	return descendantFont.fontDescriptor;
}

- (CGFloat)minY
{
	PDFKFont *descendantFont = [self.descendantFonts lastObject];
	return [descendantFont.fontDescriptor descent];
}

/* Highest point of any character */
- (CGFloat)maxY
{
	PDFKFont *descendantFont = [self.descendantFonts lastObject];
	return [descendantFont.fontDescriptor ascent];
}


#pragma mark -
#pragma mark Memory Management

- (NSMutableArray *)descendantFonts
{
	if (!descendantFonts)
	{
		descendantFonts = [[NSMutableArray alloc] init];
	}
	return descendantFonts;
}


@end
