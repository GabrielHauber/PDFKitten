#import <Foundation/Foundation.h>
#import "PDFKCompositeFont.h"

@interface PDFKCIDFont : PDFKCompositeFont {
    BOOL identity;
}

@property (readonly, getter = isIdentity) BOOL identity;
@end
