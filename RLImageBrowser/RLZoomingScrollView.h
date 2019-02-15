//
//  RLZoomingScrollView.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLPhotoProtocol.h"
#import "RLTapDetectingImageView.h"
#import "RLTapDetectingView.h"

#import <DACircularProgress/DACircularProgressView.h>

@class RLPhotoBrowser, RLPhoto, RLCaptionView;

@interface RLZoomingScrollView : UIScrollView <UIScrollViewDelegate, RLTapDetectingImageViewDelegate, RLTapDetectingViewDelegate, UIDragInteractionDelegate> {
	
	RLPhotoBrowser *__weak _photoBrowser;
    id<RLPhoto> _photo;
	
    // This view references the related caption view for simplified handling in photo browser
    RLCaptionView *_captionView;
    
	RLTapDetectingView *_tapView; // for background taps
    
    DACircularProgressView *_progressView;
}

@property (nonatomic, strong) RLTapDetectingImageView *photoImageView;
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
