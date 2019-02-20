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

// Properties
@property (nonatomic, strong) id <RLPhotoBrowserDelegate> delegate;

// Toolbar customization
@property (nonatomic, assign) BOOL displayToolbar;
@property (nonatomic, assign) BOOL displayCounterLabel;
@property (nonatomic, assign) BOOL displayArrowButton;
@property (nonatomic, assign) BOOL displayActionButton;

@property (nonatomic, weak) UIImage *leftArrowImage, *leftArrowSelectedImage;
@property (nonatomic, weak) UIImage *rightArrowImage, *rightArrowSelectedImage;
@property (nonatomic, weak) UIImage *actionButtonImage, *actionButtonSelectedImage;

// View customization
@property (nonatomic, assign) BOOL displayCloseButton;
@property (nonatomic, assign) BOOL useWhiteBackgroundColor;
@property (nonatomic, weak) UIColor *trackTintColor, *progressTintColor;

@property (nonatomic, weak) UIImage *scaleImage;

@property (nonatomic, assign) BOOL arrowButtonsChangePhotosAnimated;

@property (nonatomic, assign) BOOL forceHideStatusBar;
@property (nonatomic, assign) BOOL disableVerticalSwipe;
@property (nonatomic, assign) BOOL dismissOnTouch;

// Default value: true
// Set to false to tell the photo viewer not to hide the interface when scrolling
@property (nonatomic, assign) BOOL autoHideInterface;

// Defines zooming of the background (default 1.0)
@property (nonatomic, assign) float backgroundScaleFactor;

// Animation time (default .28)
@property (nonatomic, assign) float animationDuration;

// Init
- (instancetype)initWithPhotos:(NSArray *)photosArray;

// Init (animated from view)
- (instancetype)initWithPhotos:(NSArray *)photosArray animatedFromView:(UIView*)view;

// Init with NSURL objects
- (instancetype)initWithPhotoURLs:(NSArray *)photoURLsArray;

// Init with NSURL objects (animated from view)
- (instancetype)initWithPhotoURLs:(NSArray *)photoURLsArray animatedFromView:(UIView*)view;

// Reloads the photo browser and refetches data
- (void)reloadData;

// Set page that photo browser starts on
- (void)setInitialPageIndex:(NSUInteger)index;

// Get RLPhoto at index
- (id<RLPhoto>)photoAtIndex:(NSUInteger)index;

@end
