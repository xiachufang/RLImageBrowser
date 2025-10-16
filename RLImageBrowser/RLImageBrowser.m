//
//  RLImageBrowser.m
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "RLImageBrowser.h"
#import "RLTransitionManager.h"
#import <SDWebImage/SDImageCodersManager.h>
#import <SDWebImageWebPCoder/SDImageWebPCoder.h>

inline static UIEdgeInsets RLScreenSafeAreaInsets(void) {
    if (@available(iOS 11.0, *)) {
        return [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    } else {
        return UIEdgeInsetsZero;
    }
}

CGFloat const kLessThaniOS11StatusBarHeight = 20.0f;
CGFloat const kPageViewPadding = 10.0f;

#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)

@interface RLImageBrowser () <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, readwrite) UIScrollView *pagingScrollView;
@property (nonatomic, strong) UIActivityViewController *activityViewController;
@property (nonatomic, assign) CGPoint gestureInteractionStartPoint;
@property (nonatomic, assign) CGPoint zoomingScrollViewCenter;
@property (nonatomic, assign) NSUInteger currentPageIndex;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *counterLabel;
@property (nonatomic, strong) UIButton *hideTagButton;
@property (nonatomic, strong) RLTransitionManager *transitionManager;

@end

@implementation RLImageBrowser {
    BOOL _autoHide;
    BOOL _isGestureInteraction;
    BOOL _isDraggingPhoto;
    BOOL _viewIsActive;
    BOOL _performingLayout;
    BOOL _statusBarOriginalHidden;
    NSInteger _initalPageIndex;
    UIToolbar *_toolbar;
    NSMutableArray *_photos;
    NSMutableSet *_visiblePages, *_recycledPages;
    UIBarButtonItem *_counterButtonItem, *_photoTagButtonItem;
    UIView <RLTransitionProtocol> *_previousTransitionView;
    NSInteger _maxPhotoTags;
}

#pragma mark - NSObject

- (instancetype)init {
    if ((self = [super init])) {
        
        self.hidesBottomBarWhenPushed = YES;
		
        _currentPageIndex = 0;
		_performingLayout = NO; // Reset on view did appear
        _viewIsActive = NO;
        _visiblePages = [NSMutableSet new];
        _recycledPages = [NSMutableSet new];
        _photos = [NSMutableArray new];

        _initalPageIndex = 0;
        _autoHide = YES;
        _autoHideInterface = NO;

        _displayCloseButton = YES;
        _displayToolbar = YES;
        _displayCounterLabel = YES;

        _forceHideStatusBar = NO;
		_disableVerticalSwipe = NO;
		
		_dismissOnTouch = NO;
        _arrowButtonsChangePhotosAnimated = YES;

        _animationDuration = 0.25;

        _isDraggingPhoto = NO;
		if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
            self.automaticallyAdjustsScrollViewInsets = NO;
		}
		self.modalPresentationStyle = UIModalPresentationCustom;
		self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		self.modalPresentationCapturesStatusBarAppearance = YES;
        self.transitioningDelegate = self;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRLPhotoLoadingDidEndNotification:)
                                                     name:RLPhoto_LOADING_DID_END_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification
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
        NSInteger maxPhotoTags = 0;
        for (RLPhoto *photo in _photos) {
            if (photo.photoTags.count > maxPhotoTags) maxPhotoTags = photo.photoTags.count;
        }
        _maxPhotoTags = maxPhotoTags;
	}
	return self;
}

- (instancetype)initWithPhotoURLs:(NSArray *)photoURLsArray {
    if ((self = [self init])) {
        NSArray *photosArray = [RLPhoto photosWithURLs:photoURLsArray];
        _photos = [[NSMutableArray alloc] initWithArray:photosArray];
        NSInteger maxPhotoTags = 0;
        for (RLPhoto *photo in _photos) {
            if (photo.photoTags.count > maxPhotoTags) maxPhotoTags = photo.photoTags.count;
        }
	}
	return self;
}

- (void)applicationDidBecomeActiveNotification {
    RLZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
    if (scrollView.photo.videoURL && scrollView.videoPlayerLayer.player.status == AVPlayerStatusReadyToPlay) {
        [scrollView.videoPlayerLayer.player play];
    }
}

- (void)applicationWillResignActiveNotification {
    RLZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
    if (scrollView.photo.videoURL && scrollView.videoPlayerLayer.player.status == AVPlayerStatusReadyToPlay) {
        [scrollView.videoPlayerLayer.player pause];
    }
}

- (void)dealloc {
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseAllUnderlyingPhotos];
}

- (void)releaseAllUnderlyingPhotos {
    for (id<RLPhoto> p in _photos) {
        if (![p isKindOfClass:[NSNull class]]) {
            [p unloadUnderlyingImage];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [self releaseAllUnderlyingPhotos];
    [_recycledPages removeAllObjects];
}

#pragma mark - Video Loop

- (void)playerDidFinishPlaying:(NSNotification *)notification {
    [[self pageDisplayedAtIndex:_currentPageIndex].videoPlayerLayer.player seekToTime:kCMTimeZero];
    [[self pageDisplayedAtIndex:_currentPageIndex].videoPlayerLayer.player play];
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
        [self setControlsHidden:YES animated:YES];
        _isDraggingPhoto = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    } else if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateRecognized || sender.state == UIGestureRecognizerStateFailed) {
        CGPoint velocity = [sender velocityInView:self.view];
        BOOL velocityArrive = ABS(velocity.y) > 800;
        BOOL distanceArrive = ABS(currentPoint.y - self.gestureInteractionStartPoint.y) > [UIScreen mainScreen].bounds.size.height * 0.12;
        BOOL shouldDismiss = distanceArrive || velocityArrive;
        if (shouldDismiss) {
            if (_useAnimationForPresentOrDismiss) {
                [self doneButtonPressed:nil];
            } else {
                [UIView animateWithDuration:_animationDuration animations:^{
                    [scrollView setCenter: self.zoomingScrollViewCenter];
                    scrollView.transform = CGAffineTransformMakeScale(0.001f, 0.001f);
                    scrollView.alpha = 0;
                    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                } completion:^(BOOL finished) {
                    [self doneButtonPressed:nil];
                }];
            }
        } else {
            _isDraggingPhoto = NO;
            [self setControlsHidden:!_displayToolbar animated:YES];
            
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
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
        BOOL distanceArrive = ABS(velocity.x) < 500;
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
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
        }
    }
}

#pragma mark - Genaral

- (void)prepareForClosePhotoBrowser {
    _autoHide = NO;
    // Cancel any pending toggles from taps
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dismissPhotoBrowserAnimated:(BOOL)animated {
    if ([_delegate respondsToSelector:@selector(imageBrowser:willDismissAtPageIndex:)])
        [_delegate imageBrowser:self willDismissAtPageIndex:_currentPageIndex];

    [self dismissViewControllerAnimated:animated completion:^{
        if ([self->_delegate respondsToSelector:@selector(imageBrowser:didDismissAtPageIndex:)]) {
            [self->_delegate imageBrowser:self didDismissAtPageIndex:self->_currentPageIndex];
        }
    }];
}

- (UIButton*)customToolbarButtonImage:(UIImage *)image disabledImage:(UIImage *)disabledImage action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:disabledImage forState:UIControlStateDisabled];
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
    return CGRectMake(0, 0, buttonWidth, buttonHeight);
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

	self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
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

    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;

    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:currentOrientation]];
    _toolbar.backgroundColor = [UIColor clearColor];
    _toolbar.clipsToBounds = YES;
    _toolbar.translucent = YES;
    [_toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    // Close Button
    _closeButton = [[UIButton alloc] initWithFrame:[self frameForDoneButtonAtOrientation:currentOrientation]];
    if (@available(iOS 26.0, *)) {
        _closeButton.configuration = [UIButtonConfiguration glassButtonConfiguration];
    }
    [_closeButton setAlpha:1.0f];
    [_closeButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_closeButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"RLImageBrowser.bundle/browser_close@2x" ofType:@"png"]] forState:UIControlStateNormal];

    _counterButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.counterLabel];
    if (@available(iOS 26.0, *)) {
        _counterButtonItem.hidesSharedBackground = YES;
    }

    // Tag Button
    _hideTagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_hideTagButton setFrame:[self frameForDoneButtonAtOrientation:currentOrientation]];
    [_hideTagButton addTarget:self action:@selector(hideTagButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_hideTagButton setTitle:@"隐藏标签" forState:UIControlStateNormal];
    [_hideTagButton setTitle:@"显示标签" forState:UIControlStateSelected];
    _photoTagButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_hideTagButton];
    if (@available(iOS 26.0, *)) {
        _photoTagButtonItem.hidesSharedBackground = YES;
    }

    // Gesture
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [_panGesture setMinimumNumberOfTouches:1];
    [_panGesture setMaximumNumberOfTouches:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [self reloadData];
    
    if ([_delegate respondsToSelector:@selector(willAppearPhotoBrowser:)]) {
        [_delegate willAppearPhotoBrowser:self];
    }
    
	[super viewWillAppear:animated];
    
    _statusBarOriginalHidden = [UIApplication sharedApplication].statusBarHidden;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
    
    [self _internalLayoutSubviews];
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return  UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    if (_forceHideStatusBar) {
        return YES;
    }
    if (_isDraggingPhoto) {
        return _statusBarOriginalHidden;
    } else {
        return [self areControlsHidden];
    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationFade;
}

#pragma mark - Layout


- (void)_internalLayoutSubviews {
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
   
	[self updateToolbarSubViews];

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
    if ([_delegate respondsToSelector:@selector(imageBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate imageBrowser:self captionViewForPhotoAtIndex:index];
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
    id<RLPhoto> photo = [notification object];
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
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) { // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
    }
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
            RLZoomingScrollView *page = [self dequeueRecycledPage];
            if (!page) {
                page = [[RLZoomingScrollView alloc] initWithPhotoBrowser:self maxPhotoTags:_maxPhotoTags];
            }
            page.backgroundColor = [UIColor clearColor];
            page.opaque = YES;

			[self configurePage:page forIndex:index];
			[_visiblePages addObject:page];
			[_pagingScrollView addSubview:page];

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

    __block __weak RLPhoto *photo = (RLPhoto *)page.photo;
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
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    if ([_delegate respondsToSelector:@selector(imageBrowser:didShowPhotoAtIndex:)]) {
        [_delegate imageBrowser:self didShowPhotoAtIndex:index];
        
        if ([_delegate respondsToSelector:@selector(imageBrowser:transitionViewForPhotoAtIndex:)]) {
             _previousTransitionView.hidden = NO;
            UIView <RLTransitionProtocol> *currentTransitionView = [_delegate imageBrowser:self transitionViewForPhotoAtIndex:_currentPageIndex];
            currentTransitionView.hidden = YES;
            _previousTransitionView = currentTransitionView;
        }
    }
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;
    frame.origin.x -= kPageViewPadding;
    frame.size.width += (2 * kPageViewPadding);
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
    CGRect rtn = CGRectMake(0,
                            self.view.bounds.size.height - height - RLScreenSafeAreaInsets().bottom,
                            self.view.bounds.size.width,
                            height);
    return rtn;
}

- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation {
    if (@available(iOS 26.0, *)) {
        return CGRectMake(20, 10  + RLScreenSafeAreaInsets().top, 44.f, 44.f);
    }
    return CGRectMake(0, 10 + RLScreenSafeAreaInsets().top, 72.f, 26.f);
}

- (CGRect)frameForCaptionView:(RLCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview ? _toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);
    return captionFrame;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView  {
    
    if (!_viewIsActive || _performingLayout) { return; }

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
            [self updateToolbarSubViews];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_autoHideInterface) {
        [self setControlsHidden:YES animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!_arrowButtonsChangePhotosAnimated) {
        [self updateToolbarSubViews];
    }
}

#pragma mark - Toolbar
- (void)configToolBar {
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:self
                                                                               action:nil];
    NSMutableArray *items = [NSMutableArray new];
    if (_displayCounterLabel) {
        [items addObject:_counterButtonItem];
    }
    [items addObject:flexSpace];
    [items addObject:flexSpace];
    if (_displayTagButton) {
        [items addObject:flexSpace];
        [items addObject:_photoTagButtonItem];
    }
    
    [_toolbar setItems:items];
}

- (void)updateToolbarSubViews {
    
	if ([self numberOfPhotos] > 1) {
		_counterLabel.text = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)(_currentPageIndex + 1), (unsigned long)[self numberOfPhotos]];
	} else {
		_counterLabel.text = nil;
	}
    [_toolbar setNeedsLayout];
    [_toolbar layoutIfNeeded];
    RLPhoto *photo = [self photoAtIndex:self.currentPageIndex];
    _hideTagButton.hidden = (photo.photoTags.count == 0);
}

- (void)jumpToPageAtIndex:(NSUInteger)index {
    
	if (index < [self numberOfPhotos]) {
		CGRect pageFrame = [self frameForPageAtIndex:index];

		if (_arrowButtonsChangePhotosAnimated) {
            [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - kPageViewPadding, 0) animated:YES];
        } else {
            _pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - kPageViewPadding, 0);
            [self updateToolbarSubViews];
        }
	}
}

#pragma mark - Control Hiding / Showing

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
    NSMutableSet *captionViews = [[NSMutableSet alloc] initWithCapacity:_visiblePages.count];
    for (RLZoomingScrollView *page in _visiblePages) {
        if (page.captionView) {
            [captionViews addObject:page.captionView];
        }
    }

    [UIView animateWithDuration:(animated ? 0.1 : 0) animations:^(void) {
        CGFloat alpha = hidden ? 0 : 1;
        [self.navigationController.navigationBar setAlpha:alpha];
        [self->_toolbar setAlpha:alpha];
        [self.closeButton setAlpha:alpha];
        for (UIView *v in captionViews) {
            v.alpha = alpha;
        }
    } completion:nil];

    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)areControlsHidden {
	return (_toolbar.alpha == 0);
}

- (void)hideControls {
	if(_autoHide && _autoHideInterface) {
		[self setControlsHidden:YES animated:YES ];
	}
}
- (void)handleSingleTap {
	if (_dismissOnTouch) {
		[self doneButtonPressed:nil];
	} else {
		[self setControlsHidden:![self areControlsHidden] animated:YES];
	}
}

#pragma mark - Properties

- (void)setInitialPageIndex:(NSUInteger)index {
    
    if (index >= [self numberOfPhotos]) {
        index = [self numberOfPhotos] - 1;
    }
    _initalPageIndex = index;
    _currentPageIndex = index;
	if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index];
        if (!_viewIsActive) {
           [self tilePages];
        }
    }
}

- (RLZoomingScrollView *)currentPageZoomingScrollView {
    return [self pageDisplayedAtIndex:_currentPageIndex];
}

#pragma mark - Buttons

- (void)doneButtonPressed:(id)sender {
    _dismissOnTouch = NO;
    if ([_delegate respondsToSelector:@selector(willDisappearPhotoBrowser:)]) {
        [_delegate willDisappearPhotoBrowser:self];
    }

    [self prepareForClosePhotoBrowser];
    [self dismissPhotoBrowserAnimated:YES];
}

- (void)hideTagButtonPressed:(UIButton *)button {
    button.selected = !button.isSelected;
    
    [_photos enumerateObjectsUsingBlock:^(RLPhoto *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hiddenTags = button.isSelected;
    }];
    
    RLZoomingScrollView *view = [self currentPageZoomingScrollView];
    [view photoTagViewsShouldHide:button.isSelected];
}

- (RLTransitionManager *)transitionManager {
    if (!_transitionManager) {
        _transitionManager = [[RLTransitionManager alloc] initWithPhotoBrowser:self];
    }
    return _transitionManager;
}

- (UILabel *)counterLabel {
    if (!_counterLabel) {
        _counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 95, 40)];
        _counterLabel.backgroundColor = [UIColor clearColor];
        
        _counterLabel.textColor = [UIColor whiteColor];
        _counterLabel.shadowColor = [UIColor darkTextColor];
        _counterLabel.shadowOffset = CGSizeMake(0, 1);
    }
    return _counterLabel;
}

#pragma mark <UIViewControllerTransitioningDelegate>

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self.useAnimationForPresentOrDismiss ? self.transitionManager : nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.useAnimationForPresentOrDismiss ? self.transitionManager : nil;
}

@end
