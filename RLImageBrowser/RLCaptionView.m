//
//  RLCaptionView.m
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import "RLCaptionView.h"
#import "RLPhoto.h"
#import <QuartzCore/QuartzCore.h>

const CGFloat kCaptionLabelPadding = 10;

@interface RLCaptionView ()

@property (nonatomic, strong, readwrite) id<RLPhoto> photo;

@end

@implementation RLCaptionView

- (instancetype)initWithPhoto:(id<RLPhoto>)photo {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenBound.size.height;
    }
    self = [super initWithFrame:CGRectMake(0, 0, screenWidth, 44)]; // Random initial frame
    if (self) {
        _photo = photo;
        self.opaque = NO;
        [self setBackground];
        [self setupCaption];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (_titleLabel.text.length == 0) return CGSizeZero;
    
    CGFloat maxHeight = CGFLOAT_MAX;
    if (_titleLabel.numberOfLines > 0) {
        maxHeight = _titleLabel.font.leading * _titleLabel.numberOfLines;
    }
    CGFloat width = size.width - kCaptionLabelPadding * 2;
    CGFloat height = [_titleLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    return CGSizeMake(size.width, height + kCaptionLabelPadding * 2);
}

- (void)setupCaption {
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kCaptionLabelPadding, 0, self.bounds.size.width - kCaptionLabelPadding * 2, self.bounds.size.height)];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _titleLabel.opaque = NO;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _titleLabel.numberOfLines = 3;
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    _titleLabel.shadowOffset = CGSizeMake(0, 1);
    
    if ([_photo respondsToSelector:@selector(caption)]) {
        _titleLabel.text = [_photo caption] ?: @" ";
    }
    [self addSubview:_titleLabel];
}

- (void)setBackground {
    // Static width, autoresizingMask is not working
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, -100, 10000, 130 + 100)];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = fadeView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0 alpha:0.8] CGColor], nil];
    [fadeView.layer insertSublayer:gradient atIndex:0];
    fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:fadeView];
}

@end
