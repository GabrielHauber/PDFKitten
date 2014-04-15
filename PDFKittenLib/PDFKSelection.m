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

@end
