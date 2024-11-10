#import "OKProtobufHelper.h"
#import "../MessagesCommon.pbobjc.h"
#import "../MessagesManagement.pbobjc.h"
#import <Protobuf/GPBMessage.h>

@implementation OKProtobufHelper

+ (NSData *)buildBuffersWithName:(NSString *)name params:(NSDictionary *)params messages:(NSDictionary *)messages {
    // Magic bytes and header
    uint8_t header[] = {
        0x3F, 0x23, 0x23,  // Magic bytes
        0x00, 0x00, 0x00   // Length (0 for GetFeatures)
    };
    
    // Create buffer with 64-byte capacity
    NSMutableData *buffer = [NSMutableData dataWithLength:64];
    
    // Copy header
    [buffer replaceBytesInRange:NSMakeRange(0, sizeof(header)) withBytes:header];
    
    // Rest of buffer is already zeroed out by dataWithLength:64
    
    return buffer;
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
    
    // 解析消息到字典
    NSMutableDictionary *messageDict = [self parseMessageToDict:message];
    messageDict[@"type"] = messageName;
    
    return messageDict;
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
