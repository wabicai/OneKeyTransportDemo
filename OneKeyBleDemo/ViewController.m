//
//  ViewController.m
//  OneKeyBleDemo
//
//  Created by 蔡凯升 on 2024/11/1.
//

#import "ViewController.h"
#import "OKBleTransport.h"

@interface ViewController ()

@property (nonatomic, strong, readwrite) OKBleTransport *bleTransport;
@property (nonatomic, strong, readwrite) UITextView *logTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"App started - viewDidLoad");
    
    // 初始化 transport
    self.bleTransport = [[OKBleTransport alloc] init];
    
    // 配置 transport
    self.bleTransport.configured = YES;
    self.bleTransport.messages = @{
        @"OnekeyGetFeatures": @10025,
        @"OnekeyFeatures": @10026
    };
    
    // 创建并设置日志视图
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 180)];
    self.logTextView.editable = NO;
    self.logTextView.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.logTextView];
    
    // 创建并设置按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Get Features" forState:UIControlStateNormal];
    button.frame = CGRectMake(50, 300, self.view.frame.size.width - 100, 44);
    [button addTarget:self action:@selector(getFeatureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置按钮样式
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8;
    
    // 添加按钮到视图
    [self.view addSubview:button];
}

- (void)getFeatureButtonTapped:(UIButton *)sender {
    [self appendLog:@"Sending GetFeatures request..."];
    
    [self.bleTransport call:@"979" name:@"OnekeyGetFeatures" data:@{} completion:^(id result, NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            return;
        }
        
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)result;
            [self appendLog:[NSString stringWithFormat:@"Response Type: %@", response[@"type"]]];
            [self appendLog:[NSString stringWithFormat:@"Message: %@", response[@"message"]]];
        }
    }];
}

- (void)appendLog:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                           dateStyle:NSDateFormatterNoStyle
                                                           timeStyle:NSDateFormatterMediumStyle];
        NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        self.logTextView.text = [self.logTextView.text stringByAppendingString:logMessage];
        
        // 滚动到底部
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    });
}

@end
