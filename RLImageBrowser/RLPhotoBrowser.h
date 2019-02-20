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
#import "RLCaptionView.h"
#import "RLDetectingView.h"

// Delgate
@class RLPhotoBrowser;
@protocol RLPhotoBrowserDelegate <NSObject>
@optional
- (void)willAppearPhotoBrowser:(RLPhotoBrowser *)photoBrowser;
- (void)willDisappearPhotoBrowser:(RLPhotoBrowser *)photoBrowser;
- (void)photoBrowser:(RLPhotoBrowser *)photoBrowser didShowPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(RLPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index;
- (void)photoBrowser:(RLPhotoBrowser *)photoBrowser willDismissAtPageIndex:(NSUInteger)index;
- (RLCaptionView *)photoBrowser:(RLPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(RLPhotoBrowser *)photoBrowser imageFailed:(NSUInteger)index imageView:(RLDetectingImageView *)imageView;
@end

@interface RLPhotoBrowser : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) id <RLPhotoBrowserDelegate> delegate;

@property (nonatomic, assign) BOOL displayToolbar;
@property (nonatomic, assign) BOOL displayCounterLabel;
@property (nonatomic, assign) BOOL displayActionButton;

@property (nonatomic, weak) UIImage *actionButtonImage, *actionButtonSelectedImage;

@property (nonatomic, assign) BOOL displayCloseButton;
@property (nonatomic, assign) BOOL useWhiteBackgroundColor;
@property (nonatomic, weak) UIColor *trackTintColor, *progressTintColor;

@property (nonatomic, weak) UIImage *scaleImage;

@property (nonatomic, assign) BOOL arrowButtonsChangePhotosAnimated;

@property (nonatomic, assign) BOOL forceHideStatusBar;
@property (nonatomic, assign) BOOL disableVerticalSwipe;
@property (nonatomic, assign) BOOL dismissOnTouch;

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
 * @param  photosArray the photo array
 * @param  view animatedView for present or dismiss
 * @return new instance of browser class.
 */
- (instancetype)initWithPhotos:(NSArray<RLPhoto *> *)photosArray animatedFromView:(UIView *)view;

/**
 * Creates an instance of a browser.
 *
 * @param  photoURLsArray the photo url array
 * @return new instance of browser class.
 */
- (instancetype)initWithPhotoURLs:(NSArray<NSURL *> *)photoURLsArray;

/**
 * Creates an instance of a browser.
 *
 * @param  photoURLsArray the photo url array
 * @param  view animatedView for present or dismiss
 * @return new instance of browser class.
 */
- (instancetype)initWithPhotoURLs:(NSArray *)photoURLsArray animatedFromView:(UIView *)view;

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

@end
