# YModemlib_iOS
This is iOS YModem


### 本次更新时间 2020 8/8

更新内容：增加了其他的DFUUpatedataUtil 

数据拆包采用更简单的oc语言拆包 256 + 2个 CRC 校验 方式可以自行更改

总共是258个字节 ios蓝牙最大发送数据 好像是 400多 字节

这种协议是在Ymodem协议上精简版 ，可以尝试去试下 ，个人感觉产品使用很好， Ymodem协议在产品上出现了Bug最后采用这种简单的方式


下个版本更新 添加 osx 桌面版的 USB的传输数据协议 windows版本采用的是 c# 语言的 Java我测试过没有 c#的速度快并支持不好


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




### 本次更新增加了可以设置发送数据大小的修改 可以随意设置你发送数据大小

```objective-c

YmodemUtil.m 里面
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

调用 MainController.m
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


### 本次更新增加了新的功能 可以解决一些直接是 NSData 数据的传输

```objective-c

//NSData格式
- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status fileData:(NSData *)data completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete;

```

### 更新一些条件的判断 防止代码在更新过程中出现发送数据错误

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





原理

1.首先理解什么是YModem通讯？

YModem协议是XModem的改进协议，它最用于调制解调器之间的文件传输的协议，具有快速，稳定传输的优点。它的传输速度比XModem快，这是由于它可以一次传输1024字节的信息块，同时它还支持传输多个文件，也就是常说的批文件传输。 

YModem分成YModem-1K与YModem-g。 

我使用的是YModem-1K 也就是一次传输1024字节。


YModem-1K用1024字节信息块传输取代标准的128字节传输，数据的发送回使用CRC校验，保证数据传输的正确性。它每传输一个信息块数据时，就会等待接收端回应ACK信号，接收到回应后，才会继续传输下一个信息块，保证数据已经全部接收。 


YModem-g传输形式与YModem-1K差不多，但是它去掉了数据的CRC校验码，同时在发送完一个数据块信息后，它不会等待接收端的ACK信号，而直接传输下一个数据块。正是它没有涉及错误校验，才使得它的传输速度比YModem-1K来得块。

一般都会选择YModem-1K传输，平时所说的YModem也是指的是YModem-1K。下面就讲讲它的传输协议 

由于上面都是些 C语言相关的所以省略了直接进入主题。
2.理解传输数据格式
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
我们用的设备首先要发送0x05与蓝牙通讯 然后设备返回一个C 接受到C后立即发送头部包到设备 此处 需要CRC16校验 采用标准的欧美标准

接下来就可以依次进行数据发送

注意：每一个公司的协议是不一样的但是你理解原理之后 协议不管怎么改 都可以去解决。

发送YModem到蓝牙的关键代码 根据底层的协议去进行发送数据

具体的详细过程 请看YYModemOCDemo
