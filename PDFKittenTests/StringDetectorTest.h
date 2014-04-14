#import <XCTest/XCTest.h>
#import "PDFKStringDetector.h"

@interface StringDetectorTest : XCTestCase <PDFKStringDetectorDelegate> {
    int matchCount;
    int prefixCount;
    NSString *kurtStory;
    PDFKStringDetector *stringDetector;
}

@end
