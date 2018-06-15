//
//  MainView.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "MainView.h"

#ifdef __OBJC__
//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND
//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS
#import "Masonry.h"
#endif

@implementation MainView

//添加布局
-(instancetype) init{
    self = [super init];
    if(self){
        [self initView];
    }
    return self;
}

-(void)initView{
    //创建取消按钮
    self.updateOTA = [[UIButton alloc] init];
    self.updateOTA.backgroundColor = [[CommonUtil sharedManager] stringTOColor:@"#6495ED"];
    self.updateOTA.layer.cornerRadius = 15;
    NSString *cancel = @"开始OTA";
    [self.updateOTA setTitle:cancel forState:UIControlStateNormal];
    [self addSubview:self.updateOTA];
    
    [self.updateOTA makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self).offset(30);
        make.right.equalTo(self).offset(-30);
        make.top.equalTo(self).offset(85);
        make.height.equalTo(@55);
    }];
    
    self.downLoadView = [[DownLoadView alloc] init];
    //灰色
    self.downLoadView.backgroundColor = [UIColor grayColor];
    self.downLoadView.musicalColor=[[CommonUtil sharedManager] stringTOColor:@"#6495ED"];
    self.downLoadView.placeholderBtnFont=[UIFont fontWithName:@"Helvetica-Bold" size:14];
    self.downLoadView.placeholderFont=[UIFont fontWithName:@"Helvetica-Bold" size:12];
    self.downLoadView.musicDownLoadLab.text = @"请选择你的升级文件";
    [self addSubview:self.downLoadView];
    
    [self.downLoadView makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self).offset(250);
        make.height.equalTo(@55);
    }];
    
    self.selectFile = [[UIButton alloc] init];
    self.selectFile.backgroundColor = [[CommonUtil sharedManager] stringTOColor:@"#6495ED"];
    self.selectFile.layer.cornerRadius = 0;
    NSString *select = @"选择文件";
    [self.selectFile setTitle:select forState:UIControlStateNormal];
    [self addSubview:self.selectFile];
    
    [self.selectFile makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self).offset(0);
        make.right.equalTo(self).offset(0);
        make.bottom.equalTo(self).offset(0);
        make.height.equalTo(@55);
    }];
    
    
    
    //取消点击事件
    [self.updateOTA addTarget:self action:@selector(otaOnClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.selectFile addTarget:self action:@selector(selectOnClick) forControlEvents:UIControlEventTouchUpInside];
    
    
}

-(void)otaOnClick{
    if(self.delegate){
        [self.delegate otaOnClick];
    }
}

-(void)selectOnClick{
    if(self.delegate){
        [self.delegate selectOnClick];
    }
}

@end
