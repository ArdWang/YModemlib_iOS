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
}
@end

@implementation YModemUtil

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
    NSData* bytes = [room_name dataUsingEncoding:NSUTF8StringEncoding];
    UInt8 buff_name[bytes.length+1];
    memcpy(buff_name, [room_name UTF8String],[room_name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1);
    // 文件大小
    NSMutableData *file = [[NSMutableData alloc]init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:room_name];
    file = [NSMutableData dataWithContentsOfFile:path];
    uint32_t size = file.length>=PACKET_1K_SIZE?(PACKET_1K_SIZE):(PACKET_SIZE);
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
            
            uint32_t sub_size = PACKET_1K_SIZE;
            
            Byte *sub_file_byte = (Byte *)[sub_file_data bytes];
            uint8_t *p_packet;
            p_packet = (uint8_t *)malloc(sub_size+5);
            PreparePacket(sub_file_byte, p_packet, index, (uint32_t)sub_file_data.length);
            
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
