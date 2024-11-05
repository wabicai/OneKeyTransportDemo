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
    /**
     * from messages.proto
     * lint 81
     * enum MessageType { 
     * ...
     * MessageType_Initialize = 0 [(bitcoin_only) = true, (wire_in) = true, (wire_tiny) = true];
     * ...
     * }
     */
    
    self.bleTransport.messages = @{
        @"Initialize": @0,
        @"Success": @2,
        @"Features": @17,
        @"OnekeyGetFeatures": @10025,
        @"OnekeyFeatures": @10026,
        @"LockDevice": @24,
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
    
    // 创建 Lock Device 按钮
    UIButton *lockDeviceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [lockDeviceButton setTitle:@"Lock Device" forState:UIControlStateNormal];
    lockDeviceButton.frame = CGRectMake(20, CGRectGetMaxY(button.frame) + 20, self.view.frame.size.width - 40, 44);
    [lockDeviceButton addTarget:self action:@selector(lockDeviceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置锁按钮样式
    lockDeviceButton.backgroundColor = [UIColor systemRedColor];
    [lockDeviceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    lockDeviceButton.layer.cornerRadius = 8;
    
    // 添加锁按钮到视图
    [self.view addSubview:lockDeviceButton];
    
    // 调整 ScrollView 位置
    CGFloat scrollViewY = CGRectGetMaxY(lockDeviceButton.frame) + 20;
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
    
    // Step 1: Enumerate devices
    [self appendLog:@"Step 1: Enumerating devices..."];
    
    [self.bleTransport enumerateDevicesWithCompletion:^(NSArray *devices, NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            return;
        }
        
        if (devices.count == 0) {
            [self appendLog:@"No devices found"];
            return;
        }
        
        [self appendLog:[NSString stringWithFormat:@"Found %lu device(s)", (unsigned long)devices.count]];
        
        // Get first device
        NSDictionary *device = devices.firstObject;
        NSString *path = device[@"path"];
        NSString *session = device[@"session"];
        
        // 如果 session 为空，先尝试获取 session
        if (!session || [session isEqual:[NSNull null]]) {
            [self appendLog:@"No session found, trying to acquire one..."];
            [self.bleTransport acquireDevice:path session:@"null" completion:^(NSError *error) {
                if (error) {
                    [self appendLog:@"Failed to acquire initial session"];
                    return;
                }
                
                // 重新枚举设备以获取新的 session
                [self.bleTransport enumerateDevicesWithCompletion:^(NSArray *newDevices, NSError *error) {
                    if (error || newDevices.count == 0) {
                        [self appendLog:@"Failed to get device with session"];
                        return;
                    }
                    
                    NSDictionary *newDevice = [self findDeviceWithPath:path inDevices:newDevices];
                    if (!newDevice) {
                        [self appendLog:@"Device not found after acquiring session"];
                        return;
                    }
                    
                    NSString *newSession = newDevice[@"session"];
                    [self continueWithDevice:newDevice path:path session:newSession];
                }];
            }];
        } else {
            [self continueWithDevice:device path:path session:session];
        }
    }];
}

- (void)continueWithDevice:(NSDictionary *)device path:(NSString *)path session:(NSString *)session {
    // Step 2: Acquire device
    [self appendLog:@"\nStep 2: Acquiring device..."];
    
    [self.bleTransport acquireDevice:path session:session completion:^(NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            return;
        }
        
        [self appendLog:@"Device acquired successfully"];
        
        // Step 3: Call Initialize
        [self appendLog:@"\nStep 3: Calling Initialize..."];
        
        NSInteger sessionValue = [session integerValue];
        NSString *nextSession = [NSString stringWithFormat:@"%ld", (long)(sessionValue + 1)];
        
        [self.bleTransport call:nextSession name:@"Initialize" data:@{} completion:^(id result, NSError *error) {
            if (error) {
                [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
                [self releaseSession:nextSession];
                return;
            }
            
            if ([result isKindOfClass:[NSDictionary class]]) {
                [self handleFeatureResponse:result];
            }
            
            [self releaseSession:nextSession];
        }];
    }];
}

- (NSDictionary *)findDeviceWithPath:(NSString *)path inDevices:(NSArray *)devices {
    for (NSDictionary *device in devices) {
        if ([device[@"path"] isEqualToString:path]) {
            return device;
        }
    }
    return nil;
}

- (void)releaseSession:(NSString *)session {
    [self.bleTransport releaseSession:session completion:^(NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
        } else {
            [self appendLog:@"Session released successfully"];
        }
        [self appendLog:@"\n=== GetFeatures Request End ==="];
    }];
}

- (void)handleFeatureResponse:(NSDictionary *)response {
    [self appendLog:@"=== Response ==="];
    
    NSString *type = response[@"type"];
    if (type) {
        [self appendLog:[NSString stringWithFormat:@"Type: %@", type]];
    }
    
    NSDictionary *message = response[@"message"];
    if ([message isKindOfClass:[NSDictionary class]]) {
        [self appendLog:@"\nFeatures {"];
        NSArray *sortedKeys = [[message allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in sortedKeys) {
            id value = message[key];
            NSString *formattedValue = [self formatValue:value];
            [self appendLog:[NSString stringWithFormat:@"    %@: %@", key, formattedValue]];
        }
        [self appendLog:@"}"];
    }
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

- (void)lockDeviceButtonTapped:(UIButton *)sender {
    [self appendLog:@"=== LockDevice Request Start ==="];
    
    // Step 1: Enumerate devices
    [self appendLog:@"Step 1: Enumerating devices..."];
    
    [self.bleTransport enumerateDevicesWithCompletion:^(NSArray *devices, NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            return;
        }
        
        if (devices.count == 0) {
            [self appendLog:@"No devices found"];
            return;
        }
        
        [self appendLog:[NSString stringWithFormat:@"Found %lu device(s)", (unsigned long)devices.count]];
        
        // Get first device
        NSDictionary *device = devices.firstObject;
        NSString *path = device[@"path"];
        NSString *session = device[@"session"];
        
        // If no session, try to acquire one
        if (!session || [session isEqual:[NSNull null]]) {
            [self appendLog:@"No session found, trying to acquire one..."];
            [self.bleTransport acquireDevice:path session:@"null" completion:^(NSError *error) {
                if (error) {
                    [self appendLog:@"Failed to acquire initial session"];
                    return;
                }
                
                [self.bleTransport enumerateDevicesWithCompletion:^(NSArray *newDevices, NSError *error) {
                    if (error || newDevices.count == 0) {
                        [self appendLog:@"Failed to get device with session"];
                        return;
                    }
                    
                    NSDictionary *newDevice = [self findDeviceWithPath:path inDevices:newDevices];
                    if (!newDevice) {
                        [self appendLog:@"Device not found after acquiring session"];
                        return;
                    }
                    
                    NSString *newSession = newDevice[@"session"];
                    [self lockDeviceWithPath:path session:newSession];
                }];
            }];
        } else {
            [self lockDeviceWithPath:path session:session];
        }
    }];
}

- (void)lockDeviceWithPath:(NSString *)path session:(NSString *)session {
    // Step 2: Acquire device
    [self appendLog:@"\nStep 2: Acquiring device..."];
    
    [self.bleTransport acquireDevice:path session:session completion:^(NSError *error) {
        if (error) {
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            return;
        }
        
        [self appendLog:@"Device acquired successfully"];
        
        // Step 3: Call Initialize
        [self appendLog:@"\nStep 3: Calling Initialize..."];
        
        NSInteger sessionValue = [session integerValue];
        NSString *nextSession = [NSString stringWithFormat:@"%ld", (long)(sessionValue + 1)];
        
        [self.bleTransport call:nextSession name:@"Initialize" data:@{} completion:^(id result, NSError *error) {
            if (error) {
                [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
                [self releaseSession:nextSession];
                return;
            }
            
            if ([result isKindOfClass:[NSDictionary class]]) {
                [self handleFeatureResponse:result];
            }
            
            // Step 4: Call LockDevice
            [self appendLog:@"\nStep 4: Calling LockDevice..."];
            
            [self.bleTransport call:nextSession name:@"LockDevice" data:@{} completion:^(id lockResult, NSError *lockError) {
                if (lockError) {
                    [self appendLog:[NSString stringWithFormat:@"Error: %@", lockError.localizedDescription]];
                    [self releaseSession:nextSession];
                    return;
                }
                
                [self appendLog:@"Device locked successfully"];
                
                // Step 5: Release session
                [self appendLog:@"\nStep 5: Releasing session..."];
                [self releaseSession:nextSession];
            }];
        }];
    }];
}

@end
