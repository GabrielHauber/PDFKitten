#import <UIKit/UIKit.h>


@interface PageContentView : UIView {
}

@end

@interface Page : UIScrollView <UIScrollViewDelegate> {
	NSInteger pageNumber;
	UIView *contentView;
	UIView *detailedView;
}
- (UIView *)contentView;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, strong) UIView *detailedView;
@end
