#import "PDFCMap.h"

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

- (BOOL)isInCodeSpaceRange:(unichar)cid
{
	for (NSValue *rangeValue in self.codeSpaceRanges)
	{
		NSRange range = [rangeValue rangeValue];
		if (cid >= range.location && cid <= NSMaxRange(range))
		{
			return YES;
		}
	}
	return NO;
}

#pragma mark - Public methods

/**!
 * Returns the unicode value mapped by the given character ID
 */
- (NSUInteger)unicodeCharacter:(unichar)cid
{
	if (![self isInCodeSpaceRange:cid])
        return NSNotFound;

	NSArray	*mappedRanges = [self.characterRangeMappings allKeys];
	for (NSValue *rangeValue in mappedRanges)
	{
		NSRange range = [rangeValue rangeValue];
		if (cid >= range.location && cid <= NSMaxRange(range))
		{
			NSNumber *offsetValue = [self.characterRangeMappings objectForKey:rangeValue];
            return [offsetValue unsignedIntegerValue] + cid - range.location;
		}
	}

    NSNumber *result = self.characterMappings[@((NSUInteger)cid)];
    if (result) {
        return [result unsignedIntegerValue];
    }

    return NSNotFound;
}

- (NSUInteger)cidCharacter:(unichar)unicode {
    __block NSUInteger result = NSNotFound;

    [self.characterRangeMappings enumerateKeysAndObjectsUsingBlock:^(NSValue *rangeValue, NSNumber *offset, BOOL *stop) {
        const NSRange range = [rangeValue rangeValue];
        //range.location += [offset intValue];
        const NSUInteger firstUniChar = [offset unsignedIntegerValue];
        //if (unicode >= range.location && unicode <= NSMaxRange(range)) {
        if (unicode >= firstUniChar && unicode <= (firstUniChar + range.length)) {
            //result = unicode - [offset intValue];
            result = range.location + unicode - firstUniChar;
            *stop = YES;
        }
    }];
    if (result != NSNotFound)
        return result;

    NSArray *keys = [self.characterMappings allKeysForObject:[NSNumber numberWithInt:unicode]];
    if (keys.count) {
        if (keys.count > 1) {
            NSLog(@"more keys for character %C keys = %@", unicode, keys);
        }
        return [[keys lastObject]intValue];
    } else {
        return NSNotFound;
    }
}

enum {
    
    ParseExtModeNone,
    ParseExtModeCodeSpaceRange,
    ParseExtModeBFRange,
    ParseExtModeBFChar,
};

- (NSArray *) exractNumbersFromLine:(NSString *) line
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
            
            if (s.length) {
                
                s = [s stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSScanner *hexScaner = [NSScanner scannerWithString:s];
                
                NSUInteger value;
                if (![hexScaner scanHexInt:&value])
                    break;
                [ma addObject:@(value)];                
            }
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
                
            } else if ([line rangeOfString:@"beginbfrange"].location != NSNotFound) {
                
                mode = ParseExtModeBFRange;
                
            } else if ([line rangeOfString:@"beginbfchar"].location != NSNotFound) {
                
                mode = ParseExtModeBFChar;
            }            
        }
        
        if (mode == ParseExtModeCodeSpaceRange) {
            
            NSArray *numbers = [self exractNumbersFromLine:line];
            if (numbers.count == 2) {
                
                NSValue *range = rangeValue([numbers[0] integerValue], [numbers[1] integerValue]);
                [self.codeSpaceRanges addObject:range];
            }
            
            if ([line rangeOfString:@"endcodespacerange"].location != NSNotFound) {                
                mode = ParseExtModeNone;
            }
            
        } else  if (mode == ParseExtModeBFRange) {
            
            // TODO: arrays like <005F> <0061> [<00660066> <00660069> <00660066006C>]
            // TODO: unicode32 like <D840DC3E>
            
            NSArray *numbers = [self exractNumbersFromLine:line];
            if (numbers.count == 3) {
                
                NSValue *range = rangeValue([numbers[0] integerValue], [numbers[1] integerValue]);                
                self.characterRangeMappings[range] = numbers[2];
            }
            
            if ([line rangeOfString:@"endbfrange"].location != NSNotFound) {
                mode = ParseExtModeNone;
            }
            
        } else  if (mode == ParseExtModeBFChar) {
            
            NSArray *numbers = [self exractNumbersFromLine:line];
            if (numbers.count == 2) {
                self.characterMappings[numbers[0]] = numbers[1];
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
