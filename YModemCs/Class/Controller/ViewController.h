//
//  ViewController.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainCell.h"
#import "BlueHelp.h"
#import "DeviceModel.h"
#import "CommonUtil.h"
#import "BTAlertController.h"
#import "MainController.h"

@interface ViewController : UITableViewController

@property (nonatomic,strong) NSMutableArray *deviceList;

@property(strong,nonatomic) DeviceModel *deviceModel;

@property (nonatomic,strong ) NSMutableArray   <CBPeripheral*>*peripheralList;

//获取设备定时器
@property(strong,nonatomic) NSTimer *deviceTimer;

@end

