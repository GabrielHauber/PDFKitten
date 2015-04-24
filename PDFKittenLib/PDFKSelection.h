
@class PDFKRenderingState;

@interface PDFKSelection : NSObject

+ (PDFKSelection *)selectionWithState:(PDFKRenderingState *)state;

@property (nonatomic, readonly) CGRect frame;
@property (nonatomic, readonly) CGAffineTransform transform;

@property (nonatomic, copy) PDFKRenderingState *initialState;
@property (nonatomic, copy) PDFKRenderingState *finalState;

@property (nonatomic) NSUInteger foundLocation;

@end
