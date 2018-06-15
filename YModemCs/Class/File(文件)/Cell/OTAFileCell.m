//
//  OTAFileCell.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "OTAFileCell.h"

#ifdef __OBJC__
//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND
//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS
#import "Masonry.h"
#endif

@implementation OTAFileCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        //设备名称
        _fileLabel = [[UILabel alloc] init];
        _fileLabel.textColor = [UIColor blackColor];
        _fileLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
        [self addSubview:_fileLabel];
        
        [_fileLabel makeConstraints:^(MASConstraintMaker *make){
            make.top.equalTo(self).offset(15);
            make.left.equalTo(self).offset(10);
            make.width.equalTo(@220);
            make.height.equalTo(@30);
        }];
        
        //设备的按钮
        _checkBoxBtn = [[UIButton alloc] init];
        //_checkImg = [UIImage imageNamed:@"checkbox"];
        _checkImgView = [[UIImageView alloc] init];
        [_checkImgView setImage:_checkImg];
        [_checkBoxBtn addSubview:_checkImgView];
        [self addSubview:_checkBoxBtn];
        
        [_checkImgView makeConstraints:^(MASConstraintMaker *make){
            make.top.equalTo(_checkBoxBtn).offset(0);
            make.left.equalTo(_checkBoxBtn).offset(0);
            make.right.equalTo(_checkBoxBtn).offset(0);
            make.bottom.equalTo(_checkBoxBtn).offset(0);
        }];
        
        [_checkBoxBtn makeConstraints:^(MASConstraintMaker *make){
            make.top.equalTo(self).offset(15);
            make.right.equalTo(self).offset(-10);
            make.width.offset(@25);
            make.height.offset(@25);
        }];
    }
    return self;
}


@end

