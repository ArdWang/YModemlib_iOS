//
//  FileOTAView.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonUtil.h"

@protocol FileOTAViewDelegate <NSObject>
//加载头部刷新
-(void)upgradeonClick;

@end

@interface FileOTAView : UIView

//代理
@property(assign,nonatomic) id<FileOTAViewDelegate> delegate;

@property(strong,nonatomic) CommonUtil *commonUtil;

@property(strong,nonatomic) UITableView *filetableView;

@property(strong,nonatomic) UIButton *upgradeButton;

@end
