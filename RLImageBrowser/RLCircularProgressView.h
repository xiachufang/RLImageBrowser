
//
//  RLCircularProgressView.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/4/23.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RLCircularProgressView : UIView

@property (nonatomic, strong) UIColor *trackTintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *progressTintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *innerTintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) NSInteger roundedCorners UI_APPEARANCE_SELECTOR; // Can not use BOOL with UI_APPEARANCE_SELECTOR :-(
@property (nonatomic) CGFloat thicknessRatio UI_APPEARANCE_SELECTOR;
@property (nonatomic) NSInteger clockwiseProgress UI_APPEARANCE_SELECTOR; // Can not use BOOL with UI_APPEARANCE_SELECTOR :-(
@property (nonatomic) CGFloat progress;

@property (nonatomic) CGFloat indeterminateDuration UI_APPEARANCE_SELECTOR;
@property (nonatomic) NSInteger indeterminate UI_APPEARANCE_SELECTOR; // Can not use BOOL with UI_APPEARANCE_SELECTOR :-(

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated initialDelay:(CFTimeInterval)initialDelay;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated initialDelay:(CFTimeInterval)initialDelay withDuration:(CFTimeInterval)duration;

@end

/**
 @class DALabeledCircularProgressView
 
 @brief Subclass of DACircularProgressView that adds a UILabel.
 */
@interface RLLabeledCircularProgressView : RLCircularProgressView

/**
 UILabel placed right on the DACircularProgressView.
 */
@property (strong, nonatomic) UILabel *progressLabel;

@end
