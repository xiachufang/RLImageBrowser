//
//  ViewController.m
//  RLImageBrowser
//
//  Created by kinarobin@outlook.com on 01/29/2019.
//  Copyright (c) 2019 kinarobin@outlook.com. All rights reserved.
//

#import "ViewController.h"
#import "RLPhotoBrowser.h"
#import "RLPhoto.h"

@interface ViewController () <RLPhotoBrowserDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableViewFooterView];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return  UIStatusBarStyleDefault;
}


- (void)setupTableViewFooterView {
    UIView *tableViewFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 426 * 0.9 + 40)];
    UIButton *buttonWithImageOnScreen1 = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, 640/3 * 0.9, 426/2 * 0.9)];
    buttonWithImageOnScreen1.tag = 101;
    buttonWithImageOnScreen1.adjustsImageWhenHighlighted = false;
    [buttonWithImageOnScreen1 setImage:[UIImage imageNamed:@"photo1m.jpg"] forState:UIControlStateNormal];
    buttonWithImageOnScreen1.imageView.contentMode = UIViewContentModeScaleAspectFill;
    buttonWithImageOnScreen1.backgroundColor = [UIColor blackColor];
    [buttonWithImageOnScreen1 addTarget:self action:@selector(buttonWithImageOnScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [tableViewFooter addSubview:buttonWithImageOnScreen1];
    
    UIButton *buttonWithImageOnScreen2 = [[UIButton alloc] initWithFrame:CGRectMake(15, 426/2 * 0.9 + 20, 640/3 * 0.9, 426/2 * 0.9)];
    buttonWithImageOnScreen2.tag = 102;
    buttonWithImageOnScreen2.adjustsImageWhenHighlighted = false;
    [buttonWithImageOnScreen2 setImage:[UIImage imageNamed:@"photo3m.jpg"] forState:UIControlStateNormal];
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
        NSString *path_photo1l = [[NSBundle mainBundle] pathForResource:@"photo1l" ofType:@"jpg"];
        photo = [RLPhoto photoWithFilePath:path_photo1l];
        photo.caption = @"Grotto of the Madonna";
        [array addObject:photo];
    }
    
    NSString *path_photo3l = [[NSBundle mainBundle] pathForResource:@"photo3l" ofType:@"jpg"];
    photo = [RLPhoto photoWithFilePath:path_photo3l];
    photo.caption = @"York Floods";
    [array addObject:photo];
    
    NSString *path_photo2l = [[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"];
    photo = [RLPhoto photoWithFilePath:path_photo2l];
    photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
    [array addObject:photo];
    
    NSString *path_photo4l = [[NSBundle mainBundle] pathForResource:@"photo4l" ofType:@"jpg"];
    photo = [RLPhoto photoWithFilePath:path_photo4l];
    photo.caption = @"Campervan";
    [array addObject:photo];
    
    
    if (button.tag == 102) {
        NSString *path_photo1l = [[NSBundle mainBundle] pathForResource:@"photo1l" ofType:@"jpg"];
        photo = [RLPhoto photoWithFilePath:path_photo1l];
        photo.caption = @"Grotto of the Madonna";
        [array addObject:photo];
    }
    button.contentMode = UIViewContentModeScaleAspectFill;
    RLPhotoBrowser *browser = [[RLPhotoBrowser alloc] initWithPhotos:array animatedFromView:button];
    browser.delegate = self;
    browser.displayActionButton = YES;
    browser.displayArrowButton = YES;
    browser.displayCounterLabel = YES;
    browser.scaleImage = button.currentImage;
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
        NSString *path_photo2l = [[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"];
        photo = [RLPhoto photoWithFilePath:path_photo2l];
        photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
        [photos addObject:photo];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            NSString *path_photo1l = [[NSBundle mainBundle] pathForResource:@"photo1l" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo1l];
            photo.caption = @"Grotto of the Madonna";
            [photos addObject:photo];
            
            
            NSString *path_photo2l = [[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo2l];
            photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England";
            [photos addObject:photo];
            
            
            NSString *path_photo3l = [[NSBundle mainBundle] pathForResource:@"photo4l" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo3l];
            photo.caption = @"York Floods";
            [photos addObject:photo];
            
            NSString *path_photo4l = [[NSBundle mainBundle] pathForResource:@"photo4l" ofType:@"jpg"];
            photo = [RLPhoto photoWithFilePath:path_photo4l];
            photo.caption = @"Campervan";
            [photos addObject:photo];
        } else if ( indexPath.row == 1 || indexPath.row == 2 ) {
            NSArray *array = @[[NSURL URLWithString:@"http://assets.sbnation.com/assets/2512203/dogflops.gif"], [NSURL URLWithString:@"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif"],[NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"], [NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"], [NSURL URLWithString:@"https://apng.onevcat.com/assets/elephant.png"]];
            //             NSArray *array = @[ [NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"]];
            photos = [NSMutableArray arrayWithArray:[RLPhoto photosWithURLs:array]];
        }
    }
    
    RLPhotoBrowser *browser = [[RLPhotoBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    browser.displayCounterLabel = YES;
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            browser.displayActionButton = YES;
        } else if (indexPath.row == 2) {
            browser.useWhiteBackgroundColor = YES;
            browser.leftArrowImage = [UIImage imageNamed:@"RLPhotoBrowser_customArrowLeft.png"];
            browser.rightArrowImage = [UIImage imageNamed:@"RLPhotoBrowser_customArrowRight.png"];
            browser.leftArrowSelectedImage = [UIImage imageNamed:@"RLPhotoBrowser_customArrowLeftSelected.png"];
            browser.rightArrowSelectedImage = [UIImage imageNamed:@"RLPhotoBrowser_customArrowRightSelected.png"];
            browser.doneButtonImage = [UIImage imageNamed:@"RLPhotoBrowser_customDoneButton.png"];
            browser.view.tintColor = [UIColor orangeColor];
            browser.progressTintColor = [UIColor orangeColor];
            browser.trackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        }
    }
    
    [self presentViewController:browser animated:YES completion:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)photoBrowser:(RLPhotoBrowser *)photoBrowser didShowPhotoAtIndex:(NSUInteger)index {
    RLPhoto *photo = [photoBrowser photoAtIndex:index];
    NSLog(@"Did show photoBrowser with photo index: %zd, photo caption: %@", index, photo.caption);
}

- (void)photoBrowser:(RLPhotoBrowser *)photoBrowser willDismissAtPageIndex:(NSUInteger)index {
    RLPhoto *photo = [photoBrowser photoAtIndex:index];
    NSLog(@"Will dismiss photoBrowser with photo index: %zd, photo caption: %@", index, photo.caption);
}

- (void)photoBrowser:(RLPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index {
    RLPhoto *photo = [photoBrowser photoAtIndex:index];
    NSLog(@"Did dismiss photoBrowser with photo index: %zd, photo caption: %@", index, photo.caption);
}


@end

