#import "OKBleManager.h"

// Add these constants at the top of the file
static NSString *const kClassicServiceUUID = @"00000001-0000-1000-8000-00805f9b34fb";
static NSString *const kWriteCharacteristicUUID = @"00000002-0000-1000-8000-00805f9b34fb";
static NSString *const kNotifyCharacteristicUUID = @"00000003-0000-1000-8000-00805f9b34fb";

@interface OKBleManager()
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *mutableDiscoveredDevices;
@property (nonatomic, copy) void (^scanCompletion)(NSArray<CBPeripheral *> *devices);
@property (nonatomic, strong) dispatch_queue_t bleQueue;
@property (nonatomic, strong) NSLock *devicesLock;
@end

@implementation OKBleManager

+ (instancetype)shared {
    static OKBleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _bleQueue = dispatch_queue_create("com.onekey.ble.manager", DISPATCH_QUEUE_SERIAL);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_bleQueue];
        _devicesLock = [[NSLock alloc] init];
        
        // Initialize array in the serial queue
        dispatch_sync(_bleQueue, ^{
            self->_mutableDiscoveredDevices = [[NSMutableArray alloc] init];
        });
    }
    return self;
}

- (NSArray<CBPeripheral *> *)discoveredDevices {
    return [_mutableDiscoveredDevices copy];
}

- (void)startScan:(void(^)(NSArray<CBPeripheral *> *devices))completion {
    dispatch_async(self.bleQueue, ^{
        NSLog(@"=== BLE Manager: Starting device scan ===");
        NSLog(@"Current central manager state: %ld", (long)self.centralManager.state);
        
        // Clear devices in the serial queue
        if (self.mutableDiscoveredDevices) {
            [self.mutableDiscoveredDevices removeAllObjects];
        } else {
            self.mutableDiscoveredDevices = [[NSMutableArray alloc] init];
        }
        
        self.scanCompletion = completion;
        
        if (self.centralManager.state == CBManagerStatePoweredOn) {
            NSLog(@"Starting BLE scan with services");
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), self.bleQueue, ^{
                NSLog(@"Scan timeout reached, stopping scan");
                [self stopScan];
            });
        } else {
            NSLog(@"ERROR: Bluetooth is not powered on. Current state: %ld", (long)self.centralManager.state);
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@[]);
                });
            }
        }
    });
}

- (void)stopScan {
    [self.centralManager stopScan];
    if (self.scanCompletion) {
        NSArray *devices = [self.mutableDiscoveredDevices copy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.scanCompletion(devices);
        });
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"=== BLE Manager: Bluetooth state changed ===");
    switch (central.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"Bluetooth is powered ON");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Bluetooth is powered OFF");
            break;
        case CBManagerStateResetting:
            NSLog(@"Bluetooth is resetting");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"Bluetooth is unauthorized");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"Bluetooth is unsupported");
            break;
        case CBManagerStateUnknown:
            NSLog(@"Bluetooth state is unknown");
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central 
 didDiscoverPeripheral:(CBPeripheral *)peripheral 
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData 
                  RSSI:(NSNumber *)RSSI {
    dispatch_async(_bleQueue, ^{
        NSLog(@"=== Found Device ===");
        NSLog(@"Name: %@", peripheral.name ?: @"No Name");
        NSLog(@"Identifier: %@", peripheral.identifier);
        NSLog(@"RSSI: %@", RSSI);
        NSLog(@"Advertisement Data: %@", advertisementData);
        
        if (!peripheral.name.length) {
            NSLog(@"Skipping device with no name");
            return;
        }
        
        [self.devicesLock lock];
        BOOL deviceExists = NO;
        for (CBPeripheral *existingPeripheral in self.mutableDiscoveredDevices) {
            if ([existingPeripheral.identifier isEqual:peripheral.identifier]) {
                deviceExists = YES;
                NSLog(@"Device already in list: %@", peripheral.name);
                break;
            }
        }
        
        if (!deviceExists) {
            NSLog(@"Adding new device to list: %@", peripheral.name);
            [self.mutableDiscoveredDevices addObject:peripheral];
            if (self.scanCompletion) {
                NSArray *devices = [self.mutableDiscoveredDevices copy];
                NSLog(@"Current device list count: %lu", (unsigned long)devices.count);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.scanCompletion(devices);
                });
            }
        }
        [self.devicesLock unlock];
    });
}

@end 