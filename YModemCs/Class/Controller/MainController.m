//
//  MainController.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//  ArdWang 2025/10/15 Update

#import "MainController.h"

@interface MainController ()<MainViewDelegate,YModemUtilDelegate,FirmwareFileSelectionDelegate>

@end

@implementation MainController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self initializeYModemUtil];
    [self setupNotifications];
}

- (void)dealloc {
    // Remove notification observers to prevent memory leaks
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup Methods

/**
 Initialize and configure the user interface
 */
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Initialize main view
    self.mainView = [MainView new];
    [self.view addSubview:self.mainView];
    self.mainView.frame = self.view.bounds;
    self.mainView.delegate = self;
    
    // Set navigation title
    self.title = @"Firmware Upgrade";
}

/**
 Initialize YModem utility with configuration
 */
- (void)initializeYModemUtil {
    // Initialize YModem utility with packet size (default 1024 bytes)
    self.ymodemUtil = [[YModemUtil alloc] initWithPacketSize:1024 maxRetryCount:3];
    self.ymodemUtil.delegate = self;
}

/**
 Setup notification observers for OTA process and Bluetooth events
 */
- (void)setupNotifications {
    // Observe OTA completion notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(otaCompletion:)
                                               name:@"otaNofiction"
                                             object:nil];
    
    // Observe Bluetooth disconnection notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(disContentBle:)
                                               name:@"disNofiction"
                                             object:nil];
}

#pragma mark - Notification Handlers

/**
 Handle OTA data transmission notifications
 
 @param notification Notification containing OTA command data
 */
- (void)otaCompletion:(NSNotification *)notification {
    NSDictionary *ota = [notification userInfo];
    NSString *otaData = [ota objectForKey:@"otaData"];
    
    // Convert notification data to OrderStatus
    [self parseOTACommand:otaData];
    
    __weak typeof(self) weakSelf = self;
    
    // Method 1: Traditional file-based OTA (using file name only)
    [self.ymodemUtil setFirmwareHandleOTADataWithOrderStatus:self.orderStatus
                                                    fileName:self.fileName
                                                  completion:^(NSInteger current, NSInteger total, NSString *msg) {
        [weakSelf handleOTAProgressWithCurrent:current total:total message:msg];
    }];
    
    // Method 2: Enhanced OTA with file path support (recommended)
    [self.ymodemUtil setFirmwareUpgrade:self.orderStatus
                               fileName:self.fileName
                               filePath:self.filePath
                             completion:^(NSInteger current, NSInteger total, NSData *data, NSString *message) {
        [weakSelf handleEnhancedOTAProgressWithCurrent:current total:total data:data message:message];
    }];
}

/**
 Parse OTA command string and convert to OrderStatus enum
 
 @param otaCommand String representation of OTA command
 */
- (void)parseOTACommand:(NSString *)otaCommand {
    if ([otaCommand isEqual:OTAC]) {
        self.orderStatus = OrderStatusC;        // Start transmission command
    } else if ([otaCommand isEqual:OTASTART]) {
        self.orderStatus = OrderStatusFirst;    // First packet command
    } else if ([otaCommand isEqual:OTAACK]) {
        self.orderStatus = OrderStatusACK;      // Acknowledge command
    } else if ([otaCommand isEqual:OTANAK]) {
        self.orderStatus = OrderStatusNAK;      // Negative acknowledge command
    } else if ([otaCommand isEqual:OTACA]) {
        self.orderStatus = OrderStatusCAN;      // Cancel transmission command
    }
}

/**
 Handle Bluetooth disconnection notification
 
 @param notification Disconnection notification
 */
- (void)disContentBle:(NSNotification *)notification {
    // Navigate back to main view controller when Bluetooth disconnects
    [self navigateToMainViewController];
}

#pragma mark - OTA Progress Handlers

/**
 Handle OTA progress updates for traditional file-based method
 
 @param current Current packet index
 @param total Total number of packets
 @param message Status message
 */
- (void)handleOTAProgressWithCurrent:(NSInteger)current total:(NSInteger)total message:(NSString *)message {
    [self updateProgressUIWithCurrent:current total:total message:message];
}

/**
 Handle OTA progress updates for enhanced file path method
 
 @param current Current packet index
 @param total Total number of packets
 @param data Data to be sent to Bluetooth device
 @param message Status message
 */
- (void)handleEnhancedOTAProgressWithCurrent:(NSInteger)current total:(NSInteger)total data:(NSData *)data message:(NSString *)message {
    // Update progress UI
    [self updateProgressUIWithCurrent:current total:total message:message];
    
    // Send data to Bluetooth device if available
    // This eliminates the need for delegate method in some cases
    if (data.length > 0) {
        [[BlueHelp sharedManager] wirteBleOTAData:data];
    }
}

/**
 Update user interface with OTA progress information
 
 @param current Current packet index
 @param total Total number of packets
 @param message Status message
 */
- (void)updateProgressUIWithCurrent:(NSInteger)current total:(NSInteger)total message:(NSString *)message {
    float progress = (float)current / total;
    
    if (progress <= 1.0) {
        if (self.mainView.downLoadView.musicalProgress <= 1.0) {
            self.mainView.downLoadView.musicalProgress = progress;
            
            // Update progress bar at 5% intervals for performance
            if ((int)(self.mainView.downLoadView.musicalProgress * 100) % 5 == 0) {
                [self.mainView.downLoadView startDownLoad];
            }
        } else {
            self.mainView.downLoadView.musicDownLoadLab.text = @"Upgrade Complete!";
        }
    }
    
    // Update status message if available
    if (message && ![message isEqualToString:@""]) {
        self.mainView.downLoadView.musicDownLoadLab.text = message;
    }
}

#pragma mark - MainViewDelegate Methods

/**
 Handle OTA button click event
 */
- (void)otaOnClick {
    // Send OTA start command to Bluetooth device
    // The specific command (0x05) depends on your Bluetooth protocol requirements
    [[BlueHelp sharedManager] writeBlueOTA:@"0x05"];
    
    // Alternative: You can also start OTA process directly
    // [self.ymodemUtil setFirmwareUpgrade:OrderStatusC fileName:self.fileName filePath:self.filePath completion:...];
}

/**
 Handle file selection button click event
 */
- (void)selectOnClick {
    FileOTAController *fileController = [[FileOTAController alloc] init];
    fileController.delegate = self;
    fileController.title = @"Select Firmware File";
    [self.navigationController pushViewController:fileController animated:YES];
}

/**
 Handle cancel OTA button click event
 */
- (void)cancelOnClick {
    // Cancel ongoing OTA process
    [self.ymodemUtil cancel];
    
    // Update UI to show cancellation
    self.mainView.downLoadView.musicDownLoadLab.text = @"Upgrade Cancelled";
    self.mainView.downLoadView.musicalProgress = 0.0;
    [self.mainView.downLoadView startDownLoad];
}

/**
 Handle retry OTA button click event
 */
- (void)retryOnClick {
    // Retry current packet transmission
    [self.ymodemUtil retryCurrentPacket];
    
    self.mainView.downLoadView.musicDownLoadLab.text = @"Retrying...";
}

#pragma mark - YModemUtilDelegate Methods

/**
 Delegate method called when data needs to be written to Bluetooth device
 
 @param data Data to be sent to Bluetooth device
 */
- (void)onWriteBleData:(NSData *)data {
    // Send data to terminal device via Bluetooth
    [[BlueHelp sharedManager] wirteBleOTAData:data];
}

/**
 Delegate method for OTA progress updates
 
 @param current Current progress value
 @param total Total value
 */
- (void)onOTAProgressUpdate:(NSInteger)current total:(NSInteger)total {
    // This delegate method can be used as an alternative to completion blocks
    [self updateProgressUIWithCurrent:current total:total message:nil];
}

/**
 Delegate method for OTA completion
 
 @param success YES if OTA completed successfully, NO otherwise
 @param message Completion message
 */
- (void)onOTACompletedWithSuccess:(BOOL)success message:(NSString *)message {
    if (success) {
        self.mainView.downLoadView.musicDownLoadLab.text = @"Upgrade Completed Successfully!";
        self.mainView.downLoadView.musicalProgress = 1.0;
    } else {
        self.mainView.downLoadView.musicDownLoadLab.text = message ?: @"Upgrade Failed";
    }
    [self.mainView.downLoadView startDownLoad];
}

#pragma mark - FileSelectionDelegate Methods

/**
 Handle firmware file selection from file browser
 
 @param selectedFilesArray Array of selected firmware files
 @param selectedMode OTA mode (single file, batch, etc.)
 */
- (void)firmwareFilesSelected:(NSArray *)selectedFilesArray forUpgradeMode:(OTAModel)selectedMode {
    if (selectedFilesArray && selectedFilesArray.count > 0) {
        _firmwareFilesArray = [[NSArray alloc] initWithArray:selectedFilesArray];
        [self startParsingFirmwareFile:[_firmwareFilesArray firstObject]];
    } else {
        // Show error if no files selected
        [self showAlertWithTitle:@"No File Selected" message:@"Please select a firmware file to upgrade."];
    }
}

/**
 Parse and prepare selected firmware file for OTA upgrade
 
 @param firmwareFile Dictionary containing file information
 */
- (void)startParsingFirmwareFile:(NSDictionary *)firmwareFile {
    self.fileName = [firmwareFile objectForKey:@"FileName"];
    self.filePath = [firmwareFile objectForKey:@"FilePath"];
    
    // Update UI with selected file name
    self.mainView.downLoadView.musicDownLoadLab.text = [NSString stringWithFormat:@"Selected: %@", self.fileName];
    
    // Reset progress for new file
    self.mainView.downLoadView.musicalProgress = 0.0;
    [self.mainView.downLoadView startDownLoad];
    
    NSLog(@"Selected firmware file: %@ at path: %@", self.fileName, self.filePath);
}

#pragma mark - Navigation Methods

/**
 Navigate back to main view controller
 */
- (void)navigateToMainViewController {
    UIViewController *targetViewController = nil;
    
    // Find ViewController in navigation stack
    for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[ViewController class]]) {
            targetViewController = controller;
            break;
        }
    }
    
    if (targetViewController) {
        [self.navigationController popToViewController:targetViewController animated:YES];
    }
}

/**
 Handle back button press in navigation bar
 
 @return YES to allow pop, NO to prevent
 */
- (BOOL)navigationShouldPopOnBackButton {
    // Disconnect Bluetooth and stop upgrade when leaving the screen
    [[BlueHelp sharedManager] disContentBle];
    
    // Cancel any ongoing OTA process
    [self.ymodemUtil cancel];
    
    return YES;
}

#pragma mark - Utility Methods

/**
 Show alert dialog with title and message
 
 @param title Alert title
 @param message Alert message
 */
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 Reset OTA state and UI
 */
- (void)resetOTAState {
    [self.ymodemUtil reset];
    self.mainView.downLoadView.musicalProgress = 0.0;
    self.mainView.downLoadView.musicDownLoadLab.text = @"Ready for Upgrade";
    [self.mainView.downLoadView startDownLoad];
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Clear firmware files array if memory is low
    if (_firmwareFilesArray) {
        _firmwareFilesArray = nil;
    }
}

@end
