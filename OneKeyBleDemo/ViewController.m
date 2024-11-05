#import "ViewController.h"
#import "OKBleTransport.h"

@interface ViewController ()

@property (nonatomic, strong, readwrite) OKBleTransport *bleTransport;
@property (nonatomic, strong, readwrite) UITextView *logTextView;
@property (nonatomic, strong, readwrite) UIScrollView *scrollView;

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
        @"Initialize": @0,
        @"Success": @2,
        @"Features": @17,
        @"OnekeyGetFeatures": @10025,
        @"OnekeyFeatures": @10026,
    };
    
    [self setupUI];
}

- (void)setupUI {
    // 创建并设置按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Get Features" forState:UIControlStateNormal];
    button.frame = CGRectMake(20, 100, self.view.frame.size.width - 40, 44);
    [button addTarget:self action:@selector(getFeatureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置按钮样式
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8;
    
    // 添加按钮到视图
    [self.view addSubview:button];
    
    // 创建日志视图
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(button.frame) + 20, 
                                                                    self.view.frame.size.width - 40, 
                                                                    self.view.frame.size.height - 200)];
    self.scrollView.backgroundColor = [UIColor systemGray6Color];
    self.scrollView.layer.cornerRadius = 8;
    [self.view addSubview:self.scrollView];
    
    self.logTextView = [[UITextView alloc] initWithFrame:self.scrollView.bounds];
    self.logTextView.editable = NO;
    self.logTextView.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.logTextView.backgroundColor = [UIColor clearColor];
    self.logTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.scrollView addSubview:self.logTextView];
}

- (void)getFeatureButtonTapped:(UIButton *)sender {
    [self appendLog:@"=== GetFeatures Request Start ==="];
    
    [self.bleTransport call:@"dummy-session" 
                      name:@"Initialize" 
                      data:@{} 
                completion:^(id response, NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            return;
        }
        
        [self appendLog:@"=== GetFeatures Response ==="];
        [self appendLog:[NSString stringWithFormat:@"Response: %@", response]];
    }];
}

- (void)appendLog:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *logMessage = [NSString stringWithFormat:@"%@\n", message];
        self.logTextView.text = [self.logTextView.text stringByAppendingString:logMessage];
        
        CGFloat fixedWidth = self.scrollView.frame.size.width;
        CGSize newSize = [self.logTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGRect newFrame = self.logTextView.frame;
        newFrame.size = CGSizeMake(fixedWidth, newSize.height);
        self.logTextView.frame = newFrame;
        self.scrollView.contentSize = CGSizeMake(fixedWidth, newSize.height);
        
        [self.scrollView setContentOffset:CGPointMake(0, MAX(0, newSize.height - self.scrollView.frame.size.height)) animated:YES];
    });
}

@end
