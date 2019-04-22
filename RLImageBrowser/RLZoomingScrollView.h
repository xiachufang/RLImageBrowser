//
//  RLZoomingScrollView.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLPhotoProtocol.h"
#import "RLDetectingView.h"
#import "RLCircularProgressView.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>


NS_ASSUME_NONNULL_BEGIN

@class RLImageBrowser, RLPhoto, RLCaptionView;

@interface RLZoomingScrollView : UIScrollView <UIScrollViewDelegate, RLDetectingViewDelegate, UIDragInteractionDelegate> {
    RLCircularProgressView *_progressView;
}

@property (nonatomic, weak) RLImageBrowser *photoBrowser;
@property (nonatomic, strong) RLDetectingImageView *photoImageView;
@property (nonatomic, strong) RLDetectingView *tapView;
@property (nonatomic, strong, nullable) RLCaptionView *captionView;
@property (nonatomic, strong, nullable) RLPhoto <RLPhoto> *photo;

@property (nonatomic, strong) RLDetectingView *videoPlayerView;
@property (nonatomic, strong) AVPlayerLayer *videoPlayerLayer;

@property (nonatomic) CGFloat maximumDoubleTapZoomScale;

- (instancetype)initWithPhotoBrowser:(RLImageBrowser *)browser;
- (void)displayImage;
- (void)displayImageFailure;
- (void)setProgress:(CGFloat)progress forPhoto:(RLPhoto*)photo;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end

NS_ASSUME_NONNULL_END
