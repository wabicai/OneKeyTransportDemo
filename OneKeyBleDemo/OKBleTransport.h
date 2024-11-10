#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface OKBleTransport : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, copy) NSString *baseUrl;
@property (nonatomic, assign) BOOL configured;
@property (nonatomic, assign) BOOL stopped;
@property (nonatomic, strong) NSDictionary *messages;

@property (nonatomic, strong, readonly) CBCentralManager *centralManager;
@property (nonatomic, strong, readonly) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong, readonly) CBCharacteristic *writeCharacteristic;
@property (nonatomic, strong, readonly) CBCharacteristic *notifyCharacteristic;
@property (nonatomic, strong, readonly) NSMutableArray<CBPeripheral *> *discoveredDevices;

- (void)searchDevices:(void(^)(NSArray<CBPeripheral *> *devices))completion;
- (void)connectDevice:(NSString *)uuid completion:(void(^)(BOOL success))completion;
- (void)getFeatures:(NSString *)uuid completion:(void(^)(NSDictionary *features, NSError *error))completion;
- (void)enumerateDevicesWithCompletion:(void(^)(NSArray<CBPeripheral *> *devices))completion;
- (BOOL)isOnekeyDevice:(NSString *)name;

@end 