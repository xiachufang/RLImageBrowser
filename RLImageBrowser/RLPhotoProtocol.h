//
//  RLPhotoProtocol.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * If you wish to use your own data models for photo then they must conform
 * to this protocol. See instructions for details on each method.
 * Otherwise you can use the RLPhoto object or subclass it yourself to
 * store more information per photo.
 */

/**
 * Name of notification used when a photo has completed loading process
 * Used to notify browser display the image.
 */
#define RLPhoto_LOADING_DID_END_NOTIFICATION @"RLPhoto_LOADING_DID_END_NOTIFICATION"

@protocol RLPhoto <NSObject>

@required

/**
 * Nil if the image is not immediately available (loaded into memory, preferably
 * already decompressed) and needs to be loaded from a source (cache, file, web, etc)
 *
 * @Note You should *NOT* use this method to initiate fetching of
 * images from any external of source. That should be handled in
 * `loadUnderlyingImageAndNotify:` which may be called by the photo browser
 * if this methods returns nil.
 * @return underlying UIImage to be displayed
 */
- (UIImage *)underlyingImage;

/**
 * Called when the browser has determined the underlying images is not
 * already loaded into memory but needs it.
 */
- (void)loadUnderlyingImageAndNotify;

/**
 * This is called when the photo browser has determined the photo data
 * is no longer needed or there are low memory conditions
 *
 * You should release any underlying (possibly large and decompressed) image data
 * as long as the image can be re-loaded (from cache, file, or URL)
 */
- (void)unloadUnderlyingImage;

@optional

/**
 * Show a caption string to be displayed over the image
 *
 * @return nil to display no caption
 */
- (NSString *)caption;

/**
 * Show  placeholder to be displayed while loading underlyingImage
 *
 * @return nil if there is no placeholder
 */
- (UIImage *)placeholderImage;

@end
