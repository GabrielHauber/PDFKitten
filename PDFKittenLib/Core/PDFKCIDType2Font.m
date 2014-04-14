#import "PDFKCIDType2Font.h"


@implementation PDFKCIDType2Font

- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if (self = [super initWithFontDictionary:dict])
	{
        // Type 2 CID font only: set CID/GID mapping
        CGPDFObjectRef streamOrName = nil;
        if (CGPDFDictionaryGetObject(dict, "CIDToGIDMap", &streamOrName))
        {
            CGPDFObjectType type = CGPDFObjectGetType(streamOrName);
            identity = (type == kCGPDFObjectTypeName);
            if (type == kCGPDFObjectTypeStream)
            {
                CGPDFStreamRef stream = nil;
                if (CGPDFObjectGetValue(streamOrName, kCGPDFObjectTypeStream, &stream))
                {
                    cidGidMap = (NSData *) CFBridgingRelease(CGPDFStreamCopyData(stream, nil));
                }
            }
        }
	}

	return self;
}

- (unichar)gidWithCid:(unsigned char)cid
{
    void *gid = nil;
    [cidGidMap getBytes:gid range:NSMakeRange(cid * 2, 2)];
    return (unichar) gid;
}


- (NSString *)stringWithPDFString:(CGPDFStringRef)pdfString
{
	size_t length = CGPDFStringGetLength(pdfString);
	const unsigned char *bytes = CGPDFStringGetBytePtr(pdfString);
    
    NSMutableString *result = [NSMutableString string];

	for (int i = 0; i < length; i+=2) {
		unsigned char unicodeValue1 = bytes[i];
		unsigned char unicodeValue2 = bytes[i+1];
        unichar unicodeValue = (unicodeValue1 << 8) + unicodeValue2;
        [result appendFormat:@"%C", unicodeValue];
	}
    return result;
}

@end
