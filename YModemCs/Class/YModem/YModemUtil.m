//
//  YModemUtil.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "YModemUtil.h"

@interface YModemUtil(){
    int index_packet;
    int index_packet_cache;
    uint32_t sendSize;
}

@end

@implementation YModemUtil

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


#pragma mark - 下位机数据传输并处理
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


#pragma mark - 下位机数据传输并处理 当为NSData数据的时候
- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status fileData:(NSData *)data completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete{
    //增加为空防止出现空值错误
       NSString *msgg=@"";
       switch (status) {
           //Send Head Package
           case OrderStatusC:{
               //msgg = @"开始发送头包";
               NSData *data_first = [self prepareFirstPacketWithFileData:data];
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
                           self.packetArray = [self preparePacketWithFileData:data];
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
                               self.packetArray = [self preparePacketWithFileData:data];
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


//如果是NSData数据的时候
- (NSData *)prepareFirstPacketWithFileData:(NSData *)data{
    uint32_t length = (uint32_t)data.length;
    Byte * myByte = (Byte *)[data bytes];
    // 生成包
    UInt8 *buff_data;
    buff_data = (uint8_t *)malloc(sizeof(uint8_t)*133);
    UInt8 *crc_data;
    crc_data = (uint8_t *)malloc(sizeof(uint8_t)*128);
    PrepareIntialPacket(buff_data, myByte, length);
    NSData *data_first = [NSData dataWithBytes:buff_data length:sizeof(uint8_t)*133];
    return data_first;
}

//
- (NSArray *)preparePacketWithFileData:(NSData *)data{
    uint32_t size = data.length>=sendSize?(sendSize):(PACKET_SIZE);
    // 拆包
    int index = 0;
    NSMutableArray *dataArray = [NSMutableArray array];
    for (int i = 0; i<data.length; i++) {
        if (i%size == 0) {
            index++;
            uint32_t len = size;
            if ((data.length-i)<size) {
                len = (uint32_t)data.length - i;
            }
            // 截取256 或 128 长度数据
            NSData *sub_file_data = [data subdataWithRange:NSMakeRange(i, len)];
            
            uint32_t sub_size = sendSize;
            Byte *sub_file_byte = (Byte *)[sub_file_data bytes];
            uint8_t *p_packet;
            p_packet = (uint8_t *)malloc(sub_size+5);
            PreparePacket(sub_file_byte, p_packet, index,sendSize, (uint32_t)sub_file_data.length);
            
            NSData *data_ = [NSData dataWithBytes:p_packet length:sizeof(uint8_t)*(sub_size+5)];
            
            [dataArray addObject:data_];
        }
    }
    return dataArray;
}


/*
 停止OTA的升级
 */
-(void)stopOtaUpgrad{
    Byte stop[] = {0x18};
    NSData *data = [NSData dataWithBytes:stop length:sizeof(stop)];
    NSLog(@"停止OTA升级");
    if([self.delegate respondsToSelector:@selector(onWriteBleData:)]){
        [self.delegate onWriteBleData:data];
    }
}


/*
    发送包头数据
 */
- (NSData *)prepareFirstPacketWithFileName:(NSString *)filename {
    // 文件名
    NSString *room_name = filename;
    NSData* bytes = [room_name dataUsingEncoding:NSUTF8StringEncoding];
    Byte * myByte = (Byte *)[bytes bytes];
    UInt8 buff_name[bytes.length+1];
    memcpy(buff_name, [room_name UTF8String],[room_name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1);
    //|UTF8String|返回是包含\0的  |lengthOfBytesUsingEncoding|计算不包括\0 所以这里加上一
    // 文件大小
    NSMutableData *file = [[NSMutableData alloc]init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:room_name];
    
    file = [NSMutableData  dataWithContentsOfFile:path];
    uint32_t length = (uint32_t)file.length;
    
    // 发送SOH数据包
    // 生成包
    UInt8 *buff_data;
    buff_data = (uint8_t *)malloc(sizeof(uint8_t)*133);
    
    UInt8 *crc_data;
    crc_data = (uint8_t *)malloc(sizeof(uint8_t)*128);
    
    PrepareIntialPacket(buff_data, myByte, length);
    
    NSData *data_first = [NSData dataWithBytes:buff_data length:sizeof(uint8_t)*133];
    
    return data_first;
}


/*
 自动拆包 注意：我这里和底层协商的拆包发送是 包大小不是1024而是 256 一般的是 1024
 长度为 128
 根据文件大小自动拆包多少个
 */
- (NSArray *)preparePacketWithFileName:(NSString *)filename{
    NSString *room_name = filename;
    // 文件大小
    NSMutableData *file = [[NSMutableData alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:room_name];
    file = [NSMutableData dataWithContentsOfFile:path];
    uint32_t size = file.length>=sendSize?(sendSize):(PACKET_SIZE);
    // 拆包
    int index = 0;
    NSMutableArray *dataArray = [NSMutableArray array];
    for (int i = 0; i<file.length; i++) {
        if (i%size == 0) {
            index++;
            uint32_t len = size;
            if ((file.length-i)<size) {
                len = (uint32_t)file.length - i;
            }
            // 截取256 或 128 长度数据
            NSData *sub_file_data = [file subdataWithRange:NSMakeRange(i, len)];
            
            uint32_t sub_size = sendSize;
            Byte *sub_file_byte = (Byte *)[sub_file_data bytes];
            uint8_t *p_packet;
            p_packet = (uint8_t *)malloc(sub_size+5);
            PreparePacket(sub_file_byte, p_packet, index,sendSize, (uint32_t)sub_file_data.length);
            
            NSData *data_ = [NSData dataWithBytes:p_packet length:sizeof(uint8_t)*(sub_size+5)];
            
            [dataArray addObject:data_];
        }
    }
    return dataArray;
}


/*
    发送结束包 完成OTA升级 根据你自己的协议来发送
 */
- (NSData *)prepareEndPacket {
    UInt8 *buff_data;
    buff_data = (uint8_t *)malloc(sizeof(uint8_t)*(PACKET_SIZE+5));
    PrepareEndPacket(buff_data);
    NSData *data_first = [NSData dataWithBytes:buff_data length:sizeof(uint8_t)*(PACKET_SIZE+5)];
    return data_first;
}

@end
