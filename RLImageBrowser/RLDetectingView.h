//
//  RLTapDetectingView.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import "RLDetectingViewDelegate.h"
#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLDetectingView : UIView
@property (nonatomic, weak) id <RLDetectingViewDelegate> detectingDelegate;
@end

@interface RLDetectingImageView : SDAnimatedImageView
@property (nonatomic, weak) id <RLDetectingViewDelegate> detectingDelegate;
@end

NS_ASSUME_NONNULL_END
