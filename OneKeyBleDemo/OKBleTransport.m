#import "OKBleTransport.h"
#import "OKProtobufHelper.h"
#import "OKBleManager.h"

static NSString *const kClassicServiceUUID = @"00000001-0000-1000-8000-00805f9b34fb";
static NSString *const kWriteCharacteristicUUID = @"00000002-0000-1000-8000-00805f9b34fb";
static NSString *const kNotifyCharacteristicUUID = @"00000003-0000-1000-8000-00805f9b34fb";

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

- (void)searchDevices:(void(^)(NSArray *devices))completion {
    self.searchCompletion = completion;
    [self.discoveredDevices removeAllObjects];
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kClassicServiceUUID]] 
                                              options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
}

- (void)connectDevice:(NSString *)uuid completion:(void(^)(BOOL success))completion {
    NSLog(@"=== Connecting to device ===");
    NSLog(@"Device UUID: %@", uuid);
    
    self.connectCompletion = completion;
    NSUUID *deviceUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[deviceUUID]];
    
    if (peripherals.count > 0) {
        NSLog(@"Found peripheral in system, attempting to connect");
        self.connectedPeripheral = peripherals.firstObject;
        [self.centralManager connectPeripheral:self.connectedPeripheral options:nil];
    } else {
        NSLog(@"No peripheral found with UUID: %@", uuid);
        if (completion) {
            completion(NO);
        }
    }
}

- (void)getFeatures:(NSString *)uuid completion:(void(^)(NSDictionary *features, NSError *error))completion {
    NSLog(@"=== Getting Features ===");
    NSLog(@"Device UUID: %@", uuid);
    NSLog(@"Connected Peripheral: %@", self.connectedPeripheral);
    NSLog(@"Write Characteristic: %@", self.writeCharacteristic);
    
    // 使用 weak self 避免循环引用
    __weak typeof(self) weakSelf = self;
    self.featuresCompletion = ^(NSDictionary *features, NSError *error) {
        // 在 block 内部检查 weakSelf 是否存在
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (completion) {
                completion(features, error);
            }
            return;
        }
        
        NSLog(@"Features completion called with features: %@, error: %@", features, error);
        if (completion) {
            completion(features, error);
        }
        // 完成后清空 completion block
        strongSelf.featuresCompletion = nil;
    };
    
    if (!self.connectedPeripheral) {
        NSError *error = [NSError errorWithDomain:@"OKBleTransport" 
                                           code:1001 
                                       userInfo:@{NSLocalizedDescriptionKey: @"Device not connected"}];
        self.featuresCompletion(nil, error);
        return;
    }
    
    if (!self.writeCharacteristic) {
        NSError *error = [NSError errorWithDomain:@"OKBleTransport" 
                                           code:1002 
                                       userInfo:@{NSLocalizedDescriptionKey: @"Write characteristic not available"}];
        self.featuresCompletion(nil, error);
        return;
    }
    
    NSLog(@"Building message buffer...");
    NSData *messageData = [OKProtobufHelper buildBuffersWithName:@"GetFeatures"
                                                        params:@{}
                                                     messages:self.messages];
    
    if (!messageData) {
        NSError *error = [NSError errorWithDomain:@"OKBleTransport" 
                                           code:1003 
                                       userInfo:@{NSLocalizedDescriptionKey: @"Failed to build message buffer"}];
        self.featuresCompletion(nil, error);
        return;
    }
    
    // Convert to base64 string and back to NSData
    NSString *base64String = [messageData base64EncodedStringWithOptions:0];
    NSData *base64Data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    
    NSLog(@"=== Buffer Data ===");
    NSLog(@"Original Buffer Length: %lu", (unsigned long)messageData.length);
    NSLog(@"Base64 Buffer Length: %lu", (unsigned long)base64Data.length);
    NSLog(@"Buffer Base64: %@", base64String);
    
    NSLog(@"Writing base64 value to peripheral...");
    [self.connectedPeripheral writeValue:base64Data
                      forCharacteristic:self.writeCharacteristic
                                 type:CBCharacteristicWriteWithoutResponse];
    NSLog(@"Base64 value written to peripheral");
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

// - (void)handleFeatureResponse:(NSData *)responseData {
//     if (!self.featuresCompletion) {
//         return;
//     }
    
//     NSMutableDictionary *features = [NSMutableDictionary new];
    
//     // Parse the response according to OnekeyFeatures message format
//     // This is a basic implementation - you'll need to adjust based on your exact protocol
//     if (responseData.length >= 64) {
//         // Skip header (first 6 bytes)
//         NSData *messageData = [responseData subdataWithRange:NSMakeRange(6, responseData.length - 6)];
        
//         // Parse the features - this is where you'll need to implement your specific protocol parsing
//         // Example fields based on the protocol definition:
//         features[@"onekey_device_type"] = @"classic"; // Parse from response
//         features[@"onekey_firmware_version"] = @"1.0.0"; // Parse from response
//         features[@"onekey_serial_no"] = @""; // Parse from response
//         features[@"onekey_ble_name"] = @""; // Parse from response
//     }
    
//     self.featuresCompletion(features, nil);
//     self.featuresCompletion = nil;
// }

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
        }
        return;
    }
    
    NSLog(@"=== Discovering characteristics ===");
    NSLog(@"Service: %@", service);
    NSLog(@"Characteristics: %@", service.characteristics);
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        CBUUID *uuid = characteristic.UUID;
        if ([uuid.UUIDString isEqualToString:@"0002"]) {
            self.writeCharacteristic = characteristic;
            NSLog(@"Write characteristic discovered: %@", characteristic);
        } else if ([uuid.UUIDString isEqualToString:@"0003"]) {
            self.notifyCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            NSLog(@"Notify characteristic discovered: %@", characteristic);
        }
    }
    
    if (self.writeCharacteristic && self.notifyCharacteristic) {
        NSLog(@"All required characteristics discovered");
        if (self.connectCompletion) {
            self.connectCompletion(YES);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"=== Characteristic Value Updated ===");
    NSLog(@"Characteristic: %@", characteristic);
    NSLog(@"Error: %@", error);
    
    if (error) {
        NSLog(@"Error receiving data: %@", error);
        if (self.featuresCompletion) {
            self.featuresCompletion(nil, error);
        }
        return;
    }
    
    NSData *value = characteristic.value;
    NSLog(@"Received value: %@", value);
    NSLog(@"Received value length: %lu", (unsigned long)value.length);
    NSLog(@"Received value hex: %@", [self hexStringFromData:value]);
    
    NSError *parseError;
    NSDictionary *response = [OKProtobufHelper receiveOneWithData:value messages:self.messages];
    NSLog(@"Parsed response: %@", response);
    
    if (self.featuresCompletion) {
        self.featuresCompletion(response, parseError);
    } else {
        NSLog(@"Warning: featuresCompletion block is nil");
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
