//
//  LPScanCodeViewController.h
//  LPScanCodeDemo
//
//  Created by Leap on 2017/6/24.
//  Copyright © 2017年 leap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPScanCodeViewController : UIViewController

@property (nonatomic, copy) void(^scanResultBlock)(LPScanCodeViewController *vc, NSString *resultStr);

- (BOOL)isScaning;
- (void)startScan;
- (void)stopScan;

@end
