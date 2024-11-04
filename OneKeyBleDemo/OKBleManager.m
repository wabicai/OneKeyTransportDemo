#import "OKBleManager.h"
#import "OKBleDefines.h"

@interface OKBleManager ()

@property (nonatomic, copy) void(^scanCompletion)(NSArray<CBPeripheral *> *peripherals, NSError *error);
@property (nonatomic, copy) void(^connectCompletion)(NSError *error);
@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *discoveredPeripherals;

@end

@implementation OKBleManager

+ (instancetype)shared {
    static OKBleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OKBleManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.discoveredPeripherals = [NSMutableArray array];
    }
    return self;
}

- (void)startScanWithCompletion:(void(^)(NSArray<CBPeripheral *> *peripherals, NSError *error))completion {
    self.scanCompletion = completion;
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        [self startScan];
    }
}

- (void)startScan {
    [self.discoveredPeripherals removeAllObjects];
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    [self.centralManager scanForPeripheralsWithServices:@[serviceUUID] options:nil];
}

- (void)stopScan {
    [self.centralManager stopScan];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral completion:(void(^)(NSError *error))completion {
    self.connectCompletion = completion;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        if (self.scanCompletion) {
            [self startScan];
        }
    } else {
        if (self.scanCompletion) {
            NSError *error = [NSError errorWithDomain:OKBleErrorDomain code:OKBleErrorBluetoothUnavailable userInfo:@{NSLocalizedDescriptionKey: @"Bluetooth is not available"}];
            self.scanCompletion(nil, error);
        }
    }
}

- (void)centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                   RSSI:(NSNumber *)RSSI {

    // Filter devices based on name as per js-sdk
    NSString *name = peripheral.name;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(BixinKey\\d{10})|(K\\d{4})|(T\\d{4})|(Touch\\s\\w{4})|(Pro\\s\\w{4})" options:NSRegularExpressionCaseInsensitive error:nil];

    if (name.length > 0 && [regex numberOfMatchesInString:name options:0 range:NSMakeRange(0, name.length)] > 0) {
        if (![self.discoveredPeripherals containsObject:peripheral]) {
            [self.discoveredPeripherals addObject:peripheral];
        }

        // Stop scanning after finding a device
        [self stopScan];
        if (self.scanCompletion) {
            self.scanCompletion(self.discoveredPeripherals, nil);
            self.scanCompletion = nil;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if (self.connectCompletion) {
        self.connectCompletion(nil);
        self.connectCompletion = nil;
    }
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (self.connectCompletion) {
        self.connectCompletion(error);
        self.connectCompletion = nil;
    }
}

@end 