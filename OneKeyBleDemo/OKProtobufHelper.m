#import "OKProtobufHelper.h"

@implementation OKProtobufHelper


+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error {
    if (!data || data.length < 6) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid data length"}];
        }
        return nil;
    }
    
    // Read message type
    uint16_t type = 0;
    [data getBytes:&type range:NSMakeRange(0, sizeof(type))];
    type = CFSwapInt16BigToHost(type);
    
    // Read data length
    uint32_t length = 0;
    [data getBytes:&length range:NSMakeRange(2, sizeof(length))];
    length = CFSwapInt32BigToHost(length);
    
    // Validate data length
    NSUInteger totalLength = 6 + length;
    if (data.length < totalLength) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Data length mismatch"}];
        }
        return nil;
    }
    
    // Extract payload data
    NSData *buffer = [data subdataWithRange:NSMakeRange(6, length)];
    
    return @{
        @"typeId": @(type),
        @"buffer": buffer ?: [NSData data]
    };
}

#pragma mark - Helper Methods

+ (NSData *)hexStringToData:(NSString *)hexString {
    if (!hexString || hexString.length % 2 != 0) {
        return nil;
    }
    
    const char *chars = [hexString UTF8String];
    NSMutableData *data = [NSMutableData dataWithCapacity:hexString.length / 2];
    
    for (int i = 0; i < hexString.length; i += 2) {
        char byteChars[3] = {chars[i], chars[i + 1], '\0'};
        unsigned char byte = strtol(byteChars, NULL, 16);
        [data appendBytes:&byte length:1];
    }
    
    return data;
}
+ (NSString *)getMessageNameFromType:(NSInteger)typeId messages:(id)messages {
    switch (typeId) {
        case 1:
            return @"Features";
        case 10026:
            return @"OnekeyFeatures";
        default:
            return @"Unknown";
    }
}

+ (NSString *)dataToHexString:(NSData *)data {
    const unsigned char *bytes = data.bytes;
    NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
    
    for (NSInteger i = 0; i < data.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    
    return hex.lowercaseString; // 确保输出小写
}

+ (id)receiveOne:(id)messages response:(NSString *)response error:(NSError **)error {
    if (!response || ![response isKindOfClass:[NSString class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Response is not string"}];
        }
        return nil;
    }
    
    NSLog(@"=== Raw Response ===");
    NSLog(@"Hex: %@", response);
    
    // Convert hex string to binary data
    NSData *data = [self hexStringToData:response];
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid hex string"}];
        }
        return nil;
    }
    
    // Decode protocol to get typeId and buffer
    NSDictionary *protocolData = [self decodeProtocol:data error:error];
    if (!protocolData) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Failed to decode protocol"}];
        }
        return nil;
    }
    
    NSInteger typeId = [protocolData[@"typeId"] integerValue];
    NSData *buffer = protocolData[@"buffer"];
    
    // Get message type based on typeId
    NSString *messageName;
    if (typeId == 17) {
        messageName = @"Features";
    } else if (typeId == 10026) {
        messageName = @"OnekeyFeatures";
    } else {
        messageName = @"Unknown";
    }
    
    // Parse message based on its type
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    if ([messageName isEqualToString:@"OnekeyFeatures"]) {
        // Parse OnekeyFeatures message according to protobuf definition
        [self parseOnekeyFeaturesFromBuffer:buffer intoMessage:message];
    } else if ([messageName isEqualToString:@"Features"]) {
        // Parse Features message
        [self parseFeaturesFromBuffer:buffer intoMessage:message];
    }
    
    // Log parsed data
    NSLog(@"=== Parsed Message ===");
    NSLog(@"Type: %@", messageName);
    [message enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSData class]]) {
            NSLog(@"%@: %@", key, [self dataToHexString:value]);
        } else {
            NSLog(@"%@: %@", key, value);
        }
    }];
    NSLog(@"==================");
    
    return @{
        @"type": messageName,
        @"message": message
    };
}

+ (void)parseOnekeyFeaturesFromBuffer:(NSData *)buffer intoMessage:(NSMutableDictionary *)message {
    // Example implementation - you'll need to implement proper protobuf parsing
    message[@"onekey_device_type"] = @1; // Example value
    message[@"onekey_board_version"] = @"1.0.0";
    message[@"onekey_boot_version"] = @"2.0.0";
    message[@"onekey_firmware_version"] = @"3.0.0";
    message[@"onekey_board_hash"] = [self dataToHexString:[buffer subdataWithRange:NSMakeRange(0, 32)]];
    message[@"onekey_boot_hash"] = [self dataToHexString:[buffer subdataWithRange:NSMakeRange(32, 32)]];
    message[@"onekey_firmware_hash"] = [self dataToHexString:[buffer subdataWithRange:NSMakeRange(64, 32)]];
    message[@"onekey_serial_no"] = @"SERIAL123";
    message[@"onekey_ble_name"] = @"OneKey Device";
    message[@"onekey_ble_version"] = @"1.0.0";
    message[@"onekey_se_type"] = @1;
}

+ (void)parseFeaturesFromBuffer:(NSData *)buffer intoMessage:(NSMutableDictionary *)message {
    // Example implementation - you'll need to implement proper protobuf parsing
    message[@"vendor"] = @"onekey.so";
    message[@"major_version"] = @1;
    message[@"minor_version"] = @0;
    message[@"patch_version"] = @0;
    message[@"bootloader_mode"] = @NO;
    message[@"model"] = @"OneKey Touch";
    message[@"initialized"] = @YES;
    message[@"pin_protection"] = @NO;
    message[@"passphrase_protection"] = @NO;
    message[@"firmware_present"] = @YES;
    message[@"needs_backup"] = @NO;
    message[@"flags"] = @0;
    message[@"ble_name"] = @"OneKey Device";
    message[@"ble_ver"] = @"1.0.0";
    message[@"serial_no"] = @"SERIAL123";
}

+ (id)checkCall:(id)jsonData error:(NSError **)error {
    if (![jsonData isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid response format"}];
        }
        return nil;
    }
    return jsonData;
}

+ (id)createMessageFromType:(id)messages typeId:(NSInteger)typeId error:(NSError **)error {
    NSString *messageName = [self getMessageNameFromType:typeId messages:messages];
    
    if ([messageName isEqualToString:@"Unknown"]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Unknown message type"}];
        }
        return nil;
    }
    
    // Create an empty message structure based on the type
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    message[@"type"] = messageName;
    
    return message;
}

+ (id)decodeProtobuf:(id)messages buffer:(NSData *)buffer error:(NSError **)error {
    if (!buffer) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Buffer is nil"}];
        }
        return nil;
    }
    
    // For now, assume the buffer contains JSON data
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:buffer options:0 error:&jsonError];
    
    if (jsonError) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Failed to decode JSON"}];
        }
        return nil;
    }
    
    return jsonObject;
}

@end 