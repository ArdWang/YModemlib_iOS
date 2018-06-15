//
//  BTAlertController.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//
#import "BTAlertController.h"

@interface BTAlertController ()

@end

@implementation BTAlertController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.closeGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeAlert:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIView *superView = self.view.superview;
    if (![superView.gestureRecognizers containsObject:self.closeGesture]) {
        [superView addGestureRecognizer:self.closeGesture];
        superView.userInteractionEnabled = YES;
    }
}

- (void)closeAlert:(UITapGestureRecognizer *) gesture{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
