#import <Foundation/Foundation.h>
#import "PDFKCIDFont.h"

@interface PDFKCIDType2Font : PDFKCIDFont {
    NSData *cidGidMap;
}

@end
