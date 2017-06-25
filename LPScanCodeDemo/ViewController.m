//
//  ViewController.m
//  LPScanCodeDemo
//
//  Created by Leap on 2017/6/24.
//  Copyright © 2017年 leap. All rights reserved.
//

#import "ViewController.h"
#import "LPScanCodeViewController.h"
#import "LPQRCodeTool.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIImageView *im = [[UIImageView alloc]initWithFrame:CGRectMake(0, 40, 100, 100)];
//    im.image = [LPQRCodeTool generateWithDefaultQRCodeData:@"lplplplpplplplplpplpl" imageViewWidth:1000];
    
    im.image = [LPQRCodeTool generateWithColorQRCodeData:@"sdfsfsds" backgroundColor:[CIColor colorWithCGColor:[UIColor redColor].CGColor] mainColor:[CIColor colorWithCGColor:[UIColor blueColor].CGColor]];
    [self.view addSubview:im];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self presentViewController:[LPScanCodeViewController new] animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
