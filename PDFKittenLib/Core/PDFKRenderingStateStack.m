#import "PDFKRenderingStateStack.h"
#import "PDFKRenderingState.h"

@implementation PDFKRenderingStateStack {
	NSMutableArray *_stack;
}

+ (PDFKRenderingStateStack *)stack {
	return [[PDFKRenderingStateStack alloc] init];
}

- (id)init
{
    self = [super init];
	if (self)
	{
		_stack = [[NSMutableArray alloc] initWithObjects:[PDFKRenderingState new], nil];
	}
	return self;
}

/* The rendering state currently on top of the stack */
- (PDFKRenderingState *)currentRenderingState
{
	return [_stack lastObject];
}

/* Push a rendering state to the stack */
- (void)pushRenderingState
{
	[_stack addObject:[_stack.lastObject copy]];
}

/* Pops the top rendering state off the stack */
- (PDFKRenderingState *)popRenderingState
{
	PDFKRenderingState *state = [_stack lastObject];
	[_stack removeLastObject];
	return state;
}

@end
