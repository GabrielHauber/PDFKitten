#import <Foundation/Foundation.h>

@class PDFKRenderingState;

@interface PDFKSelection : NSObject

+ (PDFKSelection *)selectionWithState:(PDFKRenderingState *)state;

@property (nonatomic, readonly) CGRect frame;
@property (nonatomic, readonly) CGAffineTransform transform;

@property (nonatomic, copy) PDFKRenderingState *initialState;
@property (nonatomic, copy) PDFKRenderingState *finalState;

@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat ascent;

@property (nonatomic, readwrite) NSUInteger foundLocation;

@end
