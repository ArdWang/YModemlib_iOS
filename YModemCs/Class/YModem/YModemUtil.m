//
//  YModemUtil.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//  Update by rnd on Dec 15 2021

#import "YModemUtil.h"

@interface YModemUtil(){
    int index_packet;           // Current packet index
    int index_packet_cache;     // Cached packet index for retry
    uint32_t sendSize;          // Packet size for transmission
    NSInteger currentRetryCount; // Current retry count for the packet
}

@end

@implementation YModemUtil

- (instancetype)init:(uint32_t)size {
    return [self initWithPacketSize:size maxRetryCount:3];
}

- (instancetype)initWithPacketSize:(uint32_t)size maxRetryCount:(NSInteger)maxRetry {
    self = [super init];
    if (self) {
        self.status = OTAStatusNONE;
        index_packet = 0;
        index_packet_cache = -1;
        sendSize = size;
        self.isCancelled = NO;
        self.retryCount = 0;
        self.maxRetryCount = maxRetry;
        currentRetryCount = 0;
    }
    return self;
}



#pragma mark - Enhanced OTA with retry and cancellation support

/**
 Enhanced firmware upgrade with file path support, retry mechanism and cancellation
 
 @param status Order status
 @param filename File name
 @param filepath File path
 @param complete Completion block with progress and data
 */
- (void)setFirmwareUpgrade:(OrderStatus)status
                  fileName:(NSString *)filename
                  filePath:(NSString *)filepath
                completion:(void(^)(NSInteger current, NSInteger total, NSData *data, NSString *msg))complete {
    
    // Check if operation is cancelled
    if (self.isCancelled) {
        complete(0, 0, nil, @"OTA upgrade cancelled");
        return;
    }
    
    NSString *tips = @"Begin";
    NSData *record = nil;
    
    switch (status) {
        // Send Head Package
        case OrderStatusC: {
            NSData *data_first = [self autoFirstPacketWithFileName:filename filePath:filepath];
            record = data_first;
            self.status = OTAStatusFirstOrder;
            currentRetryCount = 0; // Reset retry count for new transmission
            break;
        }
            
        // Send First Package
        case OrderStatusFirst: {
            if (self.status == OTAStatusFirstOrder) {
                // The official package array obtains all disassembled packages
                if (index_packet != index_packet_cache) {
                    if (!self.packetArray) {
                        self.packetArray = [self autoPacketWithFile:filename filePath:filepath];
                    }
                    record = self.packetArray[index_packet];
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                    tips = @"Running...";
                    currentRetryCount = 0; // Reset retry count for new packet
                }
            }
            
            // End packet
            if (self.status == OTAStatusBinOrderDone) {
                if (index_packet >= self.packetArray.count) {
                    record = [self prepareEndPacket];
                }
                // End transmission
                self.status = OTAStatusEnd;
                // Reset to initial state
                self.status = OTAStatusNONE;
                index_packet = 0;
                index_packet_cache = -1;
                tips = @"Finish";
                
                // Notify delegate about completion
                if ([self.delegate respondsToSelector:@selector(onOTACompletedWithSuccess:message:)]) {
                    [self.delegate onOTACompletedWithSuccess:YES message:@"OTA upgrade completed successfully"];
                }
            }
            break;
        }
            
        case OrderStatusACK: {
            if (self.status == OTAStatusBinOrder) {
                currentRetryCount = 0; // Reset retry count on successful ACK
                index_packet++;
                
                if (index_packet < self.packetArray.count) {
                    if (index_packet != index_packet_cache) {
                        if (!self.packetArray) {
                            self.packetArray = [self autoPacketWithFile:filename filePath:filepath];
                        }
                        record = self.packetArray[index_packet];
                        [NSThread sleepForTimeInterval:0.02];
                    }
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                    tips = @"Running...";
                    
                    // Notify delegate about progress
                    if ([self.delegate respondsToSelector:@selector(onOTAProgressUpdate:total:)]) {
                        [self.delegate onOTAProgressUpdate:index_packet total:self.packetArray.count];
                    }
                } else {
                    // After all official document packages are sent, send EOT
                    Byte byte4[] = {0x04};
                    record = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
                    self.status = OTAStatusEOT;
                    tips = @"Sending EOT...";
                }
            }
            break;
        }
            
        case OrderStatusNAK: {
            if (self.status == OTAStatusEOT) {
                if (index_packet >= self.packetArray.count) {
                    Byte byte4[] = {0x04};
                    record = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
                    self.status = OTAStatusBinOrderDone;
                    tips = @"Final EOT...";
                }
            } else {
                // Handle NAK with retry mechanism
                if (currentRetryCount < self.maxRetryCount) {
                    currentRetryCount++;
                    tips = [NSString stringWithFormat:@"Retry %ld/%ld", (long)currentRetryCount, (long)self.maxRetryCount];
                    
                    // Resend current packet
                    if (index_packet_cache >= 0 && index_packet_cache < self.packetArray.count) {
                        record = self.packetArray[index_packet_cache];
                    }
                } else {
                    // Max retries exceeded
                    tips = @"OTA Upgrade Failed: Max retries exceeded";
                    Byte stop[] = {0x18};
                    record = [NSData dataWithBytes:stop length:sizeof(stop)];
                    self.status = OTAStatusNONE;
                    
                    // Notify delegate about failure
                    if ([self.delegate respondsToSelector:@selector(onOTACompletedWithSuccess:message:)]) {
                        [self.delegate onOTACompletedWithSuccess:NO message:tips];
                    }
                }
            }
            break;
        }
            
        case OrderStatusCAN: {
            // Handle cancellation request from device
            tips = @"OTA cancelled by device";
            [self cancel];
            break;
        }
            
        default:
            break;
    }
    
    if (self.packetArray.count > 0) {
        complete(index_packet, self.packetArray.count, record, tips);
    } else {
        complete(index_packet, 0, record, tips);
    }
}

#pragma mark - Bluetooth device data transmission with retry support

/**
 Handle OTA data transmission for Bluetooth devices with retry mechanism
 
 @param status Order status
 @param filename File name
 @param complete Completion block
 */
- (void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status
                                       fileName:(NSString *)filename
                                     completion:(void(^)(NSInteger current, NSInteger total, NSString *msg))complete {
    
    if (self.isCancelled) {
        complete(0, 0, @"OTA upgrade cancelled");
        return;
    }
    
    NSString *msgg = @"";
    switch (status) {
        case OrderStatusC: {
            NSData *data_first = [self prepareFirstPacketWithFileName:filename];
            if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                [self.delegate onWriteBleData:data_first];
            }
            self.status = OTAStatusFirstOrder;
            currentRetryCount = 0;
            break;
        }
            
        case OrderStatusFirst: {
            if (self.status == OTAStatusFirstOrder) {
                if (index_packet != index_packet_cache) {
                    if (!self.packetArray) {
                        self.packetArray = [self preparePacketWithFileName:filename];
                    }
                    NSData *data = self.packetArray[index_packet];
                    
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:data];
                    }
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                    currentRetryCount = 0;
                }
            }
            
            if (self.status == OTAStatusBinOrderDone) {
                if (index_packet >= self.packetArray.count) {
                    NSData *data = [self prepareEndPacket];
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:data];
                    }
                    index_packet = OTAUPEND;
                }
                self.status = OTAStatusEnd;
                
                if ([self.delegate respondsToSelector:@selector(onOTACompletedWithSuccess:message:)]) {
                    [self.delegate onOTACompletedWithSuccess:YES message:@"OTA upgrade completed"];
                }
            }
            break;
        }
            
        case OrderStatusACK: {
            if (self.status == OTAStatusBinOrder) {
                currentRetryCount = 0;
                index_packet++;
                
                if (index_packet < self.packetArray.count) {
                    if (index_packet != index_packet_cache) {
                        if (!self.packetArray) {
                            self.packetArray = [self preparePacketWithFileName:filename];
                        }
                        NSData *data = self.packetArray[index_packet];
                        
                        if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                            [self.delegate onWriteBleData:data];
                        }
                        [NSThread sleepForTimeInterval:0.02];
                    }
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                    
                    if ([self.delegate respondsToSelector:@selector(onOTAProgressUpdate:total:)]) {
                        [self.delegate onOTAProgressUpdate:index_packet total:self.packetArray.count];
                    }
                } else {
                    Byte byte4[] = {0x04};
                    NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:data23];
                    }
                    self.status = OTAStatusEOT;
                }
            }
            break;
        }
            
        case OrderStatusNAK: {
            if (self.status == OTAStatusEOT) {
                if (index_packet >= self.packetArray.count) {
                    Byte byte4[] = {0x04};
                    NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:data23];
                    }
                    self.status = OTAStatusBinOrderDone;
                }
            } else {
                // Handle NAK with retry
                if (currentRetryCount < self.maxRetryCount) {
                    currentRetryCount++;
                    msgg = [NSString stringWithFormat:@"Retrying packet %d (%ld/%ld)",
                           index_packet_cache, (long)currentRetryCount, (long)self.maxRetryCount];
                    
                    // Resend current packet
                    if (index_packet_cache >= 0 && index_packet_cache < self.packetArray.count) {
                        NSData *data = self.packetArray[index_packet_cache];
                        if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                            [self.delegate onWriteBleData:data];
                        }
                    }
                } else {
                    msgg = @"OTA Upgrade Failed: Maximum retry attempts exceeded";
                    [self stop];
                    
                    if ([self.delegate respondsToSelector:@selector(onOTACompletedWithSuccess:message:)]) {
                        [self.delegate onOTACompletedWithSuccess:NO message:msgg];
                    }
                }
            }
            break;
        }
            
        default:
            break;
    }
    
    if (self.packetArray.count > 0) {
        complete(index_packet, self.packetArray.count, msgg);
    }
}

#pragma mark - NSData based OTA with retry support

- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status
                                        fileData:(NSData *)data
                                      completion:(void(^)(NSInteger current, NSInteger total, NSString *msg))complete {
    
    if (self.isCancelled) {
        complete(0, 0, @"OTA upgrade cancelled");
        return;
    }
    
    NSString *msgg = @"";
    switch (status) {
        case OrderStatusC: {
            NSData *data_first = [self prepareFirstPacketWithFileData:data];
            if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                [self.delegate onWriteBleData:data_first];
            }
            self.status = OTAStatusFirstOrder;
            currentRetryCount = 0;
            break;
        }
            
        case OrderStatusFirst: {
            if (self.status == OTAStatusFirstOrder) {
                if (index_packet != index_packet_cache) {
                    if (!self.packetArray) {
                        self.packetArray = [self preparePacketWithFileData:data];
                    }
                    NSData *packetData = self.packetArray[index_packet];
                    
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:packetData];
                    }
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                    currentRetryCount = 0;
                }
            }
            
            if (self.status == OTAStatusBinOrderDone) {
                if (index_packet >= self.packetArray.count) {
                    NSData *endData = [self prepareEndPacket];
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:endData];
                    }
                    index_packet = OTAUPEND;
                }
                self.status = OTAStatusEnd;
                
                if ([self.delegate respondsToSelector:@selector(onOTACompletedWithSuccess:message:)]) {
                    [self.delegate onOTACompletedWithSuccess:YES message:@"OTA upgrade completed"];
                }
            }
            break;
        }
            
        case OrderStatusACK: {
            if (self.status == OTAStatusBinOrder) {
                currentRetryCount = 0; // Reset retry count on successful ACK
                index_packet++;
                
                if (index_packet < self.packetArray.count) {
                    if (index_packet != index_packet_cache) {
                        if (!self.packetArray) {
                            self.packetArray = [self preparePacketWithFileData:data];
                        }
                        NSData *packetData = self.packetArray[index_packet];
                        
                        // Send packet data via Bluetooth
                        if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                            [self.delegate onWriteBleData:packetData];
                        }
                        [NSThread sleepForTimeInterval:0.02]; // Small delay between packets
                    }
                    index_packet_cache = index_packet;
                    self.status = OTAStatusBinOrder;
                    
                    // Update progress
                    if ([self.delegate respondsToSelector:@selector(onOTAProgressUpdate:total:)]) {
                        [self.delegate onOTAProgressUpdate:index_packet total:self.packetArray.count];
                    }
                } else {
                    // All data packets sent, send EOT (End of Transmission)
                    Byte eotByte[] = {0x04};
                    NSData *eotData = [NSData dataWithBytes:eotByte length:sizeof(eotByte)];
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:eotData];
                    }
                    self.status = OTAStatusEOT;
                }
            }
            break;
        }
        case OrderStatusNAK: {
            if (self.status == OTAStatusEOT) {
                if (index_packet >= self.packetArray.count) {
                    // Send final EOT after receiving NAK for first EOT
                    Byte eotByte[] = {0x04};
                    NSData *eotData = [NSData dataWithBytes:eotByte length:sizeof(eotByte)];
                    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                        [self.delegate onWriteBleData:eotData];
                    }
                    self.status = OTAStatusBinOrderDone;
                }
            } else {
                // Handle NAK for data packet with retry mechanism
                if (currentRetryCount < self.maxRetryCount) {
                    currentRetryCount++;
                    msgg = [NSString stringWithFormat:@"Retrying packet %d (%ld/%ld)",
                            index_packet_cache, (long)currentRetryCount, (long)self.maxRetryCount];
                    
                    // Resend current packet
                    if (index_packet_cache >= 0 && index_packet_cache < self.packetArray.count) {
                        NSData *packetData = self.packetArray[index_packet_cache];
                        if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                            [self.delegate onWriteBleData:packetData];
                        }
                    }
                } else {
                    // Maximum retry attempts exceeded
                    msgg = @"OTA Upgrade Failed: Maximum retry attempts exceeded";
                    [self stop]; // Send cancellation command
                    
                    // Notify delegate about failure
                    if ([self.delegate respondsToSelector:@selector(onOTACompletedWithSuccess:message:)]) {
                        [self.delegate onOTACompletedWithSuccess:NO message:msgg];
                    }
                }
            }
            break;
        }
            
        case OrderStatusCAN: {
            // Handle cancellation request from device
            msgg = @"OTA cancelled by remote device";
            [self cancel]; // Clean up local state
            break;
        }
            
        default:
            break;
    }
    
    // Calculate progress and return completion
    if (self.packetArray.count > 0) {
        complete(index_packet, self.packetArray.count, msgg);
    } else {
        complete(index_packet, 0, msgg);
    }
}

#pragma mark - Control Methods

/**
 Stop OTA upgrade by sending cancellation command
 */
- (void)stop {
    Byte cancelByte[] = {0x18}; // CAN character
    NSData *cancelData = [NSData dataWithBytes:cancelByte length:sizeof(cancelByte)];
    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
        [self.delegate onWriteBleData:cancelData];
    }
    [self cancel];
}

/**
 Cancel OTA upgrade and reset state
 */
- (void)cancel {
    self.isCancelled = YES;
    self.status = OTAStatusCAN;
    
    // Send multiple CAN characters to ensure cancellation
    Byte cancelBytes[] = {0x18, 0x18, 0x18};
    NSData *cancelData = [NSData dataWithBytes:cancelBytes length:sizeof(cancelBytes)];
    if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
        [self.delegate onWriteBleData:cancelData];
    }
    
    // Reset state after short delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reset];
    });
    
    // Notify delegate about cancellation
    if ([self.delegate respondsToSelector:@selector(onOTACompletedWithSuccess:message:)]) {
        [self.delegate onOTACompletedWithSuccess:NO message:@"OTA upgrade cancelled"];
    }
}

/**
 Reset OTA state to initial values
 */
- (void)reset {
    self.status = OTAStatusNONE;
    index_packet = 0;
    index_packet_cache = -1;
    self.isCancelled = NO;
    currentRetryCount = 0;
    self.packetArray = nil;
}

/**
 Retry transmission of current packet
 */
- (void)retryCurrentPacket {
    if (self.isCancelled) return;
    
    if (currentRetryCount < self.maxRetryCount) {
        currentRetryCount++;
        
        // Resend current packet
        if (index_packet_cache >= 0 && index_packet_cache < self.packetArray.count) {
            NSData *packetData = self.packetArray[index_packet_cache];
            if ([self.delegate respondsToSelector:@selector(onWriteBleData:)]) {
                [self.delegate onWriteBleData:packetData];
            }
            
            NSLog(@"Retrying packet %d (attempt %ld/%ld)",
                  index_packet_cache, (long)currentRetryCount, (long)self.maxRetryCount);
        }
    } else {
        // Max retries exceeded
        NSLog(@"Maximum retry attempts (%ld) exceeded for packet %d",
              (long)self.maxRetryCount, index_packet_cache);
        [self stop];
    }
}

#pragma mark - Packet Preparation Methods

/**
 Prepare first packet with file data
 
 @param data File data
 @return First packet data
 */
- (NSData *)prepareFirstPacketWithFileData:(NSData *)data {
    uint32_t length = (uint32_t)data.length;
    Byte *fileBytes = (Byte *)[data bytes];
    
    // Generate packet
    UInt8 *packetBuffer = (uint8_t *)malloc(sizeof(uint8_t) * 133);
    UInt8 *crcBuffer = (uint8_t *)malloc(sizeof(uint8_t) * 128);
    
    PrepareIntialPacket(packetBuffer, fileBytes, length);
    
    NSData *firstPacket = [NSData dataWithBytes:packetBuffer length:sizeof(uint8_t) * 133];
    
    // Free allocated memory
    free(packetBuffer);
    free(crcBuffer);
    
    return firstPacket;
}

/**
 Prepare first packet with file name and path
 
 @param filename File name
 @param filepath File path
 @return First packet data
 */
- (NSData *)autoFirstPacketWithFileName:(NSString *)filename filePath:(NSString *)filepath {
    // File name processing
    NSString *room_name = filename;
    NSData *nameData = [room_name dataUsingEncoding:NSUTF8StringEncoding];
    Byte *nameBytes = (Byte *)[nameData bytes];
    
    // File size calculation
    NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:filepath];
    uint32_t fileLength = (uint32_t)fileData.length;
    
    // Generate SOH data packet
    UInt8 *packetBuffer = (uint8_t *)malloc(sizeof(uint8_t) * 133);
    
    PrepareIntialPacket(packetBuffer, nameBytes, fileLength);
    
    NSData *firstPacket = [NSData dataWithBytes:packetBuffer length:sizeof(uint8_t) * 133];
    
    free(packetBuffer);
    
    return firstPacket;
}

/**
 Prepare data packets from file data with automatic packet splitting
 
 @param data File data
 @return Array of data packets
 */
- (NSArray *)preparePacketWithFileData:(NSData *)data {
    uint32_t packetSize = data.length >= sendSize ? sendSize : PACKET_SIZE;
    NSMutableArray *packetArray = [NSMutableArray array];
    
    for (int i = 0; i < data.length; i += packetSize) {
        int packetIndex = (i / packetSize) + 1; // Packet index starts from 1
        uint32_t dataLength = packetSize;
        
        // Handle last packet which might be smaller
        if ((data.length - i) < packetSize) {
            dataLength = (uint32_t)data.length - i;
        }
        
        // Extract packet data
        NSData *packetData = [data subdataWithRange:NSMakeRange(i, dataLength)];
        Byte *packetBytes = (Byte *)[packetData bytes];
        
        // Prepare packet
        uint8_t *packetBuffer = (uint8_t *)malloc(packetSize + 5);
        PreparePacket(packetBytes, packetBuffer, packetIndex, sendSize, (uint32_t)packetData.length);
        
        NSData *finalPacket = [NSData dataWithBytes:packetBuffer length:sizeof(uint8_t) * (packetSize + 5)];
        [packetArray addObject:finalPacket];
        
        free(packetBuffer);
    }
    
    return [packetArray copy];
}

/**
 Prepare data packets from file with automatic packet splitting
 
 @param filename File name
 @param filepath File path
 @return Array of data packets
 */
- (NSArray *)autoPacketWithFile:(NSString *)filename filePath:(NSString *)filepath {
    NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:filepath];
    uint32_t packetSize = fileData.length >= sendSize ? sendSize : PACKET_SIZE;
    NSMutableArray *packetArray = [NSMutableArray array];
    
    for (int i = 0; i < fileData.length; i += packetSize) {
        int packetIndex = (i / packetSize) + 1;
        uint32_t dataLength = packetSize;
        
        if ((fileData.length - i) < packetSize) {
            dataLength = (uint32_t)fileData.length - i;
        }
        
        NSData *packetData = [fileData subdataWithRange:NSMakeRange(i, dataLength)];
        Byte *packetBytes = (Byte *)[packetData bytes];
        
        uint8_t *packetBuffer = (uint8_t *)malloc(packetSize + 5);
        PreparePacket(packetBytes, packetBuffer, packetIndex, sendSize, (uint32_t)packetData.length);
        
        NSData *finalPacket = [NSData dataWithBytes:packetBuffer length:sizeof(uint8_t) * (packetSize + 5)];
        [packetArray addObject:finalPacket];
        
        free(packetBuffer);
    }
    
    return [packetArray copy];
}

/**
 Prepare first packet with file name (for documents directory files)
 
 @param filename File name in documents directory
 @return First packet data
 */
- (NSData *)prepareFirstPacketWithFileName:(NSString *)filename {
    if (!filename || filename.length == 0) {
        NSLog(@"Error: Invalid filename");
        return nil;
    }
    
    // File name processing
    NSString *room_name = filename;
    NSData *nameData = [room_name dataUsingEncoding:NSUTF8StringEncoding];
    if (!nameData) {
        NSLog(@"Error: Failed to encode filename");
        return nil;
    }
    
    Byte *nameBytes = (Byte *)[nameData bytes];
    
    // File size calculation - look in documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:room_name];
    
    NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:filePath];
    if (!fileData) {
        NSLog(@"Error: Failed to read file at path: %@", filePath);
        return nil;
    }
    
    uint32_t fileLength = (uint32_t)fileData.length;
    NSLog(@"Preparing first packet for file: %@, size: %u bytes", filename, fileLength);
    
    // Generate SOH data packet
    UInt8 *packetBuffer = (uint8_t *)malloc(sizeof(uint8_t) * 133);
    if (!packetBuffer) {
        NSLog(@"Error: Failed to allocate memory for packet buffer");
        return nil;
    }
    
    // Initialize buffer to zero
    memset(packetBuffer, 0, sizeof(uint8_t) * 133);
    
    PrepareIntialPacket(packetBuffer, nameBytes, fileLength);
    
    NSData *firstPacket = [NSData dataWithBytes:packetBuffer length:sizeof(uint8_t) * 133];
    
    // Free allocated memory
    free(packetBuffer);
    
    return firstPacket;
}

/**
 Prepare data packets from file in documents directory with automatic packet splitting
 
 @param filename File name in documents directory
 @return Array of data packets
 */
- (NSArray *)preparePacketWithFileName:(NSString *)filename {
    if (!filename || filename.length == 0) {
        NSLog(@"Error: Invalid filename");
        return @[];
    }
    
    // Get file from documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:filePath];
    if (!fileData) {
        NSLog(@"Error: Failed to read file at path: %@", filePath);
        return @[];
    }
    
    uint32_t packetSize = fileData.length >= sendSize ? sendSize : PACKET_SIZE;
    NSMutableArray *packetArray = [NSMutableArray array];
    
    NSLog(@"Preparing packets for file: %@, total size: %lu bytes, packet size: %u",
          filename, (unsigned long)fileData.length, packetSize);
    
    for (int i = 0; i < fileData.length; i += packetSize) {
        @autoreleasepool {
            int packetIndex = (i / packetSize) + 1; // Packet index starts from 1
            uint32_t dataLength = packetSize;
            
            // Handle last packet which might be smaller
            if ((fileData.length - i) < packetSize) {
                dataLength = (uint32_t)fileData.length - i;
            }
            
            // Extract packet data
            NSData *packetData = [fileData subdataWithRange:NSMakeRange(i, dataLength)];
            Byte *packetBytes = (Byte *)[packetData bytes];
            
            // Prepare packet
            uint8_t *packetBuffer = (uint8_t *)malloc(packetSize + 5);
            if (!packetBuffer) {
                NSLog(@"Error: Failed to allocate memory for packet buffer at index %d", packetIndex);
                continue;
            }
            
            // Initialize buffer to zero
            memset(packetBuffer, 0, packetSize + 5);
            
            PreparePacket(packetBytes, packetBuffer, packetIndex, sendSize, (uint32_t)packetData.length);
            
            NSData *finalPacket = [NSData dataWithBytes:packetBuffer length:sizeof(uint8_t) * (packetSize + 5)];
            [packetArray addObject:finalPacket];
            
            // Free allocated memory
            free(packetBuffer);
            
            // Log progress for large files
            if (packetIndex % 50 == 0) {
                NSLog(@"Prepared %d packets...", packetIndex);
            }
        }
    }
    
    NSLog(@"Total packets prepared: %lu", (unsigned long)packetArray.count);
    return [packetArray copy];
}



/**
 Prepare end packet to complete OTA upgrade
 
 @return End packet data
 */
- (NSData *)prepareEndPacket {
    UInt8 *endPacketBuffer = (uint8_t *)malloc(sizeof(uint8_t) * (PACKET_SIZE + 5));
    PrepareEndPacket(endPacketBuffer);
    NSData *endPacket = [NSData dataWithBytes:endPacketBuffer length:sizeof(uint8_t) * (PACKET_SIZE + 5)];
    free(endPacketBuffer);
    return endPacket;
}


@end
