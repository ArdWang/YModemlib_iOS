//
//  YModemUtil.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//  2025/10/15 ArdWang Update - version 2.0.0
//

#import <Foundation/Foundation.h>
#import "YModem.h"

typedef enum : NSUInteger {
    OTAStatusNONE,          // No OTA operation
    OTAStatusWaiting,       // Waiting for OTA start
    OTAStatusFirstOrder,    // First packet sent
    OTAStatusBinOrder,      // Binary data transmission in progress
    OTAStatusBinOrderDone,  // Binary data transmission completed
    OTAStatusEnd,           // OTA process ended
    OTAStatusCAN,           // OTA cancelled
    OTAStatusEOT,           // End of transmission
} OTAStatus;

typedef enum : NSUInteger {
    OrderStatusNONE,        // No order
    OrderStatusC,           // 'C' character - start transmission
    OrderStatusACK,         // Acknowledge
    OrderStatusNAK,         // Negative acknowledge
    OrderStatusCAN,         // Cancel transmission
    OrderStatusFirst,       // First packet
} OrderStatus;

@protocol YModemUtilDelegate <NSObject>

/// Write data to Bluetooth device
- (void)onWriteBleData:(NSData*) data;

@optional
/// OTA progress update
- (void)onOTAProgressUpdate:(NSInteger)current total:(NSInteger)total;
/// OTA completed
- (void)onOTACompletedWithSuccess:(BOOL)success message:(NSString *)message;

@end

@interface YModemUtil : NSObject

@property (nonatomic, weak) id<YModemUtilDelegate> delegate;

@property (nonatomic, strong) NSArray *packetArray;     // Array of data packets
@property (nonatomic, assign) OTAStatus status;         // Current OTA status
@property (nonatomic, assign) BOOL isCancelled;         // Cancellation flag
@property (nonatomic, assign) NSInteger retryCount;     // Current retry count
@property (nonatomic, assign) NSInteger maxRetryCount;  // Maximum retry attempts

/// Initialize with packet size
- (instancetype)init:(uint32_t)size;

/// Initialize with packet size and retry count
- (instancetype)initWithPacketSize:(uint32_t)size maxRetryCount:(NSInteger)maxRetry;

#pragma mark - File based OTA
/// Handle OTA data transmission with file
- (void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status
                                       fileName:(NSString *)filename
                                     completion:(void(^)(NSInteger current, NSInteger total, NSString *msg))complete;

#pragma mark - Data based OTA
/// Handle OTA data transmission with NSData
- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status
                                        fileData:(NSData *)data
                                      completion:(void(^)(NSInteger current, NSInteger total, NSString *msg))complete;

#pragma mark - Enhanced OTA with file path
/// Enhanced firmware upgrade with file path support
- (void)setFirmwareUpgrade:(OrderStatus)status
                  fileName:(NSString *)filename
                  filePath:(NSString *)filepath
                completion:(void(^)(NSInteger current, NSInteger total, NSData *data, NSString *msg))complete;

#pragma mark - Control methods
/// Stop OTA upgrade
- (void)stop;

/// Cancel OTA upgrade
- (void)cancel;

/// Reset OTA state
- (void)reset;

/// Retry current packet transmission
- (void)retryCurrentPacket;

@end
