#import "PDFKFont.h"

// Simple fonts
#import "PDFKType1Font.h"
#import "PDFKTrueTypeFont.h"
#import "PDFKMMType1Font.h"
#import "PDFKType3Font.h"

// Composite fonts
#import "PDFKType0Font.h"
#import "PDFKCIDType2Font.h"
#import "PDFKCIDType0Font.h"

const char *kType0Key = "Type0";
const char *kType1Key = "Type1";
const char *kMMType1Key = "MMType1";
const char *kType3Key = "Type3";
const char *kTrueTypeKey = "TrueType";
const char *kCidFontType0Key = "CIDFontType0";
const char *kCidFontType2Key = "CIDFontType2";

const char *kToUnicodeKey = "ToUnicode"; 
const char *kFontDescriptorKey = "FontDescriptor";
const char *kBaseFontKey = "BaseFont";
const char *kEncodingKey = "Encoding";
const char *kBaseEncodingKey = "BaseEncoding";
const char *kFontSubtypeKey = "Subtype";
const char *kFontKey = "Font";
const char *kTypeKey = "Type";

#pragma mark 


@implementation PDFKFont

#pragma mark - Initialization

/* Factory method returns a Font object given a PDF font dictionary */
+ (PDFKFont *)fontWithDictionary:(CGPDFDictionaryRef)dictionary
{
	const char *type = nil;
	CGPDFDictionaryGetName(dictionary, kTypeKey, &type);
	if (!type || strcmp(type, kFontKey) != 0) return nil;
	const char *subtype = nil;
	CGPDFDictionaryGetName(dictionary, kFontSubtypeKey, &subtype);

	PDFKFont *font = nil;	
	if (!strcmp(subtype, kType0Key)) {
		font = [PDFKType0Font alloc];
	}
	else if (!strcmp(subtype, kType1Key)) {
		font = [PDFKType1Font alloc];
	}
	else if (!strcmp(subtype, kMMType1Key)) {
		font = [PDFKMMType1Font alloc];
	}
	else if (!strcmp(subtype, kType3Key)) {
		font = [PDFKType3Font alloc];
	}
	else if (!strcmp(subtype, kTrueTypeKey)) {
		font = [PDFKTrueTypeFont alloc];
	}
	else if (!strcmp(subtype, kCidFontType0Key)) {
		font = [PDFKCIDType0Font alloc];
	}
	else if (!strcmp(subtype, kCidFontType2Key)) {
		font = [PDFKCIDType2Font alloc];
	}
	
	return [font initWithFontDictionary:dictionary];
}

/* Initialize with font dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if ((self = [super init]))
	{
		// Populate the glyph widths store
		[self setWidthsWithFontDictionary:dict];
		
		// Initialize the font descriptor
		[self setFontDescriptorWithFontDictionary:dict];
		
		// Parse ToUnicode map
		[self setToUnicodeWithFontDictionary:dict];
		
		// Set the font's base font
		const char *fontName = nil;
		if (CGPDFDictionaryGetName(dict, kBaseFontKey, &fontName))
		{
			self.baseFont = @(fontName);
		}
		
		// NOTE: Any furhter initialization is performed by the appropriate subclass
	}
	return self;
}

#pragma mark Font Resources

- (void)setEncodingWithFontDictionary:(CGPDFDictionaryRef)fontDictionary
{
	const char *encodingName = nil;
	if (!CGPDFDictionaryGetName(fontDictionary, kEncodingKey, &encodingName))
	{
		CGPDFDictionaryRef encodingDict = nil;
		CGPDFDictionaryGetDictionary(fontDictionary, kEncodingKey, &encodingDict);
		CGPDFDictionaryGetName(encodingDict, kBaseEncodingKey, &encodingName);

		// TODO: Also get differences from font encoding dictionary
	}

	[self setEncodingNamed:@(encodingName)];
}

- (void)setEncodingNamed:(NSString *)encodingName
{
	if ([@"MacRomanEncoding" isEqualToString:encodingName])
	{
		self.encoding = PDFKMacRomanEncoding;
	}
	else if ([@"WinAnsiEncoding" isEqualToString:encodingName])
	{
		self.encoding = PDFKWinAnsiEncoding;
	}
	else
	{
		self.encoding = PDFKUnknownEncoding;
	}
}

/* Import font descriptor */
- (void)setFontDescriptorWithFontDictionary:(CGPDFDictionaryRef)dict
{
	CGPDFDictionaryRef descriptor;
	if (!CGPDFDictionaryGetDictionary(dict, kFontDescriptorKey, &descriptor)) return;
	PDFKFontDescriptor *desc = [[PDFKFontDescriptor alloc] initWithPDFDictionary:descriptor];
	self.fontDescriptor = desc;
}

/* Populate the widths array given font dictionary */
- (void)setWidthsWithFontDictionary:(CGPDFDictionaryRef)dict
{
    self.widths = [NSMutableDictionary dictionary];
}

/* Parse the ToUnicode map */
- (void)setToUnicodeWithFontDictionary:(CGPDFDictionaryRef)dict
{
	CGPDFStreamRef stream;
	if (!CGPDFDictionaryGetStream(dict, kToUnicodeKey, &stream)) return;
	PDFKCMap *map = [[PDFKCMap alloc] initWithPDFStream:stream];
	self.toUnicode = map;
}

#pragma mark Font Property Accessors

- (NSString *)unicodeStringUsingFontFile:(const unsigned char *)codes length:(size_t)length
{
	PDFKFontFile *fontFile = self.fontDescriptor.fontFile;
	NSMutableString *unicodeString = [NSMutableString string];
	for (int i = 0; i < length; i++)
	{
		NSString *string = [fontFile stringWithCode:codes[i]];
		[unicodeString appendString:string];
	}
	return unicodeString;
}

- (void)enumeratePDFStringCharacters:(CGPDFStringRef)pdfString usingBlock:(void (^)(NSUInteger, NSString *))block {
    
    if (self.toUnicode) {
        [self.toUnicode enumeratePDFStringCharacters:pdfString usingBlock:block];
        return;
    }
    
    const unsigned char *bytes = CGPDFStringGetBytePtr(pdfString);
    NSUInteger length = CGPDFStringGetLength(pdfString);

    if (self.fontDescriptor.fontFile) {
        
        PDFKFontFile *fontFile = self.fontDescriptor.fontFile;
        
        
        for (int i = 0; i < length; i++) {
            unichar cid = bytes[i];
            block(cid, [fontFile stringWithCode:cid]);
        }
        
        return;
    }
    
    NSData *rawBytes = [NSData dataWithBytes:bytes length:length];
	NSString *string = [[NSString alloc] initWithData:rawBytes encoding:self.encoding];
    
    for (int i = 0; i < length; i++) {
        unichar cid = bytes[i];
        block(cid, [string substringWithRange:NSMakeRange(i, 1)]);
    }

}

/* Lowest point of any character */
- (CGFloat)minY
{
	return [self.fontDescriptor descent];
}

/* Highest point of any character */
- (CGFloat)maxY
{
	return [self.fontDescriptor ascent];
}

/* Width of the given character (CID) scaled to fontsize */
- (CGFloat)widthOfCharacter:(unichar)character withFontSize:(CGFloat)fontSize
{
	NSNumber *key = @(character);
	NSNumber *width = self.widths[key];
	return [width floatValue] * fontSize;
}

/* Ligatures available in the current font encoding */
- (NSDictionary *)ligatures
{
	if (!ligatures)
	{
		// Mapping ligature Unicode character values to strings
		ligatures = @{[NSString stringWithFormat:@"%C", (unichar) 0xfb00]: @"ff",
					 [NSString stringWithFormat:@"%C", (unichar) 0xfb01]: @"fi",
					 [NSString stringWithFormat:@"%C", (unichar) 0xfb02]: @"fl",
					 [NSString stringWithFormat:@"%C", (unichar) 0x00e6]: @"ae",
					 [NSString stringWithFormat:@"%C", (unichar) 0x0153]: @"oe"};
	}

	return ligatures;
}

/* Width of space chacacter in glyph space */
- (CGFloat)widthOfSpace
{
	return [self widthOfCharacter:0x20 withFontSize:1.0];
}

- (NSString *)description
{
	NSMutableString *string = [NSMutableString string];
	[string appendFormat:@"%@ {\n", self.baseFont];
	[string appendFormat:@"\ttype = %@\n", [self classForKeyedArchiver]];
	[string appendFormat:@"\tcharacter widths = %d\n", (int)[self.widths count]];
	[string appendFormat:@"\ttoUnicode = %d\n", (self.toUnicode != nil)];
	if (self.descendantFonts) {
		[string appendFormat:@"\tdescendant fonts = %d\n", (int)[self.descendantFonts count]];
	}
	[string appendFormat:@"}\n"];
	return string;
}

/* Replace defined ligatures with separate characters */
- (NSString *)stringByExpandingLigatures:(NSString *)string
{
	NSString *replacement = nil;
	for (NSString *ligature in self.ligatures)
	{
		replacement = self.ligatures[ligature];
		if (!replacement) continue;
		string = [string stringByReplacingOccurrencesOfString:ligature withString:replacement];
	}
	return string;
}

#pragma mark Memory Management


@synthesize fontDescriptor, widths, toUnicode, widthsRange, baseFont, baseFontName, encoding, descendantFonts;
@end
