#import "Page.h"
#import "PDFKPageScanner.h"


@interface PDFContentView : PageContentView {
	CGPDFPageRef pdfPage;
    NSString *keyword;
	NSArray *selections;
}

#pragma mark

- (void)setPage:(CGPDFPageRef)page;

@property (nonatomic, strong) PDFKPageSelectionsScanner *scanner;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, copy) NSArray *selections;

@end

#pragma mark

@interface PDFPage : Page {
}

#pragma mark

- (void)setPage:(CGPDFPageRef)page;

@property (nonatomic, copy) NSString *keyword;

@end
