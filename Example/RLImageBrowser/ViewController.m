//
//  ViewController.m
//  RLImageBrowser
//
//  Created by kinarobin@outlook.com on 01/29/2019.
//  Copyright (c) 2019 kinarobin@outlook.com. All rights reserved.
//

#import "ViewController.h"
#import "RLImageBrowser.h"
#import "RLPhoto.h"
#import "CollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewController () <RLImageBrowserDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *colectionView;
@property (nonatomic, strong) RLImageBrowser *photoBrowser;
@property (nonatomic, copy) NSArray *urlArrays;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupTableViewHeaderView];
    
    [self setupTableViewFooterView];
    
    self.urlArrays = @[[NSURL URLWithString:@"http://i1.chuimg.com/d3a93854fcdc4b65b2c7dc263dd78e04_480w_384h.jpg@2o_50sh_1pr_1l_480w_384h_1c_1e_90q_1wh.webp"],
                       [NSURL URLWithString:@"http://i2.chuimg.com/7faea6beeedc4941a56b532722188b52_480w_384h.jpg?imageView2/1/w/480/h/384/q/90/format/webp"],
                       [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"],
                       [NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"],
                       [NSURL URLWithString:@"https://apng.onevcat.com/assets/elephant.png"],
                       [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"],
                       [NSURL URLWithString:@"http://r0k.us/graphics/kodak/kodak/kodim01.png"],
                       [NSURL URLWithString:@"http://r0k.us/graphics/kodak/kodak/kodim02.png"],
                       [NSURL URLWithString:@"http://r0k.us/graphics/kodak/kodak/kodim03.png"]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return  UIStatusBarStyleDefault;
}

- (void)setupTableViewHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.minimumLineSpacing = 2;
    flowLayout.minimumInteritemSpacing = 2;
    flowLayout.itemSize = CGSizeMake(([UIScreen mainScreen].bounds.size.width - 4) * 0.3333, ([UIScreen mainScreen].bounds.size.width - 4) * 0.3333);
    
    UICollectionView *colectionView = [[UICollectionView alloc] initWithFrame:headerView.bounds collectionViewLayout:flowLayout];
    [colectionView registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"CollectionViewCell"];
    colectionView.delegate = self;
    colectionView.dataSource = self;
    colectionView.backgroundColor = [UIColor whiteColor];
    [headerView addSubview:colectionView];
    self.colectionView = colectionView;
    
    self.tableView.tableHeaderView = headerView;
}

- (void)setupTableViewFooterView {
    UIView *tableViewFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 426 * 0.9 + 40)];
    UIButton *buttonWithImageOnScreen1 = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, 640/3 * 0.9, 426/2 * 0.9)];
    buttonWithImageOnScreen1.tag = 101;
    buttonWithImageOnScreen1.adjustsImageWhenHighlighted = false;
    [buttonWithImageOnScreen1 setImage:[UIImage imageNamed:@"photo1.jpg"] forState:UIControlStateNormal];
    buttonWithImageOnScreen1.imageView.contentMode = UIViewContentModeScaleAspectFill;
    buttonWithImageOnScreen1.backgroundColor = [UIColor blackColor];
    [buttonWithImageOnScreen1 addTarget:self action:@selector(buttonWithImageOnScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [tableViewFooter addSubview:buttonWithImageOnScreen1];
    
    UIButton *buttonWithImageOnScreen2 = [[UIButton alloc] initWithFrame:CGRectMake(15, 426/2 * 0.9 + 20, 640/3 * 0.9, 426/2 * 0.9)];
    buttonWithImageOnScreen2.tag = 102;
    buttonWithImageOnScreen2.adjustsImageWhenHighlighted = false;
    [buttonWithImageOnScreen2 setImage:[UIImage imageNamed:@"photo3.jpg"] forState:UIControlStateNormal];
    buttonWithImageOnScreen2.imageView.contentMode = UIViewContentModeScaleAspectFill;
    buttonWithImageOnScreen2.backgroundColor = [UIColor blackColor];
    [buttonWithImageOnScreen2 addTarget:self action:@selector(buttonWithImageOnScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [tableViewFooter addSubview:buttonWithImageOnScreen2];
    
    self.tableView.tableFooterView = tableViewFooter;
}

- (void)buttonWithImageOnScreenPressed:(UIButton *)button {
    NSMutableArray *array = [NSMutableArray array];
    RLPhoto *photo;
    if (button.tag == 101) {
        NSString *path_photo1l = [[NSBundle mainBundle] pathForResource:@"photo1" ofType:@"jpg"];
        photo = [RLPhoto photoWithFilePath:path_photo1l];
        photo.caption = @"Grotto of the Madonna";
        [array addObject:photo];
    }
    
    NSString *path_photo3l = [[NSBundle mainBundle] pathForResource:@"photo3" ofType:@"jpg"];
    photo = [RLPhoto photoWithFilePath:path_photo3l];
    photo.caption = @"York Floods";
    [array addObject:photo];
    
    NSString *path_photo2l = [[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"];
    photo = [RLPhoto photoWithFilePath:path_photo2l];
    photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
    [array addObject:photo];
    
    NSString *path_photo4l = [[NSBundle mainBundle] pathForResource:@"photo4" ofType:@"jpg"];
    photo = [RLPhoto photoWithFilePath:path_photo4l];
    photo.caption = @"Campervan";
    [array addObject:photo];
    
    if (button.tag == 102) {
        NSString *path_photo1l = [[NSBundle mainBundle] pathForResource:@"photo1" ofType:@"jpg"];
        photo = [RLPhoto photoWithFilePath:path_photo1l];
        photo.caption = @"Grotto of the Madonna";
        [array addObject:photo];
    }
    button.contentMode = UIViewContentModeScaleAspectFill;
    RLImageBrowser *browser = [[RLImageBrowser alloc] initWithPhotos:array];
    browser.delegate = self;
    browser.displayCounterLabel = YES;
    browser.dismissOnTouch = YES;
    
    [self presentViewController:browser animated:YES completion:nil];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 3;
        case 2:
            return 0;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Local photo";
        
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Local photsos";
                break;
            case 1:
                cell.textLabel.text = @"Photos from Flickr";
                break;
            case 2:
                cell.textLabel.text = @"Photos from Flickr - Custom";
                break;
                
            default:
                break;
        }
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:10];
    RLPhoto *photo;
    
    if (indexPath.section == 0) {
        NSString *path_photo2l = [[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"];
        photo = [RLPhoto photoWithFilePath:path_photo2l];
        photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
        [photos addObject:photo];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            NSString *path_photo1l = [[NSBundle mainBundle] pathForResource:@"photo1" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo1l];
            photo.caption = @"Grotto of the Madonna";
            [photos addObject:photo];
            
            
            NSString *path_photo2l = [[NSBundle mainBundle] pathForResource:@"photo2" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo2l];
            photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England";
            [photos addObject:photo];
            
            
            NSString *path_photo3l = [[NSBundle mainBundle] pathForResource:@"photo4" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo3l];
            photo.caption = @"York Floods";
            [photos addObject:photo];
            
            NSString *path_photo4l = [[NSBundle mainBundle] pathForResource:@"photo4" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo4l];
            photo.caption = @"Campervan";
            [photos addObject:photo];
        } else if ( indexPath.row == 1 || indexPath.row == 2 ) {
            NSArray *array = @[[NSURL URLWithString:@"http://i2.chuimg.com/c11b178206344c76932ac28dbb81836f_2448w_1836h.jpg?imageView2/2/w/300/interlace/1/q/90"],
                               [NSURL URLWithString:@"http://i2.chuimg.com/db8ebb9ed7ad4ae88e46d072338c6089_4032w_3024h.jpg?imageView2/2/w/300/interlace/1/q/90"],
                               [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"],
                               [NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"],
                               [NSURL URLWithString:@"https://apng.onevcat.com/assets/elephant.png"]];
            photos = [NSMutableArray arrayWithArray:[RLPhoto photosWithURLs:array]];
        }
    }
    
    RLImageBrowser *browser = [[RLImageBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    browser.displayCounterLabel = YES;
    if (indexPath.section == 1) {
        if (indexPath.row == 2) {
            browser.view.tintColor = [UIColor orangeColor];
            browser.progressTintColor = [UIColor orangeColor];
            browser.trackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        }
    }
    
    [self presentViewController:browser animated:YES completion:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 9;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    [cell.imageView sd_setImageWithURL:self.urlArrays[indexPath.item]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:9];
    for (int i = 0; i < 9; i ++) {
        if (i == 0 ) {
            RLPhoto *photo = [[RLPhoto alloc] initWithVideo:[NSURL URLWithString:@"http://i4.chuimg.com/ef34ba4059a611e995e202420a001538_480w_384h.mp4"]];
            [photos addObject:photo];
        } else if (i == 1) {
            RLPhoto *photo = [[RLPhoto alloc] initWithVideo:[NSURL URLWithString:@"https://video3.chuimg.com/9532a465vodtransgzp1252442451/0e55952b5285890803746811371/v.f230.m3u8?t=5ed93330&exper=0&us=vqhniudmeigr&sign=9b54aecf97012086869fe5d5015aa4f4"]];
            [photos addObject:photo];
        } else  {
            RLPhoto *photo = [RLPhoto photoWithURL:self.urlArrays[i]];
            photo.caption = @"collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath";
           
            RLPhotoTag *tag = [RLPhotoTag new];
            tag.offsetX = 0.4;
            tag.offsetY = 0.0;
            tag.name = [NSString stringWithFormat:@"一人时%d", i];
            
            RLPhotoTag *tag1 = [RLPhotoTag new];
            tag1.offsetX = 1;
            tag1.offsetY = 0.9;
            tag1.name = [NSString stringWithFormat:@"科技后打开结婚看数据都会看哈哈%d李斌会第三款会计核算肯德基和看炬华", i];
            
            RLPhotoTag *tag2 = [RLPhotoTag new];
            tag2.offsetX = 0.99;
            tag2.offsetY = -0.4;
            tag2.name = [NSString stringWithFormat:@"标签%d科技后打开结婚看数据都会看哈哈科技后打开结婚看数据都会看哈哈", i];
            if (i == 8) {
                tag2.direction = RLPhotoTagDirectionRight;
            }
            
            
            
            if (i != 4 && i != 6) {
                photo.photoTags = @[tag, tag1, tag2];
            }
            
            [photos addObject:photo];
        }
    }

    RLImageBrowser *browser = [[RLImageBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    browser.dismissOnTouch = YES;
    browser.displayTagButton = YES;
    browser.useAnimationForPresentOrDismiss = YES;
    [browser setInitialPageIndex:indexPath.item];
    [self presentViewController:browser animated:YES completion:nil];
    self.photoBrowser = browser;
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}


- (void)imageBrowser:(RLImageBrowser *)photoBrowser didShowPhotoAtIndex:(NSUInteger)index {
    RLPhoto *photo = [photoBrowser photoAtIndex:index];
    NSLog(@"Did show photoBrowser with photo index: %zd, photo caption: %@", index, photo.caption);
}

- (void)imageBrowser:(RLImageBrowser *)photoBrowser willDismissAtPageIndex:(NSUInteger)index {
    RLPhoto *photo = [photoBrowser photoAtIndex:index];
    NSLog(@"Will dismiss photoBrowser with photo index: %zd, photo caption: %@", index, photo.caption);
}

- (void)imageBrowser:(RLImageBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index {
    RLPhoto *photo = [photoBrowser photoAtIndex:index];
    NSLog(@"Did dismiss photoBrowser with photo index: %zd, photo caption: %@", index, photo.caption);
}

- (void)willDisappearPhotoBrowser:(RLImageBrowser *)photoBrowser {
     NSLog(@"willDisappearPhotoBrowser ");
}

- (UIView <RLTransitionProtocol> *)imageBrowser:(RLImageBrowser *)photoBrowser transitionViewForPhotoAtIndex:(NSUInteger)index {
    if (self.photoBrowser != photoBrowser) {
        return nil;
    }
    
    CollectionViewCell <RLTransitionProtocol> *cell = (CollectionViewCell *)[self.colectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return cell;
}

@end

