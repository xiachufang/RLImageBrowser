//
//  RLTransitionManager.m
//  DACircularProgress
//
//  Created by kinarobin on 2019/2/22.
//

#import "RLTransitionManager.h"
#import "RLImageBrowser.h"

@interface RLTransitionManager()

@property (nonatomic, assign) BOOL isTransitioning;
@property (nonatomic, strong) UIImageView *animateImageView;
@property (nonatomic, weak) RLImageBrowser *photoBrowser;

@end

@implementation RLTransitionManager

#pragma mark - life cycle

- (instancetype)initWithPhotoBrowser:(RLImageBrowser *)photoBrowser {
    if (self = [super init]) {
        _photoBrowser = photoBrowser;
        _isTransitioning = NO;
    }
    return self;
}

#pragma mark - getter

- (UIImageView *)animateImageView {
    if (!_animateImageView) {
        _animateImageView = [UIImageView new];
        if (@available(iOS 11.0, *)) {
            _animateImageView.accessibilityIgnoresInvertColors = YES;
        }
        _animateImageView.clipsToBounds = YES;
    }
    return _animateImageView;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return self.photoBrowser ? self.photoBrowser.animationDuration : 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    _photoBrowser.pagingScrollView.hidden = YES;
    
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromController.view;
    UIView *toView = toController.view;
    
    /** present */
    if (toController.isBeingPresented) {
        self.isTransitioning = YES;
        toView.frame = [transitionContext finalFrameForViewController:toController];
        [containerView addSubview:toView];
        [toView setNeedsLayout];
        [toView layoutIfNeeded];
        if ([self configAnimateImageViewInContainer:containerView]) {
            [containerView addSubview:self.animateImageView];
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                self.animateImageView.frame = [self animationFrameForImage:self.animateImageView.image inContainer:containerView scrollView:nil];
            } completion:^(BOOL finished) {
                [self.animateImageView removeFromSuperview];
                [self completeTransition:transitionContext];
            }];
        } else {
            [self completeTransition:transitionContext];
        }
        return;
    }
    
    /** dismiss */
    if (fromController.isBeingDismissed) {
        self.isTransitioning = YES;
        
        UIView <RLTransitionProtocol> *transitionView = [self configAnimateImageViewInContainer:containerView];
        RLZoomingScrollView *scrollView = [self.photoBrowser currentPageZoomingScrollView];
        
        UIImageView *transitionImageView = [transitionView transitionAnimatedImageView];
        UIImage *animatedImage = transitionView ? transitionImageView.image : scrollView.photoImageView.image;
        if (!animatedImage) {
            transitionView.hidden = NO;
            [self completeTransition:transitionContext];
            return;
        }
        CGRect imageViewFrame = [self animationFrameForImage:animatedImage inContainer:containerView scrollView:scrollView];
        
        CGFloat fadeAlpha = MAX(0, MIN(1, 1 - fabs(scrollView.frame.origin.y) / MAX(scrollView.frame.size.height, 1)));
        UIView *fadeView = [[UIView alloc] initWithFrame:containerView.bounds];
        fadeView.backgroundColor =  [UIColor blackColor];
        fadeView.alpha = fadeAlpha;
        [containerView addSubview:fadeView];
        
        self.animateImageView.frame = imageViewFrame;
        self.animateImageView.image = animatedImage;
        self.animateImageView.layer.cornerRadius = transitionImageView ? transitionImageView.layer.cornerRadius : scrollView.photoImageView.layer.cornerRadius;
        [containerView addSubview:self.animateImageView];
        
        fromView.hidden = YES;
        void (^completion)(BOOL finished) = ^(BOOL finished) {
            transitionView.hidden = transitionContext.transitionWasCancelled;
            fromView.hidden = NO;
            fromView.backgroundColor = UIColor.blackColor;
            [fadeView removeFromSuperview];
            [self.animateImageView removeFromSuperview];
            [self completeTransition:transitionContext];
        };
        
        CGRect senderViewOriginalFrame = [transitionView convertRect:transitionView.bounds toView:containerView];
        if (!transitionView.window || !CGRectIntersectsRect(containerView.bounds, senderViewOriginalFrame)) {
            senderViewOriginalFrame = CGRectMake(CGRectGetMidX(containerView.bounds), CGRectGetMidY(containerView.bounds), 1, 1);
        }
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fadeView.alpha = 0;
            fromView.backgroundColor = [UIColor clearColor];
            self.animateImageView.layer.frame = senderViewOriginalFrame;
        } completion:completion];
    }
}

- (void)completeTransition:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    self.isTransitioning = NO;
    _photoBrowser.pagingScrollView.hidden = NO;
}

- (UIView <RLTransitionProtocol> *)configAnimateImageViewInContainer:(UIView *)container {
    if (![self.photoBrowser.delegate respondsToSelector:@selector(imageBrowser:transitionViewForPhotoAtIndex:)]) {
        return nil;
    }
    UIView <RLTransitionProtocol> *transitionView = [self.photoBrowser.delegate imageBrowser:self.photoBrowser transitionViewForPhotoAtIndex:self.photoBrowser.currentPageIndex];
    if (!transitionView) {
        return nil;
    }
    NSAssert([transitionView conformsToProtocol:@protocol(RLTransitionProtocol)], @"This view must conforms `RLTransitionProtocol`");
    UIImageView *animatedImageView = [transitionView transitionAnimatedImageView];
    self.animateImageView.image = animatedImageView.image;
    self.animateImageView.contentMode = animatedImageView.contentMode;

    self.animateImageView.frame = [transitionView convertRect:transitionView.bounds toView:container];
    return transitionView;
}

- (CGRect)animationFrameForImage:(UIImage *)image inContainer:(UIView *)container scrollView:(RLZoomingScrollView *)scrollView {
    if (!image || image.size.width <= 0 || image.size.height <= 0) {
        return CGRectZero;
    }
    if (scrollView.photoImageView.image && !scrollView.photoImageView.hidden) {
        return [scrollView.photoImageView convertRect:scrollView.photoImageView.bounds toView:container];
    }
    CGSize imageSize = image.size;
    CGRect bounds = self.photoBrowser.view.bounds;
    CGFloat maxWidth = CGRectGetWidth(bounds);
    CGFloat maxHeight = CGRectGetHeight(bounds);
    
    CGRect animationFrame = CGRectZero;
    CGFloat aspect = imageSize.width / imageSize.height;
    if (maxWidth / aspect <= maxHeight) {
        animationFrame.size = CGSizeMake(maxWidth, maxWidth / aspect);
    } else {
        animationFrame.size = CGSizeMake(maxHeight * aspect, maxHeight);
    }
    animationFrame.origin.x = roundf((maxWidth - animationFrame.size.width) / 2.0f);
    animationFrame.origin.y = roundf((maxHeight - animationFrame.size.height) / 2.0f);
    
    return [self.photoBrowser.view convertRect:animationFrame toView:container];
}


@end
