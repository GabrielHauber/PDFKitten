#import <Foundation/Foundation.h>

@interface PDFCMap : NSObject {

	/* CMap ranges */
	NSMutableArray *codeSpaceRanges;
	
	/* Character mappings */
	NSMutableDictionary *characterMappings;
	
	/* Character range mappings */
	NSMutableDictionary *characterRangeMappings;
}

/* Initialize with PDF stream containing a CMap */
- (id)initWithPDFStream:(CGPDFStreamRef)stream;

/* Initialize with a string representation of a CMap */
- (id)initWithString:(NSString *)string;

/* Unicode mapping for character ID */
- (NSUInteger)unicodeCharacter:(unichar)cid;

- (NSUInteger)cidCharacter:(unichar)unicode;

@property (nonatomic, strong) NSMutableArray *codeSpaceRanges;
@property (nonatomic, strong) NSMutableDictionary *characterMappings;
@property (nonatomic, strong) NSMutableDictionary *characterRangeMappings;

@end
