#import <UIKit/UIKit.h>

@interface DocumentsView : UINavigationController <UITableViewDelegate, UITableViewDataSource> {
	UITableViewController *tableViewController;
	NSArray *documents;
	NSDictionary *urlsByName;
	
	id __weak delegate;
}

@property (nonatomic, weak) id delegate;
@end
