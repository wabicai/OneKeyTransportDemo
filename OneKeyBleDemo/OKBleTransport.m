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
    
    self.featuresCompletion = completion;
    
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
    NSData *messageData = [OKProtobufHelper buildBuffersWithName:@"GetFeatures"
                                                        params:@{}
                                                     messages:self.messages];
    
    if (!messageData) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"OKBleTransport" 
                                             code:1004 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to build message buffer"}]);
        }
        return;
    }
    
    // Convert to base64 string and back to NSData
    NSString *base64String = [messageData base64EncodedStringWithOptions:0];
    NSData *base64Data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    
    NSLog(@"=== Buffer Data ===");
    NSLog(@"Original Buffer Length: %lu", (unsigned long)messageData.length);
    NSLog(@"Base64 Buffer Length: %lu", (unsigned long)base64Data.length);
    NSLog(@"Buffer Base64: %@", base64String);
    
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
        }
        return;
    }
    
    NSLog(@"=== Discovering characteristics ===");
    NSLog(@"Service: %@", service);
    NSLog(@"Characteristics count: %lu", (unsigned long)service.characteristics.count);
    
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
    
    // 添加更多日志
    NSLog(@"After discovery - Write characteristic: %@", self.writeCharacteristic);
    NSLog(@"After discovery - Notify characteristic: %@", self.notifyCharacteristic);
    
    if (self.writeCharacteristic && self.notifyCharacteristic) {
        NSLog(@"All required characteristics discovered");
        if (self.connectCompletion) {
            self.connectCompletion(YES);
        }
    } else {
        NSLog(@"Missing required characteristics");
        if (self.connectCompletion) {
            self.connectCompletion(NO);
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
    NSLog(@"Received value hex: %@", [self hexStringFromData:value]);
    
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
