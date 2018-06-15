//
//  ViewController.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self customNav];
    [self deviceList];
    [self peripheralList];
    
    if(_deviceTimer==nil){
        _deviceTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(deviceTime) userInfo:nil repeats:YES];
    }
}

-(void)customNav{
    UIColor *blues = [[CommonUtil sharedManager] stringTOColor:@"#436EEE"];
    self.navigationItem.title = @"Demo";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:20]}];
    
    [self.navigationController.navigationBar setBarTintColor:blues];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    NSString *back = NSLocalizedString(@"back", nil);
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:back style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = item;
    UIBarButtonItem *set = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"config"] style:UIBarButtonItemStylePlain target:self action:@selector(setOnClick)];
    self.navigationItem.rightBarButtonItem = set;
    
    //创建下啦刷新
    NSString *dropscan = NSLocalizedString(@"dropscan", nil);
    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.attributedTitle = [[NSAttributedString alloc] initWithString:dropscan];
    [rc addTarget:self action:@selector(redreshTableView) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;
    
}

-(void)redreshTableView{
    if(self.refreshControl.refreshing){
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"scanning", nil)];
        if(self.deviceList!=nil&&self.deviceList.count>0){
            [self.deviceList removeAllObjects];
        }
        
        if(self.peripheralList.count>0&&self.peripheralList!=nil){
            [self.peripheralList removeAllObjects];
        }
        
        //扫描蓝牙
        [[BlueHelp sharedManager] startScan];
        [self.refreshControl endRefreshing];
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"dropscan", nil)];
        
        //扫描
        [self.tableView reloadData];
    }
}


-(void) deviceTime{
    if([[BlueHelp sharedManager] getDeviceList]!=nil&&[[BlueHelp sharedManager] getPeriperalList]!=nil){
        _peripheralList = [[BlueHelp sharedManager] getPeriperalList];
        _deviceList = [[BlueHelp sharedManager] getDeviceList];
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //重新加载数据
    [self.tableView reloadData];
    
    if (self.refreshControl.refreshing) {
        //TODO: 已经在刷新数据了
        //NSLog(@"12233");
    } else {
        NSLog(@"y is %f",self.tableView.contentOffset.y);
        if (self.tableView.contentOffset.y == -64) {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^(void){
                                 self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
                             } completion:^(BOOL finished){
                                 [self.refreshControl beginRefreshing];
                                 [self.refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
                             }];
        }
    }
}

//得到DeviceList
-(NSMutableArray*)getDeviceList{
    if(self.deviceList==nil){
        self.deviceList = [NSMutableArray array];
    }
    return self.deviceList;
}

-(NSMutableArray*)getPeripheralList{
    if(self.peripheralList==nil){
        self.peripheralList = [NSMutableArray array];
    }
    return self.peripheralList;
}


-(void)setOnClick{
    
}


#pragma mark - Navigation
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.deviceList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifiter = @"DeviceCellIdentifiter";
    MainCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifiter];
    if (cell == nil) {
        cell = [[MainCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifiter];
    }
    if([_deviceList count]>0){
        NSUInteger row = [indexPath row];
        if(row<_deviceList.count){
            _deviceModel = [_deviceList objectAtIndex:indexPath.row];
            cell.txtDeviceName.text = _deviceModel.deviceName;
        }
    }
    return cell;
}

#pragma tableView的点击事件
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifiter = @"DeviceCellIdentifiter";
    MainCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifiter];
    if (cell == nil) {
        cell = [[MainCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifiter];
    }
    
    if(_deviceList.count>0){
        NSString *contentTips = NSLocalizedString(@"connectTips", nil);
        NSString *multiple = NSLocalizedString(@"multipleunit", nil);
        //NSString *multiple = @"Copy";
        NSString *single = NSLocalizedString(@"singleunit", nil);
        //该方法响应列表中行的点击事件
        NSString *bleSelected=@"";
        //indexPath.row得到选中的行号，提取出在数组中的内容。
        BTAlertController *alertController = [BTAlertController alertControllerWithTitle:contentTips message:bleSelected preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:multiple style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            
        }];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:single style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            //连接第一个扫描到的外设
            NSUInteger row = [indexPath row];
            int rows =(int)row;
            //连接蓝牙
            [[BlueHelp sharedManager] contentBlue:rows];
            
            MainController *mainView = [[MainController alloc] init];
            mainView.title = @"ota升级";
            [self.navigationController pushViewController:mainView animated:YES];
        }];
        
        [alertController addAction:noAction];
        [alertController addAction:yesAction];
        [self presentViewController:alertController animated:true completion:nil];
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

@end
