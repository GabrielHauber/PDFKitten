#import "PDFPage.h"
#import <QuartzCore/QuartzCore.h>

@implementation PDFContentView {
    CGRect _boundingBox;
}

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];
		
		CATiledLayer *tiledLayer = (CATiledLayer *) [self layer];
		tiledLayer.frame = CGRectMake(0, 0, 100, 100);
		[tiledLayer setTileSize:CGSizeMake(1024, 1024)];
		[tiledLayer setLevelsOfDetail:4];
		[tiledLayer setLevelsOfDetailBias:4];
    }
    return self;
}

+ (Class)layerClass
{
	return [CATiledLayer class];
}

- (void)setKeyword:(NSString *)str
{
	keyword = str;
	self.selections = nil;
}

- (NSArray *)selections
{
	@synchronized (self)
	{
		if (!selections)
		{
			self.selections = [self.scanner scanSelectionsMatchingString:self.keyword];
		}
		return selections;
	}
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	CGContextSetFillColorWithColor(ctx, [[UIColor whiteColor] CGColor]);
	CGContextFillRect(ctx, layer.bounds);
	
    // Flip the coordinate system
	CGContextTranslateCTM(ctx, 0.0, layer.bounds.size.height);
	CGContextScaleCTM(ctx, 1.0, -1.0);

	// Transform coordinate system to match PDF
	int rotationAngle = CGPDFPageGetRotationAngle(pdfPage);
	CGAffineTransform transform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, layer.bounds, -rotationAngle, YES);
	CGContextConcatCTM(ctx, transform);

    CGContextSetFillColorWithColor(ctx, [[UIColor colorWithRed:0.9 green:0.9 blue:1 alpha:1] CGColor]);
    CGContextFillRect(ctx, _boundingBox);

	if (self.keyword)
    {
        CGContextSetFillColorWithColor(ctx, [[UIColor yellowColor] CGColor]);
//        CGContextSetBlendMode(ctx, kCGBlendModeMultiply);

        for (PDFKSelection *s in self.selections)
        {
            CGContextFillRect(ctx, s.frame);
        }
    }

	CGContextDrawPDFPage(ctx, pdfPage);
}

#pragma mark PDF drawing

/* Draw the PDFPage to the content view */
- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(ctx, [[UIColor redColor] CGColor]);
	CGContextFillRect(ctx, rect);
}

/* Sets the current PDFPage object */
- (void)setPage:(CGPDFPageRef)page
{
    CGPDFPageRelease(pdfPage);
	pdfPage = CGPDFPageRetain(page);
	self.scanner = [[PDFKPageSelectionsScanner alloc] initWithPage:pdfPage];
    
    PDFKPageBoundingBoxScanner *boundingBoxScanner = [[PDFKPageBoundingBoxScanner alloc] initWithPage:pdfPage];
    _boundingBox = [boundingBoxScanner scanBoundingBox];
    
    PDFKPageTextScanner *textScanner = [[PDFKPageTextScanner alloc] initWithPage:pdfPage];
    NSLog(@"--- page text --- \n%@\n--- page text ---", [textScanner scanText]);
}

- (void)dealloc
{
    CGPDFPageRelease(pdfPage);
}

@synthesize keyword, selections, scanner;
@end

#pragma mark -

@implementation PDFPage

#pragma mark -

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
}

/* Override implementation to return a PDFContentView */ 
- (UIView *)contentView
{
	if (!contentView)
	{
		contentView = [[PDFContentView alloc] initWithFrame:CGRectZero];
	}
	return contentView;
}

- (void)setPage:(CGPDFPageRef)page
{
    [(PDFContentView *)self.contentView setPage:page];
    // Also set the frame of the content view according to the page size
    CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    self.contentView.frame = rect;
}

- (void)setKeyword:(NSString *)string
{
    ((PDFContentView *)contentView).keyword = string;
}

- (NSString *)keyword
{
    return ((PDFContentView *)contentView).keyword;
}

@end
