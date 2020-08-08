//
//  DFUUpdateUtil.h
//  YModemCs
//
//  Created by ardwang on 2020/8/8.
//  Copyright © 2020 GoDream. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YModem.h"

#import "DFUUpdate.h"

#import "CommonUtil.h"

//Order enum
typedef enum : NSUInteger {
    OrderStatusC,
    OrderStatusA,
    OrderStatusE,
    OrderStatusOK,
    OrderStatusNil,
} OrderStatus;



typedef enum : NSUInteger {
    DFUStatusC,
    DFUStatusA,
    DFUStatusE,
    DFUStatusOK,
} DFUStatus;

//setting protocol
@protocol DFUUpdateUtilDelegate <NSObject>

//write data
-(void)onWriteData:(NSData* _Nullable )data;

@end

NS_ASSUME_NONNULL_BEGIN

@interface DFUUpdateUtil : NSObject

@property(nonatomic, strong) CommonUtil *cmUtil;

@property (nonatomic, weak) id<DFUUpdateUtilDelegate> delegate;


- (instancetype)init:(uint32_t) size;

/**
    DFU数据发送
 */
-(void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status fileName:(NSString *)filename completion:(void(^)(NSInteger current,NSInteger total,NSString *msg, NSInteger stateq))complete;


-(void)getCRC:(NSString*)filename;

-(void)startDFUUpgrad;

-(void)stopDFUUpgrad;


@end

NS_ASSUME_NONNULL_END
