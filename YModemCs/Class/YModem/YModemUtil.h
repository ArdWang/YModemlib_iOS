//
//  YModemUtil.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YModem.h"

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

@protocol YModemUtilDelegate <NSObject>

//writing Bluetooth data
-(void)onWriteBleData:(NSData*) data;

@end

@interface YModemUtil : NSObject

@property (nonatomic, weak) id<YModemUtilDelegate> delegate;

@property (nonatomic, strong) NSArray  *packetArray;

@property (nonatomic, assign) OTAStatus status;


//file style
-(void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status fileName:(NSString *)filename completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete;


//NSData style
- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status fileData:(NSData *)data completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete;

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

- (instancetype)init:(uint32_t)size;


@end
