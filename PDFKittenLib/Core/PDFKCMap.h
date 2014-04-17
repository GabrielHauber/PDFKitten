
@interface PDFKCMap : NSObject {

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
- (NSData *)unicodeMappingData:(NSUInteger)cid;
- (NSString *)unicodeMappingString:(NSUInteger)cid;

@property(nonatomic, readonly) NSUInteger codeSpaceRangeMinSize;
@property(nonatomic, readonly) NSUInteger codeSpaceRangeMaxSize;

- (BOOL)isInCodeSpaceRange:(NSUInteger)cid;

@property (nonatomic, strong) NSMutableArray *codeSpaceRanges;
@property (nonatomic, strong) NSMutableDictionary *characterMappings;
@property (nonatomic, strong) NSMutableDictionary *characterRangeMappings;

- (void)enumeratePDFStringCharacters:(CGPDFStringRef)pdfString usingBlock:(void (^)(NSUInteger, NSString *))block;

@end
