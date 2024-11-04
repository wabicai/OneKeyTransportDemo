#import "OKProtocolBuilder.h"

@implementation OKProtocolBuilder

- (NSData *)buildMessageWithType:(OKMessageType)type payload:(NSDictionary *)payload error:(NSError **)error {
    // Serialize the payload
    NSData *payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:error];
    if (*error) {
        return nil;
    }

    // Build the header
    uint8_t header[6];
    header[0] = 0x23; // Example magic byte 1
    header[1] = 0x23; // Example magic byte 2
    header[2] = (type >> 8) & 0xFF;
    header[3] = type & 0xFF;
    uint16_t length = CFSwapInt16HostToBig((uint16_t)payloadData.length);
    memcpy(&header[4], &length, 2);

    NSMutableData *message = [NSMutableData dataWithBytes:header length:6];
    [message appendData:payloadData];

    return message;
}

@end 