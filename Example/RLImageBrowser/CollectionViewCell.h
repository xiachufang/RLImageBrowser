//
//  CollectionViewCell.h
//  RLImageBrowser_Example
//
//  Created by kinarobin on 2019/2/21.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RLTransitionProtocol.h"
#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface CollectionViewCell : UICollectionViewCell <RLTransitionProtocol>
@property (nonatomic, weak) IBOutlet SDAnimatedImageView *imageView;
@end

NS_ASSUME_NONNULL_END
