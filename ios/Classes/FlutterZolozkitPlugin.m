#import "FlutterZolozkitPlugin.h"

#import <hummer/ZLZFacade.h>
#import <hummer/ZLZRequest.h>
#import <hummer/ZLZResponse.h>
#import <hummer/ZLZHummerFacade.h>

@protocol FlutterZolozkitPluginViewControllerDelegate
- (void)onResult:(BOOL)isSuccess withResponse:(ZLZResponse *)response;
@end

@interface FlutterZolozkitPluginViewController : UIViewController
@property(nonatomic, strong) NSString *clientCfg;
@property(nonatomic, strong) NSDictionary *bizCfg;
@property(nullable, nonatomic, weak) id <FlutterZolozkitPluginViewControllerDelegate> delegate;
@end

@implementation FlutterZolozkitPluginViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    [self startZoloz];
}

- (void)startZoloz {
    NSString *clientCfg = self.clientCfg;
    NSDictionary *bizCfg = self.bizCfg;
    NSMutableDictionary *bizConfig = [[NSMutableDictionary alloc] initWithDictionary:bizCfg];
    [bizConfig setObject:self forKey:kZLZCurrentViewControllerKey];
    ZLZRequest *request = [[ZLZRequest alloc] initWithzlzConfig:clientCfg bizConfig:bizConfig];
    __weak typeof(self) weakSelf = self;
    [[ZLZFacade sharedInstance]
            startWithRequest:request
            completeCallback:^(ZLZResponse *response) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf dismissViewControllerAnimated:NO completion:^{
                        [weakSelf onResult:YES withResponse:response];
                    }];
                });
            }
           interruptCallback:^(ZLZResponse *response) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   [weakSelf dismissViewControllerAnimated:NO completion:^{
                       [weakSelf onResult:NO withResponse:response];
                   }];
               });
           }];
}

- (void)onResult:(BOOL)isSuccess withResponse:(ZLZResponse *)response {
    NSLog(@"onResult called");
    [self.delegate onResult:isSuccess withResponse:response];
}

@end


@interface FlutterZolozkitPlugin () <FlutterZolozkitPluginViewControllerDelegate>
@property(nonatomic, retain) FlutterMethodChannel *channel;
@end

@implementation FlutterZolozkitPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"com.zoloz.flutter.plugin/zolozkit"
                  binaryMessenger:[registrar messenger]];
    FlutterZolozkitPlugin *instance = [[FlutterZolozkitPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"getMetaInfo" isEqualToString:call.method]) {
        result([ZLZFacade getMetaInfo]);
    } else if ([@"getLocaleKey" isEqualToString:call.method]) {
        result(kZLZLocaleKey);
    } else if ([@"getChameleonConfigPath" isEqualToString:call.method]) {
        result(kZLZChameleonConfigKey);
    } else if ([@"getPublicKey" isEqualToString:call.method]) {
        result(kZLZPubkey);
    } else if ([@"start" isEqualToString:call.method]) {
        [self startZoloz:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)startZoloz:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *clientCfg = [call.arguments objectForKey:@"clientCfg"];
    NSDictionary *bizCfg = [call.arguments objectForKey:@"bizCfg"];
    if (!bizCfg) {
        bizCfg = @{};
    }
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    FlutterZolozkitPluginViewController *viewController = [[FlutterZolozkitPluginViewController alloc] init];
    viewController.clientCfg = clientCfg;
    viewController.bizCfg = bizCfg;
    viewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [rootViewController presentViewController:navigationController animated:NO completion:nil];
}

- (void)onResult:(BOOL)isSuccess withResponse:(ZLZResponse *)response {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:@(isSuccess) forKey:@"result"];
    [dic setObject:response.retcode forKey:@"retCode"];
    if(response.extInfo){
        [dic setObject:response.extInfo forKey:@"extInfo"];
    }
    if(isSuccess == YES){
        [self.channel invokeMethod:@"onCompleted" arguments:dic];
    }else{
        [self.channel invokeMethod:@"onInterrupted" arguments:dic];
    }
}


@end
