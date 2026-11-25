@import XCTest;
@import RLImageBrowser;

@interface RLTestViewport : UIView
@property UIEdgeInsets testInsets;
@end
@implementation RLTestViewport
- (UIEdgeInsets)safeAreaInsets { return self.testInsets; }
@end

@interface RLTestBrowser : RLImageBrowser
@property NSUInteger dismissals;
@end
@implementation RLTestBrowser
- (void)loadView { self.view = [[RLTestViewport alloc] initWithFrame:CGRectMake(0, 0, 390, 844)]; }
- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    self.dismissals += 1;
    if (completion) completion();
}
@end

@interface RLTestPan : UIPanGestureRecognizer
@property UIGestureRecognizerState testState;
@property CGPoint testPoint;
@end
@implementation RLTestPan
- (UIGestureRecognizerState)state { return self.testState; }
- (CGPoint)locationInView:(UIView *)view { return self.testPoint; }
- (CGPoint)velocityInView:(UIView *)view { return CGPointZero; }
@end

@interface RLImageBrowser (ResizeTests)
- (void)panGestureRecognized:(UIPanGestureRecognizer *)sender;
@end

@interface Tests : XCTestCase <RLImageBrowserDelegate>
@property NSUInteger pageNotifications;
@end

@implementation Tests
- (UIImage *)imageWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, YES, 1);
    [UIColor.orangeColor setFill];
    UIRectFill((CGRect){CGPointZero, size});
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (RLTestBrowser *)browserWithPhotos:(NSArray *)photos index:(NSUInteger)index {
    RLTestBrowser *browser = [[RLTestBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    [browser setInitialPageIndex:index];
    [browser beginAppearanceTransition:YES animated:NO];
    [browser.view layoutIfNeeded];
    [browser endAppearanceTransition];
    return browser;
}

- (void)resize:(RLImageBrowser *)browser size:(CGSize)size {
    browser.view.frame = (CGRect){CGPointZero, size};
    [browser.view setNeedsLayout];
    [browser.view layoutIfNeeded];
    [browser viewDidLayoutSubviews];
    [[browser currentPageZoomingScrollView] layoutIfNeeded];
}

- (void)imageBrowser:(RLImageBrowser *)browser didShowPhotoAtIndex:(NSUInteger)index {
    self.pageNotifications += 1;
}

- (CGPoint)normalizedCenter:(RLZoomingScrollView *)page {
    UIImageView *image = page.photoImageView;
    CGPoint center = [page convertPoint:CGPointMake(CGRectGetMidX(page.bounds), CGRectGetMidY(page.bounds)) toView:image];
    return CGPointMake(center.x / image.bounds.size.width, center.y / image.bounds.size.height);
}

- (void)testInitialPageAndRepeatedFoldSizesKeepImageFitted {
    NSArray *photos = @[[RLPhoto photoWithImage:[self imageWithSize:CGSizeMake(600, 900)]],
                        [RLPhoto photoWithImage:[self imageWithSize:CGSizeMake(900, 300)]],
                        [RLPhoto photoWithImage:[self imageWithSize:CGSizeMake(800, 600)]]];
    RLImageBrowser *browser = [self browserWithPhotos:photos index:2];
    RLZoomingScrollView *page = browser.currentPageZoomingScrollView;
    NSUInteger notifications = self.pageNotifications;
    NSArray *sizes = @[[NSValue valueWithCGSize:CGSizeMake(744, 678)],
                       [NSValue valueWithCGSize:CGSizeMake(1024, 768)],
                       [NSValue valueWithCGSize:CGSizeMake(768, 1024)],
                       [NSValue valueWithCGSize:CGSizeMake(390, 844)],
                       [NSValue valueWithCGSize:CGSizeMake(844, 390)]];
    for (NSValue *value in sizes) {
        CGSize size = value.CGSizeValue;
        [self resize:browser size:size];
        XCTAssertEqual(browser.currentPageIndex, 2u);
        XCTAssertEqual(browser.currentPageZoomingScrollView, page);
        XCTAssertTrue(CGSizeEqualToSize(page.bounds.size, size));
        XCTAssertEqualWithAccuracy(browser.pagingScrollView.contentOffset.x,
                                   2 * browser.pagingScrollView.bounds.size.width, 0.5);
        CGRect image = [page.photoImageView convertRect:page.photoImageView.bounds toView:browser.view];
        XCTAssertEqualWithAccuracy(CGRectGetMidX(image), size.width / 2, 1);
        XCTAssertEqualWithAccuracy(CGRectGetMidY(image), size.height / 2, 1);
        XCTAssertLessThanOrEqual(image.size.width, size.width + 1);
        XCTAssertLessThanOrEqual(image.size.height, size.height + 1);
        XCTAssertEqualWithAccuracy(image.size.width / image.size.height, 4.0 / 3.0, 0.001);
        for (NSUInteger i = 0; i < 5; i++) [browser viewDidLayoutSubviews];
    }
    XCTAssertEqual(self.pageNotifications, notifications);
    browser.pagingScrollView.contentOffset = CGPointMake(browser.pagingScrollView.bounds.size.width, 0);
    XCTAssertEqual(browser.currentPageIndex, 1u);
    [self resize:browser size:CGSizeMake(500, 700)];
    XCTAssertEqual(browser.currentPageIndex, 1u);
    XCTAssertEqual(browser.currentPageZoomingScrollView.photo, photos[1]);
}

- (void)testCounterRemainsReadableAfterPageAndSizeChanges {
    UIImage *image = [self imageWithSize:CGSizeMake(20, 20)];
    NSMutableArray *photos = [NSMutableArray new];
    for (NSUInteger index = 0; index < 115; index++) {
        [photos addObject:[RLPhoto photoWithImage:image]];
    }
    RLImageBrowser *browser = [self browserWithPhotos:photos index:4];
    UILabel *counter = [browser valueForKey:@"counterLabel"];
    UIToolbar *toolbar = [browser valueForKey:@"toolbar"];
    NSArray *sizes = @[[NSValue valueWithCGSize:CGSizeMake(390, 844)],
                       [NSValue valueWithCGSize:CGSizeMake(844, 390)]];
    for (NSValue *size in sizes) {
        [self resize:browser size:size.CGSizeValue];
        [toolbar layoutIfNeeded];
        XCTAssertEqualObjects(counter.text, @"5 / 115");
        XCTAssertGreaterThanOrEqual(CGRectGetWidth(counter.bounds), ceil(counter.intrinsicContentSize.width));
    }
    browser.pagingScrollView.contentOffset = CGPointMake(114 * browser.pagingScrollView.bounds.size.width, 0);
    [toolbar layoutIfNeeded];
    XCTAssertEqualObjects(counter.text, @"115 / 115");
    XCTAssertGreaterThanOrEqual(CGRectGetWidth(counter.bounds), ceil(counter.intrinsicContentSize.width));
}

- (void)testZoomAndViewingPositionSurviveResize {
    RLImageBrowser *browser = [self browserWithPhotos:@[[RLPhoto photoWithImage:[self imageWithSize:CGSizeMake(1000, 1000)]]] index:0];
    [self resize:browser size:CGSizeMake(600, 600)];
    RLZoomingScrollView *page = browser.currentPageZoomingScrollView;
    page.zoomScale = page.minimumZoomScale * 1.8;
    [page layoutIfNeeded];
    page.contentOffset = CGPointMake(page.contentSize.width * 0.45 - 300, page.contentSize.height * 0.5 - 300);
    CGPoint center = [self normalizedCenter:page];
    [self resize:browser size:CGSizeMake(400, 500)];
    XCTAssertEqualWithAccuracy(page.zoomScale / page.minimumZoomScale, 1.8, 0.001);
    XCTAssertEqualWithAccuracy([self normalizedCenter:page].x, center.x, 0.005);
    XCTAssertEqualWithAccuracy([self normalizedCenter:page].y, center.y, 0.005);
    CGPoint offset = page.contentOffset;
    for (NSUInteger i = 0; i < 10; i++) [browser viewDidLayoutSubviews];
    XCTAssertTrue(CGPointEqualToPoint(page.contentOffset, offset));
    XCTAssertEqualWithAccuracy(page.zoomScale / page.minimumZoomScale, 1.8, 0.001);
    [self resize:browser size:CGSizeMake(700, 550)];
    XCTAssertEqualWithAccuracy([self normalizedCenter:page].x, center.x, 0.005);
}

- (void)testSafeAreaOnlyUpdatesControlsWithoutResettingZoom {
    RLImageBrowser *browser = [self browserWithPhotos:@[[RLPhoto photoWithImage:[self imageWithSize:CGSizeMake(700, 700)]]] index:0];
    RLZoomingScrollView *page = browser.currentPageZoomingScrollView;
    page.zoomScale = page.minimumZoomScale * 1.5;
    CGFloat scale = page.zoomScale;
    RLTestViewport *viewport = (RLTestViewport *)browser.view;
    viewport.testInsets = UIEdgeInsetsMake(35, 62, 22, 40);
    [browser viewSafeAreaInsetsDidChange];
    [browser viewDidLayoutSubviews];
    UIButton *close = [browser valueForKey:@"closeButton"];
    UIToolbar *toolbar = [browser valueForKey:@"toolbar"];
    XCTAssertGreaterThanOrEqual(CGRectGetMinX(close.frame), 62);
    XCTAssertGreaterThanOrEqual(CGRectGetMinY(close.frame), 35);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(toolbar.frame), CGRectGetHeight(viewport.bounds) - 22, 0.5);
    XCTAssertEqualWithAccuracy(page.zoomScale, scale, 0.001);
}

- (void)testTagsFollowCenteredImageAndKeepHiddenState {
    RLPhoto *photo = [RLPhoto photoWithImage:[self imageWithSize:CGSizeMake(800, 400)]];
    RLPhotoTag *tag = [RLPhotoTag new];
    tag.name = @"test tag"; tag.offsetX = 0.5; tag.offsetY = 0.5;
    photo.photoTags = @[tag];
    XCTestExpectation *widths = [self expectationWithDescription:@"tag widths"];
    [photo loadPhotoTagsWidth:^(NSArray *values) { [widths fulfill]; }];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    RLImageBrowser *browser = [self browserWithPhotos:@[photo] index:0];
    RLZoomingScrollView *page = browser.currentPageZoomingScrollView;
    UIView *tagView = [[page valueForKey:@"photoTagViews"] firstObject];
    [self resize:browser size:CGSizeMake(850, 400)];
    XCTAssertEqualWithAccuracy(CGRectGetMidY(tagView.frame), CGRectGetMidY(page.photoImageView.frame), 1);
    XCTAssertFalse(tagView.hidden);
    photo.hiddenTags = YES;
    [page photoTagViewsShouldHide:YES];
    [self resize:browser size:CGSizeMake(400, 850)];
    XCTAssertEqualWithAccuracy(CGRectGetMidY(tagView.frame), CGRectGetMidY(page.photoImageView.frame), 1);
    XCTAssertTrue(tagView.hidden);
}

- (void)testVideoResizeKeepsPlayerAndPausedState {
    RLPhoto *photo = [RLPhoto photoWithVideo:[NSURL fileURLWithPath:@"/tmp/layout-test-video.mp4"]];
    RLImageBrowser *browser = [self browserWithPhotos:@[photo] index:0];
    RLZoomingScrollView *page = browser.currentPageZoomingScrollView;
    AVPlayer *player = page.videoPlayerLayer.player;
    XCTAssertNotNil(player);
    [player pause];
    AVPlayerItem *item = player.currentItem;
    [self resize:browser size:CGSizeMake(900, 600)];
    XCTAssertEqual(page.videoPlayerLayer.player, player);
    XCTAssertEqual(player.currentItem, item);
    XCTAssertEqual(player.rate, 0);
    XCTAssertTrue(CGRectEqualToRect(page.videoPlayerLayer.frame, page.videoPlayerView.bounds));
}

- (void)testEmptyBrowserAndLoadingIndicatorHaveValidGeometry {
    RLImageBrowser *browser = [self browserWithPhotos:@[] index:NSUIntegerMax];
    [self resize:browser size:CGSizeMake(700, 500)];
    XCTAssertEqual(browser.currentPageIndex, 0u);
    XCTAssertNil(browser.currentPageZoomingScrollView);
    RLZoomingScrollView *page = [[RLZoomingScrollView alloc] initWithPhotoBrowser:browser maxPhotoTags:0];
    [page resizeToFrame:CGRectMake(0, 0, 700, 500)];
    UIView *progress = [page valueForKey:@"progressView"];
    XCTAssertEqualWithAccuracy(progress.center.x, 350, 0.5);
    XCTAssertEqualWithAccuracy(progress.center.y, 250, 0.5);
}

- (void)testResizeDuringDismissGestureCancelsWithoutClosing {
    RLTestBrowser *browser = [self browserWithPhotos:@[[RLPhoto photoWithImage:[self imageWithSize:CGSizeMake(800, 400)]]] index:0];
    RLZoomingScrollView *page = browser.currentPageZoomingScrollView;
    RLTestPan *pan = [RLTestPan new];
    pan.testState = UIGestureRecognizerStateBegan;
    pan.testPoint = CGPointMake(200, 300);
    [browser panGestureRecognized:pan];
    pan.testState = UIGestureRecognizerStateChanged;
    pan.testPoint = CGPointMake(200, 450);
    [browser panGestureRecognized:pan];
    pan.testPoint = CGPointMake(200, 650);
    [browser panGestureRecognized:pan];
    XCTAssertFalse(CGAffineTransformIsIdentity(page.transform));
    [self resize:browser size:CGSizeMake(844, 390)];
    pan.testState = UIGestureRecognizerStateCancelled;
    [browser panGestureRecognized:pan];
    XCTAssertEqual(browser.dismissals, 0u);
    XCTAssertTrue(CGAffineTransformIsIdentity(page.transform));
    XCTAssertTrue(page.userInteractionEnabled);
    XCTAssertTrue(page.scrollEnabled);
    XCTAssertEqualWithAccuracy(page.layer.anchorPoint.x, 0.5, 0.001);
    CGRect image = [page.photoImageView convertRect:page.photoImageView.bounds toView:browser.view];
    XCTAssertEqualWithAccuracy(CGRectGetMidX(image), 422, 1);
    XCTAssertEqualWithAccuracy(CGRectGetMidY(image), 195, 1);
}
@end
