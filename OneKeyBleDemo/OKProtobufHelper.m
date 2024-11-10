#import "OKProtobufHelper.h"
#import "../MessagesCommon.pbobjc.h"
#import "../MessagesManagement.pbobjc.h"

@implementation OKProtobufHelper

+ (NSData *)buildBuffer:(NSString *)name params:(NSDictionary *)params messages:(NSDictionary *)messages {
    NSLog(@"=== 🔧 Building Buffer ===");
    NSLog(@"Command: %@", name);
    NSLog(@"Params: %@", params);
    
    // Get message type ID
    NSNumber *messageType = messages[name];
    if (!messageType) {
        NSLog(@"❌ Message type not found for: %@", name);
        return nil;
    }
    
    // Create protobuf message
    Class messageClass = NSClassFromString(name);
    if (!messageClass) {
        NSLog(@"❌ Message class not found for: %@", name);
        return nil;
    }
    
    // Create and populate protobuf message
    GPBMessage *message = [[messageClass alloc] init];
    for (NSString *key in params) {
        [message setValue:params[key] forKey:key];
    }
    
    // Serialize protobuf message
    NSError *error = nil;
    NSData *messageData = [message data];
    if (!messageData) {
        NSLog(@"❌ Failed to serialize message: %@", error);
        return nil;
    }
    
    // Create fixed-size buffer (64 bytes)
    NSMutableData *buffer = [NSMutableData dataWithLength:64];
    
    // Add magic bytes (? ## in correct order)
    uint8_t magicBytes[] = {0x3F, 0x23, 0x23};
    [buffer replaceBytesInRange:NSMakeRange(0, sizeof(magicBytes)) withBytes:magicBytes];
    
    // Add message type (2 bytes)
    uint16_t typeId = CFSwapInt16HostToBig(messageType.unsignedShortValue);
    [buffer replaceBytesInRange:NSMakeRange(3, sizeof(typeId)) withBytes:&typeId];
    
    // Add length (4 bytes)
    uint32_t length = CFSwapInt32HostToBig((uint32_t)messageData.length);
    [buffer replaceBytesInRange:NSMakeRange(5, sizeof(length)) withBytes:&length];
    
    // Add message data if any (starting at offset 9)
    if (messageData.length > 0) {
        NSUInteger maxDataLength = buffer.length - 9;
        NSUInteger copyLength = MIN(messageData.length, maxDataLength);
        [buffer replaceBytesInRange:NSMakeRange(9, copyLength) withBytes:messageData.bytes];
    }
    
    NSLog(@"✅ Buffer built successfully");
    NSLog(@"Buffer length: %lu", (unsigned long)buffer.length);
    
    return buffer;
}

+ (id)receiveOne:(id)messages response:(NSString *)response error:(NSError **)error {
    NSLog(@"\n=== 🔄 ReceiveOne Process Start ===");
    NSLog(@"📥 Input Response Length: %lu", (unsigned long)response.length);
    
    NSData *data = [self hexStringToData:response];
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid hex string"}];
        }
        return nil;
    }
    
    return [self receiveOneWithData:data messages:messages error:error];
}

+ (id)receiveOneWithData:(NSData *)data messages:(id)messages error:(NSError **)error {
    NSLog(@"\n=== 🔄 ReceiveOne Process Start ===");
    NSLog(@"📥 Input Data Length: %lu", (unsigned long)data.length);
    
    NSError *protocolError;
    NSDictionary *protocolData = [self decodeProtocol:data error:&protocolError];
    if (!protocolData) {
        if (error) {
            *error = protocolError;
        }
        return nil;
    }
    
    NSInteger typeId = [protocolData[@"typeId"] integerValue];
    NSString *messageName = [self getMessageNameFromType:typeId messages:messages];
    NSLog(@"📦 Message Type: %@ (ID: %ld)", messageName, (long)typeId);
    
    Class messageClass = NSClassFromString(messageName);
    if (!messageClass) {
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
        if (error) {
            *error = parseError;
        }
        return nil;
    }
    
    NSDictionary *messageDict = [self parseMessageToDict:message];
    return @{
        @"type": messageName,
        @"message": messageDict ?: @{}
    };
}

// Helper method to decode protocol header
+ (BOOL)decodeProtocolHeader:(NSData *)data 
                     typeId:(uint16_t *)typeId 
              messageBuffer:(NSData **)messageBuffer 
                    error:(NSError **)error {
    if (data.length < 3) { // Minimum header size
        if (error) {
            *error = [NSError errorWithDomain:@"OKProtobufHelper" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Data too short"}];
        }
        return NO;
    }
    
    // First 2 bytes are typeId
    *typeId = CFSwapInt16BigToHost(*(uint16_t *)data.bytes);
    
    // Rest is message buffer
    *messageBuffer = [data subdataWithRange:NSMakeRange(2, data.length - 2)];
    
    return YES;
}

// Helper method to convert NSData to hex string
+ (NSString *)hexStringFromData:(NSData *)data {
    NSMutableString *string = [NSMutableString stringWithCapacity:data.length * 2];
    const unsigned char *bytes = data.bytes;
    for (NSInteger i = 0; i < data.length; i++) {
        [string appendFormat:@"%02x", bytes[i]];
    }
    return string;
}

+ (NSString *)getMessageNameForTypeId:(NSInteger)typeId fromMessages:(id)messages {
    NSLog(@"\n=== 🔍 Message Type Lookup ===");
    NSLog(@"🔑 Searching for Type ID: %ld", (long)typeId);
    
    if (![messages isKindOfClass:[NSDictionary class]]) {
        NSLog(@"❌ Invalid messages configuration");
        return nil;
    }
    
    NSDictionary *messagesDict = (NSDictionary *)messages;
    for (NSString *key in messagesDict) {
        if ([messagesDict[key] integerValue] == typeId) {
            NSLog(@"✅ Found message type: %@\n", key);
            return key;
        }
    }
    
    NSLog(@"⚠️ Unknown message type ID: %ld\n", (long)typeId);
    return nil;
}

+ (id)decodeProtobufMessage:(NSData *)buffer forType:(NSString *)messageName messages:(id)messages error:(NSError **)error {
    Class messageClass = NSClassFromString(messageName);
    if (!messageClass) {
        if (error) {
            *error = [NSError errorWithDomain:@"OKProtobufHelper" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Message class not found"}];
        }
        return nil;
    }
    
    NSError *parseError = nil;
    GPBMessage *message = [messageClass parseFromData:buffer error:&parseError];
    if (parseError) {
        if (error) {
            *error = parseError;
        }
        return nil;
    }
    
    return [self parseMessageToDict:message];
}

+ (NSString *)getMessageNameFromType:(NSInteger)typeId messages:(id)messages {
    if (![messages isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *messagesDict = (NSDictionary *)messages;
    for (NSString *key in messagesDict) {
        if ([messagesDict[key] integerValue] == typeId) {
            return key;
        }
    }
    
    return nil;
}

+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error {
    if (!data || data.length < 6) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Invalid data length"}];
        }
        return nil;
    }
    
    uint16_t type = 0;
    [data getBytes:&type range:NSMakeRange(0, 2)];
    type = CFSwapInt16BigToHost(type);
    
    uint32_t length = 0;
    [data getBytes:&length range:NSMakeRange(2, 4)];
    length = CFSwapInt32BigToHost(length);
    
    if (data.length < length + 6) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.onekey.ble" 
                                       code:-1 
                                   userInfo:@{NSLocalizedDescriptionKey: @"Data too short"}];
        }
        return nil;
    }
    
    NSData *buffer = [data subdataWithRange:NSMakeRange(6, length)];
    
    return @{
        @"typeId": @(type),
        @"buffer": buffer
    };
}

+ (NSDictionary *)parseMessageToDict:(GPBMessage *)message {
    if (!message) {
        return @{};
    }
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    GPBDescriptor *descriptor = [[message class] descriptor];
    NSArray *fields = descriptor.fields;
    
    for (GPBFieldDescriptor *field in fields) {
        NSString *fieldName = field.name;
        id value = [message valueForKey:fieldName];
        
        if (value) {
            if ([value isKindOfClass:[GPBMessage class]]) {
                // 递归处理嵌套消息
                result[fieldName] = [self parseMessageToDict:value];
            } else if ([value isKindOfClass:[NSArray class]] || 
                       [value isKindOfClass:[GPBEnumArray class]]) {
                // 处理数组类型
                result[fieldName] = [self transformValue:value field:field];
            } else {
                // 处理基本类型
                result[fieldName] = value;
            }
        }
    }
    
    return result;
}

+ (id)transformValue:(id)value field:(GPBFieldDescriptor *)field {
    if (!value) {
        return [NSNull null];
    }
    
    // 处理字节类型
    if (field.dataType == GPBDataTypeBytes) {
        if ([value isKindOfClass:[NSData class]]) {
            return [self dataToHexString:value];
        }
        return value;
    }
    
    // 处理枚举数组
    if ([value isKindOfClass:[GPBEnumArray class]]) {
        GPBEnumArray *enumArray = (GPBEnumArray *)value;
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:enumArray.count];
        for (NSUInteger i = 0; i < enumArray.count; i++) {
            [result addObject:@([enumArray valueAtIndex:i])];
        }
        return result;
    }
    
    // 处理普通数组
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray array];
        for (id item in value) {
            if ([item isKindOfClass:[GPBMessage class]]) {
                [result addObject:[self parseMessageToDict:item]];
            } else {
                [result addObject:item];
            }
        }
        return result;
    }
    
    return value;
}

@end 
