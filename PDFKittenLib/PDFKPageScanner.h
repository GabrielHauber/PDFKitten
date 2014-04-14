#import <Foundation/Foundation.h>

@class PDFKFontCollection, PDFKPageScanner;

@protocol PDFKScannerDelegate <NSObject>

@optional
- (void)scanner:(PDFKPageScanner *)scanner didScanString:(NSString *)string;


@end

@interface PDFKPageScanner : NSObject

+ (PDFKPageScanner *)scannerWithPage:(CGPDFPageRef)page;

- (NSArray *)select:(NSString *)keyword;
- (NSString *)scanText;
- (CGRect)boundingBox;

@property (nonatomic, strong) PDFKFontCollection *fontCollection;

@end



