#import <Foundation/Foundation.h>

@class PDFKStringDetector;

@protocol PDFKStringDetectorDelegate <NSObject>
@optional
- (void)detectorDidStartMatching:(PDFKStringDetector *)stringDetector;
- (void)detectorFoundString:(PDFKStringDetector *)detector;
- (void)detector:(PDFKStringDetector *)detector didScanCharacter:(unichar)character;
@end
