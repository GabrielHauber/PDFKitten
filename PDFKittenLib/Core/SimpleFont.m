#import "SimpleFont.h"


@implementation SimpleFont

/* Initialize with a font dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if ((self = [super initWithFontDictionary:dict]))
	{
		// Set encoding for any font
		[self setEncodingWithFontDictionary:dict];
	}
	return self;
}

/* Custom implementation for all simple fonts */
- (void)setWidthsWithFontDictionary:(CGPDFDictionaryRef)dict
{
	CGPDFArrayRef array;
	if (!CGPDFDictionaryGetArray(dict, "Widths", &array)) return;
	size_t count = CGPDFArrayGetCount(array);
	CGPDFInteger firstChar, lastChar;
	if (!CGPDFDictionaryGetInteger(dict, "FirstChar", &firstChar)) return;
	if (!CGPDFDictionaryGetInteger(dict, "LastChar", &lastChar)) return;
	widthsRange = NSMakeRange(firstChar, lastChar-firstChar);
	NSMutableDictionary *widthsDict = [NSMutableDictionary dictionary];
	for (int i = 0; i < count; i++)
	{
		CGPDFReal width;
		if (!CGPDFArrayGetNumber(array, i, &width)) continue;
		NSNumber *key = [NSNumber numberWithInt:firstChar+i];
		NSNumber *value = [NSNumber numberWithFloat:width];
		[widthsDict setObject:value forKey:key];
	}
	self.widths = widthsDict;
}

/* Set encoding, given a font dictionary */
- (void)setEncodingWithFontDictionary:(CGPDFDictionaryRef)dict
{
	CGPDFObjectRef encodingObject;
	if (!CGPDFDictionaryGetObject(dict, "Encoding", &encodingObject)) return;
	[self setEncodingWithEncodingObject:encodingObject];
}

- (void)enumeratePDFStringCharacters:(CGPDFStringRef)pdfString usingBlock:(void (^)(NSUInteger, NSString *))block {
    
    if (self.encodingDifferences) {
        
        const unsigned char *bytes = CGPDFStringGetBytePtr(pdfString);
        NSUInteger length = CGPDFStringGetLength(pdfString);
        
		for (int i = 0; i < length; i++) {
            
			unichar cid = bytes[i];
            NSUInteger chr = [self.encodingDifferences mapCid:cid withEncoding:self.encoding];
            
            block(cid, [NSString stringWithFormat:@"%C", (unichar)(chr == NSNotFound ? cid : chr)]);
		}
		
		return;
    }

    [super enumeratePDFStringCharacters:pdfString usingBlock:block];
}

/* Set encoding with name or dictionary */
- (void)setEncodingWithEncodingObject:(CGPDFObjectRef)object
{
	CGPDFObjectType type = CGPDFObjectGetType(object);
	
	/* Encoding dictionary with base encoding and differences */
	if (type == kCGPDFObjectTypeDictionary)
	{
		/*	NOTE: Also needs to capture differences */
		CGPDFDictionaryRef dict = nil;
		if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict)) return;
		
        CGPDFObjectRef baseEncoding = nil;
        if (CGPDFDictionaryGetObject(dict, "BaseEncoding", &baseEncoding)){
            [self setEncodingWithEncodingObject:baseEncoding];
        }
        
        [self setupEncodingDifferencesWithEncodingDict:dict];
		return;
	}
	
	/* Only accept name objects */
	if (type != kCGPDFObjectTypeName) return;
	
	const char *name;
	if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeName, &name)) return;
	
	if (strcmp(name, "MacRomanEncoding") == 0)
	{
		self.encoding = MacRomanEncoding;
	}
	else if (strcmp(name, "MacExpertEncoding") == 0)
	{
		// What is MacExpertEncoding ??
		self.encoding = MacRomanEncoding;
	}
	else if (strcmp(name, "WinAnsiEncoding") == 0)
	{
		self.encoding = WinAnsiEncoding;
	}
}

- (void) setupEncodingDifferencesWithEncodingDict:(CGPDFDictionaryRef)encodingDict
{
    CGPDFArrayRef diffArray = nil;
    if (CGPDFDictionaryGetArray(encodingDict, "Differences", &diffArray)) {
        
        encodingDifferences = [[PDFEncodingDifferences alloc] initWithArray:diffArray];
    }
}


/* Unicode character with CID */
//- (NSString *)stringWithCharacters:(const char *)characters
//{
//	return [NSString stringWithCString:characters encoding:encoding];
//}

- (CGFloat)widthOfSpace
{
    CGFloat result = 0;
    NSUInteger cid = NSNotFound;
    
    if (self.encodingDifferences) {
        
        cid = [self.encodingDifferences cidForName:@"space"];
        
        if (cid == NSNotFound) {
            cid = [self.encodingDifferences cidForName:@"Imonospace"];
        }
        if (cid == NSNotFound) {
            cid = [self.encodingDifferences cidForName:@"Amonospace"];
        }
        
        // TODO: search more adobeglyph spaces
        
    } else if (self.toUnicode) {
        
//        cid = [self.toUnicode cidCharacter:0x20];
//        if (cid == NSNotFound) {
//            cid = [self.toUnicode cidCharacter:0xA0]; // no-break space
//        }
//        if (cid == NSNotFound) {
//            cid = [self.toUnicode cidCharacter:0x2000]; // EN QUAD
//        }
//        if (cid == NSNotFound) {
//            cid = [self.toUnicode cidCharacter:0x2002 ]; // EN SPACE
//        }
        
        // TODO: search more unicode whitespaces
    }
    
    if (cid == NSNotFound) {
    
        result = [self widthOfCharacter:0x20 withFontSize:1.0];
        
    } else {
        
        result = [self widthOfCharacter:(unichar)cid withFontSize:1.0];
    }
    
    if (!result) {
        
        NSLog(@"warning: unable determine width of space");
        // TODO: must return some non-zero value        
    }
    
    return result;
}


@synthesize encodingDifferences;

@end
