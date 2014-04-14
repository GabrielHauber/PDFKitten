#import "PDFCMap.h"

@implementation NSString (HexData)

- (NSData *)hexData {
    
	char buf[3];
	buf[2] = '\0';

	unsigned char *bytes = malloc([self length] / 2);
	unsigned char *bp = bytes;
    
    NSUInteger length = [self length];
    if (length % 2 != 0)
        length--;
    
	for (CFIndex i = 0; i < length; i += 2) {
		buf[0] = [self characterAtIndex:i];
		buf[1] = [self characterAtIndex:i+1];
		char *b2 = NULL;
		*bp++ = strtol(buf, &b2, 16);
		if (buf + 2 != b2)
            break;
	}
	
	return [NSData dataWithBytesNoCopy:bytes length:length / 2 freeWhenDone:YES];
}

@end


@implementation NSData (NumericGetters)

- (NSUInteger)unsignedIntegerValue {

    NSUInteger result = 0;
    const unsigned char *bytes = self.bytes;
    
    for (size_t i = 0; i < self.length; i++) {
        result = result << 8;
        result |= bytes[i];
    }
    
    return result;
}

- (instancetype)dataByAddingToLastByte:(unichar)value {
    
    NSMutableData *mutableData = [self mutableCopy];
    
    const unsigned char *bytes = self.bytes;
    
    const char lastByte = bytes[self.length - 1] + value;
    
    [mutableData replaceBytesInRange:NSMakeRange(self.length - 1, 1) withBytes:&lastByte];
    
    return mutableData;
}

@end


static NSValue *rangeValue(NSUInteger from, NSUInteger to)
{
	return [NSValue valueWithRange:NSMakeRange(from, to - from + 1)];
}

@implementation PDFCMap {
    
    // NSString *_debugString;
}

- (id)initWithString:(NSString *)string
{
	if ((self = [super init]))
	{
        _codeSpaceRangeMinSize = NSNotFound;
        [self parse:string];
        // _debugString = [string copy];
        
	}
	return self;
}

- (id)initWithPDFStream:(CGPDFStreamRef)stream
{
	NSData *data = (NSData *) CFBridgingRelease(CGPDFStreamCopyData(stream, nil));
	NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    id obj = [self initWithString:text];
    return obj;
}

#pragma mark - Public methods

- (BOOL)isInCodeSpaceRange:(NSUInteger)cid
{
	for (NSValue *rangeValue in self.codeSpaceRanges)
	{
		NSRange range = [rangeValue rangeValue];
		if (NSLocationInRange(cid, range))
			return YES;
	}
    
	return NO;
}

- (NSData *)unicodeMappingData:(NSUInteger)cid
{
	NSArray	*mappedRanges = [self.characterRangeMappings allKeys];
	for (NSValue *rangeValue in mappedRanges)
	{
		NSRange range = [rangeValue rangeValue];
		if (NSLocationInRange(cid, range))
		{
			NSData *dataValue = [self.characterRangeMappings objectForKey:rangeValue];
            
            return [dataValue dataByAddingToLastByte:cid - range.location];
		}
	}

    return self.characterMappings[@(cid)];
}

- (NSString *)unicodeMappingString:(NSUInteger)cid {
    NSData *data = [self unicodeMappingData:cid];
    
    if (data)
        return [[NSString alloc] initWithData:data encoding:NSUTF16BigEndianStringEncoding];
    
    return nil;
}

- (void)enumeratePDFStringCharacters:(CGPDFStringRef)pdfString usingBlock:(void (^)(NSUInteger, NSString *))block {
    
    size_t stringLength = CGPDFStringGetLength(pdfString);
    const unsigned char *bytes = CGPDFStringGetBytePtr(pdfString);
    
    int i = 0;
    NSUInteger characterCode = 0;
    NSUInteger charSize = 0;
    
    while (i < stringLength) {
        
        characterCode = characterCode << 8;
        characterCode |= bytes[i++];
        
        charSize++;
        
        if (charSize < _codeSpaceRangeMinSize || (![self isInCodeSpaceRange:characterCode] && charSize <= _codeSpaceRangeMaxSize))
            continue;
        
        NSString *unicode = [self unicodeMappingString:characterCode];
        
        block(characterCode, unicode);
        
        charSize = 0;
        characterCode = 0;
    }

}

enum {
    
    ParseExtModeNone,
    ParseExtModeCodeSpaceRange,
    ParseExtModeBFRange,
    ParseExtModeBFChar,
};

- (NSArray *)exractDataValuesFromLine:(NSString *) line
{
    NSMutableArray *ma = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:line];
    while (!scanner.isAtEnd) {
        
        if ([scanner scanString:@"<" intoString:nil]) {
            
            NSString *s;
            if (![scanner scanUpToString:@">" intoString:&s])
                break;
            if (![scanner scanString:@">" intoString:nil])
                break;
            
            [ma addObject:[s hexData]];
        }
        
        [scanner scanUpToString:@"<" intoString:nil];
    }
    
    return ma;
}

- (void) parse:(NSString *)string
{
    NSUInteger mode = ParseExtModeNone;
    
    NSArray *lines = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        
        if (mode == ParseExtModeNone) {
        
            if ([line rangeOfString:@"begincodespacerange"].location != NSNotFound) {
                
                mode = ParseExtModeCodeSpaceRange;
                continue;
                
            } else if ([line rangeOfString:@"beginbfrange"].location != NSNotFound) {
                
                mode = ParseExtModeBFRange;
                continue;
                
            } else if ([line rangeOfString:@"beginbfchar"].location != NSNotFound) {
                
                mode = ParseExtModeBFChar;
                continue;
            }
        }
        
        if (mode == ParseExtModeCodeSpaceRange) {
            
            NSArray *dataValues = [self exractDataValuesFromLine:line];
            if (dataValues.count == 2) {
                
                NSValue *range = rangeValue([dataValues[0] unsignedIntegerValue], [dataValues[1] unsignedIntegerValue]);
                [self.codeSpaceRanges addObject:range];
                
                _codeSpaceRangeMinSize = MIN(_codeSpaceRangeMinSize, [dataValues[0] length]);
                _codeSpaceRangeMaxSize = MAX(_codeSpaceRangeMaxSize, [dataValues[1] length]);
            }
            
            if ([line rangeOfString:@"endcodespacerange"].location != NSNotFound) {                
                mode = ParseExtModeNone;
            }
            
        } else  if (mode == ParseExtModeBFRange) {
            
            // TODO: arrays like <005F> <0061> [<00660066> <00660069> <00660066006C>]
            // TODO: unicode32 like <D840DC3E>
            
            NSArray *dataValues = [self exractDataValuesFromLine:line];
            if (dataValues.count == 3) {
                
                NSValue *range = rangeValue([dataValues[0] unsignedIntegerValue], [dataValues[1] unsignedIntegerValue]);
                self.characterRangeMappings[range] = dataValues[2];
            }
            
            if ([line rangeOfString:@"endbfrange"].location != NSNotFound) {
                mode = ParseExtModeNone;
            }
            
        } else  if (mode == ParseExtModeBFChar) {
            
            NSArray *dataValues = [self exractDataValuesFromLine:line];
            if (dataValues.count == 2) {
                self.characterMappings[@([dataValues[0] unsignedIntegerValue])] = dataValues[1];
            }
            
            if ([line rangeOfString:@"endbfchar"].location != NSNotFound) {
                mode = ParseExtModeNone;                
            } 
        } 
    }
}

- (NSMutableArray *)codeSpaceRanges {
	if (!codeSpaceRanges) {
		codeSpaceRanges = [[NSMutableArray alloc] init];
	}
	return codeSpaceRanges;
}

- (NSMutableDictionary *)characterMappings {
	if (!characterMappings) {
		characterMappings = [[NSMutableDictionary alloc] init];
	}
	return characterMappings;
}

- (NSMutableDictionary *)characterRangeMappings {
	if (!characterRangeMappings) {
		self.characterRangeMappings = [NSMutableDictionary dictionary];
	}
	return characterRangeMappings;
}


@synthesize codeSpaceRanges, characterMappings, characterRangeMappings;
@end
