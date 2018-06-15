//
//  FileOTAView.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "FileOTAView.h"


#ifdef __OBJC__
//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND
//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS
#import "Masonry.h"
#endif

@implementation FileOTAView

//添加布局
-(instancetype) init{
    self = [super init];
    if(self){
        _commonUtil = [CommonUtil sharedManager];
        [self initView];
        [self initEvent];
    }
    return self;
}

-(void)initView{
    _filetableView = [[UITableView alloc] init];
    [self addSubview:_filetableView];
    //布局
    [_filetableView makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self).offset(0);
        make.right.equalTo(self).offset(0);
        make.top.equalTo(self).offset(5);
        make.bottom.equalTo(self).offset(-55);
    }];
    
    _upgradeButton = [[UIButton alloc] init];
    _upgradeButton.backgroundColor = [_commonUtil stringTOColor:@"#6495ED"];
    NSString *upgrade = NSLocalizedString(@"upgrade", nil);
    [_upgradeButton setTitle:upgrade forState:UIControlStateNormal];
    [self addSubview:_upgradeButton];
    
    [_upgradeButton makeConstraints:^(MASConstraintMaker *make){
        make.right.equalTo(self).offset(0);
        make.left.equalTo(self).offset(0);
        make.bottom.equalTo(self).offset(0);
        make.height.offset(@55);
    }];
}

-(void)initEvent{
    [_upgradeButton addTarget:self action:@selector(upgradeonClick) forControlEvents:UIControlEventTouchUpInside];
}

-(void)upgradeonClick{
    if(self.delegate){
        [self.delegate upgradeonClick];
    }
}


@end


