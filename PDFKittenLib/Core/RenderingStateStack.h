#import <Foundation/Foundation.h>

@class PDFRenderingState;

@interface RenderingStateStack : NSObject {
	NSMutableArray *stack;
}

+ (RenderingStateStack *)stack;

/* Push a rendering state to the stack */
- (void)pushRenderingState:(PDFRenderingState *)state;

/* Pops the top rendering state off the stack */
- (PDFRenderingState *)popRenderingState;

/* The rendering state currently on top of the stack */
@property (weak, nonatomic, readonly) PDFRenderingState *topRenderingState;

@end