//
//  RLTapDetectingView.m
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import "RLDetectingView.h"

@implementation RLDetectingView

- (instancetype)init {
	if ((self = [super init])) {
        [self configGestureRecognizer];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self configGestureRecognizer];
	}
	return self;
}

- (void)configGestureRecognizer {
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapOnceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapOnceGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapOnceGesture];
    
    UITapGestureRecognizer *tapTwiceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    tapTwiceGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapTwiceGesture];
    [tapOnceGesture requireGestureRecognizerToFail:tapTwiceGesture];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    if ([_detectingDelegate respondsToSelector:@selector(detectingView:singleTapDetected:)]) {
		[_detectingDelegate detectingView:self singleTapDetected:tap];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    if ([_detectingDelegate respondsToSelector:@selector(detectingView:doubleTapDetected:)]) {
		[_detectingDelegate detectingView:self doubleTapDetected:tap];
    }
}

@end



@implementation RLDetectingImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self configGestureRecognizer];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    if ((self = [super initWithImage:image])) {
        [self configGestureRecognizer];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    if ((self = [super initWithImage:image highlightedImage:highlightedImage])) {
        [self configGestureRecognizer];
    }
    return self;
}

- (void)configGestureRecognizer {
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapOnceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapOnceGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapOnceGesture];
    
    UITapGestureRecognizer *tapTwiceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    tapTwiceGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapTwiceGesture];
    [tapOnceGesture requireGestureRecognizerToFail:tapTwiceGesture];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    if ([_detectingDelegate respondsToSelector:@selector(detectingView:singleTapDetected:)]) {
        [_detectingDelegate detectingView:self singleTapDetected:tap];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    if ([_detectingDelegate respondsToSelector:@selector(detectingView:doubleTapDetected:)]) {
        [_detectingDelegate detectingView:self doubleTapDetected:tap];
    }
}

@end
