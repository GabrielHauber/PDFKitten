#import <XCTest/XCTest.h>
#import "PDFStringDetector.h"

@interface StringDetectorTest : XCTestCase <PDFStringDetectorDelegate> {
    int matchCount;
    int prefixCount;
    NSString *kurtStory;
    PDFStringDetector *stringDetector;
}

@end
