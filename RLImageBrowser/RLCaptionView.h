//
//  RLCaptionView.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "RLPhotoProtocol.h"

/**
 * To create your own custom caption view, subclass this view
 * and override the following `setupCaption` and `sizeThatFits:` methods
 * (as well as any other UIView methods that you see fit):
 */

@interface RLCaptionView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong, readonly) id<RLPhoto> photo;

/**
 * Creates an instance of a CaptionView.
 *
 * @param  photo the photo
 * @return new instance of CaptionView class.
 */
- (instancetype)initWithPhoto:(id<RLPhoto>)photo;

/**
 * @Note: Override -setupCaption so setup your subviews and customise
 * the appearance of your custom caption
 *
 * You can access the photo's data by accessing the _photo ivar
 * If you need more data per photo then simply subclass RLPhoto and return your
 * subclass to the photo browsers -photoBrowser:photoAtIndex: delegate method
 */
- (void)setupCaption;

/**
 * @Note: Override -sizeThatFits: and return a CGSize specifying the height of your
 *
 * custom caption view. With width property is ignored and the caption is displayed
 * the full width of the screen
 */
- (CGSize)sizeThatFits:(CGSize)size;

@end
