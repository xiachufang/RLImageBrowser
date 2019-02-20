//
//  RLImageBrowser.m
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RLPhotoBrowser.h"
#import "RLZoomingScrollView.h"
#import "RLRectHelper.h"
#import "SDImageCodersManager.h"
#import "SDImageWebPCoder.h"

CGFloat const kLessThaniOS11StatusBarHeight = 20.0f;
CGFloat const kPageViewPadding = 10.0f;

// Private
@interface RLPhotoBrowser () {
	// Data
    NSMutableArray *_photos;

	// Views
	UIScrollView *_pagingScrollView;
	// Paging
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _pageIndexBeforeRotation;
    NSUInteger _currentPageIndex;
    
	// Toolbar
	UIToolbar *_toolbar;
	UIBarButtonItem *_actionButtonItem;
    UIBarButtonItem *_counterButtonItem;
    UILabel *_counterLabel;
    
	BOOL _statusBarOriginallyHidden;

    // Present
    UIView *_senderViewForAnimation;

    // Misc
    BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _autoHide;
    NSInteger _initalPageIndex;
    BOOL _isDraggingPhoto;

    CGRect _senderViewOriginalFrame;
    UIWindow *_applicationWindow;
}

// Private Properties
@property (nonatomic, strong) UIActivityViewController *activityViewController;
@property (nonatomic, assign) CGPoint gestureInteractionStartPoint;
@property (nonatomic, assign) CGPoint zoomingScrollViewCenter;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation RLPhotoBrowser {
    NSTimer *_controlVisibilityTimer;
    BOOL _isGestureInteraction;
}

#pragma mark - NSObject

- (instancetype)init {
    if ((self = [super init])) {
        // Defaults
        self.hidesBottomBarWhenPushed = YES;
		
        _currentPageIndex = 0;
		_performingLayout = NO; // Reset on view did appear
		_rotating = NO;
        _viewIsActive = NO;
        _visiblePages = [NSMutableSet new];
        _recycledPages = [NSMutableSet new];
        _photos = [NSMutableArray new];

        _initalPageIndex = 0;
        _autoHide = YES;
        _autoHideInterface = NO;

        _displayCloseButton = YES;
        _displayToolbar = YES;
        _displayActionButton = YES;
        _displayCounterLabel = NO;

        _forceHideStatusBar = NO;
		_disableVerticalSwipe = NO;
		
		_dismissOnTouch = NO;

        _useWhiteBackgroundColor = NO;
        _arrowButtonsChangePhotosAnimated = YES;

        _animationDuration = 0.25;
        _senderViewForAnimation = nil;
        _scaleImage = nil;

        _isDraggingPhoto = NO;
		if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
            self.automaticallyAdjustsScrollViewInsets = NO;
		}
		
        _applicationWindow = [[[UIApplication sharedApplication] delegate] window];
		self.modalPresentationStyle = UIModalPresentationCustom;
		self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		self.modalPresentationCapturesStatusBarAppearance = YES;
		self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        // Listen for RLPhoto notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRLPhotoLoadingDidEndNotification:)
                                                     name:RLPhoto_LOADING_DID_END_NOTIFICATION
                                                   object:nil];
        if (![[SDImageCodersManager sharedManager].coders containsObject:[SDImageWebPCoder sharedCoder]]) {
            [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
        }
    }
	
    return self;
}

- (instancetype)initWithPhotos:(NSArray *)photosArray {
    if ((self = [self init])) {
		_photos = [[NSMutableArray alloc] initWithArray:photosArray];
	}
	return self;
}

- (instancetype)initWithPhotos:(NSArray *)photosArray animatedFromView:(UIView *)view {
    if ((self = [self init])) {
		_photos = [[NSMutableArray alloc] initWithArray:photosArray];
        _senderViewForAnimation = view;
	}
	return self;
}

- (instancetype)initWithPhotoURLs:(NSArray *)photoURLsArray {
    if ((self = [self init])) {
        NSArray *photosArray = [RLPhoto photosWithURLs:photoURLsArray];
		_photos = [[NSMutableArray alloc] initWithArray:photosArray];
	}
	return self;
}

- (instancetype)initWithPhotoURLs:(NSArray *)photoURLsArray animatedFromView:(UIView *)view {
    if ((self = [self init])) {
        NSArray *photosArray = [RLPhoto photosWithURLs:photoURLsArray];
		_photos = [[NSMutableArray alloc] initWithArray:photosArray];
        _senderViewForAnimation = view;
	}
	return self;
}

- (void)dealloc {
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseAllUnderlyingPhotos];
}

- (void)releaseAllUnderlyingPhotos {
    for (id p in _photos) {
        if (p != [NSNull null]) {
            [p unloadUnderlyingImage];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [self releaseAllUnderlyingPhotos];
    [_recycledPages removeAllObjects];
}

#pragma mark - Pan Gesture

- (void)panGestureRecognized:(UIPanGestureRecognizer *)sender {
    // Initial Setup
    RLZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
    CGPoint currentPoint = [sender locationInView:self.view];
    // Gesture Began
    if ([sender state] == UIGestureRecognizerStateBegan) {
        self.gestureInteractionStartPoint = currentPoint;
        self.zoomingScrollViewCenter = scrollView.center;
        [self setControlsHidden:YES animated:YES permanent:YES];
        _senderViewForAnimation.hidden = (_currentPageIndex == _initalPageIndex);
        _isDraggingPhoto = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    } else if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateRecognized || sender.state == UIGestureRecognizerStateFailed) {
        CGPoint velocity = [sender velocityInView:self.view];
        BOOL velocityArrive = ABS(velocity.y) > 800;
        BOOL distanceArrive = ABS(currentPoint.y - self.gestureInteractionStartPoint.y) > [UIScreen mainScreen].bounds.size.height * 0.22;
        BOOL shouldDismiss = distanceArrive || velocityArrive;
        if (shouldDismiss) {
            // perform Close Animation
            if (_senderViewForAnimation && _currentPageIndex == _initalPageIndex) {
                [self performCloseAnimationWithScrollView:scrollView];
                return;
            }
            [UIView animateWithDuration:0.25 animations:^{
                [scrollView setCenter: self.zoomingScrollViewCenter];
                scrollView.transform = CGAffineTransformMakeScale(0.001f, 0.001f);
                scrollView.alpha = 0;
                self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            } completion:^(BOOL finished) {
                [self doneButtonPressed:nil];
            }];
        } else {
            // Continue Showing View
            _isDraggingPhoto = NO;
            [self setNeedsStatusBarAppearanceUpdate];
            
            self.view.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor ? 1 : 0) alpha:1];
            [UIView animateWithDuration:0.15 animations:^{
                scrollView.center = self.zoomingScrollViewCenter;
                scrollView.layer.anchorPoint = CGPointMake(0.5, 0.5);
                scrollView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.gestureInteractionStartPoint = CGPointZero;
                self->_isGestureInteraction = NO;
                scrollView.userInteractionEnabled = YES;
                scrollView.scrollEnabled = YES;
            }];
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint velocity = [sender velocityInView:self.view];
        BOOL startPointValid = !CGPointEqualToPoint(self.gestureInteractionStartPoint, CGPointZero);
        BOOL distanceArrive = ABS(currentPoint.x - self.gestureInteractionStartPoint.x) < 3 && ABS(velocity.x) < 500;
        BOOL upArrive = currentPoint.y - self.gestureInteractionStartPoint.y > 3 && scrollView.contentOffset.y <= 1,
        downArrive = currentPoint.y - self.gestureInteractionStartPoint.y < - 3 && scrollView.contentOffset.y + scrollView.bounds.size.height >= MAX(scrollView.contentSize.height, scrollView.bounds.size.height) - 1;
        BOOL shouldStart = startPointValid && !_isGestureInteraction && distanceArrive && (upArrive || downArrive);
        if (shouldStart) {
            self.gestureInteractionStartPoint = currentPoint;
            
            CGRect startFrame = scrollView.frame;
            CGFloat anchorX = currentPoint.x / startFrame.size.width,
            anchorY = currentPoint.y / startFrame.size.height;
            scrollView.layer.anchorPoint = CGPointMake(anchorX, anchorY);
            scrollView.userInteractionEnabled = NO;
            scrollView.scrollEnabled = NO;
            _isGestureInteraction = YES;
        }
        
        if (_isGestureInteraction) {
            NSInteger index = _pagingScrollView.contentOffset.x / (self.view.frame.size.width + 2 * kPageViewPadding);
            scrollView.center = CGPointMake(index * (self.view.frame.size.width + 2 * kPageViewPadding) + currentPoint.x + kPageViewPadding, currentPoint.y);;
            CGFloat scale = 1 - ABS(currentPoint.y - self.gestureInteractionStartPoint.y) / ([UIScreen mainScreen].bounds.size.height);
            if (scale > 1) scale = 1;
            if (scale < 0.35) scale = 0.35;
            scrollView.transform = CGAffineTransformMakeScale(scale, scale);
            
            CGFloat alpha = 1 - ABS(currentPoint.y - self.gestureInteractionStartPoint.y) / ([UIScreen mainScreen].bounds.size.height);
            if (alpha > 1) alpha = 1;
            if (alpha < 0) alpha = 0;
            self.view.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor ? 1 : 0) alpha:alpha];
        }
    }
}

#pragma mark - Animation

- (void)performPresentAnimation {
    self.view.alpha = 0.0f;
    _pagingScrollView.alpha = 0.0f;

    UIImage *imageFromView = _scaleImage ? _scaleImage : [self getImageFromView:_senderViewForAnimation];

    _senderViewOriginalFrame = [_senderViewForAnimation.superview convertRect:_senderViewForAnimation.frame toView:nil];

    UIView *fadeView = [[UIView alloc] initWithFrame:_applicationWindow.bounds];
    fadeView.backgroundColor = [UIColor clearColor];
    [_applicationWindow addSubview:fadeView];

    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = _senderViewOriginalFrame;
    resizableImageView.clipsToBounds = YES;
    resizableImageView.contentMode = _senderViewForAnimation ? _senderViewForAnimation.contentMode : UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    if (@available(iOS 11.0, *)) {
        resizableImageView.accessibilityIgnoresInvertColors = YES;
    }
    [_applicationWindow addSubview:resizableImageView];
    _senderViewForAnimation.hidden = YES;

    void (^completion)(BOOL finished) = ^(BOOL finished) {
        self.view.alpha = 1.0f;
        self->_pagingScrollView.alpha = 1.0f;
        resizableImageView.backgroundColor = [UIColor colorWithWhite:(self->_useWhiteBackgroundColor) ? 1 : 0 alpha:1];
        [fadeView removeFromSuperview];
        [resizableImageView removeFromSuperview];
    };

    [UIView animateWithDuration:_animationDuration animations:^{
        fadeView.backgroundColor = self.useWhiteBackgroundColor ? [UIColor whiteColor] : [UIColor blackColor];
    } completion:nil];

    CGRect finalImageViewFrame = [self animationFrameForImage:imageFromView presenting:YES scrollView:nil];

    [UIView animateWithDuration:_animationDuration animations:^{
        resizableImageView.layer.frame = finalImageViewFrame;
    } completion:completion];
}

- (void)performCloseAnimationWithScrollView:(RLZoomingScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(willDisappearPhotoBrowser:)]) {
        [_delegate willDisappearPhotoBrowser:self];
    }

    float fadeAlpha = 1 - fabs(scrollView.frame.origin.y)/scrollView.frame.size.height;

    UIImage *imageFromView = [scrollView.photo underlyingImage];
    if (!imageFromView && [scrollView.photo respondsToSelector:@selector(placeholderImage)]) {
        imageFromView = [scrollView.photo placeholderImage];
    }

    UIView *fadeView = [[UIView alloc] initWithFrame:_applicationWindow.bounds];
    fadeView.backgroundColor = self.useWhiteBackgroundColor ? [UIColor whiteColor] : [UIColor blackColor];
    fadeView.alpha = fadeAlpha;
    [_applicationWindow addSubview:fadeView];

    CGRect imageViewFrame = [self animationFrameForImage:imageFromView presenting:NO scrollView:scrollView];

    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = imageViewFrame;
    resizableImageView.contentMode = _senderViewForAnimation ? _senderViewForAnimation.contentMode : UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    resizableImageView.clipsToBounds = YES;
    if (@available(iOS 11.0, *)) {
        resizableImageView.accessibilityIgnoresInvertColors = YES;
    }
    [_applicationWindow addSubview:resizableImageView];
    self.view.hidden = YES;

    void (^completion)(BOOL finished) = ^(BOOL finished) {
        self->_senderViewForAnimation.hidden = NO;
        self->_senderViewForAnimation = nil;
        self->_scaleImage = nil;

        [fadeView removeFromSuperview];
        [resizableImageView removeFromSuperview];

        [self prepareForClosePhotoBrowser];
        [self dismissPhotoBrowserAnimated:NO];
    };

    [UIView animateWithDuration:_animationDuration animations:^{
        fadeView.alpha = 0;
        self.view.backgroundColor = [UIColor clearColor];
    } completion:nil];

    CGRect senderViewOriginalFrame = _senderViewForAnimation.superview ? [_senderViewForAnimation.superview convertRect:_senderViewForAnimation.frame toView:nil] : _senderViewOriginalFrame;
    [UIView animateWithDuration:_animationDuration animations:^{
        resizableImageView.layer.frame = senderViewOriginalFrame;
    } completion:completion];
}

- (CGRect)animationFrameForImage:(UIImage *)image presenting:(BOOL)presenting scrollView:(RLZoomingScrollView *)scrollView {
    if (!image) {
        return CGRectZero;
    }
    if (scrollView.photoImageView) {
        return [_applicationWindow convertRect:scrollView.photoImageView.frame fromView:scrollView];
    }
    
    CGSize imageSize = image.size;
    CGRect bounds = _applicationWindow.bounds;
    // adjust bounds as the photo browser does
    if (@available(iOS 11.0, *)) {
        // use the windows safe area inset
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIEdgeInsets insets = UIEdgeInsetsMake(kLessThaniOS11StatusBarHeight, 0, 0, 0);
        if (window != NULL) {
            insets = window.safeAreaInsets;
        }
        bounds = [self adjustForSafeArea:bounds adjustForStatusBar:NO forInsets:insets];
    }
    CGFloat maxWidth = CGRectGetWidth(bounds);
    CGFloat maxHeight = CGRectGetHeight(bounds);

    CGRect animationFrame = CGRectZero;

    CGFloat aspect = imageSize.width / imageSize.height;
    if (maxWidth / aspect <= maxHeight) {
        animationFrame.size = CGSizeMake(maxWidth, maxWidth / aspect);
    } else {
        animationFrame.size = CGSizeMake(maxHeight * aspect, maxHeight);
    }

    animationFrame.origin.x = roundf((maxWidth - animationFrame.size.width) / 2.0f);
    animationFrame.origin.y = roundf((maxHeight - animationFrame.size.height) / 2.0f);

    if (!presenting) {
        animationFrame.origin.y += scrollView.frame.origin.y;
    }
    return animationFrame;
}

#pragma mark - Genaral

- (void)prepareForClosePhotoBrowser {
    // Gesture
    [_applicationWindow removeGestureRecognizer:_panGesture];
    _autoHide = NO;
    // Cancel any pending toggles from taps
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dismissPhotoBrowserAnimated:(BOOL)animated {
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    if ([_delegate respondsToSelector:@selector(photoBrowser:willDismissAtPageIndex:)])
        [_delegate photoBrowser:self willDismissAtPageIndex:_currentPageIndex];

    [self dismissViewControllerAnimated:animated completion:^{
        if ([self->_delegate respondsToSelector:@selector(photoBrowser:didDismissAtPageIndex:)]) {
            [self->_delegate photoBrowser:self didDismissAtPageIndex:self->_currentPageIndex];
        }
    }];
}

- (UIButton*)customToolbarButtonImage:(UIImage*)image imageSelected:(UIImage*)selectedImage action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateDisabled];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setContentMode:UIViewContentModeCenter];
    [button setFrame:[self getToolbarButtonFrame:image]];
    return button;
}

- (CGRect)getToolbarButtonFrame:(UIImage *)image{
    BOOL const isRetinaHd = ((float)[[UIScreen mainScreen] scale] > 2.0f);
    float const defaultButtonSize = isRetinaHd ? 66.0f : 44.0f;
    CGFloat buttonWidth = (image.size.width > defaultButtonSize) ? image.size.width : defaultButtonSize;
    CGFloat buttonHeight = (image.size.height > defaultButtonSize) ? image.size.width : defaultButtonSize;
    return CGRectMake(0,0, buttonWidth, buttonHeight);
}

- (UIImage*)getImageFromView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 2);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIViewController *)topviewController {
    UIViewController *topviewController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topviewController.presentedViewController) {
        topviewController = topviewController.presentedViewController;
    }
    return topviewController;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // View
	self.view.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor ? 1 : 0) alpha:1];

    self.view.clipsToBounds = YES;

	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    //_pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
	_pagingScrollView.backgroundColor = [UIColor clearColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];

    // Transition animation
    [self performPresentAnimation];

    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;

    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:currentOrientation]];
    _toolbar.backgroundColor = [UIColor clearColor];
    _toolbar.clipsToBounds = YES;
    _toolbar.translucent = YES;
    [_toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    // Close Button
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setFrame:[self frameForDoneButtonAtOrientation:currentOrientation]];
    [_closeButton setAlpha:1.0f];
    [_closeButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_closeButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"browser_close@2x" ofType:@"png"]] forState:UIControlStateNormal];

    _counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 95, 40)];
    _counterLabel.backgroundColor = [UIColor clearColor];

    if (_useWhiteBackgroundColor == NO) {
        _counterLabel.textColor = [UIColor whiteColor];
        _counterLabel.shadowColor = [UIColor darkTextColor];
        _counterLabel.shadowOffset = CGSizeMake(0, 1);
    } else {
        _counterLabel.textColor = [UIColor blackColor];
    }

    // Counter Button
    _counterButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_counterLabel];

    // Action Button
    if(_actionButtonImage != nil && _actionButtonSelectedImage != nil) {
        _actionButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self customToolbarButtonImage:_actionButtonImage
                                                                                   imageSelected:_actionButtonSelectedImage
                                                                                          action:@selector(actionButtonPressed:)]];
    } else {
        _actionButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                  target:self
                                                                  action:@selector(actionButtonPressed:)];
    }
    // Gesture
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [_panGesture setMinimumNumberOfTouches:1];
    [_panGesture setMaximumNumberOfTouches:1];
}

- (void)viewWillAppear:(BOOL)animated {
    // Update
    [self reloadData];
    
    if ([_delegate respondsToSelector:@selector(willAppearPhotoBrowser:)]) {
        [_delegate willAppearPhotoBrowser:self];
    }

    // Super
	[super viewWillAppear:animated];

    // Status Bar
    _statusBarOriginallyHidden = [UIApplication sharedApplication].statusBarHidden;

    // Update UI
	[self hideControlsAfterDelay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _useWhiteBackgroundColor ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    if (_forceHideStatusBar) {
        return YES;
    }
    if (_isDraggingPhoto) {
        return _statusBarOriginallyHidden;
    } else {
        return [self areControlsHidden];
    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationFade;
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
	// Flag
	_performingLayout = YES;

    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;

    // Toolbar
    _toolbar.frame = [self frameForToolbarAtOrientation:currentOrientation];

    _closeButton.frame = [self frameForDoneButtonAtOrientation:currentOrientation];

    // Remember index
	NSUInteger indexPriorToLayout = _currentPageIndex;

	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];

	// Frame needs changing
	_pagingScrollView.frame = pagingScrollViewFrame;

	// Recalculate contentSize based on current orientation
	_pagingScrollView.contentSize = [self contentSizeForPagingScrollView];

	// Adjust frames and configuration of each visible page
	for (RLZoomingScrollView *page in _visiblePages) {
        NSUInteger index = PAGE_INDEX(page);
		page.frame = [self frameForPageAtIndex:index];
        page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
		[page setMaxMinZoomScalesForCurrentBounds];
	}

	// Adjust contentOffset to preserve page location based on values collected prior to location
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
	[self didStartViewingPageAtIndex:_currentPageIndex]; // initial

	// Reset
	_currentPageIndex = indexPriorToLayout;
	_performingLayout = NO;

    [super viewWillLayoutSubviews];
}

- (void)performLayout {
    // Setup
    _performingLayout = YES;
    
    // Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];

    // Toolbar
    if (_displayToolbar) {
        [self.view addSubview:_toolbar];
    } else {
        [_toolbar removeFromSuperview];
    }

    // Close button
    if (_displayCloseButton && !self.navigationController.navigationBar) {
        [self.view addSubview:_closeButton];
    }
    
    [self configToolBar];
   
	[self updateToolbarCounterLabel];

    // Content offset
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;

    if (!_disableVerticalSwipe) {
        [self.view addGestureRecognizer:_panGesture];
    }
}

#pragma mark - Data

- (void)reloadData {
    // Get data
    [self releaseAllUnderlyingPhotos];

    // Update
    [self performLayout];

    // Layout
    [self.view setNeedsLayout];
}

- (NSUInteger)numberOfPhotos {
    return _photos.count;
}

- (id<RLPhoto>)photoAtIndex:(NSUInteger)index {
    return _photos[index];
}

- (RLCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    RLCaptionView *captionView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate photoBrowser:self captionViewForPhotoAtIndex:index];
    } else {
        id <RLPhoto> photo = [self photoAtIndex:index];
        if ([photo respondsToSelector:@selector(caption)]) {
            if ([photo caption]) {
                captionView = [[RLCaptionView alloc] initWithPhoto:photo];
            }
        }
    }
    captionView.alpha = [self areControlsHidden] ? 0 : 1; // Initial alpha
    return captionView;
}

- (UIImage *)imageForPhoto:(id<RLPhoto>)photo {
	if (photo) {
		// Get image or obtain in background
		if ([photo underlyingImage]) {
			return [photo underlyingImage];
		} else {
            [photo loadUnderlyingImageAndNotify];
            if ([photo respondsToSelector:@selector(placeholderImage)]) {
                return [photo placeholderImage];
            }
		}
	}
	return nil;
}

- (void)loadAdjacentPhotosIfNecessary:(id<RLPhoto>)photo {
    RLZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = PAGE_INDEX(page);
        if (_currentPageIndex == pageIndex) {
            //preload
            if (pageIndex > 0) {
                id <RLPhoto> photo = [self photoAtIndex:pageIndex - 1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                id <RLPhoto> photo = [self photoAtIndex:pageIndex + 1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                }
            }
        }
    }
}

#pragma mark - RLPhoto Loading Notification

- (void)handleRLPhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <RLPhoto> photo = [notification object];
    RLZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if ([photo underlyingImage]) {
            // Successful load
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            // Failed to load
            [page displayImageFailure];
            if ([_delegate respondsToSelector:@selector(photoBrowser:imageFailed:imageView:)]) {
                NSUInteger pageIndex = PAGE_INDEX(page);
                [_delegate photoBrowser:self imageFailed:pageIndex imageView:page.photoImageView];
            }
            // make sure the page is completely updated
            [page setNeedsLayout];
        }
    }
}

#pragma mark - Paging

- (void)tilePages {
	// Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
	CGRect visibleBounds = _pagingScrollView.bounds;
	NSInteger iFirstIndex = (NSInteger) floorf((CGRectGetMinX(visibleBounds) + kPageViewPadding * 2) / CGRectGetWidth(visibleBounds));
	NSInteger iLastIndex  = (NSInteger) floorf((CGRectGetMaxX(visibleBounds) - kPageViewPadding * 2 - 1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) {
        iFirstIndex = iFirstIndex >= 0 ?: 0 ;
    } else if (iFirstIndex > [self numberOfPhotos] - 1) {
        iFirstIndex = [self numberOfPhotos] - 1;
    }
    if (iLastIndex < 0) {
        iLastIndex = 0;
    } else if (iLastIndex > [self numberOfPhotos] - 1) {
        iLastIndex = [self numberOfPhotos] - 1;
    }
	// Recycle no longer needed pages
    NSInteger pageIndex;
	for (RLZoomingScrollView *page in _visiblePages) {
        pageIndex = PAGE_INDEX(page);
		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
			[_recycledPages addObject:page];
            [page prepareForReuse];
			[page removeFromSuperview];
            RLLog(@"Removed page at index %li", PAGE_INDEX(page));
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) { // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
    }
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
            RLZoomingScrollView *page = [[RLZoomingScrollView alloc] initWithPhotoBrowser:self];
            page.backgroundColor = [UIColor clearColor];
            page.opaque = YES;

			[self configurePage:page forIndex:index];
			[_visiblePages addObject:page];
			[_pagingScrollView addSubview:page];
            RLLog(@"Added page at index %lu", (unsigned long)index);

            // Add caption
            RLCaptionView *captionView = [self captionViewForPhotoAtIndex:index];
            captionView.frame = [self frameForCaptionView:captionView atIndex:index];
            [_pagingScrollView addSubview:captionView];
            page.captionView = captionView;
		}
	}
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    for (RLZoomingScrollView *page in _visiblePages) {
        if (PAGE_INDEX(page) == index) {
            return YES;
        }
    }
	return NO;
}

- (RLZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
	RLZoomingScrollView *thePage = nil;
	for (RLZoomingScrollView *page in _visiblePages) {
		if (PAGE_INDEX(page) == index) {
			thePage = page;
            break;
		}
	}
	return thePage;
}

- (RLZoomingScrollView *)pageDisplayingPhoto:(id<RLPhoto>)photo {
	RLZoomingScrollView *thePage = nil;
	for (RLZoomingScrollView *page in _visiblePages) {
		if (page.photo == photo) {
			thePage = page;
            break;
		}
	}
	return thePage;
}

- (void)configurePage:(RLZoomingScrollView *)page forIndex:(NSUInteger)index {
	page.frame = [self frameForPageAtIndex:index];
    page.tag = PAGE_INDEX_TAG_OFFSET + index;
    page.photo = [self photoAtIndex:index];

    __block __weak RLPhoto *photo = (RLPhoto*)page.photo;
    __weak RLZoomingScrollView *weakPage = page;
    photo.progressUpdateBlock = ^(CGFloat progress){
        [weakPage setProgress:progress forPhoto:photo];
    };
}

- (RLZoomingScrollView *)dequeueRecycledPage {
	RLZoomingScrollView *page = [_recycledPages anyObject];
	if (page) {
		[_recycledPages removeObject:page];
	}
	return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    id <RLPhoto> currentPhoto = [self photoAtIndex:index];
    if ([currentPhoto underlyingImage]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    if ([_delegate respondsToSelector:@selector(photoBrowser:didShowPhotoAtIndex:)]) {
        [_delegate photoBrowser:self didShowPhotoAtIndex:index];
    }
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;
    frame.origin.x -= kPageViewPadding;
    frame.size.width += (2 * kPageViewPadding);
    frame = [self adjustForSafeArea:frame adjustForStatusBar:false];
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * kPageViewPadding);
    pageFrame.origin.x = (bounds.size.width * index) + kPageViewPadding;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
	CGFloat pageWidth = _pagingScrollView.bounds.size.width;
	CGFloat newOffset = index * pageWidth;
	return CGPointMake(newOffset, 0);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = UIInterfaceOrientationIsLandscape(orientation) ? 32 : 44;
    CGRect rtn = CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
    rtn = [self adjustForSafeArea:rtn adjustForStatusBar:true];
    return rtn;
}

- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation {
    CGRect rtn = CGRectMake(0, 10, 55.f, 26.f);
    rtn = [self adjustForSafeArea:rtn adjustForStatusBar:true];
    return rtn;
}

- (CGRect)frameForCaptionView:(RLCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);
    return captionFrame;
}

- (CGRect)adjustForSafeArea:(CGRect)rect adjustForStatusBar:(BOOL)adjust {
    if (@available(iOS 11.0, *)) {
        return [self adjustForSafeArea:rect adjustForStatusBar:adjust forInsets:self.view.safeAreaInsets];
    }
    UIEdgeInsets insets = UIEdgeInsetsMake(kLessThaniOS11StatusBarHeight, 0, 0, 0);
    return [self adjustForSafeArea:rect adjustForStatusBar:adjust forInsets:insets];
}

- (CGRect)adjustForSafeArea:(CGRect)rect adjustForStatusBar:(BOOL)adjust forInsets:(UIEdgeInsets) insets {
    return [RLRectHelper adjustRect:rect forSafeAreaInsets:insets forBounds:self.view.bounds adjustForStatusBar:adjust statusBarHeight:kLessThaniOS11StatusBarHeight];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView  {
    // Checks
    if (!_viewIsActive || _performingLayout || _rotating) { return; }

    // Tile pages
    [self tilePages];

    // Calculate current page
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger) (floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) {
        index = 0;
    }
    if (index > [self numberOfPhotos] - 1) {
        index = [self numberOfPhotos] - 1;
    }
    NSUInteger previousCurrentPage = _currentPageIndex;
    _currentPageIndex = index;
    if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];

        if (_arrowButtonsChangePhotosAnimated) {
            [self updateToolbarCounterLabel];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// Hide controls when dragging begins
    if (_autoHideInterface) {
        [self setControlsHidden:YES animated:YES permanent:NO];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update toolbar when page changes
    if(! _arrowButtonsChangePhotosAnimated) {
        [self updateToolbarCounterLabel];
    }
}

#pragma mark - Toolbar
- (void)configToolBar {
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:self action:nil];
    NSMutableArray *items = [NSMutableArray new];
    if (_displayCounterLabel) {
        [items addObject:_counterButtonItem];
    }
    [items addObject:flexSpace];
    [items addObject:flexSpace];
    
    if (_displayActionButton) {
        [items addObject:flexSpace];
        [items addObject:_actionButtonItem];
    }
    [_toolbar setItems:items];
}

- (void)updateToolbarCounterLabel {
    // Counter
	if ([self numberOfPhotos] > 1) {
		_counterLabel.text = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)(_currentPageIndex + 1), (unsigned long)[self numberOfPhotos]];
	} else {
		_counterLabel.text = nil;
	}
}

- (void)jumpToPageAtIndex:(NSUInteger)index {
    // Change page
	if (index < [self numberOfPhotos]) {
		CGRect pageFrame = [self frameForPageAtIndex:index];

		if (_arrowButtonsChangePhotosAnimated) {
            [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - kPageViewPadding, 0) animated:YES];
        } else {
            _pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - kPageViewPadding, 0);
            [self updateToolbarCounterLabel];
        }
	}

	// Update timer to give more time
	[self hideControlsAfterDelay];
}

#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    // Cancel any timers
    [self cancelControlHiding];

    // Captions
    NSMutableSet *captionViews = [[NSMutableSet alloc] initWithCapacity:_visiblePages.count];
    for (RLZoomingScrollView *page in _visiblePages) {
        if (page.captionView) {
            [captionViews addObject:page.captionView];
        }
    }

    // Hide/show bars
    [UIView animateWithDuration:(animated ? 0.1 : 0) animations:^(void) {
        CGFloat alpha = hidden ? 0 : 1;
        [self.navigationController.navigationBar setAlpha:alpha];
        [self->_toolbar setAlpha:alpha];
        [self.closeButton setAlpha:alpha];
        for (UIView *v in captionViews) {
            v.alpha = alpha;
        }
    } completion:nil];

	// Control hiding timer
	// Will cancel existing timer but only begin hiding if they are visible
	if (!permanent) {
		[self hideControlsAfterDelay];
	}
	
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)cancelControlHiding {
	// If a timer exists then cancel and release
	if (_controlVisibilityTimer) {
		[_controlVisibilityTimer invalidate];
		_controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
    if (![self autoHideInterface]) {
        return;
    }

	if (![self areControlsHidden]) {
        [self cancelControlHiding];
		_controlVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
	}
}

- (BOOL)areControlsHidden {
	return (_toolbar.alpha == 0);
}

- (void)hideControls {
	if(_autoHide && _autoHideInterface) {
		[self setControlsHidden:YES animated:YES permanent:NO];
	}
}
- (void)handleSingleTap {
	if (_dismissOnTouch) {
		[self doneButtonPressed:nil];
	} else {
		[self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO];
	}
}

#pragma mark - Properties

- (void)setInitialPageIndex:(NSUInteger)index {
    // Validate
    if (index >= [self numberOfPhotos]) index = [self numberOfPhotos] - 1;
    _initalPageIndex = index;
    _currentPageIndex = index;
	if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index];
        if (!_viewIsActive) {
           [self tilePages]; // Force tiling if view is not visible
        }
    }
}

#pragma mark - Buttons

- (void)doneButtonPressed:(id)sender {
    _dismissOnTouch = NO;
    if ([_delegate respondsToSelector:@selector(willDisappearPhotoBrowser:)]) {
        [_delegate willDisappearPhotoBrowser:self];
    }

    if (_senderViewForAnimation && _currentPageIndex == _initalPageIndex) {
        RLZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
        [self performCloseAnimationWithScrollView:scrollView];
    } else {
        _senderViewForAnimation.hidden = NO;
        [self prepareForClosePhotoBrowser];
        [self dismissPhotoBrowserAnimated:YES];
    }
}

- (void)actionButtonPressed:(id)sender {
    id <RLPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
        // Activity view
        NSMutableArray *activityItems = [NSMutableArray arrayWithObject:[photo underlyingImage]];
        if (photo.caption) [activityItems addObject:photo.caption];

        self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

        __typeof__(self) __weak wself = self;
        [self.activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            [wself hideControlsAfterDelay];
            wself.activityViewController = nil;
        }];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:self.activityViewController animated:YES completion:nil];
        } else { // iPad
            UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:self.activityViewController];
            [popover presentPopoverFromRect:CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 4, 0, 0)
                                     inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny
                                   animated:YES];
        }
        // Keep controls hidden
        [self setControlsHidden:NO animated:YES permanent:YES];
    }
}

@end
