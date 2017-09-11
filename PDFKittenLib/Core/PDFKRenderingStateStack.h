@import Foundation;

@class PDFKRenderingState;

@interface PDFKRenderingStateStack : NSObject

+ (PDFKRenderingStateStack *)stack;

/* Pushes a copy of current rendering state to the stack */
- (void)pushRenderingState;

/* Pops the top rendering state off the stack */
- (PDFKRenderingState *)popRenderingState;

/* The rendering state currently on top of the stack */
@property (nonatomic, readonly) PDFKRenderingState *currentRenderingState;

@end
