//
//  MainController.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "MainController.h"

@interface MainController ()<MainViewDelegate,YModemUtilDelegate,FirmwareFileSelectionDelegate>

@end

@implementation MainController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.mainView = [MainView new];
    [self.view addSubview:self.mainView];
    self.mainView.frame = self.view.bounds;
    self.mainView.delegate = self;
    
    //默认为1024
    self.ymodemUtil = [[YModemUtil alloc] init:1024];
    self.ymodemUtil.delegate = self;
    
    //连接OTA的时候发送广播
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaCompletion:) name:@"otaNofiction" object:nil];
    //断开蓝牙连接的广播
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disContentBle:) name:@"disNofiction" object:nil];
}

/*
     发送OTA数据的广播
 */
-(void)otaCompletion:(NSNotification*)notification{
    NSDictionary *ota = [notification userInfo];
    NSString *otadata = [ota objectForKey:@"otaData"];
     if([otadata isEqual:OTAC]){
           self.orderStatus = OrderStatusC;
       }else if([otadata isEqual:OTASTART]){
           self.orderStatus = OrderStatusFirst;
       }else if([otadata isEqual:OTAACK]){
           self.orderStatus = OrderStatusACK;
       }else if([otadata isEqual:OTANAK]){
           self.orderStatus = OrderStatusNAK;
       }
       
       __weak typeof(self) weakSelf = self;
       
       [self.ymodemUtil setFirmwareHandleOTADataWithOrderStatus:self.orderStatus fileName:self.fileName completion:^(NSInteger current,NSInteger total,NSString *msg){
           float much = (float)current/total;
           if(much<=1.0){
               if(weakSelf.mainView.downLoadView.musicalProgress<=1.0){
                   weakSelf.mainView.downLoadView.musicalProgress=much;
                   if ((int)(weakSelf.mainView.downLoadView.musicalProgress*100)%5==0) {
                       [weakSelf.mainView.downLoadView startDownLoad];
                   }
               }else{
                   weakSelf.mainView.downLoadView.musicDownLoadLab.text = @"Upgrade Complete!";
               }
           }
           
           if(![msg isEqualToString:@""]&&msg!=nil)
               weakSelf.mainView.downLoadView.musicDownLoadLab.text = msg;
       }];
    
    
    // Use new method
    [self.ymodemUtil setFirmwareUpgrade:self.orderStatus fileName:self.fileName filePath:self.filePath completion:^(NSInteger current,NSInteger total, NSData *data, NSString *message){
        
        float much = (float)current/total;
        if(much<=1.0){
            if(weakSelf.mainView.downLoadView.musicalProgress<=1.0){
                weakSelf.mainView.downLoadView.musicalProgress=much;
                if ((int)(weakSelf.mainView.downLoadView.musicalProgress*100)%5==0) {
                    [weakSelf.mainView.downLoadView startDownLoad];
                }
            }else{
                weakSelf.mainView.downLoadView.musicDownLoadLab.text = @"Upgrade Complete!";
            }
        }
        
        if(![message isEqualToString:@""] && message!=nil)
            weakSelf.mainView.downLoadView.musicDownLoadLab.text = message;
        
        // Writting bluetooth data
        // In this way, the agent can be removed
        if(data.length > 0){
            [[BlueHelp sharedManager] wirteBleOTAData:data];
        }
    }];
}

/*
     断开蓝牙的时候发送广播
 */
-(void)disContentBle:(NSNotification*)notification{
    UIViewController *target = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        //遍历
        if ([controller isKindOfClass:[ViewController class]]) {
            //这里判断是否为你想要跳转的页面
            target = controller;
        }
    }
    if (target) {
        [self.navigationController popToViewController:target animated:YES]; //跳转
    }
}


/*
     所有的代理 包含View里面代理 YModem代理 文件选择代理等
 */
-(void)otaOnClick{
    //下面这个发送数据根据个人的需求去发送 通讯
    [[BlueHelp sharedManager] writeBlueOTA:@"0x05"];
}

-(void)selectOnClick{
    FileOTAController *file = [[FileOTAController alloc] init];
    file.delegate = self;
    file.title = @"SelectFile";
    [self.navigationController pushViewController:file animated:YES];
}


/*
    本次代理是从YModemUtil里面返回回来的 蓝牙写入数据代理
 */
-(void)onWriteBleData:(NSData*) data{
    //发送数据到终端设备
    [[BlueHelp sharedManager]  wirteBleOTAData:data];
}

/*
     文件选择的时候返回代理
 */
- (void)firmwareFilesSelected:(NSArray *)selectedFilesArray forUpgradeMode:(OTAModel)selectedMode
{
    if (selectedFilesArray) {
        _firmwareFilesArray = [[NSArray alloc] initWithArray:selectedFilesArray];
          [self startParsingFirmwareFile:[_firmwareFilesArray objectAtIndex:0]];
    }
}

- (void) startParsingFirmwareFile:(NSDictionary *)firmwareFile{
    self.fileName = [firmwareFile objectForKey:@"FileName"];
    self.filePath = [firmwareFile objectForKey:@"FilePath"];
    self.mainView.downLoadView.musicDownLoadLab.text = self.fileName;
}

- (BOOL)navigationShouldPopOnBackButton{
    //断开蓝牙 结束升级
    [[BlueHelp sharedManager] disContentBle];
    return YES;
}

@end
