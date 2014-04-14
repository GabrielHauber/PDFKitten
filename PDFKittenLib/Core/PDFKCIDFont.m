#import "PDFKCIDFont.h"

@implementation PDFKCIDFont

- (NSString *)stringWithPDFString:(CGPDFStringRef)pdfString
{
	unichar *bytes = (unichar *) CGPDFStringGetBytePtr(pdfString);
	size_t length = CGPDFStringGetLength(pdfString) / sizeof(unichar);
	int magicalOffset = ([self isIdentity] ? 0 : 30);

	NSMutableString *unicodeString = [NSMutableString string];

	for (int i = 0; i < length; i++)
	{
		unichar unicodeValue = bytes[i] + magicalOffset;
		[unicodeString appendFormat:@"%C", unicodeValue];
	}
    
	return unicodeString;
}

@synthesize identity;
@end
