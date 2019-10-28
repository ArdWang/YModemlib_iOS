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

@property(strong,nonatomic) MainView *mainView;

@property(strong,nonatomic) YModemUtil *ymodemUtil;

@property(strong,nonatomic) NSArray *firmwareFilesArray, *firmWareRowDataArray;

@property(strong,nonatomic) NSString *fileName;

@property(strong,nonatomic) NSString *filePath;

@property(nonatomic,assign) NSUInteger orderStatus;

@end
