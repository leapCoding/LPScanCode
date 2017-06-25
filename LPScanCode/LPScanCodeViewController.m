//
//  LPScanCodeViewController.m
//  LPScanCodeDemo
//
//  Created by Leap on 2017/6/24.
//  Copyright © 2017年 leap. All rights reserved.
//
#define kScreen_Width CGRectGetWidth([UIScreen mainScreen].bounds)
#define kScreen_Height CGRectGetHeight([UIScreen mainScreen].bounds)

#import "LPScanCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface ScanBGView : UIView
@property (assign, nonatomic) CGRect scanRect;
@end

@implementation ScanBGView
- (void)setBackgroundColor:(UIColor *)backgroundColor{
    super.backgroundColor = backgroundColor;
    [self setNeedsDisplay];
}

- (void)setScanRect:(CGRect)scanRect{
    _scanRect = scanRect;
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    [[UIColor clearColor] setFill];
    CGContextFillRect(context, rect);
    
    [self.backgroundColor setFill];
    CGRect topRect = CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetMinY(_scanRect));
    CGRect bottomRect = CGRectMake(0, CGRectGetMaxY(_scanRect), CGRectGetWidth(bounds), CGRectGetHeight(bounds) - CGRectGetMaxY(_scanRect));
    CGRect leftRect = CGRectMake(0, CGRectGetMinY(_scanRect), CGRectGetMinX(_scanRect), CGRectGetHeight(_scanRect));
    CGRect rightRect = CGRectMake(CGRectGetMaxX(_scanRect), CGRectGetMinY(_scanRect), CGRectGetWidth(bounds) - CGRectGetMaxX(_scanRect), CGRectGetHeight(_scanRect));
    
    CGContextAddRect(context, topRect);
    CGContextAddRect(context, bottomRect);
    CGContextAddRect(context, leftRect);
    CGContextAddRect(context, rightRect);
    
    CGContextFillPath(context);
}

@end


@interface LPScanCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) CIDetector *detector;

@property (nonatomic, strong) ScanBGView *myScanBGView;
@property (nonatomic, strong) UIImageView *scanRectView, *lineView;
@property (nonatomic, strong) UIButton *backButton, *flashlightButton;

@end

@implementation LPScanCodeViewController

- (void)dealloc {
    [self.videoPreviewLayer removeFromSuperlayer];
    self.videoPreviewLayer = nil;
    [self scanLineStopAction];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_videoPreviewLayer) {
        [self configUI];
    }else{
        [self startScan];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopScan];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)configUI {
    
    CGFloat width = kScreen_Width * 2 / 3;
    CGFloat padding = (kScreen_Width - width) / 2;
    CGRect scanRect = CGRectMake(padding, (kScreen_Height - width - 64 - 50) / 2, width, width);
    
    if (!_videoPreviewLayer) {
        NSError *error;
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        if (!input) {
            NSLog(@"%@",error.localizedDescription);
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }else {
            //设置会话的输入设备
            AVCaptureSession *captureSession = [AVCaptureSession new];
            [captureSession addInput:input];
            //对应输出
            AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
            [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            [captureSession addOutput:captureMetadataOutput];
            
            if (![captureMetadataOutput.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
                NSLog(@"摄像头不支持扫描二维码！");
            }else{
                [captureMetadataOutput setMetadataObjectTypes:captureMetadataOutput.availableMetadataObjectTypes];
            }

            
            captureMetadataOutput.rectOfInterest = CGRectMake(CGRectGetMinY(scanRect)/CGRectGetHeight(self.view.frame),
                                                              1 - CGRectGetMaxX(scanRect)/CGRectGetWidth(self.view.frame),
                                                              CGRectGetHeight(scanRect)/CGRectGetHeight(self.view.frame),
                                                              CGRectGetWidth(scanRect)/CGRectGetWidth(self.view.frame));//设置扫描区域。。默认是手机头向左的横屏坐标系（逆时针旋转90度）
            //将捕获的数据流展现出来
            _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
            [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            [_videoPreviewLayer setFrame:self.view.bounds];
        }
    }
    
    if (!_myScanBGView) {
        _myScanBGView = [[ScanBGView alloc] initWithFrame:self.view.bounds];
        _myScanBGView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _myScanBGView.scanRect = scanRect;
    }
    
    if (!_scanRectView) {
        _scanRectView = [[UIImageView alloc] initWithFrame:scanRect];
        _scanRectView.image = [[UIImage imageNamed:@"img-scFrame"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 25, 25)];
        _scanRectView.clipsToBounds = YES;
    }
    
    if (!_lineView) {
        UIImage *lineImage = [UIImage imageNamed:@"img-scline"];
        CGFloat lineHeight = 2;
        CGFloat lineWidth = CGRectGetWidth(_scanRectView.frame);
        _lineView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -lineHeight, lineWidth, lineHeight)];
        _lineView.contentMode = UIViewContentModeScaleToFill;
        _lineView.image = lineImage;
    }
    
    if (!_backButton) {
        _backButton = [[UIButton alloc]initWithFrame:CGRectMake(10, 20, 44, 44)];
        [_backButton setImage:[UIImage imageNamed:@"code-topBack"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!_flashlightButton) {
        _flashlightButton = [[UIButton alloc]initWithFrame:CGRectMake(kScreen_Width-54, 20, 44, 44)];
        [_flashlightButton setImage:[UIImage imageNamed:@"icon-FlashOpen"] forState:UIControlStateNormal];
        [_flashlightButton addTarget:self action:@selector(flashLight) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [_scanRectView addSubview:_lineView];
    [self.view.layer addSublayer:_videoPreviewLayer];
    [self.view addSubview:_myScanBGView];
    [self.view addSubview:_scanRectView];
    [self.view addSubview:_backButton];
    [self.view addSubview:_flashlightButton];
    [_videoPreviewLayer.session startRunning];
    [self scanLineStartAction];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)flashLight {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if (device.torchMode == AVCaptureTorchModeOff) {
        [device setTorchMode: AVCaptureTorchModeOn];
        [_flashlightButton setImage:[UIImage imageNamed:@"icon-FlashClose"] forState:UIControlStateNormal];
    }else{
        [device setTorchMode: AVCaptureTorchModeOff];
        [_flashlightButton setImage:[UIImage imageNamed:@"icon-FlashOpen"] forState:UIControlStateNormal];
    }
    [device unlockForConfiguration];
}

- (void)scanLineStartAction{
    [self scanLineStopAction];
    
    CABasicAnimation *scanAnimation = [CABasicAnimation animationWithKeyPath:@"position.y"];
    scanAnimation.fromValue = @(-CGRectGetHeight(_lineView.frame));
    scanAnimation.toValue = @(CGRectGetHeight(_lineView.frame) + CGRectGetHeight(_scanRectView.frame));
    
    scanAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scanAnimation.repeatCount = CGFLOAT_MAX;
    scanAnimation.duration = 2.0;
    [self.lineView.layer addAnimation:scanAnimation forKey:@"basic"];
}

- (void)scanLineStopAction{
    [self.lineView.layer removeAllAnimations];
}

#pragma mark Photo
- (BOOL)checkPhotoLibraryAuthorizationStatus
{
    if ([ALAssetsLibrary respondsToSelector:@selector(authorizationStatus)]) {
        ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
        if (ALAuthorizationStatusDenied == authStatus ||
            ALAuthorizationStatusRestricted == authStatus) {
            NSLog(@"请在iPhone的“设置->隐私->照片”中打开本应用的访问权限");
            return NO;
        }
    }
//    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
//    if (status == PHAuthorizationStatusRestricted ||
//        status == PHAuthorizationStatusDenied) {
//        NSLog(@"请在iPhone的“设置->隐私->照片”中打开本应用的访问权限");
//        return NO;
//    }
    return YES;
}

-(void)clickRightBarButton{
    if (![self checkPhotoLibraryAuthorizationStatus]) {
        return;
    }
    //停止扫描
    [self stopScan];
    
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self handleImageInfo:info];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleImageInfo:(NSDictionary *)info{
    //停止扫描
    [self stopScan];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    __block NSString *resultStr = nil;
    NSArray *features = [self.detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    [features enumerateObjectsUsingBlock:^(CIQRCodeFeature *obj, NSUInteger idx, BOOL *stop) {
        if (obj.messageString.length > 0) {
            resultStr = obj.messageString;
            *stop = YES;
        }
    }];
    //震动反馈
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    //交给 block 处理
    if (_scanResultBlock) {
        _scanResultBlock(self, resultStr);
    }
    NSLog(@"-----%@",resultStr);
}



#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"%@",metadataObjects);
    //判断是否有数据，是否是二维码数据
    if (metadataObjects.count > 0) {
        __block AVMetadataMachineReadableCodeObject *result = nil;
        [metadataObjects enumerateObjectsUsingBlock:^(AVMetadataMachineReadableCodeObject *obj, NSUInteger idx, BOOL *stop) {
            if ([obj.type isEqualToString:AVMetadataObjectTypeQRCode]) {
                result = obj;
                *stop = YES;
            }
        }];
        if (!result) {
            result = [metadataObjects firstObject];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self analyseResult:result];
        });
    }
}

- (void)analyseResult:(AVMetadataMachineReadableCodeObject *)result {
    if (![result isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
        return;
    }
    NSString *resultStr = result.stringValue;
    if (resultStr.length <= 0) {
        return;
    }
    NSLog(@"-----%@",resultStr);
    //停止扫描
    [self stopScan];
}



#pragma mark Notification
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self startScan];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self stopScan];
}

#pragma mark public
- (BOOL)isScaning{
    return _videoPreviewLayer.session.isRunning;
}
- (void)startScan{
    [self.videoPreviewLayer.session startRunning];
    [self scanLineStartAction];
}
- (void)stopScan{
    [self.videoPreviewLayer.session stopRunning];
    [self scanLineStopAction];
}


- (CIDetector *)detector{
    if (!_detector) {
        _detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    }
    return _detector;
}

@end
