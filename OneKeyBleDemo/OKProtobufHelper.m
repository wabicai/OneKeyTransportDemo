#import "OKProtobufHelper.h"
#import "../MessagesManagement.pbobjc.h"

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
    NSLog(@"Messages config: %@", messages);
    
    NSData *data = [self hexStringToData:response];
    if (!data) {
        NSLog(@"Error: Failed to convert hex string to data");
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid hex string"}];
        }
        return nil;
    }
    NSLog(@"Converted hex data length: %lu", (unsigned long)data.length);
    
    NSError *protocolError;
    NSDictionary *protocolData = [self decodeProtocol:data error:&protocolError];
    if (!protocolData) {
        NSLog(@"Error decoding protocol: %@", protocolError);
        if (error) {
            *error = protocolError;
        }
        return nil;
    }
    
    NSInteger typeId = [protocolData[@"typeId"] integerValue];
    NSData *buffer = protocolData[@"buffer"];
    NSLog(@"Decoded typeId: %ld, buffer length: %lu", (long)typeId, (unsigned long)buffer.length);
    
    // 使用 createMessageFromType 获取消息字典
    NSError *createError = nil;
    NSDictionary *messageDict = [self createMessageFromType:messages typeId:typeId error:&createError];
    if (!messageDict) {
        if (error) {
            *error = createError;
        }
        return nil;
    }
    
    // 获取消息名称
    NSString *messageName = [self getMessageNameFromType:typeId messages:messages];
    
    return @{
        @"type": messageName,
        @"message": messageDict
    };
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
    
    // 使用 protobuf 生成的类来创建消息
    Class messageClass = NSClassFromString(messageName);
    if (!messageClass) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Message class not found"}];
        }
        return nil;
    }
    
    // 创建消息实例并解析
    GPBMessage *message = [[messageClass alloc] init];
    NSMutableDictionary *result = [self parseMessageToDict:message];
    result[@"type"] = messageName;
    
    return result;
}


+ (NSString *)buildOne:(id)messages name:(NSString *)name data:(NSDictionary *)data error:(NSError **)error {
    NSLog(@"=== buildOne Start ===");
    NSLog(@"Name: %@, Data: %@", name, data);
    
    NSInteger messageType = [self getMessageTypeForName:name messages:messages];
    
    NSData *buffer = [NSData data]; 
    
    NSMutableData *result = [NSMutableData data];
    
    uint16_t type = CFSwapInt16HostToBig((uint16_t)messageType);
    [result appendBytes:&type length:sizeof(type)];
    
    uint32_t length = CFSwapInt32HostToBig((uint32_t)buffer.length);
    [result appendBytes:&length length:sizeof(length)];
    
    [result appendData:buffer];
    
    NSString *hexString = [self dataToHexString:result];
    
    NSLog(@"=== buildOne Result ===");
    NSLog(@"Message Type: %ld", (long)messageType);
    NSLog(@"Buffer Length: %lu", (unsigned long)buffer.length);
    NSLog(@"Total Length: %lu", (unsigned long)result.length);
    NSLog(@"Hex String: %@", hexString);
    
    return hexString;
}


+ (NSInteger)getMessageTypeForName:(NSString *)name messages:(NSDictionary *)messages {
    // 直接通过类名获取对应的类
    Class messageClass = NSClassFromString(name);
    
    if (!messageClass) {
        NSLog(@"Failed to find class for message name: %@", name);
        return -1;
    }
    
    // 获取消息描述符
    GPBDescriptor *descriptor = [messageClass descriptor];
    if (!descriptor) {
        NSLog(@"Failed to get descriptor for class: %@", name);
        return -1;
    }
    
    // 获取消息类型 ID
    int32_t messageType = descriptor.wireFormat;
    return messageType;
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
