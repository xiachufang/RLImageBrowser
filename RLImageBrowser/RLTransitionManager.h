//
//  RLTransitionManager.h
//  DACircularProgress
//
//  Created by kinarobin on 2019/2/22.
//

#import <Foundation/Foundation.h>

@class RLImageBrowser;

NS_ASSUME_NONNULL_BEGIN

@interface RLTransitionManager : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, readonly) BOOL isTransitioning;

- (instancetype)initWithPhotoBrowser:(RLImageBrowser *)photoBrowser NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
