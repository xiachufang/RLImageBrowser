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
#import <SDWebImage/SDWebImage.h>

@interface ViewController () <RLPhotoBrowserDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

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
    
    self.urlArrays = @[[NSURL URLWithString:@"http://i2.chuimg.com/c11b178206344c76932ac28dbb81836f_2448w_1836h.jpg?imageView2/2/w/300/interlace/1/q/90"], [NSURL URLWithString:@"http://i2.chuimg.com/db8ebb9ed7ad4ae88e46d072338c6089_4032w_3024h.jpg?imageView2/2/w/300/interlace/1/q/90"], [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"], [NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"], [NSURL URLWithString:@"https://apng.onevcat.com/assets/elephant.png"], [NSURL URLWithString:@"http://img4.duitang.com/uploads/item/201601/15/20160115231312_TWuG5.gif"], [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118892596&di=5e8f287b5c62ca0c813a548246faf148&imgtype=0&src=http%3A%2F%2Fwx1.sinaimg.cn%2Fcrop.0.0.1080.606.1000%2F8d7ad99bly1fcte4d1a8kj20u00u0gnb.jpg"], [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118914981&di=7fa3504d8767ab709c4fb519ad67cf09&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201410%2F05%2F20141005221124_awAhx.jpeg"], [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118934390&di=fbb86678336593d38c78878bc33d90c3&imgtype=0&src=http%3A%2F%2Fi2.hdslb.com%2Fbfs%2Farchive%2Fe90aa49ddb2fa345fa588cf098baf7b3d0e27553.jpg"]];
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
    browser.displayActionButton = YES;
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
            NSArray *array = @[[NSURL URLWithString:@"http://i2.chuimg.com/c11b178206344c76932ac28dbb81836f_2448w_1836h.jpg?imageView2/2/w/300/interlace/1/q/90"], [NSURL URLWithString:@"http://i2.chuimg.com/db8ebb9ed7ad4ae88e46d072338c6089_4032w_3024h.jpg?imageView2/2/w/300/interlace/1/q/90"], [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"], [NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"], [NSURL URLWithString:@"https://apng.onevcat.com/assets/elephant.png"]];
            photos = [NSMutableArray arrayWithArray:[RLPhoto photosWithURLs:array]];
        }
    }
    
    RLImageBrowser *browser = [[RLImageBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    browser.displayCounterLabel = YES;
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            browser.displayActionButton = YES;
        } else if (indexPath.row == 2) {
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
        RLPhoto *photo = [RLPhoto photoWithURL:self.urlArrays[i]];
        photo.caption = @"collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath";
        [photos addObject:photo];
    }

    RLImageBrowser *browser = [[RLImageBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    browser.dismissOnTouch = YES;
    browser.useAnimationForPresentOrDismiss = YES;
    browser.displayCounterLabel = YES;
    browser.displayActionButton = YES;
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

