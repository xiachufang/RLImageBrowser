//
//  RLTapDetectingView.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RLDetectingViewDelegate <NSObject>

- (void)detectingView:(UIView *)view singleTapDetected:(UITapGestureRecognizer *)tap;
- (void)detectingView:(UIView *)view doubleTapDetected:(UITapGestureRecognizer *)tap;

@end

@interface RLDetectingView : UIView
@property (nonatomic, weak) id <RLDetectingViewDelegate> detectingDelegate;
@end

@interface RLDetectingImageView : UIImageView
@property (nonatomic, weak) id <RLDetectingViewDelegate> detectingDelegate;
@end

NS_ASSUME_NONNULL_END
