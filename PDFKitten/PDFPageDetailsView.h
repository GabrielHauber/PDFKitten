#import <UIKit/UIKit.h>
#import "PDFKFontCollection.h"

@interface PDFPageDetailsView : UINavigationController <UITableViewDelegate, UITableViewDataSource> {
	PDFKFontCollection *fontCollection;
}

- (id)initWithFont:(PDFKFontCollection *)fontCollection;

@end
