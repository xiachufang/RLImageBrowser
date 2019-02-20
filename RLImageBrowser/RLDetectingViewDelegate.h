//
//  RLTapDetectingViewDelegate.h
//  DACircularProgress
//
//  Created by kinarobin on 2019/2/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RLDetectingViewDelegate <NSObject>

- (void)detectingView:(UIView *)view singleTapDetected:(UITouch *)touch;
- (void)detectingView:(UIView *)view doubleTapDetected:(UITouch *)touch;

@end

NS_ASSUME_NONNULL_END
