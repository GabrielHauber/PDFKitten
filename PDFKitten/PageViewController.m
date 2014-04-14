#import "PageViewController.h"

@interface PageViewController ()
@property (weak, nonatomic) IBOutlet PageView *pageView;
@end

@implementation PageViewController

- (NSInteger)numberOfPagesInPageView:(PageView *)pageView
{
	return 0;
}

- (Page *)pageView:(PageView *)pageView viewForPage:(NSInteger)page
{
	return nil;
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[_pageView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.pageView.dataSource = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
