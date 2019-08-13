# RLImageBrowser

[![Version](https://img.shields.io/cocoapods/v/RLImageBrowser.svg?style=flat)](https://cocoapods.org/pods/RLImageBrowser)


### <a id="功能介绍"></a>功能介绍

-  支持png、jgeg、webp、gif图片格式
-  支持小视频播放
-  支持图片手势返回
-  预加载图片

### <a id="示例展示"></a>示例展示

![](ScreenRecording/screen_recording.mp4)

### <a id="使用方法"></a>使用方法

创建RLPhoto:

```ruby
NSArray *photosURL = @[
[NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"], 
[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"], 
[NSURL URLWithString:@"https://apng.onevcat.com/assets/elephant.png"]
];

NSMutableArray *photos = [NSMutableArray new];
for (NSURL *url in photosURL) {
	RLPhoto *photo = [RLPhoto photoWithURL:url];
	[photos addObject:photo];
}
NSArray *photos = [RLPhoto photosWithURLs:photosURL]; 
```

展示RLImageBrowser:
 
```ruby
RLImageBrowser *browser = [[RLImageBrowser alloc] initWithPhotos:photos];
//设置代理 <RLImageBrowserDelegate>
browser.delegate = self;
//展示资源数量
browser.displayCounterLabel = YES;
//轻点关闭图片浏览器
browser.dismissOnTouch = YES;
//设置进度条颜色，默认白色
browser.progressTintColor = [UIColor orangeColor];
//设置动画时间 默认0.25s
browser.animationDuration = 0.3;
//获取当前的Index
NSUInteger index = browser.currentPageIndex;
// present 图片浏览器
[viewController presentViewController:browser animated:YES completion:nil];
```

RLImageBrowserDelegate

```ruby
- (void)willAppearPhotoBrowser:(RLImageBrowser *)photoBrowser;
- (void)willDisappearPhotoBrowser:(RLImageBrowser *)photoBrowser;
- (void)imageBrowser:(RLImageBrowser *)photoBrowser didShowPhotoAtIndex:(NSUInteger)index;
- (void)imageBrowser:(RLImageBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index;
- (void)imageBrowser:(RLImageBrowser *)photoBrowser willDismissAtPageIndex:(NSUInteger)index;
- (RLCaptionView *)imageBrowser:(RLImageBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(RLImageBrowser *)imageBrowser imageFailed:(NSUInteger)index imageView:(RLDetectingImageView *)imageView;

```

如果展示图片需要过渡动画，必须实现协议：

```ruby
- (UIView <RLTransitionProtocol> *)imageBrowser:(RLImageBrowser *)photoBrowser transitionViewForPhotoAtIndex:(NSUInteger)index;
```
返回需要做动画的视图，并且告知browser这个视图哪个image是用来做动画的.

### Requirements
iOS 8   
Xcode 10

###  Installation

RLImageBrowser is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RLImageBrowser'
```

## Author

kinarobin, kinarobin@outlook.com  
如果在使用中有好的需求及建议，或者遇到什么bug，欢迎随时issue、pr

## License

RLImageBrowser is available under the MIT license. See the LICENSE file for more info.
