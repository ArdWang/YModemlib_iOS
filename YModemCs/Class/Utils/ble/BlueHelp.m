//
//  BlueHelp.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "BlueHelp.h"


@interface BlueHelp()<CBCentralManagerDelegate,CBPeripheralDelegate>

@end

@implementation BlueHelp

+ (id)sharedManager {
    static BlueHelp *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init{
    self = [super init];
    if(self){
        self.centerManager = [[CBCentralManager alloc] init];
        self.centerManager.delegate = self;
    }
    return self;
}

#pragma 蓝牙代理 ---
//程序运行后,会自动调用的检查蓝牙的方法 并扫描蓝牙的方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (@available(iOS 10.0, *)) {
        if ([central state] == CBManagerStatePoweredOff) {
            NSLog(@"CoreBluetooth BLE hardware is powered off");
        }
        else if ([central state] == CBManagerStatePoweredOn) {
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            [self startScan];
        }
        else if ([central state] == CBManagerStateUnauthorized) {
            NSLog(@"CoreBluetooth BLE state is unauthorized");
        }
        else if ([central state] == CBManagerStateUnknown) {
            NSLog(@"CoreBluetooth BLE state is unknown");
        }
        else if ([central state] == CBManagerStateUnsupported) {
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
        }
    } else {
        // Fallback on earlier versions
    }
}

/*
 * 获取设备的list
 */
-(NSMutableArray *)getDeviceList{
    return self.deviceList;
}

/*
 * 获取设备的periperals
 */
-(NSMutableArray *)getPeriperalList{
    return self.periperals;
}

/*
 * 连接蓝牙设备给外部调用的方法
 * 传入的是相对应的行数
 */
-(void)contentBlue:(int) row{
    [self.centerManager connectPeripheral:self.periperals[row] options:nil];
}

//断开蓝牙
-(void)disContentBle{
    //关键的断开蓝牙  通知也要停止掉
    if((_peripheral!=nil && self.sendotacharateristic!=nil)){
        [_peripheral setNotifyValue:NO forCharacteristic:self.sendotacharateristic];
        [self disconnectPeripheral:_peripheral];
    }
}

- (void) disconnectPeripheral:(CBPeripheral*)peripheral
{
    [_centerManager cancelPeripheralConnection:peripheral];
}

/*
 * 程序运行的时候开始扫描
 */
-(void)startScan{
    self.periperals = [[NSMutableArray alloc] init];
    self.deviceList = [[NSMutableArray alloc] init];
    //2.利用中心设备扫描外部设备
    [self.centerManager scanForPeripheralsWithServices:nil options:nil];
}

/*
 * 停止扫描
 */
-(void)stopScan{
    [_centerManager stopScan];
}



- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSS{
    NSString *deviceName;
    if (![self.periperals containsObject:peripheral]){
        deviceName = peripheral.name;
    }
    
    self.deviceModel = [[DeviceModel alloc] init];
    self.deviceModel.deviceName = deviceName;
    
    [self.periperals addObject:peripheral];
    [self.deviceList addObject:self.deviceModel];
}

//连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    if(peripheral!=nil){
        //停止扫描 这个用于自动连接的时候
        [self.centerManager stopScan];
        //设备名称
        //_deviceName = peripheral.name;
        //_selectperipheral = peripheral;
        
        peripheral.delegate = self;
        //再去扫描服务
        [peripheral discoverServices:nil];
        
    }
}

//连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSLog(@"连接失败,失败原因:%@",error);
    NSString *disContentBlue = @"discontentblue";
    NSDictionary *blueDiscontent = [NSDictionary dictionaryWithObject:disContentBlue forKey:@"disconnect"];
    //发送广播 连接失败
    [[NSNotificationCenter defaultCenter] postNotificationName:@"disNofiction" object:nil userInfo:blueDiscontent];
}

//断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"断开连接");
    NSString *disContentBlue = @"discontentblue";
    NSDictionary *blueDiscontent = [NSDictionary dictionaryWithObject:disContentBlue forKey:@"disconnect"];
    //发送广播 连接失败
    [[NSNotificationCenter defaultCenter] postNotificationName:@"disNofiction" object:nil userInfo:blueDiscontent];
}

#pragma mark - CBPeripheralDelegate
//只要扫描到服务就会调用,其中的外设就是服务所在的外设
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error){
        NSLog(@"扫描服务出现错误,错误原因:%@",error);
    }else{
        //获取外设中所扫描到的服务
        for (CBService *service in peripheral.services){
            //把所有的service打印出来
            //从需要的服务中查找需要的特征
            //从peripheral的services中扫描特征
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

//只要扫描到特征就会调用,其中的外设和服务就是特征所在的外设和服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error{
    if (error){
        NSLog(@"扫描特征出现错误,错误原因:%@",error);
    }else{
        for (CBCharacteristic *characteristic in service.characteristics){
            if([characteristic.UUID isEqual:BOOT_OTA_UUID]){
                self.peripheral = peripheral;
                self.sendotacharateristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    NSLog(@"发现通知！");
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    [self.centerManager stopScan];
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}


//获取所以的数据处理
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //接受数据处理
    NSString *data = [self getOTAData:characteristic];
    NSLog(@"data is %@",data);
    
    //发送广播
    //发送所有数据 要在清单中注册该广播
    NSDictionary *otaDict = [NSDictionary dictionaryWithObject:data forKey:@"otaData"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"otaNofiction" object:nil userInfo:otaDict];
}


-(NSString *)getOTAData:(CBCharacteristic *)characteristic{
    NSData *data = characteristic.value;
    return [self convertDataToHexStr:data];
}

-(NSString *)convertDataToHexStr:(NSData *)data
{
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    return string;
}



- (NSData *)convertHexStrToData:(NSString *)str
{
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:20];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}



-(void)writeBlueOTA:(NSString *)value{
    NSMutableData *data = [[CommonUtil sharedManager] dataFromHexString:[value stringByReplacingOccurrencesOfString:@"0x" withString:@""]];
    NSLog(@"data is:%@",data);
    [self writeOTA:data forCharacteristic:self.sendotacharateristic];
}


-(void)wirteBleOTAData:(NSData *)value{
    [self writeOTA:value forCharacteristic:self.sendotacharateristic];
}

//写入OTA的区块
-(void)writeOTA:(NSData *)value forCharacteristic:(CBCharacteristic *)characteristic
{
    //is no write bluetooth data
    if(self.sendotacharateristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
    {
        //send phone on bluetooth data
        [self.peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }else
    {
        [self.peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    NSLog(@"已经向外设%@的特征值%@写入数据",_peripheral.name,characteristic.description);
}


@end

