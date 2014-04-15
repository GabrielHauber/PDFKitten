/**
 * A detector implementing a finite state machine with the goal of detecting a predefined keyword in a continuous stream
 * of characters. The user of a detector can append strings, and will receive a number of messages reflecting the
 * current state of the detector.
 */

#import <Foundation/Foundation.h>
#import "PDFKFont.h"
#import "PDFStringDetectorDelegate.h"

@interface PDFKStringDetector : NSObject {
	NSString *keyword;
	NSUInteger keywordPosition;
	//NSMutableString *unicodeContent;
}

+ (PDFKStringDetector *)detectorWithKeyword:(NSString *)keyword delegate:(id<PDFKStringDetectorDelegate>)delegate;
- (id)initWithKeyword:(NSString *)needle;
- (void)setKeyword:(NSString *)kword;
- (void)reset;

- (void)appendUnicodeString:(NSString *)inputString;

@property (nonatomic, weak) id<PDFKStringDetectorDelegate> delegate;
//@property (nonatomic, retain) NSMutableString *unicodeContent;
@end
