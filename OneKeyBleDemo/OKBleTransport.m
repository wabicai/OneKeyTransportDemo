#import "OKBleTransport.h"
#import "OKProtobufHelper.h"
#import "OKBleManager.h"
@interface OKBleTransport()
@property (nonatomic, strong, readwrite) CBCentralManager *centralManager;
@property (nonatomic, strong, readwrite) CBPeripheral *peripheral;
@property (nonatomic, copy, readwrite) void (^searchCompletion)(NSArray<CBPeripheral *> *devices);
@property (nonatomic, copy) void(^connectCompletion)(BOOL success);
@property (nonatomic, copy) void(^featuresCompletion)(NSDictionary *features, NSError *error);
@property (nonatomic, strong, readwrite) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong, readwrite) CBCharacteristic *writeCharacteristic;
@property (nonatomic, strong, readwrite) CBCharacteristic *notifyCharacteristic;
@property (nonatomic, strong, readwrite) NSMutableArray<CBPeripheral *> *discoveredDevices;
@property (nonatomic, strong) dispatch_queue_t deviceQueue;
@property (nonatomic, assign) NSInteger bufferLength;
@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic, copy, readwrite) void (^currentCompletion)(NSString *response, NSError *error);
@end

@implementation OKBleTransport {
    NSMutableArray<CBPeripheral *> *_discoveredDevices;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _discoveredDevices = [[NSMutableArray alloc] init];
        _deviceQueue = dispatch_queue_create("com.onekey.ble.devicequeue", DISPATCH_QUEUE_SERIAL);
        NSLog(@"OKBleTransport initialized with empty discovered devices array");
    }
    return self;
}

- (void)searchDevices:(void(^)(NSArray<CBPeripheral *> *devices))completion {
    // 清空已发现的设备列表
    [self.discoveredDevices removeAllObjects];
    
    // 保存completion回调
    self.searchCompletion = completion;
    
    // 设置5秒后停止扫描
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.centralManager stopScan];
        if (self.searchCompletion) {
            self.searchCompletion([self.discoveredDevices copy]);
            self.searchCompletion = nil;
        }
    });
    
    // 开始扫描
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
}

- (void)connectDevice:(NSString *)uuid completion:(void(^)(BOOL success))completion {
    NSLog(@"Connecting to device with UUID: %@", uuid);
    
    NSUUID *deviceUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[deviceUUID]];
    
    if (peripherals.count > 0) {
        self.connectedPeripheral = peripherals.firstObject;
        self.connectedPeripheral.delegate = self;
        self.connectCompletion = completion;
        
        // 停止扫描并连接设备
        [self.centralManager stopScan];
        [self.centralManager connectPeripheral:self.connectedPeripheral options:nil];
    } else {
        NSLog(@"No peripheral found with UUID: %@", uuid);
        if (completion) {
            completion(NO);
        }
    }
}

- (void)getFeatures:(NSString *)uuid completion:(void(^)(NSDictionary *features, NSError *error))completion {
    [self sendRequest:@"Initialize" params:@{} completion:completion];
}

- (void)lockDevice:(NSString *)uuid completion:(void(^)(BOOL success, NSError *error))completion {
    [self sendRequest:@"LockDevice" params:@{} completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            completion(NO, error);
        } else {
            BOOL success = [response[@"type"] isEqualToString:@"Success"];
            completion(success, nil);
        }
    }];
}

- (void)sendRequest:(NSString *)command 
             params:(NSDictionary *)params 
         completion:(void(^)(NSDictionary *response, NSError *error))completion {
    NSLog(@"=== Sending Request: %@ ===", command);
    
    if (!self.connectedPeripheral) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"OKBleTransport" 
                                             code:1001 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Device not connected"}]);
        }
        return;
    }
    
    if (!self.writeCharacteristic) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"OKBleTransport" 
                                             code:1002 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Write characteristic not available"}]);
        }
        return;
    }
    
    if (!self.notifyCharacteristic) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"OKBleTransport" 
                                             code:1003 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Notify characteristic not available"}]);
        }
        return;
    }
    
    NSLog(@"Building message buffer...");
    NSData *buffer = [OKProtobufHelper buildBuffer:command 
                                          params:params 
                                       messages:self.messages];
    
    if (!buffer) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"OKBleTransport" 
                                             code:1004 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to build message buffer"}]);
        }
        return;
    }
    
    // Convert to base64 string and back to NSData
    NSString *base64String = [buffer base64EncodedStringWithOptions:0];
    NSData *base64Data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    
    NSLog(@"=== Buffer Data ===");
    NSLog(@"Original Buffer Length: %lu", (unsigned long)buffer.length);
    NSLog(@"Base64 Buffer Length: %lu", (unsigned long)base64Data.length);
    NSLog(@"Buffer Base64: %@", base64String);
    
    // Store completion handler
    self.currentCompletion = ^(NSString *response, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            // Parse response
            NSData *responseData = [response dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData 
                                                                       options:0 
                                                                         error:nil];
            completion(responseDict, nil);
        }
    };
    
    NSLog(@"Writing value to peripheral...");
    [self.connectedPeripheral writeValue:base64Data
                      forCharacteristic:self.writeCharacteristic
                                 type:CBCharacteristicWriteWithResponse];
    NSLog(@"Value written to peripheral");
}

// 添加辅助方法用于转换十六进制
- (NSString *)hexStringFromData:(NSData *)data {
    NSMutableString *string = [NSMutableString stringWithCapacity:data.length * 2];
    const unsigned char *bytes = data.bytes;
    for (NSInteger i = 0; i < data.length; i++) {
        [string appendFormat:@"%02x", bytes[i]];
    }
    return string;
}

- (void)enumerateDevicesWithCompletion:(void(^)(NSArray<CBPeripheral *> *devices))completion {
    [[OKBleManager shared] startScan:completion];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"=== BLE Transport: Found Device ===");
    NSLog(@"Device Name: %@", peripheral.name ?: @"No Name");
    NSLog(@"Device ID: %@", peripheral.identifier);
    NSLog(@"RSSI: %@", RSSI);
    NSLog(@"Advertisement Data: %@", advertisementData);
    
    // 检查是否是 OneKey 设备
    if ([self isOnekeyDevice:peripheral.name]) {
        NSLog(@"Found OneKey device: %@", peripheral.name);
        if (![self.discoveredDevices containsObject:peripheral]) {
            [self.discoveredDevices addObject:peripheral];
            NSLog(@"Added to discovered devices list. Total count: %lu", (unsigned long)self.discoveredDevices.count);
        }
    } else {
        NSLog(@"Not a OneKey device, skipping: %@", peripheral.name ?: @"No Name");
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        NSLog(@"Bluetooth is powered on");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kClassicServiceUUID]]];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristics: %@", error);
        if (self.connectCompletion) {
            self.connectCompletion(NO);
            self.connectCompletion = nil;
        }
        return;
    }
    NSLog(@"=== Characteristics ===");
    NSLog(@"Write Characteristic UUID: %@", kWriteCharacteristicUUID);
    NSLog(@"Notify Characteristic UUID: %@", kNotifyCharacteristicUUID);
    NSLog(@"Characteristics:%@", service.characteristics);
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Characteristic: %@", characteristic.UUID);

        if ([characteristic.UUID.UUIDString isEqualToString:@"0002"]) {
            self.writeCharacteristic = characteristic;
            NSLog(@"Write characteristic found: %@", characteristic.UUID);
        } else if ([characteristic.UUID.UUIDString isEqualToString:@"0003"]) {
            self.notifyCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            NSLog(@"Notify characteristic found: %@", characteristic.UUID);
        }
    }
    
    if (self.writeCharacteristic && self.notifyCharacteristic) {
        NSLog(@"All characteristics discovered successfully");
        if (self.connectCompletion) {
            self.connectCompletion(YES);
            self.connectCompletion = nil;
        }
    }else{
        NSLog(@"Missing required characteristics");
        if (self.connectCompletion) {
            self.connectCompletion(NO);
            self.connectCompletion = nil;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Characteristic update error: %@", error);
        if (self.featuresCompletion) {
            self.featuresCompletion(nil, error);
        }
        return;
    }
    
    NSData *value = characteristic.value;
    
    @try {
        // Check if this is a header chunk (first 3 bytes are 0x3f2323)
        if (value.length >= 3) {
            const uint8_t *bytes = value.bytes;
            if (bytes[0] == 0x3f && bytes[1] == 0x23 && bytes[2] == 0x23) {
                // This is a header chunk
                if (value.length >= 9) {
                    uint32_t length;
                    [value getBytes:&length range:NSMakeRange(5, 4)];
                    length = CFSwapInt32BigToHost(length);
                    self.bufferLength = length;
                    
                    NSData *dataAfterHeader = [value subdataWithRange:NSMakeRange(3, value.length - 3)];
                    self.buffer = [NSMutableData dataWithData:dataAfterHeader];
                }
            } else {
                if (!self.buffer) {
                    self.buffer = [NSMutableData new];
                }
                [self.buffer appendData:value];
            }
        }
        
        NSLog(@"Current buffer length: %lu", (unsigned long)self.buffer.length);
        NSLog(@"Expected length: %lu", (unsigned long)self.bufferLength);
        
        if (self.buffer.length >= self.bufferLength) {
            // Process complete buffer
            NSError *responseError = nil;
            NSDictionary *response = [OKProtobufHelper receiveOneWithData:self.buffer 
                                                             messages:self.messages 
                                                               error:&responseError];
            NSLog(@"hexStringFromData Buffer: %@", [self hexStringFromData:self.buffer]);
            NSLog(@"Response: %@", response);
            
            if (responseError) {
                if (self.featuresCompletion) {
                    self.featuresCompletion(nil, responseError);
                    self.featuresCompletion = nil;
                }
            } else {
                if (self.featuresCompletion) {
                    self.featuresCompletion(response, nil);
                    self.featuresCompletion = nil;
                }
            }
            
            // Reset buffer
            self.bufferLength = 0;
            self.buffer = nil;
        }
    } @catch (NSException *exception) {
        NSLog(@"Error processing characteristic update: %@", exception);
        if (self.featuresCompletion) {
            self.featuresCompletion(nil, [NSError errorWithDomain:@"OKBleTransport" 
                                                           code:1006 
                                                       userInfo:@{NSLocalizedDescriptionKey: exception.reason}]);
            self.featuresCompletion = nil;
        }
    }
}

- (BOOL)isOnekeyDevice:(NSString *)name {
    if (!name) return NO;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(BixinKey\\d{10})|(K\\d{4})|(T\\d{4})|(Touch\\s\\w{4})|(Pro\\s\\w{4})" 
                                                                         options:NSRegularExpressionCaseInsensitive 
                                                                           error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
    return range.location != NSNotFound;
}

@end 
