//
//  RLHelper.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLHelper : NSObject

+ (CGRect)adjustRect:(CGRect)rect
   forSafeAreaInsets:(UIEdgeInsets)insets
           forBounds:(CGRect)bounds
  adjustForStatusBar:(BOOL)adjust
     statusBarHeight:(int)statusBarHeight;

@end

NS_ASSUME_NONNULL_END
