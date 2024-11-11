#import "ViewController.h"
#import "OKBleTransport.h"

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
    // Search Device Button
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [searchButton setTitle:@"Search Device" forState:UIControlStateNormal];
    searchButton.frame = CGRectMake(20, 100, self.view.frame.size.width - 40, 44);
    [searchButton addTarget:self action:@selector(searchDeviceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    searchButton.backgroundColor = [UIColor systemGreenColor];
    [searchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    searchButton.layer.cornerRadius = 8;
    [self.view addSubview:searchButton];
    
    // Get Features Button
    UIButton *getFeaturesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [getFeaturesButton setTitle:@"Get Features" forState:UIControlStateNormal];
    getFeaturesButton.frame = CGRectMake(20, CGRectGetMaxY(searchButton.frame) + 20, self.view.frame.size.width - 40, 44);
    [getFeaturesButton addTarget:self action:@selector(getFeatureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    getFeaturesButton.backgroundColor = [UIColor systemBlueColor];
    [getFeaturesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    getFeaturesButton.layer.cornerRadius = 8;
    [self.view addSubview:getFeaturesButton];
    
    // Lock Device Button
    self.lockDeviceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.lockDeviceButton setTitle:@"Lock Device" forState:UIControlStateNormal];
    self.lockDeviceButton.frame = CGRectMake(20, CGRectGetMaxY(getFeaturesButton.frame) + 20, self.view.frame.size.width - 40, 44);
    [self.lockDeviceButton addTarget:self action:@selector(lockDeviceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.lockDeviceButton.backgroundColor = [UIColor systemRedColor];
    [self.lockDeviceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.lockDeviceButton.layer.cornerRadius = 8;
    [self.view addSubview:self.lockDeviceButton];
    
    // Log TextView (adjusted position)
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 
                                                                    CGRectGetMaxY(self.lockDeviceButton.frame) + 20, 
                                                                    self.view.frame.size.width - 40, 
                                                                    self.view.frame.size.height - CGRectGetMaxY(self.lockDeviceButton.frame) - 40)];
    self.scrollView.backgroundColor = [UIColor systemGrayColor];
    self.scrollView.layer.cornerRadius = 8;
    [self.view addSubview:self.scrollView];
    
    self.logTextView = [[UITextView alloc] initWithFrame:self.scrollView.bounds];
    self.logTextView.editable = NO;
    self.logTextView.backgroundColor = [UIColor clearColor];
    self.logTextView.textColor = [UIColor whiteColor];
    self.logTextView.font = [UIFont systemFontOfSize:14];
    [self.scrollView addSubview:self.logTextView];
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
    }];
}

@end
