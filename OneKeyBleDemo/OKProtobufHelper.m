#import "OKProtobufHelper.h"
#import "../MessagesCommon.pbobjc.h"
#import "../MessagesManagement.pbobjc.h"

@implementation OKProtobufHelper


+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error {
    NSLog(@"\n=== 🔍 Protocol Decoding ===");
    NSLog(@"📊 Data Length: %lu bytes", (unsigned long)data.length);
    
    if (!data || data.length < 6) {
        NSLog(@"❌ Invalid data length (minimum 6 bytes required)");
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid data length"}];
        }
        return nil;
    }
    
    // Read header info
    uint16_t type = 0;
    [data getBytes:&type range:NSMakeRange(0, sizeof(type))];
    type = CFSwapInt16BigToHost(type);
    
    uint32_t length = 0;
    [data getBytes:&length range:NSMakeRange(2, sizeof(length))];
    length = CFSwapInt32BigToHost(length);
    
    NSLog(@"📋 Header Analysis:");
    NSLog(@"   • Type: 0x%04x (%d)", type, type);
    NSLog(@"   • Payload Length: %u bytes", length);
    NSLog(@"   • Total Length: %lu bytes", (unsigned long)(6 + length));
    
    // Extract payload
    NSData *buffer = [data subdataWithRange:NSMakeRange(6, length)];
    NSLog(@"✅ Protocol decode completed\n");
    
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
    NSLog(@"\n=== 🔍 Message Type Lookup ===");
    NSLog(@"🔑 Searching for Type ID: %ld", (long)typeId);
    
    if (![messages isKindOfClass:[NSDictionary class]]) {
        NSLog(@"❌ Invalid messages configuration");
        return @"Unknown";
    }
    
    NSDictionary *messagesDict = (NSDictionary *)messages;
    for (NSString *key in messagesDict) {
        if ([messagesDict[key] integerValue] == typeId) {
            NSLog(@"✅ Found message type: %@\n", key);
            return key;
        }
    }
    
    NSLog(@"⚠️ Unknown message type ID: %ld\n", (long)typeId);
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
    NSLog(@"\n=== 🔄 ReceiveOne Process Start ===");
    NSLog(@"📥 Input Response Length: %lu", (unsigned long)response.length);
    
    NSData *data = [self hexStringToData:response];
    if (!data) {
        NSLog(@"❌ Failed to convert hex string to data");
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid hex string"}];
        }
        return nil;
    }
    
    NSError *protocolError;
    NSDictionary *protocolData = [self decodeProtocol:data error:&protocolError];
    if (!protocolData) {
        NSLog(@"❌ Protocol decode failed: %@", protocolError);
        if (error) {
            *error = protocolError;
        }
        return nil;
    }
    
    NSInteger typeId = [protocolData[@"typeId"] integerValue];
    NSString *messageName = [self getMessageNameFromType:typeId messages:messages];
    NSLog(@"📦 Message Type: %@ (ID: %ld)", messageName, (long)typeId);
    
    // 使用 protobuf 生成的类来创建消息
    Class messageClass = NSClassFromString(messageName);

    if (!messageClass) {
        NSLog(@"Error: Message class not found for name: %@", messageName);
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Message class not found"}];
        }
        return nil;
    }
    
    NSError *parseError = nil;
    GPBMessage *message = [messageClass parseFromData:protocolData[@"buffer"] error:&parseError];
    if (parseError) {
        NSLog(@"Error parsing protobuf message: %@", parseError);
        if (error) {
            *error = parseError;
        }
        return nil;
    }
    
    // 解析消息到字典
    NSMutableDictionary *messageDict = [self parseMessageToDict:message];
    messageDict[@"type"] = messageName;
    
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


+ (NSArray<NSData *> *)buildBuffer:(id)messages name:(NSString *)name data:(NSDictionary *)data error:(NSError **)error {
    NSLog(@"\n=== 🔨 BuildBuffer Process Start ===");
    NSLog(@"📝 Message Name: %@", name);
    NSLog(@"📋 Input Data: %@", data);
    NSLog(@"⚙️ Messages Config: %@", messages);
    
    // Get message type
    NSNumber *typeNum = messages[name];
    if (!typeNum) {
        NSLog(@"❌ Message type not found for name: %@", name);
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Message type not found"}];
        }
        return nil;
    }
    NSLog(@"✅ Found message type: %@ (ID: %@)", name, typeNum);
    
    // Mock buffer for testing
    NSData *buffer = [@"test message" dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"📦 Created mock buffer length: %lu bytes", (unsigned long)buffer.length);
    
    // Encode protocol buffer with headers
    NSLog(@"\n=== 📝 Building Protocol Buffer ===");
    NSMutableData *encodedBuffer = [NSMutableData data];
    
    // Add header bytes (##)
    uint8_t headerBytes[] = {0x23, 0x23}; // ## as hex
    [encodedBuffer appendBytes:headerBytes length:2];
    NSLog(@"1️⃣ Added header bytes: ##");
    
    // Add message type (2 bytes)
    uint16_t type = CFSwapInt16HostToBig((uint16_t)[typeNum integerValue]);
    [encodedBuffer appendBytes:&type length:sizeof(type)];
    NSLog(@"2️⃣ Added message type: 0x%04x", type);
    
    // Add length (4 bytes)
    uint32_t length = CFSwapInt32HostToBig((uint32_t)buffer.length);
    [encodedBuffer appendBytes:&length length:sizeof(length)];
    NSLog(@"3️⃣ Added length: %u bytes", (uint32_t)buffer.length);
    
    // Add message data
    [encodedBuffer appendData:buffer];
    NSLog(@"4️⃣ Added message data");
    NSLog(@"📊 Total buffer size: %lu bytes", (unsigned long)encodedBuffer.length);
    
    // Split into chunks
    NSLog(@"\n=== 📦 Chunking Data ===");
    const NSUInteger BUFFER_SIZE = 64;
    NSLog(@"📏 Chunk size: %lu bytes", (unsigned long)BUFFER_SIZE);
    
    NSMutableArray<NSData *> *outBuffers = [NSMutableArray array];
    NSUInteger offset = 0;
    NSUInteger chunkIndex = 0;
    
    while (offset < encodedBuffer.length) {
        NSMutableData *chunkBuffer = [NSMutableData dataWithCapacity:BUFFER_SIZE + 1];
        uint8_t topChar = 0x3f; // MESSAGE_TOP_CHAR (?)
        [chunkBuffer appendBytes:&topChar length:1];
        
        NSUInteger remainingBytes = encodedBuffer.length - offset;
        NSUInteger chunkSize = MIN(BUFFER_SIZE, remainingBytes);
        [chunkBuffer appendBytes:((uint8_t *)encodedBuffer.bytes + offset) length:chunkSize];
        
        [outBuffers addObject:chunkBuffer];
        NSLog(@"  📦 Chunk %lu: %lu bytes", (unsigned long)chunkIndex++, (unsigned long)chunkBuffer.length);
        
        offset += chunkSize;
    }
    
    NSLog(@"\n=== ✅ BuildBuffer Complete ===");
    NSLog(@"📊 Total chunks created: %lu", (unsigned long)outBuffers.count);
    NSLog(@"🔍 Final buffers: %@\n", outBuffers);
    
    return outBuffers;
}


+ (NSInteger)getMessageTypeForName:(NSString *)name messages:(NSDictionary *)messages {
    // 直接通过类名获取对应的类
    Class messageClass = NSClassFromString(name);
    
    if (!messageClass) {
        NSLog(@"Failed to find class for message name: %@", name);
        return -1;
    }
    
    // 获取消息描符
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
            NSString *hexString = [self dataToHexString:value];
            NSLog(@"Transformed bytes to hex: %@", hexString);
            return hexString;
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
        NSLog(@"Transformed enum array: %@", result);
        return result;
    }
    
    // Handle regular arrays
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:[value count]];
        for (id item in value) {
            [result addObject:[self transformValue:item field:field]];
        }
        NSLog(@"Transformed array: %@", result);
        return result;
    }
    
    // Handle message types
    if ([value isKindOfClass:[GPBMessage class]]) {
        NSDictionary *dict = [self parseMessageToDict:(GPBMessage *)value];
        NSLog(@"Transformed message to dict: %@", dict);
        return dict;
    }
    
    return value;
}

+ (NSDictionary *)parseMessageToDict:(GPBMessage *)message {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    GPBDescriptor *descriptor = [[message class] descriptor];
    NSArray *fields = descriptor.fields;
    
    NSLog(@"=== Parsing Message to Dict ===");
    for (GPBFieldDescriptor *field in fields) {
        NSString *fieldName = field.name;
        NSString *originalName = field.textFormatName; // 使用原始的字段名
        BOOL hasValue = NO;
        
        // 检查字段是否有值
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
        
        // 获取值
        id value = [message valueForKey:fieldName];
        if (hasValue || [value isKindOfClass:[NSArray class]] || value != nil) {
            id transformedValue = [self transformValue:value field:field];
            if (transformedValue) {
                // 使用原始的字段名作为 key
                result[originalName] = transformedValue;
            }
        }
    }
    
    NSLog(@"=== Parsing Result ===");
    return result;
}


// Mock TypeScript: Message.create(data)
+ (void)setMessageData:(GPBMessage *)message fromDictionary:(NSDictionary *)data {
    NSLog(@"=== setMessageData Start ===");
    NSLog(@"Setting data for message: %@", [message class]);
    NSLog(@"Input dictionary: %@", data);
    
    if (!message || !data) {
        NSLog(@"Warning: Null message or data");
        return;
    }
    
    GPBDescriptor *descriptor = [[message class] descriptor];
    NSArray *fields = descriptor.fields;
    
    for (GPBFieldDescriptor *field in fields) {
        id value = data[field.name];
        if (!value) {
            NSLog(@"No value for field: %@", field.name);
            continue;
        }
        
        NSLog(@"Setting field: %@ with value: %@", field.name, value);
        
        switch (field.dataType) {
            case GPBDataTypeBool:
                [message setField:field value:@([value boolValue])];
                break;
            case GPBDataTypeString:
                [message setField:field value:value];
                break;
            case GPBDataTypeInt32:
            case GPBDataTypeInt64:
                [message setField:field value:@([value integerValue])];
                break;
            case GPBDataTypeUInt32:
            case GPBDataTypeUInt64:
                [message setField:field value:@([value unsignedIntegerValue])];
                break;
            case GPBDataTypeBytes:
                if ([value isKindOfClass:[NSString class]]) {
                    [message setField:field value:[self hexStringToData:value]];
                }
                break;
            case GPBDataTypeMessage:
                if ([value isKindOfClass:[NSDictionary class]]) {
                    GPBMessage *subMessage = [[field.msgClass alloc] init];
                    [self setMessageData:subMessage fromDictionary:value];
                    [message setField:field value:subMessage];
                }
                break;
            case GPBDataTypeEnum:
                [message setField:field value:@([value integerValue])];
                break;
            default:
                NSLog(@"Unsupported field type: %d for field: %@", field.dataType, field.name);
                break;
        }
    }
    
    NSLog(@"=== setMessageData End ===");
}

@end 
