#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface OKBleManager : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong, readonly) CBCentralManager *centralManager;
@property (nonatomic, strong, readonly) NSArray<CBPeripheral *> *discoveredDevices;

+ (instancetype)shared;

- (void)startScan:(void(^)(NSArray<CBPeripheral *> *devices))completion;
- (void)stopScan;
- (BOOL)isBluetoothAvailable;
- (CBPeripheral *)findPeripheralByUUID:(NSString *)uuid;
- (void)clearDiscoveredDevices;

@end 