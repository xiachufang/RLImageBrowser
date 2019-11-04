//
//  RLZoomingScrollView.m
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import "RLZoomingScrollView.h"
#import "RLImageBrowser.h"
#import "RLPhoto.h"
#import "RLPhotoTagView.h"

#pragma mark - Private methods of image browser
static NSString * const kPlayerKeyPath = @"status";

@interface RLImageBrowser ()

- (UIImage *)imageForPhoto:(id<RLPhoto>)photo;
- (void)handleSingleTap;

@end

@implementation RLZoomingScrollView {
    NSArray *_photoTagViews;
}

- (instancetype)initWithPhotoBrowser:(RLImageBrowser *)browser maxPhotoTags:(NSInteger)maxPhotoTags {
    if ((self = [super init])) {
        self.photoBrowser = browser;
        
        // Tap view for background
        _tapView = [[RLDetectingView alloc] initWithFrame:self.bounds];
        _tapView.detectingDelegate = self;
        _tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tapView.backgroundColor = [UIColor clearColor];
        [self addSubview:_tapView];
        
        _videoPlayerView = [[RLDetectingView alloc] initWithFrame:self.bounds];
        _videoPlayerView.detectingDelegate = self;
        _videoPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _videoPlayerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_videoPlayerView];
        
        _videoPlayerLayer = [[AVPlayerLayer alloc] init];
        _videoPlayerLayer.backgroundColor = [UIColor clearColor].CGColor;
        [_videoPlayerLayer setFrame:_videoPlayerView.bounds];
        [_videoPlayerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        [_videoPlayerView.layer addSublayer:_videoPlayerLayer];
        
        
        // Image view
        _photoImageView = [[RLDetectingImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.detectingDelegate = self;
        _photoImageView.backgroundColor = [UIColor clearColor];
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        if (@available(iOS 11.0, *)) {
            _photoImageView.accessibilityIgnoresInvertColors = YES;
        }
        [self addSubview:_photoImageView];
        
        //Add darg&drop in iOS 11
        if (@available(iOS 11.0, *)) {
            UIDragInteraction *drag = [[UIDragInteraction alloc] initWithDelegate: self];
            [_photoImageView addInteraction:drag];
            [_videoPlayerView addInteraction:drag];
        }
        
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenBound.size.width;
        CGFloat screenHeight = screenBound.size.height;
        
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
            screenWidth = screenBound.size.height;
            screenHeight = screenBound.size.width;
        }
        
        // Progress view
        _progressView = [[RLCircularProgressView alloc] initWithFrame:CGRectMake((screenWidth - 35.0) * 0.5f, (screenHeight - 35.0) * 0.5f, 35.0f, 35.0f)];
        [_progressView setProgress:0.0f];
        _progressView.thicknessRatio = 0.18;
        _progressView.roundedCorners = NO;
        _progressView.trackTintColor    = browser.trackTintColor    ? self.photoBrowser.trackTintColor    : [UIColor colorWithWhite:0.2 alpha:1];
        _progressView.progressTintColor = browser.progressTintColor ? self.photoBrowser.progressTintColor : [UIColor colorWithWhite:1.0 alpha:1];
        [self addSubview:_progressView];
        
        // Setup
        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        NSMutableArray *tempArray = [NSMutableArray array];
        for (int i = 0; i < maxPhotoTags; i ++) {
            RLPhotoTagView *tagView = [[RLPhotoTagView alloc] init];
            UITapGestureRecognizer *tagViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagViewDidClick:)];
            [tagView addGestureRecognizer:tagViewTap];
            tagView.hidden = YES;
            [self addSubview:tagView];
            [tempArray addObject:tagView];
        }
        _photoTagViews = tempArray.copy;
        
    }
    return self;
}

- (void)setPhoto:(id<RLPhoto>)photo {
    _photoImageView.image = nil;
    if (_photo != photo) {
        _photo = photo;
    }
    [self displayImage];
}

- (void)dealloc {
    [self resetPlayerLayer];
}

- (void)resetPlayerLayer {
    [_videoPlayerLayer.player removeObserver:self forKeyPath:kPlayerKeyPath context:nil];
    [_videoPlayerLayer.player pause];
    _videoPlayerLayer.player = NULL;
}

- (void)prepareForReuse {
    [_progressView setProgress:0 animated:NO];
    [_progressView setIndeterminate:NO];
    [self resetPlayerLayer];
    
    self.photo = nil;
    [_captionView removeFromSuperview];
    self.captionView = nil;
    
    [self photoTagViewsShouldHide:YES];
}

#pragma mark - Drag & Drop

- (NSArray<UIDragItem *> *)dragInteraction:(UIDragInteraction *)interaction itemsForBeginningSession:(id<UIDragSession>)session NS_AVAILABLE_IOS(11.0) {
    return @[[[UIDragItem alloc] initWithItemProvider:[[NSItemProvider alloc] initWithObject:_photoImageView.image]]];
}

- (void)photoTagViewsShouldHide:(BOOL)hidden {
    for (UIView *view in _photoTagViews) {
        view.hidden = hidden;
    }
}

#pragma mark - Image

- (void)displayImage {
    if (!_photo) {
        return;
    }
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    self.contentSize = CGSizeMake(0, 0);
    
    // Get image from browser as it handles ordering of fetching
    UIImage *photoImage = [self.photoBrowser imageForPhoto:_photo];
    if (photoImage) {
        _videoPlayerView.hidden = YES;
        //_progressView.alpha = 0.0f;
        [_progressView removeFromSuperview];
        
        // Set image
        _photoImageView.image = photoImage;
        _photoImageView.hidden = NO;
        
        // Setup photo frame
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = CGSizeMake(self.bounds.size.width, self.bounds.size.width * (photoImage.size.height / photoImage.size.width));
        
        _photoImageView.frame = photoImageViewFrame;
        
        //Async calculate the width of each tag, and cache the width
        __weak typeof(self) wself = self;
        [_photo loadPhotoTagsWidth:^(NSArray *widths) {
            [wself configPhotoTagsViewWithWidths:widths];
        }];
        
        self.contentSize = photoImageViewFrame.size;

        // Set zoom to minimum zoom
        [self setMaxMinZoomScalesForCurrentBounds];
    } else if (_photo.videoURL != NULL) {
        // Hide ProgressView
        [_progressView setProgress:0.2 animated:YES];
        [_progressView setIndeterminateDuration:0.8f];
        [_progressView setIndeterminate:YES];
        
        _photoImageView.hidden = YES;
        _videoPlayerView.hidden = NO;
        
        [_videoPlayerLayer.player pause];
        _videoPlayerLayer.player = NULL;
        AVPlayer *player = [AVPlayer playerWithURL:_photo.videoURL];
        [_videoPlayerLayer setPlayer:player];
        
        [player seekToTime:kCMTimeZero];
        [player play];
        
        [player addObserver:self forKeyPath:kPlayerKeyPath options:0 context:nil];
    } else {
        // Hide image view
        _photoImageView.hidden = YES;
        
        _progressView.alpha = 1.0f;
    }
    [self setNeedsLayout];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _videoPlayerLayer.player && [keyPath isEqualToString:kPlayerKeyPath]) {
        if (_videoPlayerLayer.player.status == AVPlayerStatusReadyToPlay) {
            __weak typeof(self) wself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                __strong typeof (wself) sself = wself;
                if (sself) {
                    [sself->_progressView removeFromSuperview];
                }
            });
        } else if (_videoPlayerLayer.player.status == AVPlayerStatusFailed) {
#ifdef DEBUG
            NSLog(@" Loading video with error: %@", _videoPlayerLayer.player.error);
#endif
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setProgress:(CGFloat)progress forPhoto:(RLPhoto*)photo {
    RLPhoto *p = (RLPhoto *)self.photo;
    if ([photo.photoURL.absoluteString isEqualToString:p.photoURL.absoluteString]) {
        if (_progressView.progress < progress) {
            [_progressView setProgress:progress animated:YES];
        }
    }
}


- (void)configPhotoTagsViewWithWidths:(NSArray *)widths {
    if (widths.count > _photoTagViews.count) {
        return;
    }
    CGSize size = _photoImageView.frame.size;
    const CGFloat tagViewHeight = 30;
    const CGFloat zoomingViewHeight = self.bounds.size.height;
    [widths enumerateObjectsUsingBlock:^(NSNumber *width, NSUInteger idx, BOOL * _Nonnull stop) {
        if (width.floatValue <= 0) {
            return;
        }
        RLPhotoTag *tagModel = self.photo.photoTags[idx];
        RLPhotoTagView *view = _photoTagViews[idx];
        view.hidden = NO;
        view.photoTag = tagModel;
        CGFloat X = MAX(size.width * tagModel.offsetX, 15) ;
        CGFloat Y = size.height * tagModel.offsetY + (zoomingViewHeight - size.height) * 0.5;
        CGFloat W = width.floatValue + 21;
        view.frame = CGRectMake(MIN(X, size.width - W - 2),
                                MIN(Y, (zoomingViewHeight + size.height) * 0.5 - tagViewHeight - 2),
                                W,
                                tagViewHeight);
    }];
    
}

// Image failed so just show black!
- (void)displayImageFailure {
    [_progressView removeFromSuperview];
}

#pragma mark - Setup

- (void)setMaxMinZoomScalesForCurrentBounds {
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    // Bail
    if (_photoImageView.image == nil) return;
    // Sizes
    CGSize boundsSize = self.bounds.size;
    boundsSize.width -= 0.1;
    boundsSize.height -= 0.1;
	
    CGSize imageSize = _photoImageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // If image is smaller than the screen then ensure we show it at
    // min scale of 1
    if (xScale > 1 && yScale > 1) {
        minScale = 1.0;
    }
    // Calculate Max
    CGFloat maxScale = 6.0; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxScale = maxScale / [[UIScreen mainScreen] scale];
        if (maxScale < minScale) {
            maxScale = minScale * 2;
        }
    }
	
    // Calculate Max Scale Of Double Tap
	
    CGFloat maxDoubleTapZoomScale = 6.0 * minScale; // Allow double scale
    
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    
    // maximum zoom scale to 0.5.
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxDoubleTapZoomScale = maxDoubleTapZoomScale / [[UIScreen mainScreen] scale];
        if (maxDoubleTapZoomScale < minScale) {
            maxDoubleTapZoomScale = minScale * 2;
        }
    }
    // Make sure maxDoubleTapZoomScale isn't larger than maxScale
    maxDoubleTapZoomScale = MIN(maxDoubleTapZoomScale, maxScale);
    
    // Set
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    self.zoomScale = minScale;
    self.maximumDoubleTapZoomScale = maxDoubleTapZoomScale;
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews {
    // Update tap view frame
    _tapView.frame = self.bounds;
    
    _videoPlayerView.frame = self.bounds;
    _videoPlayerLayer.frame = _videoPlayerView.bounds;

    // Super
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
	// Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter)) {
        _photoImageView.frame = frameToCenter;
    }
}

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _photoImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    [_photoBrowser handleSingleTap];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        // Zoom in
        CGSize targetSize = CGSizeMake(self.frame.size.width / self.maximumDoubleTapZoomScale, self.frame.size.height / self.maximumDoubleTapZoomScale);
        CGPoint targetPoint = CGPointMake(touchPoint.x - targetSize.width / 2, touchPoint.y - targetSize.height / 2);
        [self zoomToRect:CGRectMake(targetPoint.x, targetPoint.y, targetSize.width, targetSize.height) animated:YES];
    }
}

- (void)tagViewDidClick:(UITapGestureRecognizer *)tap {
    if ([self.photoBrowser.delegate respondsToSelector:@selector(imageBrowser:didClickPhotoTag:)]) {
        RLPhotoTagView *tagView = (RLPhotoTagView *)tap.view;
        [self.photoBrowser.delegate imageBrowser:self.photoBrowser
                                didClickPhotoTag:tagView.photoTag];
    }
}

#pragma mark - RLTapDetectingViewDelegate

- (void)detectingView:(UIImageView *)imageView singleTapDetected:(UITapGestureRecognizer *)tap {
    [self handleSingleTap:[tap locationInView:imageView]];
}
- (void)detectingView:(UIImageView *)imageView doubleTapDetected:(UITapGestureRecognizer *)tap {
    [self handleDoubleTap:[tap locationInView:imageView]];
}

@end
