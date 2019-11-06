//
//  RLPhotoTagView.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import "RLPhotoTagView.h"

@interface RLPhotoTagView ()

@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) CALayer *dotLayer;

@end

@implementation RLPhotoTagView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUpSubviews];
    }
    return self;
}

- (void)setUpSubviews {
    self.clipsToBounds = NO;
    _dotLayer = [CALayer layer];
    _dotLayer.frame = CGRectMake(- 15, 11, 8, 8);
    _dotLayer.cornerRadius = 4;
    _dotLayer.shadowOffset = CGSizeMake(0, 1);
    _dotLayer.shadowOpacity = 4;
    _dotLayer.shadowColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
    _dotLayer.backgroundColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:_dotLayer];

    UIImage *tagImage = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"RLImageBrowser.bundle/browser_tag@2x" ofType:@"png"]];
    UIImage *arrowImage = [tagImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 6) resizingMode:UIImageResizingModeStretch];
    _arrowImageView = [[UIImageView alloc] initWithImage:arrowImage];
    [self addSubview:_arrowImageView];
    
    _tagLabel = [UILabel new];
    _tagLabel.numberOfLines = 1;
    _tagLabel.textColor = [UIColor whiteColor];
    _tagLabel.font = [UIFont boldSystemFontOfSize:13];
    [self addSubview:_tagLabel];
}

- (void)setPhotoTag:(RLPhotoTag *)photoTag {
    _photoTag = photoTag;
    _tagLabel.text = photoTag.name;
    if (_photoTag.direction == RLPhotoTagDirectionRight) {
        self.tagLabel.transform = CGAffineTransformMakeScale(-1, 1);
        self.transform = CGAffineTransformMakeScale(-1, 1);
    } else {
        self.tagLabel.transform = CGAffineTransformIdentity;
        self.transform = CGAffineTransformIdentity;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _arrowImageView.frame = self.bounds;
    _tagLabel.frame = CGRectMake(12, 0, self.bounds.size.width - 20, 30);
}

@end


