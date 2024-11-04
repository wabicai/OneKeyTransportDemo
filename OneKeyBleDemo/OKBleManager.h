#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface OKBleManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (instancetype)shared;

@property (nonatomic, strong) CBCentralManager *centralManager;

- (void)startScanWithCompletion:(void(^)(NSArray<CBPeripheral *> *peripherals, NSError *error))completion;
- (void)stopScan;

- (void)connectPeripheral:(CBPeripheral *)peripheral completion:(void(^)(NSError *error))completion;

@end 