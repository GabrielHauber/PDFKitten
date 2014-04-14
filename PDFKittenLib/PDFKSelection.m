#import "PDFKSelection.h"
#import "PDFKRenderingState.h"

CGFloat horizontal(CGAffineTransform transform) {
	return transform.tx / transform.a;
}


@implementation PDFKRenderingState (Selection)

- (CGFloat)userSpaceBoundsY {
    return [self convertToUserSpace:self.font.fontDescriptor.bounds.origin.y];
}

- (CGFloat)userSpaceBoundsHeight {
    return [self convertToUserSpace:self.font.fontDescriptor.bounds.size.height];
}

- (CGFloat)userSpaceAscent {
	return [self convertToUserSpace:self.font.fontDescriptor.ascent];
}

- (CGFloat)userSpaceDescent {
	return [self convertToUserSpace:self.font.fontDescriptor.descent];
}

@end


@implementation PDFKSelection

+ (PDFKSelection *)selectionWithState:(PDFKRenderingState *)state {
	PDFKSelection *selection = [[PDFKSelection alloc] init];
	selection.initialState = state;
	return selection;
}

- (CGAffineTransform)transform {
	return CGAffineTransformConcat([self.initialState textMatrix], [self.initialState ctm]);
}

- (CGRect)frame {
	return CGRectMake(0, self.originY, self.width, self.height);
}

- (CGFloat)originY {
    
    CGFloat result = MIN([self.initialState userSpaceBoundsY], [self.finalState userSpaceBoundsY]);
    
    result = MIN(result, self.descent);
    
    return result;
}

- (CGFloat)height {
    
    CGFloat result = MAX(self.initialState.fontSize, self.finalState.fontSize);
    
    result = MAX(result, [self.initialState userSpaceBoundsHeight]);
    result = MAX(result, [self.finalState userSpaceBoundsHeight]);
    
    result = MAX(result, self.ascent - self.descent);
    
	return result;
}

- (CGFloat)width {
	return horizontal(self.finalState.textMatrix) - horizontal(self.initialState.textMatrix);
}

- (CGFloat)ascent {
	return MAX([self.initialState userSpaceAscent], [self.finalState userSpaceAscent]);
}

- (CGFloat)descent {
	return MIN([self.initialState userSpaceDescent], [self.finalState userSpaceDescent]);
}

@synthesize frame, transform;
@end
