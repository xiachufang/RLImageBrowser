//
//  RLTransitionManager.m
//  DACircularProgress
//
//  Created by kinarobin on 2019/2/22.
//

#import "RLTransitionManager.h"
#import "RLPhotoBrowser.h"
#import "RLRectHelper.h"

@interface RLTransitionManager()

@property (nonatomic, assign) BOOL isTransitioning;
@property (nonatomic, strong) UIImageView *animateImageView;
@property (nonatomic, weak) RLPhotoBrowser *photoBrowser;

@end

@implementation RLTransitionManager {
     BOOL _isEnter;
}

UIWindow *RLNormalWindow(void) {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow *temp in windows) {
            if (temp.windowLevel == UIWindowLevelNormal) {
                window = temp; break;
            }
        }
    }
    return window;
}

#pragma mark - life cycle

- (instancetype)initWithPhotoBrowser:(RLPhotoBrowser *)photoBrowser {
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
    }
    return _animateImageView;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    _photoBrowser.pagingScrollView.hidden = YES;
    
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromController.view;
    UIView *toView = toController.view;
    
    // present
    if (toController.isBeingPresented) {
        self->_isEnter = YES;
        self.isTransitioning = YES;
        if ([self configAnimateImageView]) {
            [containerView addSubview:toView];
            [containerView addSubview:self.animateImageView];
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                self.animateImageView.frame = [self animationFrameForImage:self.animateImageView.image presenting:YES scrollView:nil];
            } completion:^(BOOL finished) {
                [self.animateImageView removeFromSuperview];
                [self completeTransition:transitionContext isEnter:YES];
            }];
        } else {
            [containerView addSubview:toView];
            [self completeTransition:transitionContext isEnter:YES];
        }
        return;
    }
    
    // dismiss
    if (fromController.isBeingDismissed) {
        self->_isEnter = NO;
        self.isTransitioning = YES;
        
        if ([self configAnimateImageView]) {
            RLZoomingScrollView *scrollView = [self.photoBrowser currentPageZoomingScrollView];
            if ([self.photoBrowser.delegate respondsToSelector:@selector(willDisappearPhotoBrowser:)]) {
                [self.photoBrowser.delegate willDisappearPhotoBrowser:self.photoBrowser];
            }
            
            float fadeAlpha = 1 - fabs(scrollView.frame.origin.y) / scrollView.frame.size.height;
            UIView *fadeView = [[UIView alloc] initWithFrame:RLNormalWindow().bounds];
            fadeView.backgroundColor =  [UIColor blackColor];
            fadeView.alpha = fadeAlpha;
            [RLNormalWindow() addSubview:fadeView];
            
            CGRect imageViewFrame = [self animationFrameForImage:[self animateViewImage] presenting:NO scrollView:scrollView];
            
            self.animateImageView.frame = imageViewFrame;
            [RLNormalWindow() addSubview:self.animateImageView];
            _photoBrowser.view.hidden = YES;
            
            void (^completion)(BOOL finished) = ^(BOOL finished) {
                self->_photoBrowser.senderViewForAnimation.hidden = NO;
                self->_photoBrowser.senderViewForAnimation = nil;
                
                [fadeView removeFromSuperview];
                [self.animateImageView removeFromSuperview];
                [self completeTransition:transitionContext isEnter:NO];
            };
            
            CGRect senderViewOriginalFrame = [_photoBrowser.senderViewForAnimation.superview convertRect:_photoBrowser.senderViewForAnimation.frame toView:nil];
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                fadeView.alpha = 0;
                fromView.backgroundColor = [UIColor clearColor];
                self.animateImageView.layer.frame = senderViewOriginalFrame;
            } completion:completion];
        } else {
            [self completeTransition:transitionContext isEnter:NO];
        }
    }
}

- (void)completeTransition:(nullable id <UIViewControllerContextTransitioning>)transitionContext isEnter:(BOOL)isEnter {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    self.isTransitioning = NO;
    _photoBrowser.pagingScrollView.hidden = NO;
    
}

- (BOOL)configAnimateImageView {
    id sourceObj = _photoBrowser.senderViewForAnimation;
    CALayer *sourceLayer = nil;
    if ([sourceObj isKindOfClass:UIView.class]) {
        UIView *view = (UIView *)sourceObj;
        sourceLayer = view.layer;
        self.animateImageView.contentMode = view.contentMode;
        self.animateImageView.image = _photoBrowser.scaleImage;
        view.hidden = YES;
    } else if ([sourceObj isKindOfClass:CALayer.class]) {
        sourceLayer = sourceObj;
        self.animateImageView.layer.contents = sourceLayer.contents;
    } else {
        return NO;
    }
    
    self.animateImageView.layer.masksToBounds = sourceLayer.masksToBounds;
    self.animateImageView.layer.cornerRadius = sourceLayer.cornerRadius;
    self.animateImageView.layer.backgroundColor = sourceLayer.backgroundColor;
    self.animateImageView.frame = [sourceObj convertRect:sourceLayer.bounds toView:RLNormalWindow()];
    return YES;
}

- (UIImage *)animateViewImage {
    RLZoomingScrollView *scrollView = [self.photoBrowser currentPageZoomingScrollView];
    UIImage *imageFromView = [scrollView.photo underlyingImage];
    if (!imageFromView && [scrollView.photo respondsToSelector:@selector(placeholderImage)]) {
        imageFromView = [scrollView.photo placeholderImage];
    }
    return imageFromView;
}

- (CGRect)animationFrameForImage:(UIImage *)image presenting:(BOOL)presenting scrollView:(RLZoomingScrollView *)scrollView {
    if (!image) {
        return CGRectZero;
    }
    if (scrollView.photoImageView) {
        return [RLNormalWindow() convertRect:scrollView.photoImageView.frame fromView:scrollView];
    }
    CGSize imageSize = image.size;
    CGRect bounds = RLNormalWindow().bounds;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIEdgeInsets insets = UIEdgeInsetsMake(kLessThaniOS11StatusBarHeight, 0, 0, 0);
        if (window != NULL) {
            insets = window.safeAreaInsets;
        }
        bounds = [RLRectHelper adjustRect:bounds forSafeAreaInsets:insets forBounds:bounds adjustForStatusBar:NO statusBarHeight:kLessThaniOS11StatusBarHeight];
    }
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
    
    if (!presenting) {
        animationFrame.origin.y += scrollView.frame.origin.y;
    }
    return animationFrame;
}


@end
