#import "ViewController.h"
#import "OKBleTransport.h"
#import "OKProtobufHelper.h"

@interface ViewController ()

@property (nonatomic, strong, readwrite) OKBleTransport *bleTransport;
@property (nonatomic, strong, readwrite) UITextView *logTextView;
@property (nonatomic, strong, readwrite) UIScrollView *scrollView;
@property (nonatomic, strong, readwrite) UIButton *lockDeviceButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"App started - viewDidLoad");
    
    // 初始化 transport
    self.bleTransport = [[OKBleTransport alloc] init];
    
    // 配置 transport
    self.bleTransport.configured = YES;
    
    // 从 protobuf 自动获取消息类型
    self.bleTransport.messages = [OKProtobufHelper getAllMessageTypes];
    
    [self setupUI];
}

- (void)setupUI {
    // Search Device Button
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [searchButton setTitle:@"Search Device" forState:UIControlStateNormal];
    searchButton.frame = CGRectMake(20, 100, self.view.frame.size.width - 40, 44);
    [searchButton addTarget:self action:@selector(searchDeviceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];
    
    // Get Features Button
    UIButton *getFeaturesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [getFeaturesButton setTitle:@"Get Features" forState:UIControlStateNormal];
    getFeaturesButton.frame = CGRectMake(20, 160, self.view.frame.size.width - 40, 44);
    [getFeaturesButton addTarget:self action:@selector(getFeatureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:getFeaturesButton];
    
    // Lock Device Button
    self.lockDeviceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.lockDeviceButton setTitle:@"Lock Device" forState:UIControlStateNormal];
    self.lockDeviceButton.frame = CGRectMake(20, 220, self.view.frame.size.width - 40, 44);
    [self.lockDeviceButton addTarget:self action:@selector(lockDeviceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.lockDeviceButton];
    
    // EVM Address Button
    UIButton *evmAddressButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [evmAddressButton setTitle:@"Get EVM Address" forState:UIControlStateNormal];
    evmAddressButton.frame = CGRectMake(20, 280, self.view.frame.size.width - 40, 44);
    [evmAddressButton addTarget:self action:@selector(evmAddressButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:evmAddressButton];
    
    // Add ScrollView for logs
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 340, self.view.frame.size.width - 40, self.view.frame.size.height - 380)];
    self.scrollView.backgroundColor = [UIColor.systemGrayColor colorWithAlphaComponent:0.1];
    self.scrollView.layer.cornerRadius = 8;
    self.scrollView.clipsToBounds = YES;
    [self.view addSubview:self.scrollView];
    
    // Add TextView inside ScrollView
    self.logTextView = [[UITextView alloc] initWithFrame:self.scrollView.bounds];
    self.logTextView.editable = NO;
    self.logTextView.backgroundColor = [UIColor clearColor];
    self.logTextView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.logTextView.textColor = [UIColor labelColor];
    self.logTextView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    [self.scrollView addSubview:self.logTextView];
    
    // Set initial log text
    self.logTextView.text = @"Logs will appear here...\n";
}

- (void)searchDeviceButtonTapped:(UIButton *)sender {
    [self appendLog:@"Starting device search..."];
    [self showDeviceSelectionAlert];
}

- (void)getFeatureButtonTapped:(UIButton *)sender {
    if (!self.bleTransport.connectedPeripheral) {
        [self appendLog:@"No device connected. Please search and connect to a device first."];
        return;
    }
    
    [self appendLog:@"=== GetFeatures Request Start ==="];
    NSString *path = self.bleTransport.connectedPeripheral.identifier.UUIDString;
    [self continueWithPeripheral:self.bleTransport.connectedPeripheral path:path];
}

- (void)showDeviceSelectionAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Scanning"
                                                                 message:@"Searching for OneKey devices..."
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [self presentViewController:alert animated:YES completion:^{
        [self.bleTransport searchDevices:^(NSArray<CBPeripheral *> *devices) {
            [alert dismissViewControllerAnimated:YES completion:^{
                if (devices.count == 0) {
                    [self appendLog:@"No devices found"];
                    UIAlertController *noDevicesAlert = [UIAlertController alertControllerWithTitle:@"No Devices"
                                                                                         message:@"No OneKey devices found"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                    [noDevicesAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:noDevicesAlert animated:YES completion:nil];
                    return;
                }
                [self showDeviceList:devices];
            }];
        }];
    }];
}

- (void)showDeviceList:(NSArray<CBPeripheral *> *)devices {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Available Devices"
                                                                 message:@"Select a device to connect"
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (CBPeripheral *device in devices) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:device.name ?: @"Unknown Device"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
            [self connectToDevice:device];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)connectToDevice:(CBPeripheral *)device {
    [self appendLog:[NSString stringWithFormat:@"Connecting to device: %@", device.name]];
    [self.bleTransport connectDevice:device.identifier.UUIDString completion:^(BOOL success) {
        if (success) {
            [self appendLog:@"Device connected successfully"];
        } else {
            [self appendLog:@"Failed to connect to device"];
        }
    }];
}

- (void)continueWithPeripheral:(CBPeripheral *)peripheral path:(NSString *)path {
    [self appendLog:[NSString stringWithFormat:@"Continuing with peripheral: %@", peripheral.name]];
    [self appendLog:[NSString stringWithFormat:@"Path: %@", path]];
    
    [self.bleTransport getFeatures:path completion:^(NSDictionary *features, NSError *error) {
        if (error) {
            [self appendLog:@"=== GetFeatures Error ==="];
            [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            [self appendLog:[NSString stringWithFormat:@"Error Code: %ld", (long)error.code]];
            return;
        }
        
        if (features) {
            [self appendLog:@"=== GetFeatures Response ==="];
            [self appendLog:[NSString stringWithFormat:@"Features: %@", features]];
        } else {
            [self appendLog:@"Failed to get features: No data received"];
        }
        [self logResponse:@"GetFeatures" response:features error:error];
    }];
}

- (void)lockDeviceButtonTapped:(UIButton *)sender {
    [self appendLog:@"🔒 Lock Device button tapped"];
    [self performLockDevice];
}

- (void)performLockDevice {
    // Get the connected device UUID
    NSString *deviceUUID = self.bleTransport.connectedPeripheral.identifier.UUIDString;
    if (!deviceUUID) {
        [self appendLog:@"❌ No device connected"];
        return;
    }
    
    [self appendLog:@"🔄 Sending lock command..."];
    
    [self.bleTransport lockDevice:deviceUUID completion:^(BOOL success, NSError *error) {
        if (success) {
            [self appendLog:@"✅ Device locked successfully"];
        } else {
            [self appendLog:[NSString stringWithFormat:@"❌ Lock failed: %@", error.localizedDescription]];
        }
        [self logResponse:@"LockDevice" response:@{@"success": @(success)} error:error];
    }];
}

- (void)evmAddressButtonTapped:(UIButton *)sender {
    [self appendLog:@"📍 Get EVM Address button tapped"];
    [self performGetEvmAddress];
}

- (void)performGetEvmAddress {
    NSString *deviceUUID = self.bleTransport.connectedPeripheral.identifier.UUIDString;
    if (!deviceUUID) {
        [self appendLog:@"❌ No device connected"];
        return;
    }
    
    [self appendLog:@"🔄 Getting EVM address..."];
    
    // Convert BIP44 path string to array
    NSString *path = @"m/44'/60'/0'/1/1";
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    NSMutableArray *addressN = [NSMutableArray array];
    
    for (NSString *component in pathComponents) {
        if ([component length] == 0 || [component isEqualToString:@"m"]) {
            continue;
        }
        
        NSString *cleanComponent = [component stringByReplacingOccurrencesOfString:@"'" withString:@""];
        NSInteger value = [cleanComponent integerValue];
        
        if ([component hasSuffix:@"'"]) {
            value |= 0x80000000;
        }
        
        [addressN addObject:@(value)];
    }
    
    // Prepare parameters according to the protocol
    NSDictionary *params = @{
        @"addressNArray": addressN,
        @"showDisplay": @YES,
        @"chainId": @1  // Ethereum mainnet chain ID
    };
    
    __weak typeof(self) weakSelf = self;
    [self.bleTransport sendRequest:@"EthereumGetAddressOneKey" params:params completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            [weakSelf appendLog:[NSString stringWithFormat:@"❌ Error: %@", error.localizedDescription]];
            return;
        }
        [weakSelf appendLog:[NSString stringWithFormat:@"🔍 Response: %@", response]];
        
        // Check if we received a ButtonRequest
        if ([response[@"type"] isEqualToString:@"ButtonRequest"]) {
            [weakSelf appendLog:@"📱 Please confirm on device..."];
            
            // Send confirmation request
            [weakSelf.bleTransport sendRequest:@"ButtonAck" params:@{} completion:^(NSDictionary *addressResponse, NSError *addressError) {
                if (addressError) {
                    [weakSelf appendLog:[NSString stringWithFormat:@"❌ Error: %@", addressError.localizedDescription]];
                    return;
                }
                
                [weakSelf appendLog:@"✅ Received address response"];
                
                NSString *address = addressResponse[@"message"][@"address"];
                if (address) {
                    [weakSelf appendLog:[NSString stringWithFormat:@"✅ EVM Address: %@", address]];
                    // 创建一个新的响应字典，只包含必要的信息
                    NSDictionary *simplifiedResponse = @{
                        @"type": addressResponse[@"type"],
                        @"message": @{
                            @"address": address
                        }
                    };
                    [weakSelf logResponse:@"EthereumGetAddressOneKey" response:simplifiedResponse error:addressError];
                } else {
                    [weakSelf appendLog:@"❌ Failed to get address"];
                }
            }];
        }
    }];
}

- (void)logResponse:(NSString *)command response:(NSDictionary *)response error:(NSError *)error {
    if (error) {
        [self appendLog:[NSString stringWithFormat:@"❌ %@ Error: %@", command, error.localizedDescription]];
        return;
    }
    
    if (response) {
        [self appendLog:[NSString stringWithFormat:@"=== %@ Response ===", command]];
        
        // 创建一个新的可序列化字典
        NSMutableDictionary *serializableResponse = [NSMutableDictionary dictionary];
        
        [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSData class]]) {
                // 将 NSData 转换为 base64 字符串
                serializableResponse[key] = [(NSData *)obj base64EncodedStringWithOptions:0];
            } else if ([obj isKindOfClass:[NSDictionary class]]) {
                // 递归处理嵌套字典
                NSMutableDictionary *nestedDict = [NSMutableDictionary dictionary];
                [(NSDictionary *)obj enumerateKeysAndObjectsUsingBlock:^(id nestedKey, id nestedObj, BOOL *nestedStop) {
                    if ([nestedObj isKindOfClass:[NSData class]]) {
                        nestedDict[nestedKey] = [(NSData *)nestedObj base64EncodedStringWithOptions:0];
                    } else if ([nestedObj isKindOfClass:[NSString class]] ||
                              [nestedObj isKindOfClass:[NSNumber class]] ||
                              [nestedObj isKindOfClass:[NSNull class]] ||
                              [nestedObj isKindOfClass:[NSArray class]]) {
                        nestedDict[nestedKey] = nestedObj;
                    } else {
                        nestedDict[nestedKey] = [nestedObj description];
                    }
                }];
                serializableResponse[key] = nestedDict;
            } else if ([obj isKindOfClass:[NSString class]] ||
                      [obj isKindOfClass:[NSNumber class]] ||
                      [obj isKindOfClass:[NSNull class]] ||
                      [obj isKindOfClass:[NSArray class]]) {
                serializableResponse[key] = obj;
            } else {
                serializableResponse[key] = [obj description];
            }
        }];
        
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:serializableResponse
                                                         options:NSJSONWritingPrettyPrinted
                                                           error:&jsonError];
        if (jsonError) {
            [self appendLog:[NSString stringWithFormat:@"Response: %@", response]];
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self appendLog:jsonString];
        }
    } else {
        [self appendLog:[NSString stringWithFormat:@"❌ No %@ response received", command]];
    }
}

- (void)appendLog:(NSString *)log {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                           dateStyle:NSDateFormatterNoStyle
                                                           timeStyle:NSDateFormatterMediumStyle];
        NSString *logWithTimestamp = [NSString stringWithFormat:@"[%@] %@\n", timestamp, log];
        
        self.logTextView.text = [self.logTextView.text stringByAppendingString:logWithTimestamp];
        
        // Scroll to bottom
        CGPoint bottomOffset = CGPointMake(0, self.logTextView.contentSize.height - self.logTextView.bounds.size.height);
        if (bottomOffset.y > 0) {
            [self.logTextView setContentOffset:bottomOffset animated:YES];
        }
    });
}

@end
