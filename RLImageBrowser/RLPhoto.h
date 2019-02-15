//
//  RLPhoto.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "RLPhotoProtocol.h"
#import <SDWebImage/SDWebImageManager.h>

// This class models a photo/image and it's caption
// If you want to handle photos, caching, decompression
// yourself then you can simply ensure your custom data model
// conforms to RLPhotoProtocol
@interface RLPhoto : NSObject <RLPhoto>

// Progress download block, used to update the circularView
typedef void (^RLProgressUpdateBlock)(CGFloat progress);

// Properties
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSURL *photoURL;
@property (nonatomic, strong) RLProgressUpdateBlock progressUpdateBlock;
@property (nonatomic, strong) UIImage *placeholderImage;

+ (RLPhoto *)photoWithImage:(UIImage *)image;
+ (RLPhoto *)photoWithFilePath:(NSString *)path;
+ (RLPhoto *)photoWithURL:(NSURL *)url;

+ (NSArray *)photosWithImages:(NSArray *)imagesArray;
+ (NSArray *)photosWithFilePaths:(NSArray *)pathsArray;
+ (NSArray *)photosWithURLs:(NSArray *)urlsArray;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithFilePath:(NSString *)path;
- (instancetype)initWithURL:(NSURL *)url;

@end

