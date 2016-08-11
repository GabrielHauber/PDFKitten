#import "PDFKFontDescriptor.h"
#import "PDFKTrueTypeFont.h"
#import "PDFKFontFile.h"
#import <CommonCrypto/CommonDigest.h>

const char *kAscentKey = "Ascent";
const char *kDescentKey = "Descent";
const char *kLeadingKey = "Leading";
const char *kCapHeightKey = "CapHeight";
const char *kXHeightKey = "XHeight";
const char *kAverageWidthKey = "AvgWidth";
const char *kMaxWidthKey = "MaxWidth";
const char *kMissingWidthKey = "MissingWidth";
const char *kFlagsKey = "Flags";
const char *kStemVKey = "StemV";
const char *kStemHKey = "StemH";
const char *kItalicAngleKey = "ItalicAngle";
const char *kFontNameKey = "FontName";
const char *kFontBBoxKey = "FontBBox";
const char *kFontFileKey = "FontFile";


@implementation PDFKFontDescriptor

- (id)initWithPDFDictionary:(CGPDFDictionaryRef)dict
{
	const char *type = nil;
	CGPDFDictionaryGetName(dict, kTypeKey, &type);
	if (!type || strcmp(type, kFontDescriptorKey) != 0)
	{
		// some editior may omit /FontDescriptor key
		// [self release]; return nil;
	}

	if ((self = [super init]))
	{
		CGPDFReal ascentValue = 0;
		CGPDFReal descentValue = 0;
		CGPDFReal leadingValue = 0;
		CGPDFReal capHeightValue = 0;
		CGPDFReal xHeightValue = 0;
		CGPDFReal averageWidthValue = 0;
		CGPDFReal maxWidthValue = 0;
		CGPDFReal missingWidthValue = 0;
		CGPDFInteger flagsValue = 0L;
		CGPDFReal stemV = 0;
		CGPDFReal stemH = 0;
		CGPDFReal italicAngleValue = 0;
		const char *fontNameString = nil;
		CGPDFArrayRef bboxValue = nil;

		CGPDFDictionaryGetNumber(dict, kAscentKey, &ascentValue);
        CGPDFDictionaryGetNumber(dict, kDescentKey, &descentValue);
        CGPDFDictionaryGetNumber(dict, kLeadingKey, &leadingValue);
		CGPDFDictionaryGetNumber(dict, kCapHeightKey, &capHeightValue);
		CGPDFDictionaryGetNumber(dict, kXHeightKey, &xHeightValue);
		CGPDFDictionaryGetNumber(dict, kAverageWidthKey, &averageWidthValue);
		CGPDFDictionaryGetNumber(dict, kMaxWidthKey, &maxWidthValue);
		CGPDFDictionaryGetNumber(dict, kMissingWidthKey, &missingWidthValue);
		CGPDFDictionaryGetInteger(dict, kFlagsKey, &flagsValue);
		CGPDFDictionaryGetNumber(dict, kStemVKey, &stemV);
        CGPDFDictionaryGetNumber(dict, kStemHKey, &stemH);
        CGPDFDictionaryGetNumber(dict, kItalicAngleKey, &italicAngleValue);
        CGPDFDictionaryGetName(dict, kFontNameKey, &fontNameString);
		CGPDFDictionaryGetArray(dict, kFontBBoxKey, &bboxValue);
        
        self.ascent = ascentValue;
        self.descent = descentValue;
        self.leading = leadingValue;
		self.capHeight = capHeightValue;
		self.xHeight = xHeightValue;
		self.averageWidth = averageWidthValue;
		self.maxWidth = maxWidthValue;
        self.missingWidth = missingWidthValue;
        self.flags = flagsValue;
        self.verticalStemWidth = stemV;
        self.horizontalStemWidth = stemH;
        self.italicAngle = italicAngleValue;
        self.fontName = @(fontNameString);

		if (CGPDFArrayGetCount(bboxValue) == 4)
		{
			CGPDFReal x = 0, y = 0, width = 0, height = 0;
			CGPDFArrayGetNumber(bboxValue, 0, &x);
			CGPDFArrayGetNumber(bboxValue, 1, &y);
			CGPDFArrayGetNumber(bboxValue, 2, &width);
			CGPDFArrayGetNumber(bboxValue, 3, &height);
			self.bounds = CGRectMake(x, y, width, height);
		}
		
		CGPDFStreamRef fontFileStream;
		if (CGPDFDictionaryGetStream(dict, kFontFileKey, &fontFileStream))
		{
			CGPDFDataFormat format;
			NSData *data = (NSData *) CFBridgingRelease(CGPDFStreamCopyData(fontFileStream, &format));
			/*
	 		NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
			path = [path stringByAppendingPathComponent:@"fontfile"];
			[data writeToFile:path atomically:YES];
			  */
			fontFile = [[PDFKFontFile alloc] initWithData:data];
		}

	}
	return self;
}

/* True if a font is symbolic */
- (BOOL)isSymbolic
{
	return ((self.flags & PDFKFontSymbolic) > 0) && ((self.flags & PDFKFontNonSymbolic) == 0);
}

#pragma mark Memory Management


@synthesize ascent, descent, bounds, leading, capHeight, averageWidth, maxWidth, missingWidth, xHeight, flags, verticalStemWidth, horizontalStemWidth, italicAngle, fontName;
@synthesize fontFile;
@end
