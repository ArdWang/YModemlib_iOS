//
//  FileOTAController.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileOTAView.h"
#import "OTAFileCell.h"
#import "CommonUtil.h"
#import "Constants.h"

#define FILE_NAME       @"FileName"
#define FILE_PATH       @"FilePath"

typedef enum{
    app_upgrade,
    app_stack_combined,
    app_stack_separate
}OTAModel;

@protocol FirmwareFileSelectionDelegate <NSObject>

@required

- (void)firmwareFilesSelected:(NSArray *)selectedFilesArray forUpgradeMode:(OTAModel)selectedMode;

@end

@interface FileOTAController : UIViewController

@property (strong, nonatomic) id <FirmwareFileSelectionDelegate> delegate;

@property OTAModel selectedUpgradeMode;

@property(strong,nonatomic) FileOTAView *fileOtaView;

@property(strong,nonatomic) CommonUtil *commonUtil;

@property(strong,nonatomic) NSMutableArray * selectedFirmwareFilesArray;

@property(strong,nonatomic) NSArray * firmwareFilesListArray;

@property(nonatomic) BOOL isFileSearchFinished, isStackFileSelected;

///------------------


@end

