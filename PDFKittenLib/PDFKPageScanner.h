#import <Foundation/Foundation.h>

@class PDFKFontCollection, PDFKPageScanner, PDFKRenderingState;

@protocol PDFKScannerDelegate <NSObject>

@optional
- (void)scanner:(PDFKPageScanner *)scanner didScanString:(NSString *)string;
- (void)scanner:(PDFKPageScanner *)scanner didUpdateRenderingStateForString:(NSString *)string;

@end

@interface PDFKPageScanner : NSObject

- (instancetype)initWithPage:(CGPDFPageRef)page;

- (void)scan;

@property(nonatomic) id<PDFKScannerDelegate>delegate;

@property (nonatomic, readonly) PDFKRenderingState *renderingState;

@property (nonatomic, readonly) PDFKFontCollection *fontCollection;

@end


@interface PDFKPageTextScanner : PDFKPageScanner
- (NSString *)scanText;
@end


@interface PDFKPageSelectionsScanner : PDFKPageScanner
- (NSArray *)scanSelectionsMatchingString:(NSString *)seachString;
@end


@interface PDFKPageBoundingBoxScanner : PDFKPageScanner
- (CGRect)scanBoundingBox;
@end
