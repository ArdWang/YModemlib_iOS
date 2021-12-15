# YModemlib_iOS

<br>
<a href="https://raw.githubusercontent.com/QuickDevelopers/YModemLib/master/LICENSE" rel="nofollow"><img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="GitHub license" data-canonical-src="https://img.shields.io/badge/license-MIT-lightgrey.svg" style="max-width:100%;"></a> <a href="https://cocoapods.org/pods/YModemLib" rel="nofollow"><img src="https://img.shields.io/cocoapods/v/YModemLib.svg" alt="CocoaPods Compatible" data-canonical-src="https://img.shields.io/cocoapods/v/YModemLib.svg" style="max-width:100%;"></a> <a href="http://cocoadocs.org/docsets/YModemLib" rel="nofollow"><img src="https://img.shields.io/cocoapods/p/YModemLib.svg?style=flat" alt="Platform" data-canonical-src="https://img.shields.io/cocoapods/p/YModemLib.svg?style=flat" style="max-width:100%;"></a>
<br>

## Support MacOs ，iOS ，flutter Mixed development
<br>

Android Version： https://github.com/ArdWang/YModemlib_Android

View the latest version

https://cocoapods.org/pods/YModemLib

https://github.com/QuickDevelopers/YModemLib

Use:

swift
 ```
 import YModemLib
 ```
 
 oc
 
 ```
#import "YModemLib.h"

 ```

Added practical pod import

```shell

target 'MyApp' do
  pod 'YModemLib', '~> 1.0.2'
end

```

If you report the following error when using

```java
[!] CocoaPods could not find compatible versions for pod "BleManageSwift":
  In Podfile:
    BleManageSwift (~> current version)

None of your spec sources contain a spec satisfying the dependency: `BleManageSwift (~> current version)`.

You have either:
 * out-of-date source repos which you can update with `pod repo update` or with `pod install --repo-update`.
 * mistyped the name or version.
 * not added the source repo that hosts the Podspec to your Podfile.

```

run pod repo update or pod install --repo-update

Then run a pod install inside your terminal, or from CocoaPods.app.

Alternatively to give it a test run, run the command:

### Update Dec 15 2021

This update adds a new method，No proxy method is required to run

stopOtaUpgrade modify is stop

Updated only the file name and file path, which can be applied to MacOS and iOS

This update supports the development of ymodem protocol by flutter hybrid Bluetooth


```
/*
 fileName: file is name
 filePath: The real path where the file is located
 return current: Current file write progress, total: file total size, data: file is data, msg: return message
 */
-(void) setFirmwareUpgrade:(OrderStatus) status fileName:(NSString *) filename filePath:(NSString *) filepath completion:(void(^)(NSInteger current, NSInteger total, NSData *data, NSString *msg))complete;

/*
 Stop upgrade
 */
-(void)stop;

```

use example

```
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

```




### Update 2020 8/8

Update content: Added other DFUUpatedataUtil

Data unpacking adopts simpler oc language unpacking 256 + 2 CRC check method can be changed by yourself

The total is 258 bytes. The maximum data sent by ios Bluetooth seems to be more than 400 bytes.

This protocol is a streamlined version of the Ymodem protocol. You can try it. I personally feel that the product is used very well. The Ymodem protocol has a bug on the product and finally adopts this simple method.


The next version update adds the osx desktop version of the USB transmission data protocol. The windows version uses c# language Java. I have tested that it is not as fast as c# and does not support well.


```
/**
 * @brief  Cal CRC16 for YModem Packet
 * @retval None
 */
uint16_t Cccal_CRC16(const uint8_t* p_data, uint32_t size)
{
    uint32_t crc = 0;
    const uint8_t* dataEnd = p_data+size;
    
    while(p_data < dataEnd)
        crc = UpdateCRC16(crc, *p_data++);
    
    crc = UpdateCRC16(crc, 0);
    crc = UpdateCRC16(crc, 0);
    
    return crc&0xffffu;
}

```




### This update adds the modification that can set the size of the sent data, you can set the size of your sent data at will

```objective-c

YmodemUtil.m 
- (instancetype)init:(uint32_t)size
{
    self = [super init];
    if (self) {
        self.status = OTAStatusNONE;
        index_packet = 0;
        index_packet_cache = -1;
        sendSize = size;
    }
    return self;
}

 MainController.m
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.mainView = [MainView new];
    [self.view addSubview:self.mainView];
    self.mainView.frame = self.view.bounds;
    self.mainView.delegate = self;
    
    //默认为1024 可以根据你传的数据来修改
    self.ymodemUtil = [[YModemUtil alloc] init:1024];
    self.ymodemUtil.delegate = self;
    
    //连接OTA的时候发送广播
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaCompletion:) name:@"otaNofiction" object:nil];
    //断开蓝牙连接的广播
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disContentBle:) name:@"disNofiction" object:nil];
}

```


### This update adds new features that can solve some direct NSData data transmission

```objective-c

//NSData格式
- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status fileData:(NSData *)data completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete;

```

### Update the judgment of some conditions to prevent the code from sending data errors during the update process

```objective-c

typedef enum : NSUInteger {
    OTAStatusNONE,
    OTAStatusWaiting,
    OTAStatusFirstOrder,
    OTAStatusBinOrder,
    OTAStatusBinOrderDone,
    OTAStatusEnd,
    OTAStatusCAN,
    OTAStatusEOT,
} OTAStatus;


typedef enum : NSUInteger {
    OrderStatusNONE,
    OrderStatusC,
    OrderStatusACK,
    OrderStatusNAK,
    OrderStatusCAN,
    OrderStatusFirst,
} OrderStatus;


# 在原来的代码基础上面增加了一些判断
#pragma mark - 下位机数据File传输并处理 
- (void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status fileName:(NSString *)filename completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete{
    //增加为空防止出现空值错误
    NSString *msgg=@"";
    switch (status) {
        //Send Head Package
        case OrderStatusC:{
            //msgg = @"开始发送头包";
            NSData *data_first = [self prepareFirstPacketWithFileName:filename];
            if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                [self.delegate onWriteBleData:data_first];
            }
            self.status = OTAStatusFirstOrder;
            break;
        }
            
        //Send First Package
        case OrderStatusFirst:{
            if(self.status == OTAStatusFirstOrder){
                //msgg=@"开始发送第一包";
                // 正式包数组 获取所有拆解包放入数组中存储
                if (index_packet != index_packet_cache) {
                    if (!self.packetArray) {
                        self.packetArray = [self preparePacketWithFileName:filename];
                    }
                    NSData *data = self.packetArray[index_packet];
                    
                    //写入蓝牙数据
                    if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                        [self.delegate onWriteBleData:data];
                    }
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                }
            }
            
            //结束包的时候
            if(self.status == OTAStatusBinOrderDone){
                if(index_packet >= self.packetArray.count){
                    NSData *data = [self prepareEndPacket];
                    if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                        [self.delegate onWriteBleData:data];
                    }
                    index_packet = OTAUPEND;
                }
                //结束标记位
                self.status = OTAStatusEnd;
            }
            
            break;
        }
            
        case OrderStatusACK:{
            if(self.status == OTAStatusBinOrder){
                index_packet++;
                if (index_packet < self.packetArray.count) {
                    if (index_packet != index_packet_cache) {
                        if (!self.packetArray) {
                            self.packetArray = [self preparePacketWithFileName:filename];
                        }
                        NSData *data = self.packetArray[index_packet];
                        //拆包发送
                        if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                            [self.delegate onWriteBleData:data];
                        }
                        [NSThread sleepForTimeInterval:0.02];
                    }
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                }else{
                    // 所有正式文件包发送完成，发送结束OTA命令
                    Byte byte4[] = {0x04};
                    NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
                    //msgg=@"准备结束第一次EOT";
                    if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                        [self.delegate onWriteBleData:data23];
                    }
                    self.status = OTAStatusEOT;
                }
            }
            break;
        }
            
        case OrderStatusNAK:{
            if(self.status == OTAStatusEOT){
                if(index_packet >= self.packetArray.count){
                    Byte byte4[] = {0x04};
                    NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
                    //msgg=@"准备结束第二次EOT";
                    if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                        [self.delegate onWriteBleData:data23];
                    }
                    self.status = OTAStatusBinOrderDone;
                }
            }else{
                //返回你自己的代码
                msgg=@"OTA Upgared Fail...";
                [self stopOtaUpgrad];
            }
            break;
        }
            
            
        default:
            break;
    }
    
    if(self.packetArray.count>0){
        complete(index_packet,self.packetArray.count,msgg);
    }
}



```





principle

1. First understand what is YModem communication?

The YModem protocol is an improved protocol of XModem. It is the most used protocol for file transfer between modems. It has the advantages of fast and stable transmission. Its transmission speed is faster than XModem, this is because it can transmit 1024 bytes of information block at a time, and it also supports the transmission of multiple files, which is often referred to as batch file transmission.

YModem is divided into YModem-1K and YModem-g.

I am using YModem-1K, which is to transmit 1024 bytes at a time.


YModem-1K uses 1024-byte information block transmission instead of standard 128-byte transmission, and the data is sent back using CRC to ensure the correctness of data transmission. Each time it transmits an information block data, it will wait for the receiver to respond with an ACK signal. After receiving the response, it will continue to transmit the next information block to ensure that all data has been received.


The transmission form of YModem-g is similar to that of YModem-1K, but it removes the CRC check code of the data. At the same time, after sending a data block information, it will not wait for the ACK signal from the receiving end, but directly transmits the next data block. It is precisely that it does not involve error checking that makes its transmission speed faster than YModem-1K.

Generally, YModem-1K is selected for transmission, and YModem usually refers to YModem-1K. Let’s talk about its transmission protocol

Because the above are all related to the C language, I omitted to go directly to the topic.

2. Transmission data format

```java
/**
 * ========================================================================================
 * THE YMODEM:
 * Send 0x05>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>* 发送0x05
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< C
 * SOH 00 FF "foo.c" "1064'' NUL[118] CRC CRC >>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ACK
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< C
 * STX 01 FE data[256] CRC CRC>>>>>>>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 * ACK STX 02 FD data[256] CRC CRC>>>>>>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 * ACK STX 03 FC data[256] CRC CRC>>>>>>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ACK
 * STX 04 FB data[256] CRC CRC>>>>>>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ACK
 * SOH 05 FA data[100] 1A[28] CRC CRC>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ACK
 * EOT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< NAK
 * EOT>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ACK
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< C
 * SOH 00 FF NUL[128] CRC CRC >>>>>>>>>>>>>>>>>>>>>>>
 * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ACK
 * ===========================================================================================
 **/
```
The device we use first sends 0x05 to communicate with Bluetooth, and then the device returns a C. After receiving C, it sends the header packet to the device immediately. CRC16 check is required here. Standard European and American standards are adopted.

Then you can send data sequentially

Note: The agreement of each company is different, but after you understand the principle, no matter how you change the agreement, you can solve it.

The key code for sending YModem to Bluetooth is to send data according to the underlying protocol

For the detailed process, please see YYModemOCDemo
