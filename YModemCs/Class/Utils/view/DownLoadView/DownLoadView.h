//
//  DownLoadView.h
//  YModemCs
//
//  Created by rnd on 2018/6/15.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DownLoadView;

@protocol DownLoadViewDelegate <NSObject>;

-(void)ClickToStartTheDownLoadBtnInLoadView:(DownLoadView *)downLoadView ;

@end;

@interface DownLoadView : UIView

/** MusicalProgress */
@property (nonatomic, assign) CGFloat musicalProgress;

/** placeholderText */
@property (nonatomic, copy) NSString *placeholderText;

/** placeholderBtnText */
@property (nonatomic, copy) NSString *placeholderBtnText;

/** placeholderFont */
@property (nonatomic) UIFont *placeholderFont;

/** placeholderBtnFont */
@property (nonatomic) UIFont *placeholderBtnFont;

/** MusicalColor */
@property (nonatomic) UIColor *musicalColor;

/** TitleColor */
@property (nonatomic) UIColor *titleColor;

/** ZWMusicDownLoadLab */
@property (nonatomic, strong) UILabel *musicDownLoadLab;


/** ZWMusicDownLoadViewDelegate */
@property (nonatomic, weak) id<DownLoadViewDelegate>  delegate;

- (void)startDownLoad;
- (void)endDownLoad;


@end
