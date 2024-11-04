#import "OKProtobufHelper.h"
#import "Features.pbobjc.h"

@implementation OKProtobufHelper


+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error {
    NSLog(@"=== decodeProtocol Start ===");
    NSLog(@"Input data length: %lu", (unsigned long)data.length);
    NSLog(@"Raw data (hex): %@", [self dataToHexString:data]);
    
    if (!data || data.length < 6) {
        NSLog(@"Error: Invalid data length - minimum required is 6 bytes");
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid data length"}];
        }
        return nil;
    }
    
    // Log first 6 bytes separately for header analysis
    NSData *headerData = [data subdataWithRange:NSMakeRange(0, 6)];
    NSLog(@"Header bytes (hex): %@", [self dataToHexString:headerData]);
    
    // Read message type (first 2 bytes)
    uint16_t type = 0;
    [data getBytes:&type range:NSMakeRange(0, sizeof(type))];
    type = CFSwapInt16BigToHost(type);
    NSLog(@"Type bytes: 0x%04x", type);
    
    // Read data length (next 4 bytes)
    uint32_t length = 0;
    [data getBytes:&length range:NSMakeRange(2, sizeof(length))];
    length = CFSwapInt32BigToHost(length);
    NSLog(@"Length bytes: 0x%08x (%u decimal)", length, length);
    
    NSLog(@"Decoded header - Type: %d (0x%04x), Length: %d", type, type, length);
    
    // Validate total length
    NSUInteger totalLength = 6 + length;
    NSLog(@"Expected total length: %lu", (unsigned long)totalLength);
    NSLog(@"Actual data length: %lu", (unsigned long)data.length);
    
    if (data.length < totalLength) {
        NSLog(@"Error: Data length mismatch - Expected: %lu, Actual: %lu", 
              (unsigned long)totalLength, (unsigned long)data.length);
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Data length mismatch"}];
        }
        return nil;
    }
    
    // Extract payload data
    NSData *buffer = [data subdataWithRange:NSMakeRange(6, length)];
    NSLog(@"Extracted buffer length: %lu", (unsigned long)buffer.length);
    NSLog(@"Buffer content (hex): %@", [self dataToHexString:buffer]);
    NSLog(@"=== decodeProtocol End ===");
    
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
    NSLog(@"Looking for typeId: %ld in messages: %@", (long)typeId, messages);
    if (![messages isKindOfClass:[NSDictionary class]]) {
        return @"Unknown";
    }
    
    // 遍历 messages 字典，查找匹配的 typeId
    NSDictionary *messagesDict = (NSDictionary *)messages;
    for (NSString *key in messagesDict) {
        if ([messagesDict[key] integerValue] == typeId) {
            return key;
        }
    }
    
    NSLog(@"Unknown typeId: %ld, available types: %@", (long)typeId, messages);
    return @"Unknown";
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
    NSLog(@"=== receiveOne Start ===");
    NSLog(@"Raw Response: %@", response);
    
    if (!response || ![response isKindOfClass:[NSString class]]) {
        NSLog(@"Error: Response is not string");
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Response is not string"}];
        }
        return nil;
    }
    
    // Convert hex string to binary data
    NSData *data = [self hexStringToData:response];
    if (!data) {
        NSLog(@"Error: Invalid hex string");
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid hex string"}];
        }
        return nil;
    }
    
    NSLog(@"Binary data length: %lu", (unsigned long)data.length);
    
    // Decode protocol to get typeId and buffer
    NSError *protocolError;
    NSDictionary *protocolData = [self decodeProtocol:data error:&protocolError];
    NSLog(@"Decoded Protocol: %@", protocolData);
    if (!protocolData) {
        NSLog(@"Error: Protocol decode failed - %@", protocolError.localizedDescription);
        if (error) {
            *error = protocolError;
        }
        return nil;
    }
    
    NSInteger typeId = [protocolData[@"typeId"] integerValue];
    NSData *buffer = protocolData[@"buffer"];
    
    NSLog(@"Decoded Protocol - TypeID: %ld, Buffer length: %lu", 
          (long)typeId, (unsigned long)buffer.length);
    
    // Get message type based on typeId
    NSString *messageName = [self getMessageNameFromType:typeId messages:messages];
    NSLog(@"Message Type: %@", messageName);
    
    // Parse message based on its type
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    if ([messageName isEqualToString:@"OnekeyFeatures"]) {
        [self parseOnekeyFeaturesFromBuffer:buffer intoMessage:message];
    } else if ([messageName isEqualToString:@"Features"]) {
        [self parseFeaturesFromBuffer:buffer intoMessage:message];
    }
    
    NSLog(@"=== Parsed Message ===");
    [message enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        NSLog(@"%@: %@", key, value);
    }];
    NSLog(@"=== receiveOne End ===");
    
    return @{
        @"type": messageName,
        @"message": message
    };
}

+ (void)parseOnekeyFeaturesFromBuffer:(NSData *)buffer intoMessage:(NSMutableDictionary *)message {
    NSLog(@"Parsing OnekeyFeatures buffer length: %lu", (unsigned long)buffer.length);
    NSLog(@"Buffer hex: %@", [self dataToHexString:buffer]);
    
    const uint8_t *bytes = buffer.bytes;
    NSUInteger length = buffer.length;
    NSUInteger index = 0;
    
    while (index < length) {
        uint8_t tag = bytes[index++];
        uint32_t fieldNumber = tag >> 3;
        uint32_t wireType = tag & 0x7;
        
        switch (wireType) {
            case 0: { // Varint
                uint64_t value = 0;
                uint8_t byte;
                int shift = 0;
                do {
                    byte = bytes[index++];
                    value |= ((uint64_t)(byte & 0x7F) << shift);
                    shift += 7;
                } while (byte & 0x80);
                
                switch (fieldNumber) {
                    case 1: // onekey_device_type
                        message[@"onekey_device_type"] = @"PRO";
                        break;
                    // Add more cases for other numeric fields
                }
                break;
            }
            case 2: { // Length-delimited
                uint64_t strLength = 0;
                uint8_t byte;
                int shift = 0;
                do {
                    byte = bytes[index++];
                    strLength |= ((uint64_t)(byte & 0x7F) << shift);
                    shift += 7;
                } while (byte & 0x80);
                
                NSData *strData = [NSData dataWithBytes:&bytes[index] length:strLength];
                NSString *strValue = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
                index += strLength;
                
                switch (fieldNumber) {
                    case 2: // onekey_board_version
                        message[@"onekey_board_version"] = strValue;
                        break;
                    case 3: // onekey_boot_version
                        message[@"onekey_boot_version"] = strValue;
                        break;
                    // Add more cases based on proto definition
                }
                break;
            }
        }
    }
    
    NSLog(@"Parsed OnekeyFeatures message: %@", message);
}

+ (void)parseFeaturesFromBuffer:(NSData *)buffer intoMessage:(NSMutableDictionary *)message {
    NSError *error = nil;
    Features *features = [Features parseFromData:buffer error:&error];
    
    if (error) {
        NSLog(@"Error parsing protobuf: %@", error);
        return;
    }
    
    NSDictionary *parsedFeatures = [self parseMessageToDict:features];
    [message addEntriesFromDictionary:parsedFeatures];
    
    NSLog(@"Parsed Features message: %@", message);
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

+ (NSString *)buildOne:(id)messages name:(NSString *)name data:(NSDictionary *)data error:(NSError **)error {
    if (!messages || ![messages isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid messages object"}];
        }
        return nil;
    }
    
    // Get message type ID from messages dictionary
    NSNumber *typeId = messages[name];
    if (!typeId) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Unknown message type"}];
        }
        return nil;
    }
    
    // Create protocol header (6 bytes)
    uint16_t type = CFSwapInt16HostToBig([typeId unsignedShortValue]);
    NSMutableData *header = [NSMutableData dataWithBytes:&type length:sizeof(type)];
    
    // Convert data dictionary to JSON
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
    if (jsonError) {
        if (error) {
            *error = jsonError;
        }
        return nil;
    }
    
    // Add length to header (4 bytes)
    uint32_t length = CFSwapInt32HostToBig((uint32_t)jsonData.length);
    [header appendBytes:&length length:sizeof(length)];
    
    // Combine header and data
    NSMutableData *message = [header mutableCopy];
    [message appendData:jsonData];
    
    // Convert to hex string
    return [self dataToHexString:message];
}

+ (id)transformValue:(id)value field:(GPBFieldDescriptor *)field {
    if (!value) {
        return [NSNull null];
    }
    
    // Handle bytes type
    if (field.dataType == GPBDataTypeBytes) {
        if ([value isKindOfClass:[NSData class]]) {
            return [self dataToHexString:value];
        }
        return value;
    }
    
    // Handle enum arrays
    if ([value isKindOfClass:[GPBEnumArray class]]) {
        GPBEnumArray *enumArray = (GPBEnumArray *)value;
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:enumArray.count];
        for (NSUInteger i = 0; i < enumArray.count; i++) {
            [result addObject:@([enumArray valueAtIndex:i])];
        }
        return result;
    }
    
    // Handle regular arrays
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:[value count]];
        for (id item in value) {
            [result addObject:[self transformValue:item field:field]];
        }
        return result;
    }
    
    // Handle message types
    if ([value isKindOfClass:[GPBMessage class]]) {
        return [self parseMessageToDict:(GPBMessage *)value];
    }
    
    return value;
}

+ (NSDictionary *)parseMessageToDict:(GPBMessage *)message {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    GPBDescriptor *descriptor = [[message class] descriptor];
    NSArray *fields = descriptor.fields;
    
    for (GPBFieldDescriptor *field in fields) {
        NSString *fieldName = field.name;
        BOOL hasValue = NO;
        
        // Check if the field has a value using the dynamic has accessor
        SEL hasSelector = NSSelectorFromString([NSString stringWithFormat:@"has%@%@",
                                              [[fieldName substringToIndex:1] uppercaseString],
                                              [fieldName substringFromIndex:1]]);
        
        if ([message respondsToSelector:hasSelector]) {
            NSMethodSignature *signature = [message methodSignatureForSelector:hasSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:hasSelector];
            [invocation setTarget:message];
            [invocation invoke];
            [invocation getReturnValue:&hasValue];
        }
        
        // Get the value using KVC
        id value = [message valueForKey:fieldName];
        
        // Only include the field if:
        // 1. It has a value (hasValue is true), or
        // 2. It's an array type, or
        // 3. It's a non-nil value
        if (hasValue || 
            [value isKindOfClass:[NSArray class]] || 
            value != nil) {
            id transformedValue = [self transformValue:value field:field];
            if (transformedValue) {
                result[fieldName] = transformedValue;
            }
        }
    }
    
    return result;
}

@end 
