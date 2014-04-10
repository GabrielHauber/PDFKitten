/**
 * A detector implementing a finite state machine with the goal of detecting a predefined keyword in a continuous stream
 * of characters. The user of a detector can append strings, and will receive a number of messages reflecting the
 * current state of the detector.
 */

#import <Foundation/Foundation.h>
#import "PDFFont.h"
#import "PDFStringDetectorDelegate.h"

@interface PDFStringDetector : NSObject {
	NSString *keyword;
	NSUInteger keywordPosition;
	//NSMutableString *unicodeContent;
	id<PDFStringDetectorDelegate> __weak delegate;
}

+ (PDFStringDetector *)detectorWithKeyword:(NSString *)keyword delegate:(id<PDFStringDetectorDelegate>)delegate;
- (id)initWithKeyword:(NSString *)needle;
- (void)setKeyword:(NSString *)kword;
- (void)reset;

- (NSString *)appendString:(NSString *)inputString;

@property (nonatomic, weak) id<PDFStringDetectorDelegate> delegate;
//@property (nonatomic, retain) NSMutableString *unicodeContent;
@end
