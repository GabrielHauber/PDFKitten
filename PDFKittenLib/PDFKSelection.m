#import "PDFKSelection.h"
#import "PDFKRenderingState.h"


@implementation PDFKSelection

+ (PDFKSelection *)selectionWithState:(PDFKRenderingState *)state {
	PDFKSelection *selection = [[PDFKSelection alloc] init];
	selection.initialState = state;
	return selection;
}

- (CGRect)frame {
    return CGRectUnion(_initialState.frame, _finalState.frame);
}

- (CGAffineTransform)transform {
    CGAffineTransform transform = CGAffineTransformConcat([_initialState textMatrix], [_initialState ctm]);
    return CGAffineTransformMakeRotation(atan2(transform.b, transform.a));
}

@end
