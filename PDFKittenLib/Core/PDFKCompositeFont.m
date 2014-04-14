#import "PDFKCompositeFont.h"

@implementation PDFKCompositeFont

/* Override with implementation for composite fonts */
- (void)setWidthsWithFontDictionary:(CGPDFDictionaryRef)dict
{
    [super setWidthsWithFontDictionary:dict];
    
	CGPDFArrayRef widthsArray;
	if (CGPDFDictionaryGetArray(dict, "W", &widthsArray))
    {
        [self setWidthsWithArray:widthsArray];
    }

	CGPDFInteger defaultWidthValue;
	if (CGPDFDictionaryGetInteger(dict, "DW", &defaultWidthValue))
	{
		self.defaultWidth = defaultWidthValue;
	}
}

- (void)setWidthsWithArray:(CGPDFArrayRef)widthsArray
{
    NSUInteger length = CGPDFArrayGetCount(widthsArray);
    int idx = 0;

    while (idx < length)
    {
        CGPDFInteger baseCid = 0;
        CGPDFArrayGetInteger(widthsArray, idx++, &baseCid);

        CGPDFObjectRef integerOrArray = nil;
		CGPDFArrayGetObject(widthsArray, idx++, &integerOrArray);
		if (CGPDFObjectGetType(integerOrArray) == kCGPDFObjectTypeInteger)
		{
            // [ first last width ]
			CGPDFInteger maxCid;
			CGPDFInteger glyphWidth;
			CGPDFObjectGetValue(integerOrArray, kCGPDFObjectTypeInteger, &maxCid);
			CGPDFArrayGetInteger(widthsArray, idx++, &glyphWidth);
			[self setWidthsFrom:baseCid to:maxCid width:glyphWidth];
		}
		else
		{
            // [ first list-of-widths ]
			CGPDFArrayRef glyphWidths;
			CGPDFObjectGetValue(integerOrArray, kCGPDFObjectTypeArray, &glyphWidths);
            [self setWidthsWithBase:baseCid array:glyphWidths];
        }
	}
}

- (void)setWidthsFrom:(CGPDFInteger)cid to:(CGPDFInteger)maxCid width:(CGPDFInteger)width
{
    while (cid <= maxCid)
    {
        self.widths[@(cid++)] = @(width);
    }
}

- (void)setWidthsWithBase:(CGPDFInteger)base array:(CGPDFArrayRef)array
{
    NSInteger count = CGPDFArrayGetCount(array);
    CGPDFInteger width;
    for (int index = 0; index < count ; index++)
    {
        if (CGPDFArrayGetInteger(array, index, &width))
        {
            self.widths[@(base+index)] = @(width);
        }
    }
}

- (CGFloat)widthOfCharacter:(unichar)characher withFontSize:(CGFloat)fontSize
{
	NSNumber *width = self.widths[@(characher)];
	if (!width)
	{
		return self.defaultWidth * fontSize;
	}
	return [width floatValue] * fontSize;
}

@synthesize defaultWidth;
@end
