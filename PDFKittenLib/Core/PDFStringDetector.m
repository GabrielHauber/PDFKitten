#import "PDFStringDetector.h"

@implementation PDFStringDetector

+ (PDFStringDetector *)detectorWithKeyword:(NSString *)keyword delegate:(id<PDFStringDetectorDelegate>)delegate {
	PDFStringDetector *detector = [[PDFStringDetector alloc] initWithKeyword:keyword];
	detector.delegate = delegate;
	return detector;
}

- (id)initWithKeyword:(NSString *)string {
	if (self = [super init]) {
        keyword = [string lowercaseString];
        //self.unicodeContent = [NSMutableString string];
	}

	return self;
}

- (NSString *)appendUnicodeString:(NSString *)inputString forCharacter:(NSUInteger)cid {
	NSString *lowercaseString = [inputString lowercaseString];
    int position = 0;

    while (position < inputString.length) {
		unichar actualCharacter = [lowercaseString characterAtIndex:position++];
        unichar expectedCharacter = [keyword characterAtIndex:keywordPosition];

        if (actualCharacter != expectedCharacter) {
            if (keywordPosition > 0) {
                // Read character again
                position--;
            }
			else if ([_delegate respondsToSelector:@selector(detector:didScanCharacter:)]) {
				[_delegate detector:self didScanCharacter:cid];
			}

            // Reset keyword position
            keywordPosition = 0;
            continue;
        }

        if (keywordPosition == 0 && [_delegate respondsToSelector:@selector(detectorDidStartMatching:)]) {
            [_delegate detectorDidStartMatching:self];
        }

        if ([_delegate respondsToSelector:@selector(detector:didScanCharacter:)]) {
            [_delegate detector:self didScanCharacter:cid];
        }

        if (++keywordPosition < keyword.length) {
            // Keep matching keyword
            continue;
        }

        // Reset keyword position
        keywordPosition = 0;
        if ([_delegate respondsToSelector:@selector(detectorFoundString:)]) {
            [_delegate detectorFoundString:self];
        }
    }

    return inputString;
}

- (void)setKeyword:(NSString *)kword {
    keyword = [kword lowercaseString];

    keywordPosition = 0;
}

- (void)reset {
    keywordPosition = 0;
}

@end
