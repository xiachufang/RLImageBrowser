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

#import <DACircularProgress/DACircularProgressView.h>

NS_ASSUME_NONNULL_BEGIN

@class RLPhotoBrowser, RLPhoto, RLCaptionView;

@interface RLZoomingScrollView : UIScrollView <UIScrollViewDelegate, RLDetectingViewDelegate, UIDragInteractionDelegate> {
    DACircularProgressView *_progressView;
}

@property (nonatomic, weak) RLPhotoBrowser *photoBrowser;
@property (nonatomic, strong) RLDetectingImageView *photoImageView;
@property (nonatomic, strong) RLDetectingView *tapView;
@property (nonatomic, strong) RLCaptionView *captionView;
@property (nonatomic, strong) id<RLPhoto> photo;
@property (nonatomic) CGFloat maximumDoubleTapZoomScale;

- (instancetype)initWithPhotoBrowser:(RLPhotoBrowser *)browser;
- (void)displayImage;
- (void)displayImageFailure;
- (void)setProgress:(CGFloat)progress forPhoto:(RLPhoto*)photo;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end

NS_ASSUME_NONNULL_END
