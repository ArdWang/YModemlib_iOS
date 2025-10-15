//
//  MainController.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainView.h"
#import "BlueHelp.h"
#import "YModemUtil.h"
#import "FileOTAController.h"
#import "ViewController.h"

@interface MainController : UIViewController


@property (nonatomic, strong) MainView *mainView;           // Main user interface view
@property (nonatomic, strong) YModemUtil *ymodemUtil;       // YModem protocol utility
@property (nonatomic, assign) OrderStatus orderStatus;      // Current OTA command status
@property (nonatomic, strong) NSString *fileName;           // Selected firmware file name
@property (nonatomic, strong) NSString *filePath;           // Selected firmware file path
@property (nonatomic, strong) NSArray *firmwareFilesArray;  // Array of available firmware files

@end
