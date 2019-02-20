//
//  RLPhoto.m
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//


#import "RLPhoto.h"
#import "RLPhotoBrowser.h"
#import "SDImageCodersManager.h"
#import "SDImageWebPCoder.h"
#import "UIImage+MultiFormat.h"

// Private
@interface RLPhoto () {
    // Image Sources
    NSString *_photoPath;

    // Image
    UIImage *_underlyingImage;

    // Other
    NSString *_caption;
    BOOL _loadingInProgress;
}

// Properties
@property (nonatomic, strong) UIImage *underlyingImage;

// Methods
- (void)imageLoadingComplete;

@end

@implementation RLPhoto

#pragma mark Class Methods

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
    });
}

+ (RLPhoto *)photoWithImage:(UIImage *)image {
	return [[RLPhoto alloc] initWithImage:image];
}

+ (RLPhoto *)photoWithFilePath:(NSString *)path {
	return [[RLPhoto alloc] initWithFilePath:path];
}

+ (RLPhoto *)photoWithURL:(NSURL *)url {
	return [[RLPhoto alloc] initWithURL:url];
}

+ (NSArray *)photosWithImages:(NSArray *)imagesArray {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:imagesArray.count];
    
    for (UIImage *image in imagesArray) {
        if ([image isKindOfClass:[UIImage class]]) {
            RLPhoto *photo = [RLPhoto photoWithImage:image];
            [photos addObject:photo];
        }
    }
    return photos;
}

+ (NSArray *)photosWithFilePaths:(NSArray *)pathsArray {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:pathsArray.count];
    
    for (NSString *path in pathsArray) {
        if ([path isKindOfClass:[NSString class]]) {
            RLPhoto *photo = [RLPhoto photoWithFilePath:path];
            [photos addObject:photo];
        }
    }
    return photos;
}

+ (NSArray *)photosWithURLs:(NSArray *)urlsArray {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:urlsArray.count];
    
    for (id url in urlsArray) {
        if ([url isKindOfClass:[NSURL class]]) {
            RLPhoto *photo = [RLPhoto photoWithURL:url];
            [photos addObject:photo];
        } else if ([url isKindOfClass:[NSString class]]) {
            RLPhoto *photo = [RLPhoto photoWithURL:[NSURL URLWithString:url]];
            [photos addObject:photo];
        }
    }
    return photos;
}

#pragma mark NSObject

- (instancetype)initWithImage:(UIImage *)image {
	if ((self = [super init])) {
		self.underlyingImage = image;
	}
	return self;
}

- (instancetype)initWithFilePath:(NSString *)path {
	if ((self = [super init])) {
		_photoPath = [path copy];
	}
	return self;
}

- (instancetype)initWithURL:(NSURL *)url {
	if ((self = [super init])) {
		_photoURL = [url copy];
	}
	return self;
}

#pragma mark RLPhoto Protocol Methods

- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    _loadingInProgress = YES;
    if (self.underlyingImage) {
        // Image already loaded
        [self imageLoadingComplete];
    } else {
        if (_photoPath) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self loadImageFromFileAsync];
            });
        } else if (_photoURL) {
            __weak typeof(self) wself = self;
			[[SDWebImageManager sharedManager] loadImageWithURL:_photoURL options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    CGFloat progress = ((CGFloat)receivedSize)/((CGFloat)expectedSize);
                    if (wself.progressUpdateBlock) {
                        wself.progressUpdateBlock(progress);
                    }
                });
			} completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image) {
                        wself.underlyingImage = image;
                    }
                    [wself imageLoadingComplete];
                });
			}];
        } else {
            // Failed - no source
            self.underlyingImage = nil;
            [self imageLoadingComplete];
        }
    }
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    _loadingInProgress = NO;

	if (self.underlyingImage && (_photoPath || _photoURL)) {
		self.underlyingImage = nil;
	}
}

#pragma mark - Async Loading
// Called in background
// Load image in background from local file
- (void)loadImageFromFileAsync {
    @autoreleasepool {
        @try {
            self.underlyingImage = [UIImage imageWithContentsOfFile:_photoPath];
            if (!_underlyingImage) {
                RLLog(@"Error loading photo from path: %@", _photoPath);
            }
        } @finally {
            if (self.underlyingImage) {
                self.underlyingImage = [[SDImageCodersManager sharedManager] decodedImageWithData:self.underlyingImage.sd_imageData options:0] ;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self imageLoadingComplete];
                });
            }
        }
    }
}

// Called on main
- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:RLPhoto_LOADING_DID_END_NOTIFICATION
                                                        object:self];
}

@end
