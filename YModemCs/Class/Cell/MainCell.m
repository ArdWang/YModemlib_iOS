//
//  MainCell.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "MainCell.h"

#ifdef __OBJC__
//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND
//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS
#import "Masonry.h"
#endif

@implementation MainCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

/*
 * 初始化布局
 */
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        //品牌
        UILabel *txtBrand = [[UILabel alloc] init];
        txtBrand.textColor = [UIColor redColor];
        txtBrand.font = [UIFont fontWithName:@"Helvetica" size:30];
        txtBrand.text = @"BT";
        txtBrand.textAlignment = NSTextAlignmentCenter;
        [self addSubview:txtBrand];
        
        [txtBrand makeConstraints:^(MASConstraintMaker *make){
            make.top.equalTo(self).offset(30);
            make.left.equalTo(self).offset(20);
            make.width.equalTo(@50);
            make.height.equalTo(@30);
        }];
        
        //设备名称
        _txtDeviceName = [[UILabel alloc] init];
        _txtDeviceName.textColor = [UIColor blackColor];
        _txtDeviceName.font = [UIFont fontWithName:@"Helvetica" size:16];
        _txtDeviceName.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_txtDeviceName];
        
        [_txtDeviceName makeConstraints:^(MASConstraintMaker *make){
            make.top.equalTo(self).offset(10);
            make.left.equalTo(self).offset(55);
            make.width.equalTo(@150);
            make.height.equalTo(@30);
        }];
        
        //设备地址
        _txtDeviceRssi = [[UILabel alloc] init];
        _txtDeviceRssi.textColor = [UIColor blackColor];
        _txtDeviceRssi.font = [UIFont fontWithName:@"Helvetica" size:14];
        _txtDeviceRssi.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_txtDeviceRssi];
        
        [_txtDeviceRssi makeConstraints:^(MASConstraintMaker *make){
            make.top.equalTo(_txtDeviceName).offset(40);
            make.left.equalTo(self).offset(58);
            make.width.equalTo(@160);
            make.height.equalTo(@30);
        }];
        
        //提示是否连接
        UILabel *txtConnect = [[UILabel alloc] init];
        txtConnect.textColor = [UIColor blackColor];
        txtConnect.font = [UIFont fontWithName:@"Helvetica" size:18];
        txtConnect.text = @"Connect";
        txtConnect.textAlignment = NSTextAlignmentCenter;
        [self addSubview:txtConnect];
        
        [txtConnect makeConstraints:^(MASConstraintMaker *make){
            make.top.equalTo(self).offset(30);
            make.right.equalTo(self).offset(-5);
            make.width.equalTo(@100);
            make.height.equalTo(@30);
        }];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end

