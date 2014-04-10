#import <UIKit/UIKit.h>
#import "PageView.h"

@interface PageViewController : UIViewController <PageViewDelegate> {
	IBOutlet PageView *__weak pageView;
}

@property (weak, nonatomic, readonly) PageView *pageView;

@end
