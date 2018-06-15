//
//  FileOTAController.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "FileOTAController.h"
#import <QuartzCore/QuartzCore.h>
/*
 常量定义
 */
#define BACK_BUTTON_IMAGE                           @"backButton"

#define CHECKBOX_BUTTON_TAG     15
#define FILENAME_LABEL_TAG      25
#define ACTIVITY_INDICATOR_TAG  35

@interface FileOTAController ()<UITableViewDataSource, UITableViewDelegate,FileOTAViewDelegate>

@end

@implementation FileOTAController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initView];
    [self initData];
    
}


-(void)initView{
    _fileOtaView = [[FileOTAView alloc] init];
    _fileOtaView.frame = self.view.bounds;
    [self.view addSubview:_fileOtaView];
    _fileOtaView.delegate = self;
    _fileOtaView.filetableView.dataSource = self;
    _fileOtaView.filetableView.delegate = self;
}

-(void)initData{
    _commonUtil = [CommonUtil sharedManager];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    _isFileSearchFinished = NO;
    _isStackFileSelected = NO;
    _selectedFirmwareFilesArray = [NSMutableArray new];
    [self findFilesInDocumentsFolderWithFinishBlock:^(NSArray * fileListArray) {
        _firmwareFilesListArray = [[NSArray alloc] initWithArray:fileListArray];
        _isFileSearchFinished = YES;
        [_fileOtaView.filetableView reloadData];
    }];
    
}

#pragma mark
-(void)upgradeonClick{
    if (_selectedUpgradeMode == app_stack_separate) {
        if ([_fileOtaView.upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_FOR_SEPERATE_SELECTION]) {
            if (_selectedFirmwareFilesArray.count == 0) {
               
            }else{
                _isStackFileSelected = YES;
               
                [_fileOtaView.filetableView reloadData];
            }
        }else{
            if (_selectedFirmwareFilesArray.count < 2) {
               
            }else{
                [self.navigationController popViewControllerAnimated:YES];
                [self.delegate firmwareFilesSelected:_selectedFirmwareFilesArray forUpgradeMode:_selectedUpgradeMode];
            }
        }
    }else{
        if (_selectedFirmwareFilesArray.count == 0) {
            if (_selectedUpgradeMode == app_stack_combined)
            {
                
            }
        }else{
            [self.navigationController popViewControllerAnimated:YES];
            //这里执行了
            [_delegate firmwareFilesSelected:_selectedFirmwareFilesArray forUpgradeMode:_selectedUpgradeMode];
        }
    }
}

#pragma mark - Read .cyacd Files
/*!
 *  @method findFilesInDocumentsFolderWithFinishBlock
 *
 *  @discussion Method - Searches the document folder of app for .cyacd files and lists them in table
 *
 */
- (void)findFilesInDocumentsFolderWithFinishBlock:(void(^)(NSArray *))finish
{
    NSMutableArray * fileListArray = [NSMutableArray new];
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirPath = [documentPaths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:documentsDirPath error:nil];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'bin'"];
    NSArray * fileNameArray = (NSMutableArray *)[dirContents filteredArrayUsingPredicate:predicate];
    
    for (NSString * fileName in fileNameArray) {
        NSMutableDictionary * firmwareFile = [NSMutableDictionary new];
        [firmwareFile setValue:fileName forKey:FILE_NAME];
        [firmwareFile setValue:documentsDirPath forKey:FILE_PATH];
        [fileListArray addObject:firmwareFile];
    }
    if (finish) {
        finish(fileListArray);
    }
}

#pragma mark - Table View Delegates

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifiter = @"FriendCellIdentifiter";
    OTAFileCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifiter];
    if (cell == nil) {
        cell = [[OTAFileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifiter];
    }
    if (!_isFileSearchFinished) {
        [cell.checkBoxBtn setHidden:YES];
        [cell.fileLabel setHidden:YES];
    }else{
        [cell.fileLabel setHidden:NO];
        if (_firmwareFilesListArray.count == 0) {
            [cell.checkBoxBtn setHidden:YES];
            cell.fileLabel.text = LOCALIZEDSTRING(@"fileNotAvailableMessage");
        }else if (_selectedUpgradeMode == app_stack_separate &&
                  [_fileOtaView.upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_DEFAULT] &&
                  _firmwareFilesListArray.count <= 1){
            
            [cell.checkBoxBtn setHidden:YES];
            cell.fileLabel.text = LOCALIZEDSTRING(@"fileNotAvailableMessage");
        }else{
            [cell.checkBoxBtn setHidden:NO];
            [cell.checkBoxBtn setSelected:NO];
            [cell.checkBoxBtn setImage:[UIImage imageNamed:@"checkbox"] forState:UIControlStateNormal];
            
            if (_selectedUpgradeMode == app_stack_separate && _selectedFirmwareFilesArray.count == 1) {
                NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[_selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_NAME], nil]];
                NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
                if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
                    if (!_isStackFileSelected) {
                        [cell.checkBoxBtn setSelected:YES];
                        //选择box为选中 图片切换？
                        //[button setImage:[UIImage imageNamed:@"你的图片的名字"] forState:UIControlStateNormal];
                        
                        [cell.checkBoxBtn setImage:[UIImage imageNamed:@"checkbox_fill"] forState:UIControlStateSelected];
                    }
                }
            }else if (_selectedUpgradeMode == app_stack_separate && _selectedFirmwareFilesArray.count == 2){
                NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[_selectedFirmwareFilesArray objectAtIndex:1] valueForKey:FILE_NAME], nil]];
                NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
                if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
                    [cell.checkBoxBtn setSelected:YES];
                    [cell.checkBoxBtn setImage:[UIImage imageNamed:@"checkbox_fill"] forState:UIControlStateSelected];
                }
            }else if (_selectedUpgradeMode != app_stack_separate && _selectedFirmwareFilesArray.count == 1){
                NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[_selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_NAME], nil]];
                NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
                if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
                    [cell.checkBoxBtn setSelected:YES];
                    [cell.checkBoxBtn setImage:[UIImage imageNamed:@"checkbox_fill"] forState:UIControlStateSelected];
                }
            }
            
            cell.fileLabel.text = [[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME];
        }
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_firmwareFilesListArray || _firmwareFilesListArray.count == 0) {
        
        // The value is returned as one to set the "File not available" text in the table. The user must check the count of firmwareFilesListArray before adding values to the cells of table.
        return 1;
    }
    return _firmwareFilesListArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedUpgradeMode == app_stack_separate && _selectedFirmwareFilesArray.count >= 1) {
        NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[_selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_NAME], nil]];
        NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[_firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
        if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
            if (_isStackFileSelected) {
                return 0.0f;
            }
        }
    }
    return 65.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIButton * checkBoxBtn = (UIButton *) [[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:15];
    //NSLog(@"indexpath is %d",indexPath.row);
    [self checkBoxButtonClicked:checkBoxBtn rowAtIndexPath:indexPath];
    
}

- (void)checkBoxButtonClicked:(UIButton *)sender rowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isFileSearchFinished && _firmwareFilesListArray.count > 0 ) {
        if (!_selectedFirmwareFilesArray) {
            _selectedFirmwareFilesArray = [NSMutableArray new];
        }
        
        if(sender.selected)
        {
            if ([_fileOtaView.filetableView cellForRowAtIndexPath:indexPath].tag == _selectedFirmwareFilesArray.count)
                [_selectedFirmwareFilesArray removeObjectAtIndex:[_fileOtaView.filetableView cellForRowAtIndexPath:indexPath].tag-1];
            else
                [_selectedFirmwareFilesArray removeObjectAtIndex:[_fileOtaView.filetableView cellForRowAtIndexPath:indexPath].tag];
            
            [_fileOtaView.filetableView reloadData];
            
        }else{
            if (_selectedUpgradeMode == app_stack_separate && [_fileOtaView.upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_DEFAULT] && _selectedFirmwareFilesArray.count == 2) {
                [_selectedFirmwareFilesArray removeObjectAtIndex:1];
            }else if ((_selectedFirmwareFilesArray.count == 1 && _selectedUpgradeMode != app_stack_separate) || (_selectedUpgradeMode == app_stack_separate  && [_fileOtaView.upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_FOR_SEPERATE_SELECTION] && _selectedFirmwareFilesArray.count == 1)){
                [_selectedFirmwareFilesArray removeObjectAtIndex:0];
            }
            if (_selectedFirmwareFilesArray.count < 2) {
                if((_selectedUpgradeMode == app_stack_separate && _isStackFileSelected) || (_selectedFirmwareFilesArray.count == 0)){
                    [_fileOtaView.filetableView cellForRowAtIndexPath:indexPath].tag = _selectedFirmwareFilesArray.count;
                    [_selectedFirmwareFilesArray addObject:[_firmwareFilesListArray objectAtIndex:indexPath.row]];
                }
            }
            [_fileOtaView.filetableView reloadData];
        }
    }
    
}


@end
