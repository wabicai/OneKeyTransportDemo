#import "OKProtobufHelper.h"

@implementation OKProtobufHelper

+ (NSData *)buildOneWithMessages:(id)messages name:(NSString *)name data:(NSDictionary *)data {
    // 参考 send.ts 的实现
    // startLine: 13
    // endLine: 22
    
    // 1. 创建消息
    NSInteger messageType = [self getMessageTypeFromName:name messages:messages];
    NSData *buffer = [self encodeProtobufWithMessage:name data:data messages:messages];
    
    // 2. 编码协议
    return [self encodeProtocolWithData:buffer messageType:messageType];
}

+ (NSDictionary *)receiveOneWithMessages:(id)messages data:(NSString *)data {
    if (!data || ![data isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    // Convert hex string to NSData
    NSData *binaryData = [self hexStringToData:data];
    if (!binaryData) {
        return nil;
    }
    
    // 1. Decode protocol
    NSDictionary *protocolResult = [self decodeProtocolWithData:binaryData];
    if (!protocolResult) {
        return nil;
    }
    
    NSInteger typeId = [protocolResult[@"typeId"] integerValue];
    NSData *buffer = protocolResult[@"buffer"];
    
    // 2. Get message name from type ID
    NSString *messageName = [self getMessageNameFromType:typeId messages:messages];
    
    // 3. Decode protobuf message
    NSDictionary *message = [self decodeProtobufWithBuffer:buffer messageName:messageName messages:messages];
    
    // Add logging
    NSLog(@"=== Decoded Response ===");
    NSLog(@"Type: %@", messageName);
    NSLog(@"Message: %@", message);
    
    NSDictionary *result = @{
        @"message": message ?: @{},
        @"type": messageName ?: @"Unknown"
    };
    
    NSLog(@"Full Result: %@", result);
    NSLog(@"==================");
    
    return result;
}

+ (NSData *)encodeProtocolWithData:(NSData *)data messageType:(NSInteger)messageType {
    // 创建一个 ByteBuffer 来构建协议数据
    NSMutableData *buffer = [NSMutableData data];
    
    // 写入消息类型 (2字节)
    uint16_t type = CFSwapInt16HostToBig((uint16_t)messageType);
    [buffer appendBytes:&type length:sizeof(type)];
    
    // 写入数据长度 (4字节)
    uint32_t length = CFSwapInt32HostToBig((uint32_t)data.length);
    [buffer appendBytes:&length length:sizeof(length)];
    
    // 写入数据
    [buffer appendData:data];
    
    return buffer;
}

+ (NSDictionary *)decodeProtocolWithData:(NSData *)data {
    if (!data || data.length < 6) {
        return nil;
    }
    
    // 读取消息类型
    uint16_t type = 0;
    [data getBytes:&type range:NSMakeRange(0, sizeof(type))];
    type = CFSwapInt16BigToHost(type);
    
    // 读取数据长度
    uint32_t length = 0;
    [data getBytes:&length range:NSMakeRange(2, sizeof(length))];
    length = CFSwapInt32BigToHost(length);
    
    // 验证数据长度
    NSUInteger totalLength = 6 + length;
    if (data.length < totalLength) {
        return nil;
    }
    
    // 提取数据
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

+ (NSInteger)getMessageTypeFromName:(NSString *)name messages:(id)messages {
    // Get message type mapping from messages definition
    if ([name isEqualToString:@"Features"]) {
        return 1;  // Features message type
    } else if ([name isEqualToString:@"OnekeyFeatures"]) {
        return 10026; // OnekeyFeatures message type from messages.proto
    }
    // Add more message type mappings as needed
    return 0;
}

+ (NSData *)encodeProtobufWithMessage:(NSString *)name data:(NSDictionary *)data messages:(id)messages {
    // 临时实现，将数据转换为 JSON 格式
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data ?: @{} options:0 error:&error];
    if (error) {
        return nil;
    }
    return jsonData;
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

+ (NSDictionary *)decodeProtobufWithBuffer:(NSData *)buffer messageName:(NSString *)messageName messages:(id)messages {
    if (!buffer || !messageName || ![messageName isKindOfClass:[NSString class]]) {
        return @{};
    }
    
    // Here we should implement proper protobuf decoding based on the message definition
    // For now, we'll use JSON as a temporary solution
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:buffer options:0 error:&error];
    if (error) {
        NSLog(@"Protobuf decoding error: %@", error);
        return @{};
    }
    
    // Add message-specific field processing
    if ([messageName isEqualToString:@"Features"] || [messageName isEqualToString:@"OnekeyFeatures"]) {
        NSMutableDictionary *processedMessage = [NSMutableDictionary dictionaryWithDictionary:json];
        
        // Convert any binary/hex fields to proper format
        for (NSString *key in json) {
            if ([key hasSuffix:@"_hash"] || [key isEqualToString:@"session_id"]) {
                NSString *hexValue = json[key];
                if ([hexValue isKindOfClass:[NSString class]]) {
                    processedMessage[key] = [self hexStringToData:hexValue];
                }
            }
        }
        
        return processedMessage;
    }
    
    return json ?: @{};
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
    NSDictionary *protocolData = [self decodeProtocolWithData:data];
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

@end 