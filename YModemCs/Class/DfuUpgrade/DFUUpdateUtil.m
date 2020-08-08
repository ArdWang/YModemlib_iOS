//
//  DFUUpdateUtil.m
//  YModemCs
//
//  Created by ardwang on 2020/8/8.
//  Copyright © 2020 GoDream. All rights reserved.
//

#import "DFUUpdateUtil.h"


@interface DFUUpdateUtil(){
    int index_packet;
    int index_packet_cache;
    uint32_t sendSize;
    NSArray* a_128;
}

@property (nonatomic, strong) NSArray  *packetArray;

@property (nonatomic, assign) DFUStatus status;

@end

@implementation DFUUpdateUtil


- (instancetype)init:(uint32_t) size
{
    self = [super init];
    if (self) {
        self.status = OrderStatusNil;
        index_packet = -1;
        index_packet_cache = -2;
        sendSize = size;
        self.cmUtil = [[CommonUtil alloc] init];
    }
    return self;
}


-(void)startDFUUpgrad{
    index_packet = -1;
    index_packet_cache = -2;
    //清空列表
    _packetArray = @[];
}


-(void)getCRC:(NSString*)filename{
    _packetArray = [self preparePacketWithFile:filename];
    NSData *data = self.packetArray[0];
    NSString *kko = [self.cmUtil convertDataToHexStr:data];
    NSLog(@"data is :%@",kko);
}


-(void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status fileName:(NSString *)filename completion:(void(^)(NSInteger current,NSInteger total,NSString *msg, NSInteger stateq))complete{
    NSString *msges=@"";
    NSInteger states = 0;
    switch (status){
        case OrderStatusC:
            if(index_packet != index_packet_cache){
                //必须添加防止去拆包错误
                if(_packetArray.count == 0){
                    _packetArray = [self preparePacketWithFile:filename];
                }
                
                long jk = [self fileSize:filename];

                NSData *data_ =[self.cmUtil convertHexStrToData:[self.cmUtil ToHex:jk]];
                //Write Device Data
                if([self.delegate respondsToSelector:@selector(onWriteData:)]){
                    [self.delegate onWriteData:data_];
                }
                
                [NSThread sleepForTimeInterval:0.02];
                index_packet_cache = index_packet;
                msges = @"Upgrading...";
                _status = DFUStatusA;
            }
            break;
        case OrderStatusA:
            if(_status == DFUStatusA){
                index_packet++;
                if(index_packet < self.packetArray.count){
                    NSData *data = self.packetArray[index_packet];
                    //NSString *kko = [self.cmUtil convertDataToHexStr:data];
                    NSData *chunk = [NSData dataWithBytes:data.bytes length:data.length];

                    //write device data
                    if([self.delegate respondsToSelector:@selector(onWriteData:)]){
                        [self.delegate onWriteData:chunk];
                    }
                    [NSThread sleepForTimeInterval:0.02];
                    index_packet_cache = index_packet;
                    _status = DFUStatusA;
                    msges = @"Upgrading...";
                    states = 0;
                }
            }
            
            break;
    
        case OrderStatusE:
            msges=@"Upgared Fail.";
            states = -1;
            index_packet = -1;
            index_packet_cache = -2;
            break;
        case OrderStatusOK:
            msges = @"Upgared Success.";
            states = 100;
            index_packet = -1;
            index_packet_cache = -2;
            break;
        case OrderStatusNil:
            msges = @"Upgared Nil.";
            states = -1;
            index_packet = -1;
            index_packet_cache = -2;
            break;
    }
    
    if(self.packetArray.count>0){
        complete(index_packet,self.packetArray.count,msges,states);
    }
}


/**
    获取文件的大小
 */
-(long)fileSize:(NSString *)filename{
    NSString *room_name = filename;
    // 文件大小
    NSMutableData *file = [[NSMutableData alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:room_name];
    file = [NSMutableData dataWithContentsOfFile:path];
    return file.length;
}

/**
    拆包发送数据
 */
-(NSArray*)preparePacketWithFile:(NSString*)filename{
    // 文件大小
    NSMutableData *file = [[NSMutableData alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:filename];
    file = [NSMutableData dataWithContentsOfFile:path];
    
    NSMutableArray *dataArray = [NSMutableArray array];
    
    if(file.length>0){
        for (int i = 0; i<file.length; i+=sendSize) {
            if((i+sendSize)<file.length){
                
                NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, sendSize];
                NSData *subData = [file subdataWithRange:NSRangeFromString(rangeStr)];

                [dataArray addObject:[self.cmUtil calCRCWithData:subData]];
            }else{
                NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([file length] - i)];
                NSData *subData = [file subdataWithRange:NSRangeFromString(rangeStr)];
                
                [dataArray addObject:[self calCRCWithData:subData]];
            }
        }
    }
    return dataArray;
}

#pragma mark - 将16进制字符串转成NSData+CRC数据
- (NSData *)calCRCWithData:(NSData *)visibleData
{
    //将16进制字符串转成NSData数据
    NSMutableData *visibleDataM = [visibleData mutableCopy];
    //    Byte byte[5] = {0x00,0xc0,0x00,0x00,0x32};

    //NSData做crc验证得到short返回值
    Byte *byte = (Byte *)[visibleDataM bytes];
    unsigned short crcShort = Cccal_CRC16(byte, (int)visibleDataM.length);
    //将short返回值转成byte类型添加到可变数组末尾
    Byte bytes[2];
    bytes[0] = (Byte) (crcShort >> 8);
    bytes[1] = (Byte) (crcShort);

    [visibleDataM appendBytes:bytes length:sizeof(bytes)];

    return visibleDataM;
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
    uint32_t size = file.length>=sendSize?(sendSize):(sendSize);
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
            // 截取 n 或 128 长度数据
            NSData *sub_file_data = [file subdataWithRange:NSMakeRange(i, len)];
            
            uint32_t sub_size = sendSize;
            Byte *sub_file_byte = (Byte *)[sub_file_data bytes];
            uint8_t *p_packet;
            //不需要任何的补位操作
            p_packet = (uint8_t *)malloc(sub_size+2);
            PreparePacket(sub_file_byte, p_packet, index, sendSize, (uint32_t)sub_file_data.length);
            
            NSData *data_ = [NSData dataWithBytes:p_packet length:sizeof(uint8_t)*(sub_size+2)];
            
            [dataArray addObject:data_];
        }
    }
    return dataArray;
}


-(void)stopDFUUpgrad{
    index_packet = -1;
    index_packet_cache = -2;
}

@end
