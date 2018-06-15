//
//  MainView.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonUtil.h"
#import "DownLoadBtn.h"
#import "DownLoadView.h"


#define Color(r,g,b,a) [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:a]

//设置代理方法
@protocol MainViewDelegate <NSObject>

-(void)otaOnClick;
-(void)selectOnClick;

@end

@interface MainView : UIView

//制作delegate
@property (nonatomic, weak) id<MainViewDelegate> delegate;

@property(strong,nonatomic) UIButton *updateOTA;

@property(strong,nonatomic) UIButton *selectFile;

@property(strong,nonatomic) DownLoadBtn *downLoadBtn;

@property(strong,nonatomic) DownLoadView *downLoadView;

@end
