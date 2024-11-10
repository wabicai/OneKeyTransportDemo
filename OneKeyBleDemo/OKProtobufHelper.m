#import "OKProtobufHelper.h"

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

+ (NSDictionary *)receiveOneWithData:(NSData *)data messages:(id)messages {
    NSLog(@"Received data length: %lu", (unsigned long)data.length);
    NSLog(@"Received data hex: %@", [self hexStringFromData:data]);
    
    if (!data || data.length < 3) {
        NSLog(@"Invalid data: too short");
        return nil;
    }
    
    // 解析头部获取 typeId (前两个字节)
    uint16_t typeId = CFSwapInt16BigToHost(*(uint16_t *)data.bytes);
    NSLog(@"Type ID: %d", typeId);
    
    // 获取消息内容 (跳过头部)
    NSData *messageBuffer = [data subdataWithRange:NSMakeRange(2, data.length - 2)];
    
    // 根据 typeId 获取消息类型
    NSString *messageName = [self getMessageNameForTypeId:typeId fromMessages:messages];
    if (!messageName) {
        NSLog(@"Unknown message type for typeId: %d", typeId);
        return nil;
    }
    
    // 解析 protobuf 消息
    NSError *error = nil;
    id decodedMessage = [self decodeProtobufMessage:messageBuffer forType:messageName messages:messages error:&error];
    if (error) {
        NSLog(@"Failed to decode protobuf message: %@", error);
        return nil;
    }
    
    return @{
        @"message": decodedMessage ?: [NSNull null],
        @"type": messageName
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

@end 
