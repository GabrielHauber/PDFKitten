#import <Foundation/Foundation.h>

@class PDFFontCollection;

@interface PDFScanner : NSObject

+ (PDFScanner *)scannerWithPage:(CGPDFPageRef)page;

- (NSArray *)select:(NSString *)keyword;
- (NSString *)scanText;
- (CGRect)boundingBox;

@property (nonatomic, strong) PDFFontCollection *fontCollection;

@end
