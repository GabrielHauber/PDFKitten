#import <Foundation/Foundation.h>

@class PDFFontCollection;

@interface PDFScanner : NSObject

+ (PDFScanner *)scannerWithPage:(CGPDFPageRef)page;

- (NSArray *)select:(NSString *)keyword;
- (CGRect)boundingBox;

@property (nonatomic, strong) PDFFontCollection *fontCollection;
@property (nonatomic, strong) NSMutableString *content;
@property (nonatomic, strong) NSMutableArray *selections;

@end
