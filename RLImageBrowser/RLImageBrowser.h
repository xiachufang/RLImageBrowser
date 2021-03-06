//
//  RLImageBrowser.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RLPhoto.h"
#import "RLPhotoProtocol.h"
#import "RLTransitionProtocol.h"
#import "RLCaptionView.h"
#import "RLDetectingView.h"
#import "RLZoomingScrollView.h"

extern CGFloat const kLessThaniOS11StatusBarHeight;

@class RLImageBrowser;

@protocol RLImageBrowserDelegate <NSObject>
@optional
- (void)willAppearPhotoBrowser:(RLImageBrowser *)photoBrowser;
- (void)willDisappearPhotoBrowser:(RLImageBrowser *)photoBrowser;
- (void)imageBrowser:(RLImageBrowser *)photoBrowser didShowPhotoAtIndex:(NSUInteger)index;
- (void)imageBrowser:(RLImageBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index;
- (void)imageBrowser:(RLImageBrowser *)photoBrowser willDismissAtPageIndex:(NSUInteger)index;
- (void)imageBrowser:(RLImageBrowser *)photoBrowser didClickPhotoTag:(RLPhotoTag *)photoTag;
- (RLCaptionView *)imageBrowser:(RLImageBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
- (UIView <RLTransitionProtocol> *)imageBrowser:(RLImageBrowser *)photoBrowser transitionViewForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(RLImageBrowser *)imageBrowser imageFailed:(NSUInteger)index imageView:(RLDetectingImageView *)imageView;
@end

@interface RLImageBrowser : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) id <RLImageBrowserDelegate> delegate;

@property (nonatomic, assign) BOOL displayToolbar;
@property (nonatomic, assign) BOOL displayCounterLabel;
@property (nonatomic, assign) BOOL displayCloseButton;
@property (nonatomic, assign) BOOL displayTagButton;
@property (nonatomic, weak) UIColor *trackTintColor, *progressTintColor;
@property (nonatomic, assign) BOOL arrowButtonsChangePhotosAnimated;

@property (nonatomic, assign) BOOL forceHideStatusBar;
@property (nonatomic, assign) BOOL disableVerticalSwipe;
@property (nonatomic, assign) BOOL dismissOnTouch;

@property (nonatomic, strong, readonly) UIScrollView *pagingScrollView;

/**
 * Current page index.
 */
@property (nonatomic, assign, readonly) NSUInteger currentPageIndex;

/**
 * Set to YES to tell the photo browser use animation when present or dismiss.
 * Default to NO.
 * @Note If you set YES, you have to implement `photoBrowser:transitionViewForPhotoAtIndex:`.
 */
@property (nonatomic, assign) BOOL useAnimationForPresentOrDismiss;

/**
 * Set to false to tell the photo viewer not to hide the interface when scrolling
 * Default to NO.
 */
@property (nonatomic, assign) BOOL autoHideInterface;

/**
 * Animation duration
 * Default to 0.25.
 */
@property (nonatomic, assign) CGFloat animationDuration;

/**
 * Creates an instance of a browser.
 *
 * @param  photosArray the photo array
 * @return new instance of browser class.
 */
- (instancetype)initWithPhotos:(NSArray<RLPhoto *> *)photosArray;

/**
 * Creates an instance of a browser.
 *
 * @param  photoURLsArray the photo url array
 * @return new instance of browser class.
 */
- (instancetype)initWithPhotoURLs:(NSArray<NSURL *> *)photoURLsArray;

/**
 * Reloads the photo browser and refetches data
 */
- (void)reloadData;

/**
 * Set page that photo browser starts on
 * @param index start index
 */
- (void)setInitialPageIndex:(NSUInteger)index;

/**
 * Get RLPhoto at index
 *
 * @param index photo index
 * @return instance conform `RLPhoto`.
 */
- (id<RLPhoto>)photoAtIndex:(NSUInteger)index;

/**
 * Get ZoomingScrollView at browser
 *
 * @return instance if `RLZoomingScrollView`.
 */
- (RLZoomingScrollView *)currentPageZoomingScrollView;


@end
