//
//  RLTransitionProtocol.h
//  DACircularProgress
//
//  Created by kinarobin on 2019/2/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RLTransitionProtocol <NSObject>

- (UIImage *)transitionImage;
- (UIViewContentMode)transitionViewContentMode;

@end

NS_ASSUME_NONNULL_END
