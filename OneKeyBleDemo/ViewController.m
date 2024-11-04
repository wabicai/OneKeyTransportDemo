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
        @"OnekeyGetFeatures": @10025,
        @"OnekeyFeatures": @10026,
        @"Features": @17
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
    
    // 创建 ScrollView
    CGFloat scrollViewY = CGRectGetMaxY(button.frame) + 20;
    CGFloat scrollViewHeight = self.view.frame.size.height - scrollViewY - 20;
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, scrollViewY, self.view.frame.size.width - 40, scrollViewHeight)];
    self.scrollView.backgroundColor = [UIColor systemGray6Color];
    self.scrollView.layer.cornerRadius = 8;
    [self.view addSubview:self.scrollView];
    
    // 创建并设置日志视图
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
    self.logTextView.editable = NO;
    self.logTextView.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.logTextView.backgroundColor = [UIColor clearColor];
    self.logTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.scrollView addSubview:self.logTextView];
}

- (void)getFeatureButtonTapped:(UIButton *)sender {
    [self appendLog:@"=== GetFeatures Request Start ==="];
    [self appendLog:@"Sending OnekeyGetFeatures request..."];
    
    [self.bleTransport call:@"982" name:@"OnekeyGetFeatures" data:@{} completion:^(id result, NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            return;
        }
        NSLog(@"result: %@", result);
        
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)result;
            [self appendLog:@"=== Response ==="];
            
            // 先显示消息类型
            NSString *type = response[@"type"];
            if (type) {
                [self appendLog:[NSString stringWithFormat:@"Type: %@", type]];
            }
            
            // 显示完整的消息内容
            NSDictionary *message = response[@"message"];
            if ([message isKindOfClass:[NSDictionary class]]) {
                [self appendLog:@"\nFeatures {"];
                
                // 按字母顺序排序键
                NSArray *sortedKeys = [[message allKeys] sortedArrayUsingSelector:@selector(compare:)];
                for (NSString *key in sortedKeys) {
                    id value = message[key];
                    NSString *formattedValue = [self formatValue:value];
                    // 缩进格式化
                    [self appendLog:[NSString stringWithFormat:@"    %@: %@", key, formattedValue]];
                }
                
                [self appendLog:@"}"];
            }
            
            [self appendLog:@"\n=== GetFeatures Request End ==="];
        }
    }];
}

- (NSString *)formatValue:(id)value {
    if ([value isKindOfClass:[NSArray class]]) {
        if ([value count] == 0) {
            return @"[]";
        }
        NSArray *array = (NSArray *)value;
        NSMutableArray *formattedItems = [NSMutableArray array];
        for (id item in array) {
            [formattedItems addObject:[self formatValue:item]];
        }
        return [NSString stringWithFormat:@"[%@]", [formattedItems componentsJoinedByString:@", "]];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)value;
        if ([dict count] == 0) {
            return @"{}";
        }
        NSMutableArray *pairs = [NSMutableArray array];
        NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (id key in sortedKeys) {
            [pairs addObject:[NSString stringWithFormat:@"%@: %@", key, [self formatValue:dict[key]]]];
        }
        return [NSString stringWithFormat:@"{ %@ }", [pairs componentsJoinedByString:@", "]];
    } else if ([value isKindOfClass:[NSData class]]) {
        NSData *data = (NSData *)value;
        const unsigned char *bytes = [data bytes];
        NSMutableString *hexString = [NSMutableString stringWithCapacity:[data length] * 2];
        for (NSInteger i = 0; i < [data length]; i++) {
            [hexString appendFormat:@"%02x", bytes[i]];
        }
        return hexString;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    } else if (value == nil || value == [NSNull null]) {
        return @"null";
    }
    return [value description];
}

- (void)appendLog:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *logMessage = [NSString stringWithFormat:@"%@\n", message];
        self.logTextView.text = [self.logTextView.text stringByAppendingString:logMessage];
        
        // 调整 logTextView 的大小以适应内容
        CGFloat fixedWidth = self.scrollView.frame.size.width;
        CGSize newSize = [self.logTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGRect newFrame = self.logTextView.frame;
        newFrame.size = CGSizeMake(fixedWidth, newSize.height);
        self.logTextView.frame = newFrame;
        self.scrollView.contentSize = CGSizeMake(fixedWidth, newSize.height);
        
        // 滚动到底部
        [self.scrollView setContentOffset:CGPointMake(0, MAX(0, newSize.height - self.scrollView.frame.size.height)) animated:YES];
    });
}

@end
