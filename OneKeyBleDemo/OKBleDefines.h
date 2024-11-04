#import <Foundation/Foundation.h>

extern NSString *const OKBleErrorDomain;

typedef NS_ENUM(NSInteger, OKBleError) {
    OKBleErrorTimeout = -1001,
    OKBleErrorBluetoothUnavailable = -1002,
    // Add other error codes as needed
};

// Service and characteristic UUIDs
extern NSString *const kServiceUUID;
extern NSString *const kWriteUUID;
extern NSString *const kNotifyUUID;

extern const NSTimeInterval kBleOperationTimeout; 