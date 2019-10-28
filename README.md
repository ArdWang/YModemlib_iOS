# YModemlib_iOS
This is iOS YModem

### 本次更新增加了新的功能 可以解决一些直接是 NSData 数据的传输

```

//NSData格式
- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status fileData:(NSData *)data completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete;

```

### 更新一些条件的判断 防止代码在更新过程中出现发送数据错误

```

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

```Objective-c
//接受终端数据然后再发送数据到终端
- (void)setOTADataWithOrderStatus:(NSString *)status fileName:(NSString *)filename {
    //发送头包
    if([status isEqual:OTAC]){
        NSLog(@"Head");
        NSData *data_first = [self prepareFirstPacketWithFileName:filename];
        if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
            [self.delegate onWriteBleData:data_first];
        }
    }
    //发送第一包 和 最后的结束包 ACK/C
    else if([status isEqual:OTASTART]){
        if(index_packet>0){
            NSData *data = [self prepareEndPacket];
            if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                [self.delegate onWriteBleData:data];
            }
            index_packet = OTAUPEND;
        }else{
            // 正式包数组 获取所有拆解包放入数组中存储
            if (self.packetArray.count==0) {
                self.packetArray = [self preparePacketWithFileName:filename];
            }
            NSData *data = self.packetArray[index_packet];
            
            //写入蓝牙数据
            if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                [self.delegate onWriteBleData:data];
            }
            index_packet_cache = index_packet;
        }
    }
    
    //接受到ACK
    else if([status isEqual:OTAACK]){
        if(index_packet==OTAUPEND){
            NSLog(@"升级完成");
        }
        index_packet++;
        NSLog(@"ACK");
        if (index_packet < self.packetArray.count) {
            if (index_packet != index_packet_cache) {
                self.packetArray = [self preparePacketWithFileName:filename];
                NSData *data = self.packetArray[index_packet];
                //拆包发送
                if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                    [self.delegate onWriteBleData:data];
                }
            }
            index_packet_cache = index_packet;
        }else{
            Byte byte4[] = {0x04};
            NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
            NSLog(@"准备结束第一次OTA");
            if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                [self.delegate onWriteBleData:data23];
            }
        }
        //沉睡300ms
        [NSThread sleepForTimeInterval:0.5];
    }
    //接受到NAK的时候
    else if([status isEqual:OTANAK]){
        if(index_packet>0){
            Byte byte4[] = {0x04};
            NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
            NSLog(@"准备结束第二次OTA");
            if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
                [self.delegate onWriteBleData:data23];
            }
        }else{
            NSLog(@"升级失败了");
        }
    }
    
    //通过代理返回当前你的升级大小
    if(self.packetArray.count>0){
        if([self.delegate respondsToSelector:@selector(onCurrent:onTotal:)]){
            [self.delegate onCurrent:index_packet onTotal:self.packetArray.count];
        }
    }
}

```

具体的详细过程 请看YYModemOCDemo
